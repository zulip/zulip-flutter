import '../api/model/events.dart';
import '../api/model/model.dart';
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
    for (final view in _messageListViews) {
      view.maybeUpdateMessage(event); // TODO update mainly in [messages] instead
    }
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    // TODO handle DeleteMessageEvent, particularly in MessageListView
  }

  void handleUpdateMessageFlagsEvent(UpdateMessageFlagsEvent event) {
    for (final view in _messageListViews) {
      view.maybeUpdateMessageFlags(event); // TODO update mainly in [messages] instead
    }
  }

  void handleReactionEvent(ReactionEvent event) {
    for (final view in _messageListViews) {
      view.maybeUpdateMessageReactions(event); // TODO update mainly in [messages] instead
    }
  }
}
