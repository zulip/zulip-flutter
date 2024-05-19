import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'algorithms.dart';
import 'content.dart';
import 'narrow.dart';
import 'store.dart';

/// The number of messages to fetch in each request.
const kMessageListFetchBatchSize = 100; // TODO tune

/// A message, or one of its siblings shown in the message list.
///
/// See [MessageListView.items], which is a list of these.
sealed class MessageListItem {
  const MessageListItem();
}

class MessageListRecipientHeaderItem extends MessageListItem {
  final Message message;

  MessageListRecipientHeaderItem(this.message);
}

class MessageListDateSeparatorItem extends MessageListItem {
  final Message message;

  MessageListDateSeparatorItem(this.message);
}

/// A message to show in the message list.
class MessageListMessageItem extends MessageListItem {
  final Message message;
  ZulipContent content;
  bool showSender;
  bool isLastInBlock;

  MessageListMessageItem(
    this.message,
    this.content, {
    required this.showSender,
    required this.isLastInBlock,
  });
}

/// Indicates the app is loading more messages at the top.
// TODO(#80): or loading at the bottom, by adding a [MessageListDirection.newer]
class MessageListLoadingItem extends MessageListItem {
  final MessageListDirection direction;

  const MessageListLoadingItem(this.direction);
}

enum MessageListDirection { older }

/// Indicates we've reached the oldest message in the narrow.
class MessageListHistoryStartItem extends MessageListItem {
  const MessageListHistoryStartItem();
}

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

  /// Whether we know we have the oldest messages for this narrow.
  ///
  /// (Currently we always have the newest messages for the narrow,
  /// once [fetched] is true, because we start from the newest.)
  bool get haveOldest => _haveOldest;
  bool _haveOldest = false;

  /// Whether we are currently fetching the next batch of older messages.
  bool get fetchingOlder => _fetchingOlder;
  bool _fetchingOlder = false;

  /// The parsed message contents, as a list parallel to [messages].
  ///
  /// The i'th element is the result of parsing the i'th element of [messages].
  ///
  /// This information is completely derived from [messages].
  /// It exists as an optimization, to memoize the work of parsing.
  final List<ZulipContent> contents = [];

  /// The messages and their siblings in the UI, in order.
  ///
  /// This has a [MessageListMessageItem] corresponding to each element
  /// of [messages], in order.  It may have additional items interspersed
  /// before, between, or after the messages.
  ///
  /// This information is completely derived from [messages] and
  /// the flags [haveOldest] and [fetchingOlder].
  /// It exists as an optimization, to memoize that computation.
  final QueueList<MessageListItem> items = QueueList();

  int _findMessageWithId(int messageId) {
    return binarySearchByKey(messages, messageId,
      (message, messageId) => message.id.compareTo(messageId));
  }

  int findItemWithMessageId(int messageId) {
    return binarySearchByKey(items, messageId, _compareItemToMessageId);
  }

  static int _compareItemToMessageId(MessageListItem item, int messageId) {
    switch (item) {
      case MessageListHistoryStartItem():        return -1;
      case MessageListLoadingItem():
        switch (item.direction) {
          case MessageListDirection.older:       return -1;
        }
      case MessageListRecipientHeaderItem(:var message):
      case MessageListDateSeparatorItem(:var message):
        return (message.id <= messageId) ? -1 : 1;
      case MessageListMessageItem(:var message): return message.id.compareTo(messageId);
    }
  }

  /// Update data derived from the content of the index-th message.
  void _reparseContent(int index) {
    final message = messages[index];
    final content = parseContent(message.content);
    contents[index] = content;

    final itemIndex = findItemWithMessageId(message.id);
    assert(itemIndex > -1
      && items[itemIndex] is MessageListMessageItem
      && identical((items[itemIndex] as MessageListMessageItem).message, message));
    (items[itemIndex] as MessageListMessageItem).content = content;
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
    _processMessage(messages.length - 1);
  }

  void _insertAllMessages(int index, Iterable<Message> toInsert) {
    // TODO parse/process messages in smaller batches, to not drop frames.
    //   On a Pixel 5, a batch of 100 messages takes ~15-20ms in _insertAllMessages.
    //   (Before that, ~2-5ms in jsonDecode and 0ms in fromJson,
    //   so skip worrying about those steps.)
    assert(contents.length == messages.length);
    messages.insertAll(index, toInsert);
    contents.insertAll(index, toInsert.map(
      (message) => parseContent(message.content)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Redo all computations from scratch, based on [messages].
  void _recompute() {
    assert(contents.length == messages.length);
    contents.clear();
    contents.addAll(messages.map((message) => parseContent(message.content)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Append to [items] based on the index-th message and its content.
  ///
  /// The previous messages in the list must already have been processed.
  /// This message must already have been parsed and reflected in [contents].
  void _processMessage(int index) {
    // This will get more complicated to handle the ways that messages interact
    // with the display of neighboring messages: sender headings #175
    // and date separators #173.
    final message = messages[index];
    final content = contents[index];
    bool canShareSender;
    if (index == 0 || !haveSameRecipient(messages[index - 1], message)) {
      items.add(MessageListRecipientHeaderItem(message));
      canShareSender = false;
    } else {
      assert(items.last is MessageListMessageItem);
      final prevMessageItem = items.last as MessageListMessageItem;
      assert(identical(prevMessageItem.message, messages[index - 1]));
      assert(prevMessageItem.isLastInBlock);
      prevMessageItem.isLastInBlock = false;

      if (!messagesSameDay(prevMessageItem.message, message)) {
        items.add(MessageListDateSeparatorItem(message));
        canShareSender = false;
      } else {
        canShareSender = (prevMessageItem.message.senderId == message.senderId);
      }
    }
    items.add(MessageListMessageItem(message, content,
      showSender: !canShareSender, isLastInBlock: true));
  }

  /// Update [items] to include markers at start and end as appropriate.
  void _updateEndMarkers() {
    assert(!(haveOldest && fetchingOlder));
    final startMarker = switch ((fetchingOlder, haveOldest)) {
      (true, _) => const MessageListLoadingItem(MessageListDirection.older),
      (_, true) => const MessageListHistoryStartItem(),
      (_,    _) => null,
    };
    final hasStartMarker = switch (items.firstOrNull) {
      MessageListLoadingItem()      => true,
      MessageListHistoryStartItem() => true,
      _                             => false,
    };
    switch ((startMarker != null, hasStartMarker)) {
      case (true, true): items[0] = startMarker!;
      case (true, _   ): items.addFirst(startMarker!);
      case (_,    true): items.removeFirst();
      case (_,    _   ): break;
    }
  }

  /// Recompute [items] from scratch, based on [messages], [contents], and flags.
  void _reprocessAll() {
    items.clear();
    for (var i = 0; i < messages.length; i++) {
      _processMessage(i);
    }
    _updateEndMarkers();
  }
}

@visibleForTesting
bool haveSameRecipient(Message prevMessage, Message message) {
  if (prevMessage is StreamMessage && message is StreamMessage) {
    if (prevMessage.streamId != message.streamId) return false;
    if (prevMessage.subject != message.subject) return false;
  } else if (prevMessage is DmMessage && message is DmMessage) {
    if (!_equalIdSequences(prevMessage.allRecipientIds, message.allRecipientIds)) {
      return false;
    }
  } else {
    return false;
  }
  return true;

  // switch ((prevMessage, message)) {
  //   case (StreamMessage(), StreamMessage()):
  //     // TODO(dart-3): this doesn't type-narrow prevMessage and message
  //   case (DmMessage(), DmMessage()):
  //     // …
  //   default:
  //     return false;
  // }
}

@visibleForTesting
bool messagesSameDay(Message prevMessage, Message message) {
  // TODO memoize [DateTime]s... also use memoized for showing date/time in msglist
  final prevTime = DateTime.fromMillisecondsSinceEpoch(prevMessage.timestamp * 1000);
  final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp * 1000);
  if (!_sameDay(prevTime, time)) return false;
  return true;
}

// Intended for [Message.allRecipientIds].  Assumes efficient `length`.
bool _equalIdSequences(Iterable<int> xs, Iterable<int> ys) {
  if (xs.length != ys.length) return false;
  final xs_ = xs.iterator; final ys_ = ys.iterator;
  while (xs_.moveNext() && ys_.moveNext()) {
    if (xs_.current != ys_.current) return false;
  }
  return true;
}

bool _sameDay(DateTime date1, DateTime date2) {
  if (date1.year != date2.year) return false;
  if (date1.month != date2.month) return false;
  if (date1.day != date2.day) return false;
  return true;
}

/// A view-model for a message list.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create with [init].
///  * Add listeners with [addListener].
///  * Fetch messages with [fetchInitial].  When the fetch completes, this object
///    will notify its listeners (as it will any other time the data changes.)
///  * Fetch more messages as needed with [fetchOlder].
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
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

  /// Whether [message] should actually appear in this message list,
  /// given that it does belong to the narrow.
  ///
  /// This depends in particular on whether the message is muted in
  /// one way or another.
  ///
  /// See also [_allMessagesVisible].
  bool _messageVisible(Message message) {
    switch (narrow) {
      case CombinedFeedNarrow():
        return switch (message) {
          StreamMessage() =>
            store.isTopicVisible(message.streamId, message.subject),
          DmMessage() => true,
        };

      case StreamNarrow(:final streamId):
        assert(message is StreamMessage && message.streamId == streamId);
        if (message is! StreamMessage) return false;
        return store.isTopicVisibleInStream(streamId, message.subject);

      case TopicNarrow():
      case DmNarrow():
        return true;
    }
  }

  /// Whether [_messageVisible] is true for all possible messages.
  ///
  /// This is useful for an optimization.
  bool get _allMessagesVisible {
    switch (narrow) {
      case CombinedFeedNarrow():
      case StreamNarrow():
        return false;

      case TopicNarrow():
      case DmNarrow():
        return true;
    }
  }

  /// Fetch messages, starting from scratch.
  Future<void> fetchInitial() async {
    // TODO(#80): fetch from anchor firstUnread, instead of newest
    // TODO(#82): fetch from a given message ID as anchor
    assert(!fetched && !haveOldest && !fetchingOlder);
    assert(messages.isEmpty && contents.isEmpty);
    // TODO schedule all this in another isolate
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: AnchorCode.newest,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
    for (final message in result.messages) {
      if (_messageVisible(message)) {
        _addMessage(message);
      }
    }
    _fetched = true;
    _haveOldest = result.foundOldest;
    _updateEndMarkers();
    notifyListeners();
  }

  /// Fetch the next batch of older messages, if applicable.
  Future<void> fetchOlder() async {
    if (haveOldest) return;
    if (fetchingOlder) return;
    assert(fetched);
    assert(messages.isNotEmpty);
    _fetchingOlder = true;
    _updateEndMarkers();
    notifyListeners();
    try {
      final result = await getMessages(store.connection,
        narrow: narrow.apiEncode(),
        anchor: NumericAnchor(messages[0].id),
        includeAnchor: false,
        numBefore: kMessageListFetchBatchSize,
        numAfter: 0,
      );

      if (result.messages.isNotEmpty
          && result.messages.last.id == messages[0].id) {
        // TODO(server-6): includeAnchor should make this impossible
        result.messages.removeLast();
      }

      final fetchedMessages = _allMessagesVisible
        ? result.messages // Avoid unnecessarily copying the list.
        : result.messages.where(_messageVisible);

      _insertAllMessages(0, fetchedMessages);
      _haveOldest = result.foundOldest;
    } finally {
      _fetchingOlder = false;
      _updateEndMarkers();
      notifyListeners();
    }
  }

  /// Add [message] to this view, if it belongs here.
  ///
  /// Called in particular when we get a [MessageEvent].
  void maybeAddMessage(Message message) {
    if (!narrow.containsMessage(message) || !_messageVisible(message)) {
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
  // NB that when handling message moves (#150), recipient headers
  // may need updating, and consequently showSender too.
  void maybeUpdateMessage(UpdateMessageEvent event) {
    final idx = _findMessageWithId(event.messageId);
    if (idx == -1)  {
      return;
    }

    _applyChangesToMessage(event, messages[idx]);
    _reparseContent(idx);
    notifyListeners();
  }

  void maybeUpdateMessageFlags(UpdateMessageFlagsEvent event) {
    final isAdd = switch (event) {
      UpdateMessageFlagsAddEvent()    => true,
      UpdateMessageFlagsRemoveEvent() => false,
    };

    bool didUpdateAny = false;
    if (isAdd && (event as UpdateMessageFlagsAddEvent).all) {
      for (final message in messages) {
        message.flags.add(event.flag);
        didUpdateAny = true;
      }
    } else {
      for (final messageId in event.messages) {
        final index = _findMessageWithId(messageId);
        if (index != -1) {
          final message = messages[index];
          isAdd ? message.flags.add(event.flag) : message.flags.remove(event.flag);
          didUpdateAny = true;
        }
      }
    }
    if (!didUpdateAny) {
      return;
    }

    notifyListeners();
  }

  void maybeUpdateMessageReactions(ReactionEvent event) {
    final index = _findMessageWithId(event.messageId);
    if (index == -1) {
      return;
    }

    final message = messages[index];
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
