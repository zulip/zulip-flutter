import '../api/model/events.dart';
import 'message_list.dart';

/// The portion of [PerAccountStore] for messages and message lists.
mixin MessageStore {
  void registerMessageList(MessageListView view);
  void unregisterMessageList(MessageListView view);
}

class MessageStoreImpl with MessageStore {
  MessageStoreImpl();

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

  void handleMessageEvent(MessageEvent event) {
    for (final view in _messageListViews) {
      view.maybeAddMessage(event.message);
    }
  }

  void handleUpdateMessageEvent(UpdateMessageEvent event) {
    for (final view in _messageListViews) {
      view.maybeUpdateMessage(event);
    }
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    // TODO handle DeleteMessageEvent in MessageListView
  }

  void handleUpdateMessageFlagsEvent(UpdateMessageFlagsEvent event) {
    for (final view in _messageListViews) {
      view.maybeUpdateMessageFlags(event);
    }
  }

  void handleReactionEvent(ReactionEvent event) {
    for (final view in _messageListViews) {
      view.maybeUpdateMessageReactions(event);
    }
  }
}
