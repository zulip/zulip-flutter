import 'dart:convert';

import '../api/core.dart';
import '../api/exception.dart';
import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../log.dart';
import 'message_list.dart';

const _apiSendMessage = sendMessage; // Bit ugly; for alternatives, see: https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20PerAccountStore.20methods/near/1545809
const kLocalEchoDebounceDuration = Duration(milliseconds: 300);

/// States outlining where an [OutboxMessage] is, in its lifecycle.
///
/// ```
///                                                Event received,
///               Send                             or we abandoned
///            immediately.            200.        the queue.
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

/// A locally echoed message sent by the self-user.
sealed class OutboxMessage<T extends MessageDestination> implements DisplayableMessage<T> {
  /// Construct a new [OutboxMessage] with a unique [localMessageId].
  OutboxMessage({
    required int selfUserId,
    required this.content,
  }) : senderId = selfUserId,
       timestamp = (DateTime.timestamp().millisecondsSinceEpoch / 1000).toInt(),
       localMessageId = _nextLocalMessageId++,
       _state = OutboxMessageLifecycle.sending;

  static OutboxMessage fromDestination(MessageDestination destination, {
    required int selfUserId,
    required String content,
  }) {
    return switch (destination) {
      StreamDestination() => StreamOutboxMessage(
        selfUserId: selfUserId, destination: destination, content: content),
      DmDestination() => DmOutboxMessage(
        selfUserId: selfUserId, destination: destination, content: content),
    };
  }

  @override
  int? get id => null;

  @override
  final int senderId;
  @override
  final int timestamp;
  final String content;

  /// The next fresh local message ID from a strictly increasing sequence.
  static int _nextLocalMessageId = 1;
  /// ID corresponding to [MessageEvent.localMessageId], which identifies
  /// locally echoed message.
  final int localMessageId;

  OutboxMessageLifecycle get state => _state;
  OutboxMessageLifecycle _state;
  set state(OutboxMessageLifecycle value) {
    // See [OutboxMessageLifecycle] for valid state transitions.
    switch (value) {
      case OutboxMessageLifecycle.sending:
        assert(false);
      case OutboxMessageLifecycle.sent:
      case OutboxMessageLifecycle.failed:
        assert(_state == OutboxMessageLifecycle.sending);
    }
    _state = value;
  }

  /// Whether the OutboxMessage will be hidden to [MessageListView] or not.
  ///
  /// When set to false with [unhide], this cannot be toggle back to true again.
  bool get hidden => _hidden;
  bool _hidden = true;
  void unhide() {
    assert(_hidden);
    _hidden = false;
  }
}

class StreamOutboxMessage extends OutboxMessage<StreamDestination> {
  StreamOutboxMessage({
    required super.selfUserId,
    required this.destination,
    required super.content,
  });

  @override
  final StreamDestination destination;
}

class DmOutboxMessage extends OutboxMessage<DmDestination> {
  DmOutboxMessage({
    required super.selfUserId,
    required this.destination,
    required super.content,
  });

  @override
  final DmDestination destination;
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

class MessageStoreImpl with MessageStore {
  MessageStoreImpl({
    required this.connection,
    required this.queueId,
    required this.selfUserId,
  })
    // There are no messages in InitialSnapshot, so we don't have
    // a use case for initializing MessageStore with nonempty [messages].
    : messages = {},
      outboxMessages = {};

  final ApiConnection connection;

  /// The event queue ID, for local-echoing, as in [InitialSnapshot.queueId].
  final String queueId;

  final int selfUserId;

  @override
  final Map<int, Message> messages;

  @override
  final Map<int, OutboxMessage> outboxMessages;

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
  }

  @override
  Future<void> sendMessage({required MessageDestination destination, required String content}) async {
    final outboxMessage = OutboxMessage.fromDestination(
      destination, selfUserId: selfUserId, content: content);
    final localMessageId = outboxMessage.localMessageId;
    assert(!outboxMessages.containsKey(localMessageId));
    outboxMessages[localMessageId] = outboxMessage;

    // The outbox message only become visible to views after
    // [kLocalEchoDebounceDuration].
    Future<void>.delayed(kLocalEchoDebounceDuration, () {
      if (!outboxMessages.containsKey(outboxMessage.localMessageId)) {
        // The outbox message was deleted, one such reason can be that the
        // corresponding "message" event arrived quickly.
        return;
      }
      if (!outboxMessage.hidden) {
        // The outbox message was unhidden due to an error from the
        // send-message request.
        assert(outboxMessage.state == OutboxMessageLifecycle.failed);
        return;
      }
      outboxMessage.unhide();
      for (final view in _messageListViews) {
        view.handleOutboxMessage(outboxMessage);
      }
    });

    try {
      await _apiSendMessage(connection,
        destination: destination,
        content: content,
        readBySender: true,
        queueId: queueId,
        localId: localMessageId);
      _updateOutboxMessage(
        localMessageId: localMessageId, newState: OutboxMessageLifecycle.sent);
    } on ApiRequestException {
      outboxMessage.unhide();
      for (final view in _messageListViews) {
        view.handleOutboxMessage(outboxMessage);
      }
      _updateOutboxMessage(
        localMessageId: localMessageId, newState: OutboxMessageLifecycle.failed);
      rethrow;
    }
  }

  void _updateOutboxMessage({
    required int localMessageId,
    required OutboxMessageLifecycle newState,
  }) {
    final outboxMessage = outboxMessages[localMessageId];
    assert(outboxMessage != null);
    if (outboxMessage == null) {
      return;
    }
    outboxMessage.state = newState;
    for (final view in _messageListViews) {
      view.handleUpdateOutboxMessage(localMessageId);
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

    outboxMessages.remove(event.localMessageId);

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
        message.streamId = newStreamId;
        // See [StreamMessage.displayRecipient] on why the invalidation is
        // needed.
        message.displayRecipient = null;
      }

      if (newTopic != origTopic) {
        message.topic = newTopic;
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
}
