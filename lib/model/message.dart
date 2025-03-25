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
const kLocalEchoDebounceDuration = Duration(milliseconds: 300);
const kSendMessageTimeLimit = Duration(seconds: 10);

/// States outlining where an [OutboxMessage] is, in its lifecycle.
///
/// ```
////                              ┌─────────────────────────────────────┐
///                               │                  Event received,    │
///               Send            │                  or we abandoned    │
///            immediately.       │     200.         the queue.         ▼
///  (create) ──────────────► sending ──────► sent ────────────────► (delete)
///                               │                                     ▲
///                               │ 4xx or                     User     │
///                               │ other error.               cancels. │
///                               └────────► failed ────────────────────┘
/// ```
enum OutboxMessageLifecycle {
  sending,
  sent,
  failed,
}

/// A message sent by the self-user.
sealed class OutboxMessage<T extends Conversation> implements MessageBase<T> {
  OutboxMessage({
    required this.localMessageId,
    required int selfUserId,
    required this.content,
    required this.onDebounceTimeout,
    required this.onSendTimeLimitTimeout,
  }) : senderId = selfUserId,
       timestamp = (DateTime.timestamp().millisecondsSinceEpoch / 1000).toInt(),
       _state = OutboxMessageLifecycle.sending,
       _debounceTimer = Timer(kLocalEchoDebounceDuration, onDebounceTimeout),
       _sendTimeLimitTimer = Timer(kSendMessageTimeLimit, onSendTimeLimitTimeout);

  static OutboxMessage fromDestination(MessageDestination destination, {
    required int localMessageId,
    required int selfUserId,
    required String content,
    required VoidCallback onDebounceTimeout,
    required VoidCallback onSendTimeLimitTimeout,
  }) {
    if (destination case DmDestination(:final userIds)) {
      assert(userIds.contains(selfUserId));
    }
    return switch (destination) {
      StreamDestination() => StreamOutboxMessage(
        localMessageId: localMessageId,
        selfUserId: selfUserId,
        conversation: StreamConversation(destination.streamId, destination.topic),
        content: content,
        onDebounceTimeout: onDebounceTimeout,
        onSendTimeLimitTimeout: onSendTimeLimitTimeout,
      ),
      DmDestination() => DmOutboxMessage(
        localMessageId: localMessageId,
        selfUserId: selfUserId,
        conversation: DmConversation(allRecipientIds: destination.userIds),
        content: content,
        onDebounceTimeout: onDebounceTimeout,
        onSendTimeLimitTimeout: onSendTimeLimitTimeout,
      ),
    };
  }

  /// ID corresponding to [MessageEvent.localMessageId], which uniquely
  /// identifies a locally echoed message in events from the same event queue.
  ///
  /// See also [sendMessage].
  final int localMessageId;
  @override
  int? get id => null;
  @override
  final int senderId;
  @override
  final int timestamp;
  final String content;

  /// Called after [kLocalEchoDebounceDuration] if the outbox message is still
  /// [hidden].
  ///
  /// If [hidden] gets set to false before the timeout, this will not get called.
  final VoidCallback onDebounceTimeout;
  final Timer _debounceTimer;

  /// Called after the time limit ([kSendMessageTimeLimit]) for the message
  /// event to arrive.
  ///
  /// If the [state] is [OutboxMessageLifecycle.failed] prior to the time limit
  /// this will not get called.
  final VoidCallback onSendTimeLimitTimeout;
  final Timer _sendTimeLimitTimer;

  OutboxMessageLifecycle get state => _state;
  OutboxMessageLifecycle _state;
  set state(OutboxMessageLifecycle value) {
    assert(!_disposed);
    // See [OutboxMessageLifecycle] for valid state transitions.
    assert(_state != value);
    switch (value) {
      case OutboxMessageLifecycle.sending:
        assert(false);
      case OutboxMessageLifecycle.sent:
        assert(_state == OutboxMessageLifecycle.sending);
      case OutboxMessageLifecycle.failed:
        assert(_state == OutboxMessageLifecycle.sending || _state == OutboxMessageLifecycle.sent);
        _sendTimeLimitTimer.cancel();
    }
    _state = value;
  }

  /// Whether the [OutboxMessage] will be hidden to [MessageListView] or not.
  ///
  /// When set to false with [unhide], this cannot be toggled back to true again.
  bool get hidden => _hidden;
  bool _hidden = true;
  void unhide() {
    assert(!_disposed);
    assert(_hidden);
    _debounceTimer.cancel();
    _hidden = false;
  }

  bool _disposed = false;
  /// Clean up all pending timers to prepare for abandoning this instance.
  ///
  /// This must be called whenever the outbox message is removed from the store.
  void dispose() {
    assert(!_disposed);
    _disposed = true;
    _debounceTimer.cancel();
    _sendTimeLimitTimer.cancel();
  }
}

class StreamOutboxMessage extends OutboxMessage<StreamConversation> {
  StreamOutboxMessage({
    required super.localMessageId,
    required super.selfUserId,
    required this.conversation,
    required super.content,
    required super.onDebounceTimeout,
    required super.onSendTimeLimitTimeout,
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
    required super.onDebounceTimeout,
    required super.onSendTimeLimitTimeout,
  });

  @override
  final DmConversation conversation;
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
  /// The message to remove must already exist.
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

class MessageStoreImpl extends PerAccountStoreBase with MessageStore {
  MessageStoreImpl({required super.core})
    // There are no messages in InitialSnapshot, so we don't have
    // a use case for initializing MessageStore with nonempty [messages].
    : messages = {},
      _outboxMessages = {};

  /// A fresh ID to use for [OutboxMessage.localMessageId],
  /// unique within the [PerAccountStore] instance.
  int _nextLocalMessageId = 0;

  @override
  final Map<int, Message> messages;

  @override
  late final UnmodifiableMapView<int, OutboxMessage> outboxMessages =
    UnmodifiableMapView(_outboxMessages);
  final Map<int, OutboxMessage> _outboxMessages;

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

    for (final outboxMessage in outboxMessages.values) {
      outboxMessage.dispose();
    }
    _outboxMessages.clear();
  }

  @override
  Future<void> sendMessage({required MessageDestination destination, required String content}) async {
    if (!debugOutboxEnabled) {
      await _apiSendMessage(connection,
        destination: destination,
        content: content,
        readBySender: true);
      return;
    }

    final localMessageId = _nextLocalMessageId++;
    assert(!outboxMessages.containsKey(localMessageId));
    _outboxMessages[localMessageId] = OutboxMessage.fromDestination(destination,
      localMessageId: localMessageId,
      selfUserId: selfUserId,
      content: content,
      onDebounceTimeout: () {
        assert(outboxMessages.containsKey(localMessageId));
        _unhideOutboxMessage(localMessageId);
      },
      onSendTimeLimitTimeout: () {
        assert(outboxMessages.containsKey(localMessageId));
        // This should be called before `_unhideOutboxMessage(localMessageId)`
        // to avoid unnecessarily notifying the listeners twice.
        _updateOutboxMessage(localMessageId, newState: OutboxMessageLifecycle.failed);
        _unhideOutboxMessage(localMessageId);
      },
    );

    try {
      await _apiSendMessage(connection,
        destination: destination,
        content: content,
        readBySender: true,
        queueId: queueId,
        localId: localMessageId.toString());
      if (_outboxMessages[localMessageId]?.state == OutboxMessageLifecycle.failed) {
        // Reached time limit while request was pending.
        // No state update is needed.
        return;
      }
      _updateOutboxMessage(localMessageId, newState: OutboxMessageLifecycle.sent);
    } catch (e) {
      // This should be called before `_unhideOutboxMessage(localMessageId)`
      // to avoid unnecessarily notifying the listeners twice.
      _updateOutboxMessage(localMessageId, newState: OutboxMessageLifecycle.failed);
      _unhideOutboxMessage(localMessageId);
      rethrow;
    }
  }

  /// Unhide the [OutboxMessage] with the given [localMessageId],
  /// and notify listeners if necessary.
  ///
  /// This is a no-op if the outbox message does not exist or is not hidden.
  void _unhideOutboxMessage(int localMessageId) {
    final outboxMessage = outboxMessages[localMessageId];
    if (outboxMessage == null || !outboxMessage.hidden) {
      return;
    }
    outboxMessage.unhide();
    for (final view in _messageListViews) {
      view.handleOutboxMessage(outboxMessage);
    }
  }

  /// Update the state of the [OutboxMessage] with the given [localMessageId],
  /// and notify listeners if necessary.
  ///
  /// This is a no-op if the outbox message does not exists, or that
  /// [OutboxMessage.state] already equals [newState].
  void _updateOutboxMessage(int localMessageId, {
    required OutboxMessageLifecycle newState,
  }) {
    final outboxMessage = outboxMessages[localMessageId];
    if (outboxMessage == null || outboxMessage.state == newState) {
      return;
    }
    outboxMessage.state = newState;
    if (outboxMessage.hidden) {
      return;
    }
    for (final view in _messageListViews) {
      view.notifyListenersIfOutboxMessagePresent(localMessageId);
    }
  }


  @override
  void removeOutboxMessage(int localMessageId) {
    final removed = _outboxMessages.remove(localMessageId)?..dispose();
    if (removed == null) {
      assert(false, 'Removing unknown outbox message with localMessageId: $localMessageId');
      return;
    }
    for (final view in _messageListViews) {
      view.removeOutboxMessageIfExists(removed);
    }
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

    if (event.localMessageId != null) {
      final localMessageId = int.parse(event.localMessageId!, radix: 10);
      _outboxMessages.remove(localMessageId)?.dispose();
    }

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
        // See [StreamMessage.displayRecipient] on why the invalidation is
        // needed.
        message.displayRecipient = null;
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
  static bool get debugOutboxEnabled {
    bool result = true;
    assert(() {
      result = _debugOutboxEnabled;
      return true;
    }());
    return result;
  }
  static bool _debugOutboxEnabled = true;
  static set debugOutboxEnabled(bool value) {
    assert(() {
      _debugOutboxEnabled = value;
      return true;
    }());
  }

  @visibleForTesting
  static void debugReset() {
    _debugOutboxEnabled = true;
  }
}
