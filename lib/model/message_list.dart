import 'package:flutter/foundation.dart';

import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'content.dart';
import 'narrow.dart';
import 'store.dart';

/// A view-model for a message list.
class MessageListView extends ChangeNotifier {
  MessageListView({required this.store, required this.narrow});

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
    final result =
        await getMessages(store.connection, num_before: 100, num_after: 10);
    messages.addAll(result.messages);
    contents.addAll(_contentsOfMessages(result.messages));
    _fetched = true;
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

  static Iterable<ZulipContent> _contentsOfMessages(
      Iterable<Message> messages) {
    return messages.map((message) => parseContent(message.content));
  }
}
