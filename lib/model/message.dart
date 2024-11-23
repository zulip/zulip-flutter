import 'dart:convert';

/// Represents a message with a topic and content.
class Message {
  final int id;
  final String topic;
  final String content;

  String normalizedTopic; // Normalized for case-insensitivity.

  Message(this.id, this.topic, this.content)
      : normalizedTopic = normalizeTopicName(topic);

  static String normalizeTopicName(String topic) {
    return topic.toLowerCase();
  }
}

/// Represents the list view for messages (interface).
abstract class MessageListView {
  void reassemble();
  void dispose();
  void handleUserTopicEvent(UserTopicEvent event);
  void handleMessageEvent(MessageEvent event);
  void notifyListenersIfAnyMessagePresent(Set<int> messageIds);
  void messagesMoved({
    required int origStreamId,
    required int newStreamId,
    required String origTopic,
    required String newTopic,
    required Set<int> messageIds,
    required String propagateMode,
  });
}

/// Represents events for managing messages.
class MessageEvent {
  final Message message;

  MessageEvent(this.message);
}

/// Represents a user-topic event.
class UserTopicEvent {}

/// Represents an update message event.
class UpdateMessageEvent {
  final int messageId;
  final Set<int> messageIds;
  final String? newTopic;
  final String? origTopic;
  final int? newStreamId;
  final int? origStreamId;
  final String? propagateMode;

  UpdateMessageEvent({
    required this.messageId,
    required this.messageIds,
    this.newTopic,
    this.origTopic,
    this.newStreamId,
    this.origStreamId,
    this.propagateMode,
  });
}

/// Manages the state and operations on messages.
mixin MessageStore {
  Map<int, Message> get messages;
  Set<MessageListView> get debugMessageListViews;

  void registerMessageList(MessageListView view);
  void unregisterMessageList(MessageListView view);
  void reconcileMessages(List<Message> messages);
  void handleUserTopicEvent(UserTopicEvent event);
  void handleMessageEvent(MessageEvent event);
  void handleUpdateMessageEvent(UpdateMessageEvent event);
}

/// Implementation of the message store.
class MessageStoreImpl with MessageStore {
  MessageStoreImpl() : messages = {};

  @override
  final Map<int, Message> messages;

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
    for (final view in _messageListViews.toList()) {
      view.dispose();
    }
  }

  @override
  void reconcileMessages(List<Message> messages) {
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      messages[i] = this.messages.putIfAbsent(message.id, () => message);
    }
  }

  @override
  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    messages[message.id] = message;

    for (final view in _messageListViews) {
      view.handleMessageEvent(event);
    }
  }

  @override
  void handleUpdateMessageEvent(UpdateMessageEvent event) {
    if (event.newTopic != null) {
      for (final messageId in event.messageIds) {
        final message = messages[messageId];
        if (message != null) {
          message.normalizedTopic = Message.normalizeTopicName(event.newTopic!);
        }
      }
    }

    for (final view in _messageListViews) {
      view.messagesMoved(
        origStreamId: event.origStreamId!,
        newStreamId: event.newStreamId ?? event.origStreamId!,
        origTopic: event.origTopic!,
        newTopic: event.newTopic ?? event.origTopic!,
        messageIds: event.messageIds,
        propagateMode: event.propagateMode!,
      );
    }
  }
}

void main() {
  final store = MessageStoreImpl();

  // Simulate messages and events.
  final msg1 = Message(1, "Test", "Message 1");
  final msg2 = Message(2, "test", "Message 2");
  final msg3 = Message(3, "TEST", "Message 3");

  store.reconcileMessages([msg1, msg2, msg3]);

  store.handleMessageEvent(MessageEvent(msg1));
  store.handleMessageEvent(MessageEvent(msg2));
  store.handleMessageEvent(MessageEvent(msg3));

  // Print the normalized topics for verification.
  store.messages.forEach((id, message) {
    print("Message ID: $id, Topic: ${message.normalizedTopic}, Content: ${message.content}");
  });
}
