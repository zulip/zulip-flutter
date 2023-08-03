import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'content.dart';
import 'narrow.dart';
import 'store.dart';

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
/// TODO: richer fetch method: use narrow, take anchor, support fetching another batch
/// TODO: update on server events
class MessageListView extends ChangeNotifier {
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

  final List<Message> messages = [];

  /// The parsed message contents, as a list parallel to [messages].
  final List<ZulipContent> contents = [];

  /// Whether [messages] represents the results of a fetch.
  ///
  /// TODO this bit of API will get more complex
  bool get fetched => _fetched;
  bool _fetched = false;

  Future<void> fetch() async {
    assert(!fetched);
    assert(messages.isEmpty);
    assert(contents.isEmpty);
    // TODO schedule all this in another isolate
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: AnchorCode.newest, // TODO(#80): switch to firstUnread
      numBefore: 100,
      numAfter: 10,
    );
    messages.addAll(result.messages);
    contents.addAll(_contentsOfMessages(result.messages));
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
    messages.add(message);
    contents.add(parseContent(message.content));
    notifyListeners();
  }

  _applyChangesToMessage(UpdateMessageEvent event, Message message) {
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

  // This is almost directly copied from package:collection/src/algorithms.dart
  // The way that package was set up doesn't allow us to search
  // for a message ID among a bunch of message objects - this is a quick
  // modification of that method to work here for us.
  @visibleForTesting
  int findMessageWithId(int messageId) {
    var min = 0;
    var max = messages.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      final message = messages[mid];
      var comp = message.id.compareTo(messageId);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
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

    final message = messages[idx];
    _applyChangesToMessage(event, message);

    contents[idx] = parseContent(message.content);
    notifyListeners();
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo from scratch any computations we can, such as parsing
  /// message contents.  It won't repeat network requests.
  void reassemble() {
    contents.clear();
    contents.addAll(_contentsOfMessages(messages));
    notifyListeners();
  }

  static Iterable<ZulipContent> _contentsOfMessages(Iterable<Message> messages) {
    // This will get more complicated to handle the ways that messages interact
    // with the display of neighboring messages: sender headings #175,
    // recipient headings #174, and date separators #173.
    // TODO factor [messages] and [contents] into own class to encapsulate that
    return messages.map((message) => parseContent(message.content));
  }
}
