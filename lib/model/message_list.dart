import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'content.dart';
import 'narrow.dart';
import 'store.dart';

/// The number of messages to fetch in each request.
const kMessageListFetchBatchSize = 100; // TODO tune

/// The sequence of messages in a message list, and how to display them.
///
/// This comprises much of the guts of [MessageListView].
mixin _MessageSequence {
  /// The messages.
  ///
  /// See also [contents] and [items].
  final List<Message> messages = [];

  /// Whether [messages] and [items] represent the results of a fetch.
  ///
  /// This allows the UI to distinguish "still working on fetching messages"
  /// from "there are in fact no messages here".
  bool get fetched => _fetched;
  bool _fetched = false;

  /// The parsed message contents, as a list parallel to [messages].
  ///
  /// The i'th element is the result of parsing the i'th element of [messages].
  ///
  /// This information is completely derived from [messages].
  /// It exists as an optimization, to memoize the work of parsing.
  final List<ZulipContent> contents = [];

  // Based on binarySearchBy in package:collection/src/algorithms.dart .
  // (The package:collection version expects to be passed a whole element,
  // not just a key -- so here, a whole [Message] rather than a message ID.)
  @visibleForTesting
  int findMessageWithId(int messageId) {
    int min = 0;
    int max = messages.length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final message = messages[mid];
      final comp = message.id.compareTo(messageId);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// Update data derived from the content of the index-th message.
  void _reparseContent(int index) {
    contents[index] = parseContent(messages[index].content);
  }

  /// Append [message] to [messages], and update derived data accordingly.
  ///
  /// The caller is responsible for ensuring this is an appropriate thing to do
  /// given [narrow], our state of being caught up, and other concerns.
  void _addMessage(Message message) {
    assert(contents.length == messages.length);
    messages.add(message);
    contents.add(parseContent(message.content));
    assert(contents.length == messages.length);
    // This will get more complicated to handle the ways that messages interact
    // with the display of neighboring messages: sender headings #175,
    // recipient headings #174, and date separators #173.
  }

  /// Redo all computations from scratch, based on [messages].
  void _recompute() {
    assert(contents.length == messages.length);
    contents.clear();
    contents.addAll(messages.map((message) => parseContent(message.content)));
    assert(contents.length == messages.length);
  }
}

/// A view-model for a message list.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create with [init].
///  * Add listeners with [addListener].
///  * Fetch messages with [fetch].  When the fetch completes, this object
///    will notify its listeners (as it will any other time the data changes.)
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
///
/// TODO support fetching another batch
class MessageListView with ChangeNotifier, _MessageSequence {
  MessageListView._({required this.store, required this.narrow});

  factory MessageListView.init(
      {required PerAccountStore store, required Narrow narrow}) {
    final view = MessageListView._(store: store, narrow: narrow);
    store.registerMessageList(view);
    return view;
  }

  @override
  void dispose() {
    store.unregisterMessageList(this);
    super.dispose();
  }

  final PerAccountStore store;
  final Narrow narrow;

  Future<void> fetch() async {
    // TODO(#80): fetch from anchor firstUnread, instead of newest
    // TODO(#82): fetch from a given message ID as anchor
    assert(!fetched);
    assert(messages.isEmpty && contents.isEmpty);
    // TODO schedule all this in another isolate
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: AnchorCode.newest,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
    for (final message in result.messages) {
      _addMessage(message);
    }
    _fetched = true;
    notifyListeners();
  }

  /// Add [message] to this view, if it belongs here.
  ///
  /// Called in particular when we get a [MessageEvent].
  void maybeAddMessage(Message message) {
    if (!narrow.containsMessage(message)) {
      return;
    }
    if (!_fetched) {
      // TODO mitigate this fetch/event race: save message to add to list later
      return;
    }
    // TODO insert in middle instead, when appropriate
    _addMessage(message);
    notifyListeners();
  }

  static void _applyChangesToMessage(UpdateMessageEvent event, Message message) {
    // TODO(server-5): Cut this fallback; rely on renderingOnly from FL 114
    final isRenderingOnly = event.renderingOnly ?? (event.userId == null);
    if (event.editTimestamp != null && !isRenderingOnly) {
      // A rendering-only update gets omitted from the message edit history,
      // and [Message.lastEditTimestamp] is the last timestamp of that history.
      // So on a rendering-only update, the timestamp doesn't get updated.
      message.lastEditTimestamp = event.editTimestamp;
    }

    message.flags = event.flags;

    if (event.renderedContent != null) {
      assert(message.contentType == 'text/html',
        "Message contentType was ${message.contentType}; expected text/html.");
      message.content = event.renderedContent!;
    }

    if (event.isMeMessage != null) {
      message.isMeMessage = event.isMeMessage!;
    }
  }

  /// Update the message the given event applies to, if present in this view.
  ///
  /// This method only handles the case where the message's contents
  /// were changed, and ignores any changes to its stream or topic.
  ///
  /// TODO(#150): Handle message moves.
  void maybeUpdateMessage(UpdateMessageEvent event) {
    final idx = findMessageWithId(event.messageId);
    if (idx == -1)  {
      return;
    }

    _applyChangesToMessage(event, messages[idx]);
    _reparseContent(idx);
    notifyListeners();
  }

  void maybeUpdateMessageReactions(ReactionEvent event) {
    final index = findMessageWithId(event.messageId);
    if (index == -1) {
      return;
    }

    final message = messages[index];
    switch (event.op) {
      case ReactionOp.add:
        message.reactions.add(Reaction(
          emojiName: event.emojiName,
          emojiCode: event.emojiCode,
          reactionType: event.reactionType,
          userId: event.userId,
        ));
      case ReactionOp.remove:
        message.reactions.removeWhere((r) {
          return r.emojiCode == event.emojiCode
            && r.reactionType == event.reactionType
            && r.userId == event.userId;
        });
    }

    notifyListeners();
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo from scratch any computations we can, such as parsing
  /// message contents.  It won't repeat network requests.
  void reassemble() {
    _recompute();
    notifyListeners();
  }
}
