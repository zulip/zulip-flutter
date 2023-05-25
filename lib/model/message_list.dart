import 'package:flutter/foundation.dart';

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
    // with the display of neighboring messages: sender headings,
    // recipient headings, and date separators.
    // TODO factor [messages] and [contents] into own class to encapsulate that
    return messages.map((message) => parseContent(message.content));
  }
}
