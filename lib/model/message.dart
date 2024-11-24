import 'dart:convert';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../log.dart';
import 'message_list.dart';

/// Utility function to normalize topic names for case-insensitivity.
String normalizeTopicName(String topic) => topic.toLowerCase();

/// The portion of [PerAccountStore] for messages and message lists.
mixin MessageStore {
  /// All known messages, indexed by [Message.id].
  Map<int, Message> get messages;

  Set<MessageListView> get debugMessageListViews;

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
      : messages = {};

  @override
  final Map<int, Message> messages;

  final Set<MessageListView> _messageListViews = {};

  /// Map of stream ID to topics, with each topic normalized for case-insensitivity.
  final Map<int, Map<String, List<Message>>> _topics = {};

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
    for (final view in _messageListViews.toList()) {
      view.dispose();
    }
  }

  @override
  void reconcileMessages(List<Message> messages) {
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      messages[i] = this.messages.putIfAbsent(message.id, () => message);

      final streamId = message.streamId;
      if (streamId != null) {
        final normalizedTopic = normalizeTopicName(message.topic);
        _topics[streamId] ??= {};
        _topics[streamId]![normalizedTopic] ??= [];
        _topics[streamId]![normalizedTopic]!.add(message);
      }
    }
  }

  void handleUserTopicEvent(UserTopicEvent event) {
    for (final view in _messageListViews) {
      view.handleUserTopicEvent(event);
    }
  }

  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    messages[message.id] = message;

    final streamId = message.streamId;
    if (streamId != null) {
      final normalizedTopic = normalizeTopicName(message.topic);
      _topics[streamId] ??= {};
      final topicMessages = _topics[streamId]!.putIfAbsent(normalizedTopic, () => []);
      topicMessages.add(message);
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
    final isRenderingOnly = event.renderingOnly ?? (event.userId == null);
    if (event.editTimestamp == null || isRenderingOnly) {
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
    final origStreamId = event.origStreamId;
    final newStreamId = event.newStreamId;
    final origTopic = normalizeTopicName(event.origTopic ?? '');
    final newTopic = event.newTopic != null ? normalizeTopicName(event.newTopic!) : null;
    final propagateMode = event.propagateMode;

    if (origStreamId == null || propagateMode == null) return;

    for (final messageId in event.messageIds) {
      final message = messages[messageId];
      if (message == null || message is! StreamMessage) continue;

      if (newStreamId != null) {
        message.streamId = newStreamId;
        message.displayRecipient = null;
      }

      if (newTopic != null) {
        message.topic = newTopic;
      }

      if (message.editState == MessageEditState.none) {
        message.editState = MessageEditState.moved;
      }
    }

    for (final view in _messageListViews) {
      view.messagesMoved(
        origStreamId: origStreamId,
        newStreamId: newStreamId ?? origStreamId,
        origTopic: origTopic,
        newTopic: newTopic ?? origTopic,
        messageIds: event.messageIds,
        propagateMode: propagateMode,
      );
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
      UpdateMessageFlagsAddEvent() => true,
      UpdateMessageFlagsRemoveEvent() => false,
    };

    for (final messageId in event.messages) {
      final message = messages[messageId];
      if (message == null) continue;

      isAdd
          ? message.flags.add(event.flag)
          : message.flags.remove(event.flag);
    }
    for (final view in _messageListViews) {
      view.notifyListenersIfAnyMessagePresent(event.messages);
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
        if (message.reactions == null) return;
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
      assert(debugLog('Missing poll for submessage event:\n${jsonEncode(event)}'));
      return;
    }

    poll.handleSubmessageEvent(event);
  }
}
