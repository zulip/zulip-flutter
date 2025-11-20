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
import 'user.dart';

export '../api/route/messages.dart' show Anchor, AnchorCode, NumericAnchor;

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

/// A [MessageBase] to show in the message list.
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

/// A [Message] to show in the message list.
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

/// An [OutboxMessage] to show in the message list.
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
    ParagraphNode(links: null, nodes: [TextNode(message.contentMarkdown)]),
  ]);
}

/// The status of outstanding or recent `fetchInitial` request from a [MessageListView].
enum FetchingInitialStatus {
  /// The model has not made a `fetchInitial` request (since its last reset, if any).
  unstarted,

  /// The model has made a `fetchInitial` request, which hasn't succeeded.
  fetching,

  /// The model made a successful `fetchInitial` request.
  idle,
}

/// The status of outstanding or recent "fetch more" request from a [MessageListView].
///
/// By a "fetch more" request we mean a `fetchOlder` or a `fetchNewer` request.
enum FetchingMoreStatus {
  /// The model has not made the "fetch more" request (since its last reset, if any).
  unstarted,

  /// The model has made the "fetch more" request, which hasn't succeeded.
  fetching,

  /// The model made a successful "fetch more" request,
  /// and has no outstanding request of the same kind or backoff.
  idle,

  /// The model is in a backoff period from the failed "fetch more" request.
  backoff,
}

/// The sequence of messages in a message list, and how to display them.
///
/// This comprises much of the guts of [MessageListView].
mixin _MessageSequence {
  /// Whether each message should have its own recipient header,
  /// even if it's in the same conversation as the previous message.
  ///
  /// In some message-list views, notably "Mentions" and "Starred",
  /// it would be misleading to give the impression that consecutive messages
  /// in the same conversation were sent one after the other
  /// with no other messages in between.
  /// By giving each message its own recipient header (a `true` value for this),
  /// we intend to avoid giving that impression.
  @visibleForTesting
  bool get oneMessagePerBlock;

  /// A sequence number for invalidating stale fetches.
  int generation = 0;

  /// The known messages in the list.
  ///
  /// This may or may not represent all the message history that
  /// conceptually belongs in this message list.
  /// That information is expressed in [initialFetched], [haveOldest], [haveNewest].
  ///
  /// This also may or may not represent all the message history that
  /// conceptually belongs in this narrow because some messages might be
  /// muted in one way or another and they may not appear in the message list.
  ///
  /// See also [middleMessage], an index which divides this list
  /// into a top slice and a bottom slice.
  ///
  /// See also [contents] and [items].
  final List<Message> messages = [];

  /// An index into [messages] dividing it into a top slice and a bottom slice.
  ///
  /// The indices 0 to before [middleMessage] are the top slice of [messages],
  /// and the indices from [middleMessage] to the end are the bottom slice.
  ///
  /// The corresponding item index is [middleItem].
  int middleMessage = 0;

  /// The ID of the oldest known message so far in this narrow.
  ///
  /// This will be `null` if no messages of this narrow are fetched yet.
  /// Having a non-null value for this doesn't always mean [haveOldest] is `true`.
  ///
  /// The related message may not appear in [messages] because it
  /// is muted in one way or another.
  int? get oldMessageId => _oldMessageId;
  int? _oldMessageId;

  /// The ID of the newest known message so far in this narrow.
  ///
  /// This will be `null` if no messages of this narrow are fetched yet.
  /// Having a non-null value for this doesn't always mean [haveNewest] is `true`.
  ///
  /// The related message may not appear in [messages] because it
  /// is muted in one way or another.
  int? get newMessageId => _newMessageId;
  int? _newMessageId;

  /// Whether the first batch of messages for this narrow is fetched yet.
  ///
  /// Some or all of the fetched messages may not make it to [messages]
  /// and [items] if they're muted in one way or another.
  ///
  /// This allows the UI to distinguish "still working on fetching first batch
  /// of messages" from "there are in fact no messages here".
  bool get initialFetched => switch (_fetchInitialStatus) {
    .unstarted || .fetching => false,
    _ => true,
  };

  /// Whether we know we have the oldest messages for this narrow.
  ///
  /// See also [haveNewest].
  bool get haveOldest => _haveOldest;
  bool _haveOldest = false;

  /// Whether we know we have the newest messages for this narrow.
  ///
  /// See also [haveOldest].
  bool get haveNewest => _haveNewest;
  bool _haveNewest = false;

  /// Whether this message list is currently busy when it comes to
  /// fetching older messages.
  ///
  /// Here "busy" means a new call to fetch older messages would do nothing,
  /// rather than make any request to the server,
  /// as a result of an existing recent request.
  /// This is true both when the recent request is still outstanding,
  /// and when it failed and the backoff from that is still in progress.
  bool get busyFetchingOlder => switch(_fetchOlderStatus) {
    .fetching || .backoff => true,
    _ => false,
  };

  /// Whether this message list is currently busy when it comes to
  /// fetching newer messages.
  ///
  /// Here "busy" means a new call to fetch older messages would do nothing,
  /// rather than make any request to the server,
  /// as a result of an existing recent request.
  /// This is true both when the recent request is still outstanding,
  /// and when it failed and the backoff from that is still in progress.
  bool get busyFetchingNewer => switch(_fetchNewerStatus) {
    .fetching || .backoff => true,
    _ => false,
  };

  FetchingInitialStatus _fetchInitialStatus = .unstarted;
  FetchingMoreStatus _fetchOlderStatus = .unstarted;
  FetchingMoreStatus _fetchNewerStatus = .unstarted;

  BackoffMachine? _fetchBackoffMachine;

  /// The parsed message contents, as a list parallel to [messages].
  ///
  /// The i'th element is the result of parsing the i'th element of [messages].
  ///
  /// This information is completely derived from [messages].
  /// It exists as an optimization, to memoize the work of parsing.
  final List<ZulipMessageContent> contents = [];

  /// The [OutboxMessage]s sent by the self-user, retrieved from
  /// [MessageStore.outboxMessages].
  ///
  /// See also [items].
  ///
  /// O(N) iterations through this list are acceptable
  /// because it won't normally have more than a few items.
  final List<OutboxMessage> outboxMessages = [];

  /// The messages and their siblings in the UI, in order.
  ///
  /// This has a [MessageListMessageItem] corresponding to each element
  /// of [messages], in order.  It may have additional items interspersed
  /// before, between, or after the messages. Then, similarly,
  /// [MessageListOutboxMessageItem]s corresponding to [outboxMessages].
  ///
  /// This information is completely derived from [messages], [outboxMessages],
  /// and the flags [haveOldest], [haveNewest], [busyFetchingNewer], and [busyFetchingOlder].
  /// It exists as an optimization, to memoize that computation.
  ///
  /// See also [middleItem], an index which divides this list
  /// into a top slice and a bottom slice.
  final QueueList<MessageListItem> items = QueueList();

  /// An index into [items] dividing it into a top slice and a bottom slice.
  ///
  /// The indices 0 to before [middleItem] are the top slice of [items],
  /// and the indices from [middleItem] to the end are the bottom slice.
  ///
  /// The top slice of [items] corresponds to the top slice of [messages].
  /// The bottom slice of [items] corresponds to the bottom slice of [messages]
  /// plus any [outboxMessages].
  ///
  /// The bottom slice will either be empty
  /// or start with a [MessageListMessageBaseItem].
  /// It will not start with a [MessageListDateSeparatorItem]
  /// or a [MessageListRecipientHeaderItem].
  int middleItem = 0;

  int _findMessageWithId(int messageId) {
    return binarySearchByKey(messages, messageId,
      (message, messageId) => message.id.compareTo(messageId));
  }

  int findItemWithMessageId(int messageId) {
    return binarySearchByKey(items, messageId, _compareItemToMessageId);
  }

  Iterable<Message>? getMessagesRange(int firstMessageId, int lastMessageId) {
    assert(firstMessageId <= lastMessageId);
    final firstIndex = _findMessageWithId(firstMessageId);
    final lastIndex = _findMessageWithId(lastMessageId);
    if (firstIndex == -1 || lastIndex == -1) {
      // TODO(log)
      return null;
    }
    return messages.getRange(firstIndex, lastIndex + 1);
  }

  static int _compareItemToMessageId(MessageListItem item, int messageId) {
    switch (item) {
      case MessageListRecipientHeaderItem(:var message):
      case MessageListDateSeparatorItem(:var message):
        if (message.id == null)                  return 1;
        return message.id! <= messageId ? -1 : 1;
      case MessageListMessageItem(:var message): return message.id.compareTo(messageId);
      case MessageListOutboxMessageItem():       return 1;
    }
  }

  /// Update data derived from the content of the index-th message.
  void _reparseContent(int index) {
    final message = messages[index];
    final content = parseMessageContent(message);
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
    contents.add(parseMessageContent(message));
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
      if (candidate == middleMessage) middleMessage = target;
      if (test(messages[candidate])) {
        candidate++;
        continue;
      }
      messages[target] = messages[candidate];
      contents[target] = contents[candidate];
      target++; candidate++;
    }
    if (candidate == middleMessage) middleMessage = target;
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

    if (middleMessage == messages.length) {
      middleMessage -= messagesToRemoveById.length;
    } else {
      final middleMessageId = messages[middleMessage].id;
      middleMessage -= messagesToRemoveById
        .where((id) => id < middleMessageId).length;
    }
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
    final oldLength = messages.length;
    assert(contents.length == messages.length);
    messages.insertAll(index, toInsert);
    contents.insertAll(index, toInsert.map(
      (message) => parseMessageContent(message)));
    assert(contents.length == messages.length);
    if (index <= middleMessage) {
      middleMessage += messages.length - oldLength;
    }
    _reprocessAll();
  }

  /// Append [outboxMessage] to [outboxMessages] and update derived data
  /// accordingly.
  ///
  /// The caller is responsible for ensuring this is an appropriate thing to do
  /// given [narrow] and other concerns.
  void _addOutboxMessage(OutboxMessage outboxMessage) {
    assert(haveNewest);
    assert(!outboxMessages.contains(outboxMessage));
    outboxMessages.add(outboxMessage);
    _processOutboxMessage(outboxMessages.length - 1);
  }

  /// Remove the [outboxMessage] from the view.
  ///
  /// Returns true if the outbox message was removed, false otherwise.
  bool _removeOutboxMessage(OutboxMessage outboxMessage) {
    if (!outboxMessages.remove(outboxMessage)) {
      return false;
    }
    _reprocessOutboxMessages();
    return true;
  }

  /// Remove all outbox messages that satisfy [test] from [outboxMessages].
  ///
  /// Returns true if any outbox messages were removed, false otherwise.
  bool _removeOutboxMessagesWhere(bool Function(OutboxMessage) test) {
    final count = outboxMessages.length;
    outboxMessages.removeWhere(test);
    if (outboxMessages.length == count) {
      return false;
    }
    _reprocessOutboxMessages();
    return true;
  }

  /// Reset all [_MessageSequence] data, and cancel any active fetches.
  void _reset() {
    generation += 1;
    messages.clear();
    middleMessage = 0;
    _oldMessageId = null;
    _newMessageId = null;
    outboxMessages.clear();
    _haveOldest = false;
    _haveNewest = false;
    _fetchInitialStatus = .unstarted;
    _fetchOlderStatus = .unstarted;
    _fetchNewerStatus = .unstarted;
    _fetchBackoffMachine = null;
    contents.clear();
    items.clear();
    middleItem = 0;
  }

  /// Redo all computations from scratch, based on [messages].
  void _recompute() {
    assert(contents.length == messages.length);
    contents.clear();
    contents.addAll(messages.map((message) => parseMessageContent(message)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Append to [items] based on [message] and [prevMessage].
  ///
  /// This appends a recipient header or a date separator to [items],
  /// depending on how [prevMessage] relates to [message],
  /// and then the result of [buildItem], updating [middleItem] if desired.
  ///
  /// See [middleItem] to determine the value of [shouldSetMiddleItem].
  ///
  /// [prevMessage] should be the message that visually appears before [message].
  ///
  /// The caller must ensure that [prevMessage] and all messages before it
  /// have been processed.
  void _addItemsForMessage(MessageBase message, {
    required bool shouldSetMiddleItem,
    required MessageBase? prevMessage,
    required MessageListMessageBaseItem Function(bool canShareSender) buildItem,
  }) {
    final bool canShareSender;
    if (
      prevMessage == null
      || oneMessagePerBlock
      || !haveSameRecipient(prevMessage, message)
    ) {
      items.add(MessageListRecipientHeaderItem(message));
      canShareSender = false;
    } else {
      assert(items.last is MessageListMessageBaseItem);
      final prevMessageItem = items.last as MessageListMessageBaseItem;
      assert(identical(prevMessageItem.message, prevMessage));
      assert(prevMessageItem.isLastInBlock);
      prevMessageItem.isLastInBlock = false;

      if (!messagesSameDay(prevMessageItem.message, message)) {
        items.add(MessageListDateSeparatorItem(message));
        canShareSender = false;
      } else if (prevMessageItem.message.senderId == message.senderId) {
        canShareSender = messagesCloseInTime(prevMessage, message);
      } else {
        canShareSender = false;
      }
    }
    final item = buildItem(canShareSender);
    assert(identical(item.message, message));
    assert(item.showSender == !canShareSender);
    assert(item.isLastInBlock);
    if (shouldSetMiddleItem) {
      middleItem = items.length;
    }
    items.add(item);
  }

  /// Append to [items] based on the index-th message and its content.
  ///
  /// The previous messages in the list must already have been processed.
  /// This message must already have been parsed and reflected in [contents].
  void _processMessage(int index) {
    assert(items.lastOrNull is! MessageListOutboxMessageItem);
    final prevMessage = index == 0 ? null : messages[index - 1];
    final message = messages[index];
    final content = contents[index];

    _addItemsForMessage(message,
      shouldSetMiddleItem: index == middleMessage,
      prevMessage: prevMessage,
      buildItem: (bool canShareSender) => MessageListMessageItem(
        message, content, showSender: !canShareSender, isLastInBlock: true));
  }

  /// Append to [items] based on the index-th message in [outboxMessages].
  ///
  /// All [messages] and previous messages in [outboxMessages] must already have
  /// been processed.
  void _processOutboxMessage(int index) {
    final prevMessage = index == 0 ? messages.lastOrNull
                                   : outboxMessages[index - 1];
    final message = outboxMessages[index];

    _addItemsForMessage(message,
      // The first outbox message item becomes the middle item
      // when the bottom slice of [messages] is empty.
      shouldSetMiddleItem: index == 0 && middleMessage == messages.length,
      prevMessage: prevMessage,
      buildItem: (bool canShareSender) => MessageListOutboxMessageItem(
        message, showSender: !canShareSender, isLastInBlock: true));
  }

  /// Remove items associated with [outboxMessages] from [items].
  ///
  /// This is designed to be idempotent; repeated calls will not change the
  /// content of [items].
  ///
  /// This is efficient due to the expected small size of [outboxMessages].
  void _removeOutboxMessageItems() {
    // This loop relies on the assumption that all items that follow
    // the last [MessageListMessageItem] are derived from outbox messages.
    while (items.isNotEmpty && items.last is! MessageListMessageItem) {
      items.removeLast();
    }

    if (items.isNotEmpty) {
      final lastItem = items.last as MessageListMessageItem;
      lastItem.isLastInBlock = true;
    }
    if (middleMessage == messages.length) middleItem = items.length;
  }

  /// Recompute the portion of [items] derived from outbox messages,
  /// based on [outboxMessages] and [messages].
  ///
  /// All [messages] should have been processed when this is called.
  void _reprocessOutboxMessages() {
    assert(haveNewest);
    _removeOutboxMessageItems();
    for (var i = 0; i < outboxMessages.length; i++) {
      _processOutboxMessage(i);
    }
  }

  /// Recompute [items] from scratch, based on [messages], [contents],
  /// [outboxMessages] and flags.
  void _reprocessAll() {
    items.clear();
    for (var i = 0; i < messages.length; i++) {
      _processMessage(i);
    }
    if (middleMessage == messages.length) middleItem = items.length;
    for (var i = 0; i < outboxMessages.length; i++) {
      _processOutboxMessage(i);
    }
  }
}

@visibleForTesting
bool haveSameRecipient(MessageBase prevMessage, MessageBase message) {
  return prevMessage.conversation.isSameAs(message.conversation);
}

@visibleForTesting
bool messagesSameDay(MessageBase prevMessage, MessageBase message) {
  // TODO memoize [DateTime]s... also use memoized for showing date/time in msglist
  final prevTime = DateTime.fromMillisecondsSinceEpoch(prevMessage.timestamp * 1000);
  final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp * 1000);
  if (!_sameDay(prevTime, time)) return false;
  return true;
}

@visibleForTesting
bool messagesCloseInTime(MessageBase prevMessage, MessageBase message) {
  final diffSeconds = (message.timestamp - prevMessage.timestamp).abs();
  return diffSeconds <= 10 * 60;
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
///  * Fetch more messages as needed with [fetchOlder] and [fetchNewer].
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
class MessageListView with ChangeNotifier, _MessageSequence {
  factory MessageListView.init({
    required PerAccountStore store,
    required Narrow narrow,
    required Anchor anchor,
  }) {
    return MessageListView._(store: store, narrow: narrow, anchor: anchor)
      .._register();
  }

  MessageListView._({
    required this.store,
    required Narrow narrow,
    required Anchor anchor,
  }) : _narrow = narrow, _anchor = anchor;

  final PerAccountStore store;

  /// The narrow shown in this message list.
  ///
  /// This can change over time, notably if showing a topic that gets moved,
  /// or if [renarrowAndFetch] is called.
  Narrow get narrow => _narrow;
  Narrow _narrow;

  /// Set [narrow] and [anchor], reset, [notifyListeners], and [fetchInitial].
  void renarrowAndFetch(Narrow newNarrow, Anchor anchor) {
    _narrow = newNarrow;
    _anchor = anchor;
    _reset();
    notifyListeners();
    fetchInitial();
  }

  /// The anchor point this message list starts from in the message history.
  ///
  /// This is passed to the server in the get-messages request
  /// sent by [fetchInitial].
  /// That includes not only the original [fetchInitial] call made by
  /// the message-list widget, but any additional [fetchInitial] calls
  /// which might be made internally by this class in order to
  /// fetch the messages from scratch, e.g. after certain events.
  Anchor get anchor => _anchor;
  Anchor _anchor;

  void _register() {
    store.registerMessageList(this);
  }

  @override
  void dispose() {
    store.unregisterMessageList(this);
    super.dispose();
  }

  @override bool get oneMessagePerBlock => switch (narrow) {
    CombinedFeedNarrow()
      || ChannelNarrow()
      || TopicNarrow()
      || DmNarrow() => false,
    MentionsNarrow()
      || StarredMessagesNarrow()
      || KeywordSearchNarrow() => true,
  };

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
        final conversation = message.conversation;
        return switch (conversation) {
          StreamConversation(:final streamId, :final topic) =>
            store.isTopicVisible(streamId, topic),
          DmConversation() => !store.shouldMuteDmConversation(
            DmNarrow.ofConversation(conversation, selfUserId: store.selfUserId)),
        };

      case ChannelNarrow(:final streamId):
        assert(message is MessageBase<StreamConversation>
               && message.conversation.streamId == streamId);
        if (message is! MessageBase<StreamConversation>) return false;
        return store.isTopicVisibleInStream(streamId, message.conversation.topic);

      case TopicNarrow():
      case DmNarrow():
        return true;

      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        if (message.conversation case DmConversation(:final allRecipientIds)) {
          return !store.shouldMuteDmConversation(DmNarrow(
            allRecipientIds: allRecipientIds, selfUserId: store.selfUserId));
        }
        return true;
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
        return true;

      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return false;
    }
  }

  /// Whether this event could affect the result that [_messageVisible]
  /// would ever have returned for any possible message in this message list.
  UserTopicVisibilityEffect _canAffectVisibility(UserTopicEvent event) {
    switch (narrow) {
      case CombinedFeedNarrow():
        return store.willChangeIfTopicVisible(event);

      case ChannelNarrow(:final streamId):
        if (event.streamId != streamId) return UserTopicVisibilityEffect.none;
        return store.willChangeIfTopicVisibleInStream(event);

      case TopicNarrow():
      case DmNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return UserTopicVisibilityEffect.none;
    }
  }

  /// Whether this event could affect the result that [_messageVisible]
  /// would ever have returned for any possible message in this message list.
  MutedUsersVisibilityEffect _mutedUsersEventCanAffectVisibility(MutedUsersEvent event) {
    switch(narrow) {
      case CombinedFeedNarrow():
        return store.mightChangeShouldMuteDmConversation(event);

      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return MutedUsersVisibilityEffect.none;

      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return store.mightChangeShouldMuteDmConversation(event);
    }
  }

  void _setInitialStatus(FetchingInitialStatus value, {FetchingInitialStatus? was}) {
    assert(was == null || _fetchInitialStatus == was);
    _fetchInitialStatus = value;
    if (!initialFetched) return;
    notifyListeners();
  }

  void _setOlderStatus(FetchingMoreStatus value, {FetchingMoreStatus? was}) {
    assert(was == null || _fetchOlderStatus == was);
    _fetchOlderStatus = value;
    notifyListeners();
  }

  void _setNewerStatus(FetchingMoreStatus value, {FetchingMoreStatus? was}) {
    assert(was == null || _fetchNewerStatus == was);
    _fetchNewerStatus = value;
    notifyListeners();
  }

  /// Fetch messages, starting from scratch.
  Future<void> fetchInitial() async {
    assert(!initialFetched && !haveOldest && !haveNewest
           && !busyFetchingOlder && !busyFetchingNewer);
    assert(messages.isEmpty && contents.isEmpty);
    assert(oldMessageId == null && newMessageId == null);

    if (narrow case KeywordSearchNarrow(keyword: '')) {
      // The server would reject an empty keyword search; skip the request.
      // TODO this seems like an awkward layer to handle this at --
      //   probably better if the UI code doesn't take it to this point.
      _haveOldest = true;
      _haveNewest = true;
      _setInitialStatus(.idle, was: .unstarted);
      return;
    }

    _setInitialStatus(.fetching, was: .unstarted);
    // TODO schedule all this in another isolate
    final generation = this.generation;
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: anchor,
      numBefore: kMessageListFetchBatchSize,
      numAfter: kMessageListFetchBatchSize,
      allowEmptyTopicName: true,
    );
    if (this.generation > generation) return;

    _oldMessageId = result.messages.firstOrNull?.id;
    _newMessageId = result.messages.lastOrNull?.id;

    _adjustNarrowForTopicPermalink(result.messages.firstOrNull);

    store.reconcileMessages(result.messages);
    store.recentSenders.handleMessages(result.messages); // TODO(#824)

    // The bottom slice will start at the "anchor message".
    // This is the first visible message at or past [anchor] if any,
    // else the last visible message if any.  [reachedAnchor] helps track that.
    bool reachedAnchor = false;
    for (final message in result.messages) {
      if (!_messageVisible(message)) continue;
      if (!reachedAnchor) {
        // Push the previous message into the top slice.
        middleMessage = messages.length;
        // We could interpret [anchor] for ourselves; but the server has already
        // done that work, reducing it to an int, `result.anchor`.  So use that.
        reachedAnchor = message.id >= result.anchor;
      }
      _addMessage(message);
    }
    _haveOldest = result.foundOldest;
    _haveNewest = result.foundNewest;

    if (haveNewest) {
      _syncOutboxMessagesFromStore();
    }

    _setInitialStatus(.idle, was: .fetching);
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
        _narrow = narrow.sansWith();
      case StreamMessage():
        _narrow = TopicNarrow.ofMessage(someFetchedMessageOrNull);
      case DmMessage(): // TODO(log)
        assert(false);
    }
  }

  /// Fetch the next batch of older messages, if applicable.
  ///
  /// If there are no older messages to fetch (i.e. if [haveOldest]),
  /// or if this message list is already busy fetching older messages
  /// (i.e. if [busyFetchingOlder], which includes backoff from failed requests),
  /// then this method does nothing and immediately returns.
  /// That makes this method suitable to call frequently, e.g. every frame,
  /// whenever it looks likely to be useful to have older messages.
  Future<void> fetchOlder() async {
    final generation = this.generation;
    int visibleMessageCount = 0;
    do {
      if (haveOldest) return;
      if (busyFetchingOlder) return;
      assert(initialFetched);
      assert(oldMessageId != null);
      await _fetchMore(
        anchor: NumericAnchor(oldMessageId!),
        numBefore: kMessageListFetchBatchSize,
        numAfter: 0,
        setStatus: _setOlderStatus,
        processResult: (result) {
          _oldMessageId = result.messages.firstOrNull?.id ?? oldMessageId;
          store.reconcileMessages(result.messages);
          store.recentSenders.handleMessages(result.messages); // TODO(#824)

          final fetchedMessages = _allMessagesVisible
            ? result.messages // Avoid unnecessarily copying the list.
            : result.messages.where(_messageVisible);

          _insertAllMessages(0, fetchedMessages);
          _haveOldest = result.foundOldest;
          visibleMessageCount += fetchedMessages.length;
        });
    } while (visibleMessageCount < kMessageListFetchBatchSize / 2
             && this.generation == generation);
  }

  /// Fetch the next batch of newer messages, if applicable.
  ///
  /// If there are no newer messages to fetch (i.e. if [haveNewest]),
  /// or if this message list is already busy fetching newer messages
  /// (i.e. if [busyFetchingNewer], which includes backoff from failed requests),
  /// then this method does nothing and immediately returns.
  /// That makes this method suitable to call frequently, e.g. every frame,
  /// whenever it looks likely to be useful to have newer messages.
  Future<void> fetchNewer() async {
    final generation = this.generation;
    int visibleMessageCount = 0;
    do {
      if (haveNewest) return;
      if (busyFetchingNewer) return;
      assert(initialFetched);
      assert(newMessageId != null);
      await _fetchMore(
        anchor: NumericAnchor(newMessageId!),
        numBefore: 0,
        numAfter: kMessageListFetchBatchSize,
        setStatus: _setNewerStatus,
        processResult: (result) {
          _newMessageId = result.messages.lastOrNull?.id ?? newMessageId;
          store.reconcileMessages(result.messages);
          store.recentSenders.handleMessages(result.messages); // TODO(#824)

          for (final message in result.messages) {
            if (_messageVisible(message)) {
              _addMessage(message);
              visibleMessageCount++;
            }
          }
          _haveNewest = result.foundNewest;

          if (haveNewest) {
            _syncOutboxMessagesFromStore();
          }
        });
    } while (visibleMessageCount < kMessageListFetchBatchSize / 2
             && this.generation == generation);
  }

  Future<void> _fetchMore({
    required Anchor anchor,
    required int numBefore,
    required int numAfter,
    required void Function(FetchingMoreStatus value, {FetchingMoreStatus? was}) setStatus,
    required void Function(GetMessagesResult) processResult,
  }) async {
    assert(narrow is! TopicNarrow
      // We only intend to send "with" in [fetchInitial]; see there.
      || (narrow as TopicNarrow).with_ == null);
    setStatus(.fetching);
    final generation = this.generation;
    bool hasFetchError = false;
    try {
      final result = await getMessages(store.connection,
        narrow: narrow.apiEncode(),
        anchor: anchor,
        includeAnchor: false,
        numBefore: numBefore,
        numAfter: numAfter,
        allowEmptyTopicName: true,
      );
      if (this.generation > generation) return;

      processResult(result);
    } catch (e) {
      hasFetchError = true;
      rethrow;
    } finally {
      if (this.generation == generation) {
        if (hasFetchError) {
          setStatus(.backoff, was: .fetching);
          unawaited((_fetchBackoffMachine ??= BackoffMachine())
            .wait().then((_) {
              if (this.generation != generation) return;
              setStatus(.idle, was: .backoff);
            }));
        } else {
          setStatus(.idle, was: .fetching);
          _fetchBackoffMachine = null;
        }
      }
    }
  }

  /// Reset this view to start from the newest messages.
  ///
  /// This will set [anchor] to [AnchorCode.newest],
  /// and cause messages to be re-fetched from scratch.
  void jumpToEnd() {
    assert(initialFetched);
    assert(!haveNewest);
    assert(anchor != AnchorCode.newest);
    _anchor = AnchorCode.newest;
    _reset();
    notifyListeners();
    fetchInitial();
  }

  bool _shouldAddOutboxMessage(OutboxMessage outboxMessage) {
    assert(haveNewest);
    return !outboxMessage.hidden
      && narrow.containsMessage(outboxMessage) == true
      && _messageVisible(outboxMessage);
  }

  /// Reads [MessageStore.outboxMessages] and copies to [outboxMessages]
  /// the ones belonging to this view.
  ///
  /// This should only be called when [haveNewest] is true
  /// because outbox messages are considered newer than regular messages.
  ///
  /// This does not call [notifyListeners].
  void _syncOutboxMessagesFromStore() {
    assert(haveNewest);
    assert(outboxMessages.isEmpty);
    for (final outboxMessage in store.outboxMessages.values) {
      if (_shouldAddOutboxMessage(outboxMessage)) {
        _addOutboxMessage(outboxMessage);
      }
    }
  }

  /// Add [outboxMessage] if it belongs to the view.
  void addOutboxMessage(OutboxMessage outboxMessage) {
    // We don't have the newest messages;
    // we shouldn't show any outbox messages until we do.
    if (!haveNewest) return;

    assert(outboxMessages.none(
      (message) => message.localMessageId == outboxMessage.localMessageId));
    if (_shouldAddOutboxMessage(outboxMessage)) {
      _addOutboxMessage(outboxMessage);
      notifyListeners();
    }
  }

  /// Remove the [outboxMessage] from the view.
  ///
  /// This is a no-op if the message is not found.
  ///
  /// This should only be called from [MessageStore.takeOutboxMessage].
  void removeOutboxMessage(OutboxMessage outboxMessage) {
    if (_removeOutboxMessage(outboxMessage)) {
      notifyListeners();
    }
  }

  void handleUserTopicEvent(UserTopicEvent event) {
    switch (_canAffectVisibility(event)) {
      case UserTopicVisibilityEffect.none:
        return;

      case UserTopicVisibilityEffect.muted:
        bool removed = _removeMessagesWhere((message) =>
          message is StreamMessage
            && message.streamId == event.streamId
            && message.topic == event.topicName);

        removed |= _removeOutboxMessagesWhere((message) =>
          message is StreamOutboxMessage
            && message.conversation.streamId == event.streamId
            && message.conversation.topic == event.topicName);

        if (removed) {
          notifyListeners();
        }

      case UserTopicVisibilityEffect.unmuted:
        // TODO get the newly-unmuted messages from the message store
        // For now, we simplify the task by just refetching this message list
        // from scratch.
        if (initialFetched) {
          _reset();
          notifyListeners();
          fetchInitial();
        }
    }
  }

  void handleMutedUsersEvent(MutedUsersEvent event) {
    switch (_mutedUsersEventCanAffectVisibility(event)) {
      case MutedUsersVisibilityEffect.none:
        return;

      case MutedUsersVisibilityEffect.muted:
        final anyRemoved = _removeMessagesWhere((message) {
          if (message is! DmMessage) return false;
          final narrow = DmNarrow.ofMessage(message, selfUserId: store.selfUserId);
          return store.shouldMuteDmConversation(narrow, event: event);
        });
        if (anyRemoved) {
          notifyListeners();
        }

      case MutedUsersVisibilityEffect.mixed:
      case MutedUsersVisibilityEffect.unmuted:
        // TODO get the newly-unmuted messages from the message store
        // For now, we simplify the task by just refetching this message list
        // from scratch.
        if (initialFetched) {
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
    if (narrow.containsMessage(message) != true || !_messageVisible(message)) {
      assert(event.localMessageId == null || outboxMessages.none((message) =>
        message.localMessageId == int.parse(event.localMessageId!, radix: 10)));
      return;
    }
    if (!haveNewest) {
      // This message list's [messages] doesn't yet reach the new end
      // of the narrow's message history.  (Either [fetchInitial] hasn't yet
      // completed, or if it has then it was in the middle of history and no
      // subsequent [fetchNewer] has reached the end.)
      // So this still-newer message doesn't belong.
      // Leave it to be found by a subsequent fetch when appropriate.
      // TODO mitigate this fetch/event race: save message to add to list later,
      //   in case the fetch that reaches the end is already ongoing and
      //   didn't include this message.
      return;
    }

    // Remove the outbox messages temporarily.
    // We'll add them back after the new message.
    _removeOutboxMessageItems();
    // TODO insert in middle of [messages] instead, when appropriate
    _addMessage(message);
    if (event.localMessageId != null) {
      final localMessageId = int.parse(event.localMessageId!, radix: 10);
      // [outboxMessages] is expected to be short, so removing the corresponding
      // outbox message and reprocessing them all in linear time is efficient.
      outboxMessages.removeWhere(
        (message) => message.localMessageId == localMessageId);
    }
    _reprocessOutboxMessages();
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
        // TODO(#1009) anchor to some visible message, if any
        renarrowAndFetch(newNarrow, anchor);
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
        // The messages didn't enter or leave this narrow.
        // TODO(#1255): … except they may have become muted or not.
        //   We'll handle that at the same time as we handle muting itself changing.
        // Recipient headers, and downstream of those, may change, though.
        _messagesMovedInternally(messageIds);

      case KeywordSearchNarrow():
        // This might not be quite true, since matches can be determined by
        // the topic alone, and topics change. Punt on trying to add/remove
        // messages, though, because we aren't equipped to evaluate the match
        // without asking the server.
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
