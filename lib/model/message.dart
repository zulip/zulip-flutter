import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../log.dart';
import 'message_list.dart';
import 'store.dart';

const _apiSendMessage = sendMessage; // Bit ugly; for alternatives, see: https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20PerAccountStore.20methods/near/1545809
const kLocalEchoDebounceDuration = Duration(milliseconds: 300);  // TODO(#1441) find the right values for this
const kSendMessageRetryWaitPeriod = Duration(seconds: 10);  // TODO(#1441) find the right values for this

/// States of an [OutboxMessage] since its creation from a
/// [MessageStore.sendMessage] call and before its eventual deletion.
///
/// ```
///                 4xx or other                        User restores
///                 error.                              the draft.
///                ┌──────┬─────────────────┬──► failed ──────────┐
///                │      ▲                 ▲                     ▼
/// (create) ─► hidden    └─── waiting      └─ waitPeriodExpired ─┴► (delete)
///                │            ▲   │          ▲
///                └────────────┘   └──────────┘
///                Debounce         Wait period
///                timed out.       timed out.
///
///              Event received.
///              Or we abandoned the queue.
/// (any state) ────────────────────────────► (delete)
/// ```
///
/// During its lifecycle, it is guaranteed that the outbox message is deleted
/// as soon a message event with a matching [MessageEvent.localMessageId]
/// arrives.
enum OutboxMessageState {
  /// The [sendMessage] request has started but hasn't finished, and the
  /// outbox message is hidden to the user.
  ///
  /// This is the initial state when an [OutboxMessage] is created.
  hidden,

  /// The [sendMessage] request has started but hasn't finished, and the
  /// outbox message is shown to the user.
  ///
  /// This state can be reached after staying in [hidden] for
  /// [kLocalEchoDebounceDuration].
  waiting,

  /// The message was assumed not delivered after some time it was sent.
  ///
  /// This state can be reached when the message event hasn't arrived in
  /// [kSendMessageRetryWaitPeriod] since the outbox message's creation.
  waitPeriodExpired,

  /// The message could not be delivered.
  ///
  /// This state can be reached when we got a 4xx or other error in the HTTP
  /// response.
  failed,
}

/// A message sent by the self-user.
sealed class OutboxMessage<T extends Conversation> implements MessageBase<T> {
  OutboxMessage({
    required this.localMessageId,
    required int selfUserId,
    required this.content,
  }) : senderId = selfUserId,
       timestamp = (DateTime.timestamp().millisecondsSinceEpoch / 1000).toInt(),
       _state = OutboxMessageState.hidden;

  static OutboxMessage fromDestination(MessageDestination destination, {
    required int localMessageId,
    required int selfUserId,
    required String content,
    required int zulipFeatureLevel,
    required String? realmEmptyTopicDisplayName,
  }) {
    return switch (destination) {
      StreamDestination(:final streamId, :final topic) => StreamOutboxMessage(
        localMessageId: localMessageId,
        selfUserId: selfUserId,
        conversation: StreamConversation(
          streamId,
          topic.interpretAsServer(
            // Because either of the values can get updated, the actual topic
            // can change, for example, between "(no topic)" and "general chat",
            // or between different names of "general chat".  This should be
            // uncommon during the lifespan of an outbox message.
            //
            // There's also an unavoidable race that has the same effect:
            // an admin could change the name of "general chat"
            // (i.e. the value of realmEmptyTopicDisplayName) concurrently with
            // the user making the send request, so that the setting in effect
            // by the time the request arrives is different from the setting the
            // client last heard about.  The realm update events do not have
            // information about this race for us to update the prediction
            // correctly.
            zulipFeatureLevel: zulipFeatureLevel,
            realmEmptyTopicDisplayName: realmEmptyTopicDisplayName),
          displayRecipient: null),
        content: content),
      DmDestination(:final userIds) => DmOutboxMessage(
        localMessageId: localMessageId,
        selfUserId: selfUserId,
        conversation: DmConversation(allRecipientIds: userIds),
        content: content),
    };
  }

  /// As in [MessageEvent.localMessageId].
  ///
  /// This uniquely identifies this outbox message's corresponding message object
  /// in events from the same event queue.
  ///
  /// See also:
  ///  * [MessageStoreImpl.sendMessage], where this ID is assigned.
  final int localMessageId;
  @override
  int? get id => null;
  @override
  final int senderId;
  @override
  final int timestamp;
  final String content;

  OutboxMessageState get state => _state;
  OutboxMessageState _state;
  set state(OutboxMessageState value) {
    // See [OutboxMessageState] for valid state transitions.
    assert(_state != value);
    switch (value) {
      case OutboxMessageState.hidden:
        assert(false);
      case OutboxMessageState.waiting:
        assert(_state == OutboxMessageState.hidden);
      case OutboxMessageState.waitPeriodExpired:
        assert(_state == OutboxMessageState.waiting);
      case OutboxMessageState.failed:
        assert(_state == OutboxMessageState.hidden
          || _state == OutboxMessageState.waiting
          || _state == OutboxMessageState.waitPeriodExpired);
    }
    _state = value;
  }

  /// Whether the [OutboxMessage] is hidden to [MessageListView] or not.
  bool get hidden => _state == OutboxMessageState.hidden;
}

class StreamOutboxMessage extends OutboxMessage<StreamConversation> {
  StreamOutboxMessage({
    required super.localMessageId,
    required super.selfUserId,
    required this.conversation,
    required super.content,
  });

  @override
  final StreamConversation conversation;
}

class DmOutboxMessage extends OutboxMessage<DmConversation> {
  DmOutboxMessage({
    required super.localMessageId,
    required super.selfUserId,
    required this.conversation,
    required super.content,
  }) : assert(conversation.allRecipientIds.contains(selfUserId));

  @override
  final DmConversation conversation;
}

/// Manages the outbox messages portion of [MessageStore].
mixin _OutboxMessageStore on PerAccountStoreBase {
  late final UnmodifiableMapView<int, OutboxMessage> outboxMessages =
    UnmodifiableMapView(_outboxMessages);
  final Map<int, OutboxMessage> _outboxMessages = {};

  /// A map of timers to show outbox messages after a delay,
  /// indexed by [OutboxMessage.localMessageId].
  ///
  /// If the send message request failed within the time limit,
  /// the outbox message's timer gets removed and cancelled.
  final Map<int, Timer> _outboxMessageDebounceTimers = {};

  /// A map of timers to update outbox messages state to
  /// [OutboxMessageState.waitPeriodExpired] after a delay,
  /// indexed by [OutboxMessage.localMessageId].
  ///
  /// If the send message request failed within the time limit,
  /// the outbox message's timer gets removed and cancelled.
  final Map<int, Timer> _outboxMessageWaitPeriodTimers = {};

  /// A fresh ID to use for [OutboxMessage.localMessageId],
  /// unique within this instance.
  int _nextLocalMessageId = 0;

  Set<MessageListView> get _messageListViews;

  /// Update the state of the [OutboxMessage] with the given [localMessageId],
  /// and notify listeners if necessary.
  ///
  /// This is a no-op if the outbox message does not exist, or that
  /// [OutboxMessage.state] already equals [newState].
  void _updateOutboxMessage(int localMessageId, {
    required OutboxMessageState newState,
  }) {
    final outboxMessage = outboxMessages[localMessageId];
    if (outboxMessage == null || outboxMessage.state == newState) {
      return;
    }
    final wasFirstShown = outboxMessage.state == OutboxMessageState.hidden;
    outboxMessage.state = newState;
    for (final view in _messageListViews) {
      if (wasFirstShown) {
        view.addOutboxMessage(outboxMessage);
      } else {
        view.notifyListenersIfOutboxMessagePresent(localMessageId);
      }
    }
  }

  /// Send a message and create an entry of [OutboxMessage].
  Future<void> outboxSendMessage({
    required MessageDestination destination,
    required String content,
    required String? realmEmptyTopicDisplayName,
  }) async {
    final localMessageId = _nextLocalMessageId++;
    assert(!outboxMessages.containsKey(localMessageId));
    _outboxMessages[localMessageId] = OutboxMessage.fromDestination(destination,
      localMessageId: localMessageId, selfUserId: selfUserId, content: content,
      zulipFeatureLevel: zulipFeatureLevel,
      realmEmptyTopicDisplayName: realmEmptyTopicDisplayName);

    _outboxMessageDebounceTimers[localMessageId] = Timer(kLocalEchoDebounceDuration, () {
      assert(outboxMessages.containsKey(localMessageId));
      _outboxMessageDebounceTimers.remove(localMessageId);
      _updateOutboxMessage(localMessageId, newState: OutboxMessageState.waiting);
    });

    _outboxMessageWaitPeriodTimers[localMessageId] = Timer(kSendMessageRetryWaitPeriod, () {
      assert(outboxMessages.containsKey(localMessageId));
      _outboxMessageWaitPeriodTimers.remove(localMessageId);
      _updateOutboxMessage(localMessageId, newState: OutboxMessageState.waitPeriodExpired);
    });

    try {
      await _apiSendMessage(connection,
        destination: destination,
        content: content,
        readBySender: true,
        queueId: queueId,
        localId: localMessageId.toString());
    } catch (e) {
      // `localMessageId` is not necessarily in the store. This is because
      // message event can still arrive before the send request fails to
      // networking issues.
      _outboxMessageDebounceTimers.remove(localMessageId)?.cancel();
      _outboxMessageWaitPeriodTimers.remove(localMessageId)?.cancel();
      _updateOutboxMessage(localMessageId, newState: OutboxMessageState.failed);
      rethrow;
    }
  }

  void removeOutboxMessage(int localMessageId) {
    final removed = _outboxMessages.remove(localMessageId);
    _outboxMessageDebounceTimers.remove(localMessageId)?.cancel();
    _outboxMessageWaitPeriodTimers.remove(localMessageId)?.cancel();
    if (removed == null) {
      assert(false, 'Removing unknown outbox message with localMessageId: $localMessageId');
      return;
    }
    for (final view in _messageListViews) {
      view.removeOutboxMessage(removed);
    }
  }

  void _handleMessageEventOutbox(MessageEvent event) {
    if (event.localMessageId != null) {
      final localMessageId = int.parse(event.localMessageId!, radix: 10);
      // The outbox message can be missing if the user removes it (to be
      // implemented in #1441) before the event arrives.
      // Nothing to do in that case.
      _outboxMessages.remove(localMessageId);
      _outboxMessageDebounceTimers.remove(localMessageId)?.cancel();
      _outboxMessageWaitPeriodTimers.remove(localMessageId)?.cancel();
    }
  }

  /// Remove all outbox messages, and cancel pending timers.
  void _clearOutboxMessages() {
    for (final localMessageId in outboxMessages.keys) {
      _outboxMessageDebounceTimers.remove(localMessageId)?.cancel();
      _outboxMessageWaitPeriodTimers.remove(localMessageId)?.cancel();
    }
    _outboxMessages.clear();
    assert(_outboxMessageDebounceTimers.isEmpty);
    assert(_outboxMessageWaitPeriodTimers.isEmpty);
  }
}

/// The portion of [PerAccountStore] for messages and message lists.
mixin MessageStore {
  /// All known messages, indexed by [Message.id].
  Map<int, Message> get messages;

  /// Messages sent by the user, indexed by [OutboxMessage.localMessageId].
  Map<int, OutboxMessage> get outboxMessages;

  Set<MessageListView> get debugMessageListViews;

  void registerMessageList(MessageListView view);
  void unregisterMessageList(MessageListView view);

  Future<void> sendMessage({
    required MessageDestination destination,
    required String content,
  });

  /// Remove from [outboxMessages] given the [localMessageId].
  ///
  /// The message to remove must exist.
  void removeOutboxMessage(int localMessageId);

  /// Reconcile a batch of just-fetched messages with the store,
  /// mutating the list.
  ///
  /// This is called after a [getMessages] request to report the result
  /// to the store.
  ///
  /// The list's length will not change, but some entries may be replaced
  /// by a different [Message] object with the same [Message.id].
  /// All [Message] objects in the resulting list will be present in
  /// [this.messages].
  void reconcileMessages(List<Message> messages);
}

class MessageStoreImpl extends PerAccountStoreBase with MessageStore, _OutboxMessageStore {
  MessageStoreImpl({required super.core, required this.realmEmptyTopicDisplayName})
    // There are no messages in InitialSnapshot, so we don't have
    // a use case for initializing MessageStore with nonempty [messages].
    : messages = {};

  final String? realmEmptyTopicDisplayName;

  @override
  final Map<int, Message> messages;

  @override
  final Set<MessageListView> _messageListViews = {};

  @override
  Set<MessageListView> get debugMessageListViews => _messageListViews;

  @override
  void registerMessageList(MessageListView view) {
    final added = _messageListViews.add(view);
    assert(added);
  }

  @override
  void unregisterMessageList(MessageListView view) {
    final removed = _messageListViews.remove(view);
    assert(removed);
  }

  void reassemble() {
    for (final view in _messageListViews) {
      view.reassemble();
    }
  }

  void dispose() {
    // Not disposing the [MessageListView]s here, because they are owned by
    // (i.e., they get [dispose]d by) the [_MessageListState], including in the
    // case where the [PerAccountStore] is replaced.
    //
    // TODO: Add assertions that the [MessageListView]s are indeed disposed, by
    //   first ensuring that [PerAccountStore] is only disposed after those with
    //   references to it are disposed, then reinstating this `dispose` method.
    //
    //   We can't add the assertions as-is because the sequence of events
    //   guarantees that `PerAccountStore` is disposed (when that happens,
    //   [GlobalStore] notifies its listeners, causing widgets dependent on the
    //   [InheritedNotifier] to rebuild in the next frame) before the owner's
    //   `dispose` or `onNewStore` is called.  Discussion:
    //     https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/MessageListView.20lifecycle/near/2086893

    _clearOutboxMessages();
  }

  @override
  Future<void> sendMessage({required MessageDestination destination, required String content}) {
    if (!debugOutboxEnable) {
      return _apiSendMessage(connection,
        destination: destination,
        content: content,
        readBySender: true);
    }
    return outboxSendMessage(
      destination: destination, content: content,
      realmEmptyTopicDisplayName: realmEmptyTopicDisplayName);
  }

  @override
  void reconcileMessages(List<Message> messages) {
    // What to do when some of the just-fetched messages are already known?
    // This is common and normal: in particular it happens when one message list
    // overlaps another, e.g. a stream and a topic within it.
    //
    // Most often, the just-fetched message will look just like the one we
    // already have.  But they can differ: message fetching happens out of band
    // from the event queue, so there's inherently a race.
    //
    // If the fetched message reflects changes we haven't yet heard from the
    // event queue, then it doesn't much matter which version we use: we'll
    // soon get the corresponding events and apply the changes anyway.
    // But if it lacks changes we've already heard from the event queue, then
    // we won't hear those events again; the only way to wind up with an
    // updated message is to use the version we have, that already reflects
    // those events' changes.  So we always stick with the version we have.
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      messages[i] = this.messages.putIfAbsent(message.id, () => message);
    }
  }

  void handleUserTopicEvent(UserTopicEvent event) {
    for (final view in _messageListViews) {
      view.handleUserTopicEvent(event);
    }
  }

  void handleMessageEvent(MessageEvent event) {
    // If the message is one we already know about (from a fetch),
    // clobber it with the one from the event system.
    // See [fetchedMessages] for reasoning.
    messages[event.message.id] = event.message;

    _handleMessageEventOutbox(event);

    for (final view in _messageListViews) {
      view.handleMessageEvent(event);
    }
  }

  void handleUpdateMessageEvent(UpdateMessageEvent event) {
    assert(event.messageIds.contains(event.messageId), "See https://github.com/zulip/zulip-flutter/pull/753#discussion_r1649463633");
    _handleUpdateMessageEventTimestamp(event);
    _handleUpdateMessageEventContent(event);
    _handleUpdateMessageEventMove(event);
    for (final view in _messageListViews) {
      view.notifyListenersIfAnyMessagePresent(event.messageIds);
    }
  }

  void _handleUpdateMessageEventTimestamp(UpdateMessageEvent event) {
    // TODO(server-5): Cut this fallback; rely on renderingOnly from FL 114
    final isRenderingOnly = event.renderingOnly ?? (event.userId == null);
    if (event.editTimestamp == null || isRenderingOnly) {
      // A rendering-only update gets omitted from the message edit history,
      // and [Message.lastEditTimestamp] is the last timestamp of that history.
      // So on a rendering-only update, the timestamp doesn't get updated.
      return;
    }

    for (final messageId in event.messageIds) {
      final message = messages[messageId];
      if (message == null) continue;
      message.lastEditTimestamp = event.editTimestamp;
    }
  }

  void _handleUpdateMessageEventContent(UpdateMessageEvent event) {
    final message = messages[event.messageId];
    if (message == null) return;

    message.flags = event.flags;
    if (event.origContent != null) {
      // The message is guaranteed to be edited.
      // See also: https://zulip.com/api/get-events#update_message
      message.editState = MessageEditState.edited;
    }
    if (event.renderedContent != null) {
      assert(message.contentType == 'text/html',
        "Message contentType was ${message.contentType}; expected text/html.");
      message.content = event.renderedContent!;
    }
    if (event.isMeMessage != null) {
      message.isMeMessage = event.isMeMessage!;
    }

    for (final view in _messageListViews) {
      view.messageContentChanged(event.messageId);
    }
  }

  void _handleUpdateMessageEventMove(UpdateMessageEvent event) {
    final messageMove = event.moveData;
    if (messageMove == null) {
      // There was no move.
      return;
    }

    final UpdateMessageMoveData(
      :origStreamId, :newStreamId, :origTopic, :newTopic) = messageMove;

    final wasResolveOrUnresolve = newStreamId == origStreamId
      && MessageEditState.topicMoveWasResolveOrUnresolve(origTopic, newTopic);

    for (final messageId in event.messageIds) {
      final message = messages[messageId];
      if (message == null) continue;

      if (message is! StreamMessage) {
        assert(debugLog('Bad UpdateMessageEvent: stream/topic move on a DM')); // TODO(log)
        continue;
      }

      if (newStreamId != origStreamId) {
        message.conversation.streamId = newStreamId;
        // See [StreamConversation.displayRecipient] on why the invalidation is
        // needed.
        message.conversation.displayRecipient = null;
      }

      if (newTopic != origTopic) {
        message.conversation.topic = newTopic;
      }

      if (!wasResolveOrUnresolve
          && message.editState == MessageEditState.none) {
        message.editState = MessageEditState.moved;
      }
    }

    for (final view in _messageListViews) {
      view.messagesMoved(messageMove: messageMove, messageIds: event.messageIds);
    }
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    for (final messageId in event.messageIds) {
      messages.remove(messageId);
    }
    for (final view in _messageListViews) {
      view.handleDeleteMessageEvent(event);
    }
  }

  void handleUpdateMessageFlagsEvent(UpdateMessageFlagsEvent event) {
    final isAdd = switch (event) {
      UpdateMessageFlagsAddEvent()    => true,
      UpdateMessageFlagsRemoveEvent() => false,
    };

    if (isAdd && (event as UpdateMessageFlagsAddEvent).all) {
      for (final message in messages.values) {
        message.flags.add(event.flag);
      }

      for (final view in _messageListViews) {
        if (view.messages.isEmpty) continue;
        view.notifyListeners();
      }
    } else {
      bool anyMessageFound = false;
      for (final messageId in event.messages) {
        final message = messages[messageId];
        if (message == null) continue; // a message we don't know about yet
        anyMessageFound = true;

        isAdd
          ? message.flags.add(event.flag)
          : message.flags.remove(event.flag);
      }
      if (anyMessageFound) {
        for (final view in _messageListViews) {
          view.notifyListenersIfAnyMessagePresent(event.messages);
          // TODO(#818): Support MentionsNarrow live-updates when handling
          //   @-mention flags.

          // To make it easier to re-star a message, we opt-out from supporting
          // live-updates when starred flag is removed.
          //
          // TODO: Support StarredMessagesNarrow live-updates when starred flag
          //   is added.
        }
      }
    }
  }

  void handleReactionEvent(ReactionEvent event) {
    final message = messages[event.messageId];
    if (message == null) return;

    switch (event.op) {
      case ReactionOp.add:
        (message.reactions ??= Reactions([])).add(Reaction(
          emojiName: event.emojiName,
          emojiCode: event.emojiCode,
          reactionType: event.reactionType,
          userId: event.userId,
        ));
      case ReactionOp.remove:
        if (message.reactions == null) { // TODO(log)
          return;
        }
        message.reactions!.remove(
          reactionType: event.reactionType,
          emojiCode: event.emojiCode,
          userId: event.userId,
        );
    }

    for (final view in _messageListViews) {
      view.notifyListenersIfMessagePresent(event.messageId);
    }
  }

  void handleSubmessageEvent(SubmessageEvent event) {
    final message = messages[event.messageId];
    if (message == null) return;

    final poll = message.poll;
    if (poll == null) {
      assert(debugLog('Missing poll for submessage event:\n${jsonEncode(event)}')); // TODO(log)
      return;
    }

    // Live-updates for polls should not rebuild the message lists.
    // [Poll] is responsible for notifying the affected listeners.
    poll.handleSubmessageEvent(event);
  }

  /// In debug mode, controls whether outbox messages should be created when
  /// [sendMessage] is called.
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugOutboxEnable {
    bool result = true;
    assert(() {
      result = _debugOutboxEnable;
      return true;
    }());
    return result;
  }
  static bool _debugOutboxEnable = true;
  static set debugOutboxEnable(bool value) {
    assert(() {
      _debugOutboxEnable = value;
      return true;
    }());
  }

  @visibleForTesting
  static void debugReset() {
    _debugOutboxEnable = true;
  }
}
