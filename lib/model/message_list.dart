import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/backoff.dart';
import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'algorithms.dart';
import 'channel.dart';
import 'content.dart';
import 'message.dart';
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
  final MessageBase message;

  MessageListRecipientHeaderItem(this.message);
}

class MessageListDateSeparatorItem extends MessageListItem {
  final MessageBase message;

  MessageListDateSeparatorItem(this.message);
}

/// A message to show in the message list.
sealed class MessageListMessageBaseItem extends MessageListItem {
  MessageBase get message;
  ZulipMessageContent get content;
  bool showSender;
  bool isLastInBlock;

  MessageListMessageBaseItem({
    required this.showSender,
    required this.isLastInBlock,
  });
}

class MessageListMessageItem extends MessageListMessageBaseItem {
  @override
  final Message message;
  @override
  ZulipMessageContent content;

  MessageListMessageItem(
    this.message,
    this.content, {
    required super.showSender,
    required super.isLastInBlock,
  });
}

class MessageListOutboxMessageItem extends MessageListMessageBaseItem {
  @override
  final OutboxMessage message;
  @override
  final ZulipContent content;

  MessageListOutboxMessageItem(
    this.message, {
    required super.showSender,
    required super.isLastInBlock,
  }) : content = ZulipContent(nodes: [
    ParagraphNode(links: [], nodes: [TextNode(message.content)]),
  ]);
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
  /// A sequence number for invalidating stale fetches.
  int generation = 0;

  /// The messages.
  ///
  /// See also [contents] and [items].
  final List<Message> messages = [];

  /// The messages sent by the self-user.
  ///
  /// See also [items].
  // Usually this should not have that many items, so we do not anticipate
  // performance issues with unoptimized O(N) iterations through this list.
  final List<OutboxMessage> outboxMessages = [];

  /// Whether [messages], [outboxMessages], and [items] represent the results
  /// of a fetch.
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
  ///
  /// When this is true, [fetchOlder] is a no-op.
  /// That method is called frequently by Flutter's scrolling logic,
  /// and this field helps us avoid spamming the same request just to get
  /// the same response each time.
  ///
  /// See also [fetchOlderCoolingDown].
  bool get fetchingOlder => _fetchingOlder;
  bool _fetchingOlder = false;

  /// Whether [fetchOlder] had a request error recently.
  ///
  /// When this is true, [fetchOlder] is a no-op.
  /// That method is called frequently by Flutter's scrolling logic,
  /// and this field mitigates spamming the same request and getting
  /// the same error each time.
  ///
  /// "Recently" is decided by a [BackoffMachine] that resets
  /// when a [fetchOlder] request succeeds.
  ///
  /// See also [fetchingOlder].
  bool get fetchOlderCoolingDown => _fetchOlderCoolingDown;
  bool _fetchOlderCoolingDown = false;

  BackoffMachine? _fetchOlderCooldownBackoffMachine;

  /// The parsed message contents, as a list parallel to [messages].
  ///
  /// The i'th element is the result of parsing the i'th element of [messages].
  ///
  /// This information is completely derived from [messages].
  /// It exists as an optimization, to memoize the work of parsing.
  final List<ZulipMessageContent> contents = [];

  /// The messages and their siblings in the UI, in order.
  ///
  /// This has a [MessageListMessageItem] corresponding to each element
  /// of [messages], followed by each element in [outboxMessages] in order.
  /// It may have additional items interspersed before, between, or after the
  /// messages.
  ///
  /// This information is completely derived from [messages], [outboxMessages]
  /// and the flags [haveOldest], [fetchingOlder] and [fetchOlderCoolingDown].
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
        if (message.id == null)                  return 1;  // TODO(#1441): test
        return message.id! <= messageId ? -1 : 1;
      case MessageListMessageItem(:var message): return message.id.compareTo(messageId);
      case MessageListOutboxMessageItem():       return 1;
    }
  }

  ZulipMessageContent _parseMessageContent(Message message) {
    final poll = message.poll;
    if (poll != null) return PollContent(poll);
    return parseContent(message.content);
  }

  /// Update data derived from the content of the index-th message.
  void _reparseContent(int index) {
    final message = messages[index];
    final content = _parseMessageContent(message);
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
    contents.add(_parseMessageContent(message));
    assert(contents.length == messages.length);
    _processMessage(messages.length - 1);
  }

  /// Removes all messages from the list that satisfy [test].
  ///
  /// Returns true if any messages were removed, false otherwise.
  bool _removeMessagesWhere(bool Function(Message) test) {
    // Before we find a message to remove, there's no need to copy elements.
    // This is like the loop below, but simplified for `target == candidate`.
    int candidate = 0;
    while (true) {
      if (candidate == messages.length) return false;
      if (test(messages[candidate])) break;
      candidate++;
    }

    int target = candidate;
    candidate++;
    assert(contents.length == messages.length);
    while (candidate < messages.length) {
      if (test(messages[candidate])) {
        candidate++;
        continue;
      }
      messages[target] = messages[candidate];
      contents[target] = contents[candidate];
      target++; candidate++;
    }
    messages.length = target;
    contents.length = target;
    assert(contents.length == messages.length);
    _reprocessAll();
    return true;
  }

  /// Removes the given messages, if present.
  ///
  /// Returns true if at least one message was present, false otherwise.
  /// If none of [messageIds] are found, this is a no-op.
  bool _removeMessagesById(Iterable<int> messageIds) {
    final messagesToRemoveById = <int>{};
    final contentToRemove = Set<ZulipMessageContent>.identity();
    for (final messageId in messageIds) {
      final index = _findMessageWithId(messageId);
      if (index == -1) continue;
      messagesToRemoveById.add(messageId);
      contentToRemove.add(contents[index]);
    }
    if (messagesToRemoveById.isEmpty) return false;

    assert(contents.length == messages.length);
    messages.removeWhere((message) => messagesToRemoveById.contains(message.id));
    contents.removeWhere((content) => contentToRemove.contains(content));
    assert(contents.length == messages.length);
    _reprocessAll();

    return true;
  }

  void _insertAllMessages(int index, Iterable<Message> toInsert) {
    // TODO parse/process messages in smaller batches, to not drop frames.
    //   On a Pixel 5, a batch of 100 messages takes ~15-20ms in _insertAllMessages.
    //   (Before that, ~2-5ms in jsonDecode and 0ms in fromJson,
    //   so skip worrying about those steps.)
    assert(contents.length == messages.length);
    messages.insertAll(index, toInsert);
    contents.insertAll(index, toInsert.map(
      (message) => _parseMessageContent(message)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Reset all [_MessageSequence] data, and cancel any active fetches.
  void _reset() {
    generation += 1;
    messages.clear();
    outboxMessages.clear();
    _fetched = false;
    _haveOldest = false;
    _fetchingOlder = false;
    _fetchOlderCoolingDown = false;
    _fetchOlderCooldownBackoffMachine = null;
    contents.clear();
    items.clear();
  }

  /// Redo all computations from scratch, based on [messages].
  void _recompute() {
    assert(contents.length == messages.length);
    contents.clear();
    contents.addAll(messages.map((message) => _parseMessageContent(message)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Append to [items] an auxillary item like a date separator and update
  /// properties of the previous message item, if necessary.
  ///
  /// Returns whether an item has been appended or not.
  ///
  /// The caller must append a [MessageListMessageBaseItem] for [message]
  /// after this.
  bool _maybeAppendAuxillaryItem(MessageBase message, {
    required MessageBase? prevMessage,
  }) {
    if (prevMessage == null || !haveSameRecipient(prevMessage, message)) {
      items.add(MessageListRecipientHeaderItem(message));
      return true;
    } else {
      final prevMessageItem = items.last as MessageListMessageBaseItem;
      assert(identical(prevMessageItem.message, prevMessage));
      assert(prevMessageItem.isLastInBlock);
      prevMessageItem.isLastInBlock = false;

      if (!messagesSameDay(prevMessageItem.message, message)) {
        items.add(MessageListDateSeparatorItem(message));
        return true;
      } else {
        return false;
      }
    }
  }

  /// Append to [items] based on the index-th message and its content.
  ///
  /// The previous messages in the list must already have been processed.
  /// This message must already have been parsed and reflected in [contents].
  void _processMessage(int index) {
    final prevMessage = index == 0 ? null : messages[index - 1];
    final message = messages[index];
    final content = contents[index];

    final appended = _maybeAppendAuxillaryItem(message, prevMessage: prevMessage);
    items.add(MessageListMessageItem(message, content,
      showSender: appended || prevMessage?.senderId != message.senderId,
      isLastInBlock: true));
  }

  /// Append to [items] based on the index-th outbox message.
  ///
  /// All [messages] and previous messages in [outboxMessages] must already have
  /// been processed.
  void _processOutboxMessage(int index) {
    final prevMessage = index == 0 ? messages.lastOrNull : outboxMessages[index - 1];
    final message = outboxMessages[index];

    final appended = _maybeAppendAuxillaryItem(message, prevMessage: prevMessage);
    items.add(MessageListOutboxMessageItem(message,
      showSender: appended || prevMessage?.senderId != message.senderId,
      isLastInBlock: true));
  }

  /// Remove items associated with [outboxMessages] from [items].
  ///
  /// This is efficient due to the expected small size of [outboxMessages].
  void _removeOutboxMessageItems() {
    // This loop relies on the assumption that all [MessageListMessageItem]
    // items comes before those associated with outbox messages.  If there
    // is no [MessageListMessageItem] at all, this will end up removing
    // end markers as well.
    while (items.isNotEmpty && items.last is! MessageListMessageItem) {
      items.removeLast();
    }
    assert(items.none((e) => e is MessageListOutboxMessageItem));

    if (items.isNotEmpty) {
      final lastItem = items.last as MessageListMessageItem;
      lastItem.isLastInBlock = true;
    }
    _updateEndMarkers();
  }

  /// Update [items] to include markers at start and end as appropriate.
  void _updateEndMarkers() {
    assert(fetched);
    assert(!(fetchingOlder && fetchOlderCoolingDown));
    final effectiveFetchingOlder = fetchingOlder || fetchOlderCoolingDown;
    assert(!(effectiveFetchingOlder && haveOldest));
    final startMarker = switch ((effectiveFetchingOlder, haveOldest)) {
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

  /// Recompute [items] from scratch, based on [messages], [contents],
  /// [outboxMessages] and flags.
  void _reprocessAll() {
    items.clear();
    for (var i = 0; i < messages.length; i++) {
      _processMessage(i);
    }
    for (var i = 0; i < outboxMessages.length; i++) {
      _processOutboxMessage(i);
    }
    _updateEndMarkers();
  }
}

@visibleForTesting
bool haveSameRecipient(MessageBase prevMessage, MessageBase message) {
  final prevConversation = prevMessage.conversation;
  final conversation = message.conversation;
  if (prevConversation is StreamConversation && conversation is StreamConversation) {
    if (prevConversation.streamId != conversation.streamId) return false;
    if (prevConversation.topic.canonicalize() != conversation.topic.canonicalize()) return false;
  } else if (prevConversation is DmConversation && conversation is DmConversation) {
    if (!_equalIdSequences(prevConversation.allRecipientIds, conversation.allRecipientIds)) {
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
bool messagesSameDay(MessageBase prevMessage, MessageBase message) {
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
  Narrow narrow;

  /// Whether [message] should actually appear in this message list,
  /// given that it does belong to the narrow.
  ///
  /// This depends in particular on whether the message is muted in
  /// one way or another.
  ///
  /// See also [_allMessagesVisible].
  bool _messageVisible(MessageBase message) {
    switch (narrow) {
      case CombinedFeedNarrow():
        return switch (message.conversation) {
          StreamConversation(:final streamId, :final topic) =>
            store.isTopicVisible(streamId, topic),
          DmConversation() => true,
        };

      case ChannelNarrow(:final streamId):
        assert(message is MessageBase<StreamConversation>
               && message.conversation.streamId == streamId);
        if (message is! MessageBase<StreamConversation>) return false;
        return store.isTopicVisibleInStream(streamId, message.conversation.topic);

      case TopicNarrow():
      case DmNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return true;
    }
  }

  /// Whether this event could affect the result that [_messageVisible]
  /// would ever have returned for any possible message in this message list.
  VisibilityEffect _canAffectVisibility(UserTopicEvent event) {
    switch (narrow) {
      case CombinedFeedNarrow():
        return store.willChangeIfTopicVisible(event);

      case ChannelNarrow(:final streamId):
        if (event.streamId != streamId) return VisibilityEffect.none;
        return store.willChangeIfTopicVisibleInStream(event);

      case TopicNarrow():
      case DmNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return VisibilityEffect.none;
    }
  }

  /// Whether [_messageVisible] is true for all possible messages.
  ///
  /// This is useful for an optimization.
  bool get _allMessagesVisible {
    switch (narrow) {
      case CombinedFeedNarrow():
      case ChannelNarrow():
        return false;

      case TopicNarrow():
      case DmNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return true;
    }
  }

  /// Fetch messages, starting from scratch.
  Future<void> fetchInitial() async {
    // TODO(#80): fetch from anchor firstUnread, instead of newest
    // TODO(#82): fetch from a given message ID as anchor
    assert(!fetched && !haveOldest && !fetchingOlder && !fetchOlderCoolingDown);
    assert(messages.isEmpty && contents.isEmpty && outboxMessages.isEmpty);
    // TODO schedule all this in another isolate
    final generation = this.generation;
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: AnchorCode.newest,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
    if (this.generation > generation) return;
    _adjustNarrowForTopicPermalink(result.messages.firstOrNull);
    store.reconcileMessages(result.messages);
    store.recentSenders.handleMessages(result.messages); // TODO(#824)
    for (final message in result.messages) {
      if (_messageVisible(message)) {
        _addMessage(message);
      }
    }
    for (final outboxMessage in store.outboxMessages.values) {
      _maybeAddOutboxMessage(outboxMessage);
    }
    _fetched = true;
    _haveOldest = result.foundOldest;
    _updateEndMarkers();
    notifyListeners();
  }

  /// Update [narrow] for the result of a "with" narrow (topic permalink) fetch.
  ///
  /// To avoid an extra round trip, the server handles [ApiNarrowWith]
  /// by returning results from the indicated message's current stream/topic
  /// (if the user has access),
  /// even if that differs from the narrow's stream/topic filters
  /// because the message was moved.
  ///
  /// If such a "redirect" happened, this helper updates the stream and topic
  /// in [narrow] to match the message's current conversation.
  /// It also removes the "with" component from [narrow]
  /// whether or not a redirect happened.
  ///
  /// See API doc:
  ///   https://zulip.com/api/construct-narrow#message-ids
  void _adjustNarrowForTopicPermalink(Message? someFetchedMessageOrNull) {
    final narrow = this.narrow;
    if (narrow is! TopicNarrow || narrow.with_ == null) return;

    switch (someFetchedMessageOrNull) {
      case null:
        // This can't be a redirect; a redirect can't produce an empty result.
        // (The server only redirects if the message is accessible to the user,
        // and if it is, it'll appear in the result, making it non-empty.)
        this.narrow = narrow.sansWith();
      case StreamMessage():
        this.narrow = TopicNarrow.ofMessage(someFetchedMessageOrNull);
      case DmMessage(): // TODO(log)
        assert(false);
    }
  }

  /// Fetch the next batch of older messages, if applicable.
  Future<void> fetchOlder() async {
    if (haveOldest) return;
    if (fetchingOlder) return;
    if (fetchOlderCoolingDown) return;
    assert(fetched);
    assert(narrow is! TopicNarrow
      // We only intend to send "with" in [fetchInitial]; see there.
      || (narrow as TopicNarrow).with_ == null);
    assert(messages.isNotEmpty);
    _fetchingOlder = true;
    _updateEndMarkers();
    notifyListeners();
    final generation = this.generation;
    bool hasFetchError = false;
    try {
      final GetMessagesResult result;
      try {
        result = await getMessages(store.connection,
          narrow: narrow.apiEncode(),
          anchor: NumericAnchor(messages[0].id),
          includeAnchor: false,
          numBefore: kMessageListFetchBatchSize,
          numAfter: 0,
        );
      } catch (e) {
        hasFetchError = true;
        rethrow;
      }
      if (this.generation > generation) return;

      if (result.messages.isNotEmpty
          && result.messages.last.id == messages[0].id) {
        // TODO(server-6): includeAnchor should make this impossible
        result.messages.removeLast();
      }

      store.reconcileMessages(result.messages);
      store.recentSenders.handleMessages(result.messages); // TODO(#824)

      final fetchedMessages = _allMessagesVisible
        ? result.messages // Avoid unnecessarily copying the list.
        : result.messages.where(_messageVisible);

      _insertAllMessages(0, fetchedMessages);
      _haveOldest = result.foundOldest;
    } finally {
      if (this.generation == generation) {
        _fetchingOlder = false;
        if (hasFetchError) {
          assert(!fetchOlderCoolingDown);
          _fetchOlderCoolingDown = true;
          unawaited((_fetchOlderCooldownBackoffMachine ??= BackoffMachine())
            .wait().then((_) {
              if (this.generation != generation) return;
              _fetchOlderCoolingDown = false;
              _updateEndMarkers();
              notifyListeners();
            }));
        } else {
          _fetchOlderCooldownBackoffMachine = null;
        }
        _updateEndMarkers();
        notifyListeners();
      }
    }
  }

  /// Add [outboxMessage] if it belongs to the view.
  ///
  /// Returns true if the message was added, false otherwise.
  bool _maybeAddOutboxMessage(OutboxMessage outboxMessage) {
    assert(outboxMessages.none(
      (message) => message.localMessageId == outboxMessage.localMessageId));
    if (!outboxMessage.hidden
        && narrow.containsMessage(outboxMessage)
        && _messageVisible(outboxMessage)) {
      outboxMessages.add(outboxMessage);
      _processOutboxMessage(outboxMessages.length - 1);
      return true;
    }
    return false;
  }

  void addOutboxMessage(OutboxMessage outboxMessage) {
    if (!fetched) return;
    if (_maybeAddOutboxMessage(outboxMessage)) {
      notifyListeners();
    }
  }

  /// Remove the [outboxMessage] from the view.
  ///
  /// This is a no-op if the message is not found.
  void removeOutboxMessage(OutboxMessage outboxMessage) {
    final removed = outboxMessages.remove(outboxMessage);
    if (!removed) {
      return;
    }

    _removeOutboxMessageItems();
    for (int i = 0; i < outboxMessages.length; i++) {
      _processOutboxMessage(i);
    }
    notifyListeners();
  }

  void handleUserTopicEvent(UserTopicEvent event) {
    switch (_canAffectVisibility(event)) {
      case VisibilityEffect.none:
        return;

      case VisibilityEffect.muted:
        if (_removeMessagesWhere((message) =>
            (message is StreamMessage
             && message.streamId == event.streamId
             && message.topic == event.topicName))) {
          notifyListeners();
        }

      case VisibilityEffect.unmuted:
        // TODO get the newly-unmuted messages from the message store
        // For now, we simplify the task by just refetching this message list
        // from scratch.
        if (fetched) {
          _reset();
          notifyListeners();
          fetchInitial();
        }
    }
  }

  void handleDeleteMessageEvent(DeleteMessageEvent event) {
    if (_removeMessagesById(event.messageIds)) {
      notifyListeners();
    }
  }

  /// Add [MessageEvent.message] to this view, if it belongs here.
  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    if (!narrow.containsMessage(message) || !_messageVisible(message)) {
      assert(event.localMessageId == null || outboxMessages.none((message) =>
        message.localMessageId == int.parse(event.localMessageId!, radix: 10)));
      return;
    }
    if (!_fetched) {
      // TODO mitigate this fetch/event race: save message to add to list later
      return;
    }
    // We always remove all outbox message items
    // to ensure that message items come before them.
    _removeOutboxMessageItems();
    // TODO insert in middle instead, when appropriate
    _addMessage(message);
    if (event.localMessageId != null) {
      final localMessageId = int.parse(event.localMessageId!);
      // [outboxMessages] is epxected to be short, so removing the corresponding
      // outbox message and reprocessing them all in linear time is efficient.
      outboxMessages.removeWhere(
        (message) => message.localMessageId == localMessageId);
    }
    for (int i = 0; i < outboxMessages.length; i++) {
      _processOutboxMessage(i);
    }
    notifyListeners();
  }

  /// Update data derived from the content of the given message.
  ///
  /// This does not notify listeners.
  /// The caller should ensure that happens later.
  void messageContentChanged(int messageId) {
    final index = _findMessageWithId(messageId);
    if (index != -1) {
      _reparseContent(index);
    }
  }

  void _messagesMovedInternally(List<int> messageIds) {
    for (final messageId in messageIds) {
      if (_findMessageWithId(messageId) != -1) {
        _reprocessAll();
        notifyListeners();
        return;
      }
    }
  }

  void _messagesMovedIntoNarrow() {
    // If there are some messages we don't have in [MessageStore], and they
    // occur later than the messages we have here, then we just have to
    // re-fetch from scratch.  That's always valid, so just do that always.
    // TODO in cases where we do have data to do better, do better.
    _reset();
    notifyListeners();
    fetchInitial();
  }

  void _messagesMovedFromNarrow(List<int> messageIds) {
    if (_removeMessagesById(messageIds)) {
      notifyListeners();
    }
  }

  void _handlePropagateMode(PropagateMode propagateMode, Narrow newNarrow) {
    switch (propagateMode) {
      case PropagateMode.changeAll:
      case PropagateMode.changeLater:
        narrow = newNarrow;
        _reset();
        fetchInitial();
      case PropagateMode.changeOne:
    }
  }

  void messagesMoved({
    required UpdateMessageMoveData messageMove,
    required List<int> messageIds,
  }) {
    final UpdateMessageMoveData(
      :origStreamId, :newStreamId, :origTopic, :newTopic, :propagateMode,
    ) = messageMove;
    switch (narrow) {
      case DmNarrow():
        // DMs can't be moved (nor created by moves),
        // so the messages weren't in this narrow and still aren't.
        return;

      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        // The messages were and remain in this narrow.
        // TODO(#421): … except they may have become muted or not.
        //   We'll handle that at the same time as we handle muting itself changing.
        // Recipient headers, and downstream of those, may change, though.
        _messagesMovedInternally(messageIds);

      case ChannelNarrow(:final streamId):
        switch ((origStreamId == streamId, newStreamId == streamId)) {
          case (false, false): return;
          case (true,  true ): _messagesMovedInternally(messageIds);
          case (false, true ): _messagesMovedIntoNarrow();
          case (true,  false): _messagesMovedFromNarrow(messageIds);
        }

      case TopicNarrow(:final streamId, :final topic):
        final oldMatch = (origStreamId == streamId && origTopic == topic);
        final newMatch = (newStreamId == streamId && newTopic == topic);
        switch ((oldMatch, newMatch)) {
          case (false, false): return;
          case (true,  true ): return; // TODO(log) no-op move
          case (false, true ): _messagesMovedIntoNarrow();
          case (true,  false):
            _messagesMovedFromNarrow(messageIds);
            _handlePropagateMode(propagateMode, TopicNarrow(newStreamId, newTopic));
        }
    }
  }

  // Repeal the `@protected` annotation that applies on the base implementation,
  // so we can call this method from [MessageStoreImpl].
  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// Notify listeners if the given message is present in this view.
  void notifyListenersIfMessagePresent(int messageId) {
    final index = _findMessageWithId(messageId);
    if (index != -1) {
      notifyListeners();
    }
  }

  /// Notify listeners if any of the given messages is present in this view.
  void notifyListenersIfAnyMessagePresent(Iterable<int> messageIds) {
    final isAnyPresent = messageIds.any((id) => _findMessageWithId(id) != -1);
    if (isAnyPresent) {
      notifyListeners();
    }
  }

  /// Notify listeners if the given outbox message is present in this view.
  void notifyListenersIfOutboxMessagePresent(int localMessageId) {
    final isAnyPresent =
      outboxMessages.any((message) => message.localMessageId == localMessageId);
    if (isAnyPresent) {
      notifyListeners();
    }
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
