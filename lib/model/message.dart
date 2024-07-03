import '../api/model/events.dart';
import '../api/model/model.dart';
import '../log.dart';
import 'message_list.dart';

/// The portion of [PerAccountStore] for messages and message lists.
mixin MessageStore {
  /// All known messages, indexed by [Message.id].
  Map<int, Message> get messages;

  void registerMessageList(MessageListView view);
  void unregisterMessageList(MessageListView view);

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
  MessageStoreImpl()
    // There are no messages in InitialSnapshot, so we don't have
    // a use case for initializing MessageStore with nonempty [messages].
    : messages = {};

  @override
  final Map<int, Message> messages;

  final Set<MessageListView> _messageListViews = {};

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
    for (final view in _messageListViews) {
      view.dispose();
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

  void handleMessageEvent(MessageEvent event) {
    // If the message is one we already know about (from a fetch),
    // clobber it with the one from the event system.
    // See [fetchedMessages] for reasoning.
    messages[event.message.id] = event.message;

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
    // The interaction between the fields of these events are a bit tricky.
    // For reference, see: https://zulip.com/api/get-events#update_message

    final origStreamId = event.origStreamId;
    final newStreamId = event.newStreamId; // null if topic-only move
    final origTopic = event.origTopic;
    final newTopic = event.newTopic;

    if (origTopic == null) {
      // There was no move.
      assert(() {
        if (newStreamId != null && origStreamId != null
            && newStreamId != origStreamId) {
          // This should be impossible; `orig_subject` (aka origTopic) is
          // documented to be present when either the stream or topic changed.
          debugLog('Malformed UpdateMessageEvent: stream move but no origTopic'); // TODO(log)
        }
        return true;
      }());
      return;
    }

    if (newTopic == null) {
      // The `subject` field (aka newTopic) is documented to be present on moves.
      assert(debugLog('Malformed UpdateMessageEvent: move but no newTopic')); // TODO(log)
      return;
    }
    if (origStreamId == null) {
      // The `stream_id` field (aka origStreamId) is documented to be present on moves.
      assert(debugLog('Malformed UpdateMessageEvent: move but no origStreamId')); // TODO(log)
      return;
    }

    if (newStreamId == null
        && MessageEditState.topicMoveWasResolveOrUnresolve(origTopic, newTopic)) {
      // The topic was only resolved/unresolved.
      // No change to the messages' editState.
      return;
    }

    // TODO(#150): Handle message moves.  The views' recipient headers
    //   may need updating, and consequently showSender too.
    //   Currently only editState gets updated.
    for (final messageId in event.messageIds) {
      final message = messages[messageId];
      if (message == null) continue;
      // Do not override the edited marker if the message has also been moved.
      if (message.editState == MessageEditState.edited) continue;
      message.editState = MessageEditState.moved;
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
}
