
import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/narrow.dart';
import '../api/route/messages.dart';
import 'algorithms.dart';

/// A Zulip narrow.
sealed class Narrow {
  /// This const constructor allows subclasses to have const constructors.
  const Narrow();

  /// Whether this message satisfies the filters of this narrow.
  ///
  /// This is true just when the server would be expected to include the message
  /// in a [getMessages] request for this narrow, given appropriate anchor etc.
  ///
  /// This does not necessarily mean the message list would show this message
  /// when navigated to this narrow; in particular it does not address the
  /// question of whether the stream or topic, or the sending user, is muted.
  ///
  /// Null when the client is unable to predict whether the message
  /// satisfies the filters of this narrow, e.g. when this is a search narrow.
  bool? containsMessage(MessageBase message);

  /// This narrow, expressed as an [ApiNarrow].
  ApiNarrow apiEncode();
}

/// A non-interleaved narrow, completely specifying a place to send a message.
sealed class SendableNarrow extends Narrow {
  factory SendableNarrow.ofMessage(Message message, {required int selfUserId}) {
    switch (message) {
      case StreamMessage():
        return TopicNarrow.ofMessage(message);
      case DmMessage():
        return DmNarrow.ofMessage(message, selfUserId: selfUserId);
    }
  }

  MessageDestination get destination;
}

/// The narrow called "Combined feed" in the UI.
///
/// All messages the user has access to, excluding unsubscribed streams
/// and muted streams and topics. See [PerAccountStore.isTopicVisible].
class CombinedFeedNarrow extends Narrow {
  const CombinedFeedNarrow();

  @override
  bool containsMessage(MessageBase message) {
    return true;
  }

  @override
  ApiNarrow apiEncode() => [];

  @override
  bool operator ==(Object other) {
    if (other is! CombinedFeedNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'CombinedFeedNarrow'.hashCode;
}

class ChannelNarrow extends Narrow {
  const ChannelNarrow(this.streamId);

  final int streamId;

  @override
  bool containsMessage(MessageBase message) {
    final conversation = message.conversation;
    return conversation is StreamConversation && conversation.streamId == streamId;
  }

  @override
  ApiNarrow apiEncode() => [ApiNarrowChannel(streamId)];

  @override
  String toString() => 'ChannelNarrow($streamId)';

  @override
  bool operator ==(Object other) {
    if (other is! ChannelNarrow) return false;
    return other.streamId == streamId;
  }

  @override
  int get hashCode => Object.hash('ChannelNarrow', streamId);
}

class TopicNarrow extends Narrow implements SendableNarrow {
  const TopicNarrow(this.streamId, this.topic, {this.with_});

  factory TopicNarrow.ofMessage(MessageBase<StreamConversation> message) {
    return TopicNarrow(message.conversation.streamId, message.conversation.topic);
  }

  final int streamId;
  final TopicName topic;
  final int? with_;

  TopicNarrow sansWith() => TopicNarrow(streamId, topic);

  @override
  bool containsMessage(MessageBase message) {
    final conversation = message.conversation;
    return conversation is StreamConversation
      && conversation.streamId == streamId && conversation.topic.isSameAs(topic);
  }

  @override
  ApiNarrow apiEncode() => [
    ApiNarrowChannel(streamId),
    ApiNarrowTopic(topic),
    if (with_ != null) ApiNarrowWith(with_!),
  ];

  @override
  StreamDestination get destination => StreamDestination(streamId, topic);

  @override
  String toString() {
    final fields = [
      streamId.toString(),
      topic.displayName,
      if (with_ != null) 'with: ${with_!}',
    ];
    return 'TopicNarrow(${fields.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (other is! TopicNarrow) return false;
    return other.streamId == streamId && other.topic == topic && other.with_ == with_;
  }

  @override
  int get hashCode => Object.hash('TopicNarrow', streamId, topic, with_);
}

/// The narrow for a direct-message conversation.
// Zulip has many ways of representing a DM conversation; for example code
// handling many of them, see zulip-mobile:src/utils/recipient.js .
// Please add more constructors and getters here to handle any of those
// as we turn out to need them.
class DmNarrow extends Narrow implements SendableNarrow {
  /// Construct a [DmNarrow] directly from its representation.
  ///
  /// The user IDs in `allRecipientIds` must be distinct and sorted,
  /// and must include `selfUserId`.
  ///
  /// For consuming data that follows a different convention,
  /// see other constructors.
  DmNarrow({required this.allRecipientIds, required int selfUserId})
    : assert(isSortedWithoutDuplicates(allRecipientIds)),
      assert(allRecipientIds.contains(selfUserId)),
      _selfUserId = selfUserId;

  /// A [DmNarrow] for self plus the given zero-or-more other users.
  ///
  /// The user IDs in `otherRecipientIds` must all be distinct from
  /// each other and from `selfUserId`.  They need not be sorted.
  ///
  /// See also:
  ///  * the plain [DmNarrow] constructor, given a list that includes self.
  ///  * [DmNarrow.withUsers], given a list that may or may not include self.
  factory DmNarrow.withOtherUsers(Iterable<int> otherRecipientIds,
      {required int selfUserId}) {
    return DmNarrow(selfUserId: selfUserId,
      allRecipientIds: [...otherRecipientIds, selfUserId]..sort());
  }

  /// A [DmNarrow] for a 1:1 DM conversation, either with self or otherwise.
  factory DmNarrow.withUser(int userId, {required int selfUserId}) {
    return DmNarrow(selfUserId: selfUserId,
      allRecipientIds: (userId == selfUserId)  ? [selfUserId]
                       : (userId < selfUserId) ? [userId, selfUserId]
                       :                         [selfUserId, userId]);
  }

  /// A [DmNarrow] from a list of users which may or may not include self
  /// and may or may not be sorted.
  ///
  /// Use this only when the input format is actually permitted both to
  /// include and to exclude the self user.  When the list is known to be
  /// one or the other, using the plain [DmNarrow] constructor
  /// or [DmNarrow.withOtherUsers] respectively will be more efficient.
  factory DmNarrow.withUsers(List<int> userIds, {required int selfUserId}) {
    return DmNarrow(
      allRecipientIds: {...userIds, selfUserId}.toList()..sort(),
      selfUserId: selfUserId,
    );
  }

  factory DmNarrow.ofMessage(MessageBase<DmConversation> message, {
    required int selfUserId,
  }) {
    return DmNarrow(
      // TODO should this really be making a copy of `allRecipientIds`?
      allRecipientIds: List.unmodifiable(message.conversation.allRecipientIds),
      selfUserId: selfUserId,
    );
  }

  factory DmNarrow.ofConversation(DmConversation conversation, {
    required int selfUserId,
  }) {
    return DmNarrow(
      allRecipientIds: conversation.allRecipientIds,
      selfUserId: selfUserId,
    );
  }

  /// A [DmNarrow] from an item in [InitialSnapshot.recentPrivateConversations].
  factory DmNarrow.ofRecentDmConversation(RecentDmConversation conversation, {required int selfUserId}) {
    return DmNarrow.withOtherUsers(conversation.userIds, selfUserId: selfUserId);
  }

  /// A [DmNarrow] from an [UnreadHuddleSnapshot].
  factory DmNarrow.ofUnreadHuddleSnapshot(UnreadHuddleSnapshot snapshot, {required int selfUserId}) {
    final userIds = snapshot.userIdsString.split(',').map((id) => int.parse(id));
    return DmNarrow(selfUserId: selfUserId,
      // (already sorted; see API doc)
      allRecipientIds: userIds.toList(growable: false));
  }

  factory DmNarrow.ofUpdateMessageFlagsMessageDetail(
    UpdateMessageFlagsMessageDetail detail, {
    required int selfUserId,
  }) {
    assert(detail.type == MessageType.direct);
    return DmNarrow.withOtherUsers(detail.userIds!, selfUserId: selfUserId);
  }

  /// The user IDs of everyone in the conversation, sorted.
  ///
  /// Each message in the conversation is sent by one of these users
  /// and received by all the other users.
  ///
  /// The self-user is always a member of this list.
  /// It has one element for the self-1:1 thread,
  /// two elements for other 1:1 threads,
  /// and three or more elements for a group DM thread.
  ///
  /// See also:
  /// * [otherRecipientIds], an alternate way of identifying the conversation.
  /// * [DmMessage.allRecipientIds], which provides this same format.
  /// * [DmConversation.allRecipientIds], which also provides this same format.
  final List<int> allRecipientIds;

  /// The user ID of the self-user.
  ///
  /// The [DmNarrow] implementation needs this information
  /// for converting between different forms of referring to the narrow,
  /// such as [allRecipientIds] vs. [otherRecipientIds].
  final int _selfUserId;

  /// The user IDs of everyone in the conversation except self, sorted.
  ///
  /// This is empty for the self-1:1 thread,
  /// has one element for other 1:1 threads,
  /// and has two or more elements for a group DM thread.
  ///
  /// See also:
  /// * [allRecipientIds], an alternate way of identifying the conversation.
  late final List<int> otherRecipientIds = allRecipientIds
    .where((userId) => userId != _selfUserId)
    .toList(growable: false);

  /// A string that uniquely identifies the DM conversation (within the account).
  late final String _key = otherRecipientIds.join(',');

  @override
  bool containsMessage(MessageBase message) {
    final conversation = message.conversation;
    if (conversation is! DmConversation) return false;
    if (conversation.allRecipientIds.length != allRecipientIds.length) return false;
    int i = 0;
    for (final userId in conversation.allRecipientIds) {
      if (userId != allRecipientIds[i]) return false;
      i++;
    }
    return true;
  }

  // Not [otherRecipientIds], because for the self-1:1 thread the server rejects
  // that as of Zulip Server 7 (2023-06), with BAD_REQUEST.
  @override
  DmDestination get destination => DmDestination(userIds: allRecipientIds);

  // Not [otherRecipientIds], because for the self-1:1 thread that triggers
  // a server bug as of Zulip Server 7 (2023-05): an empty list here
  // causes a 5xx response from the server.
  // TODO(server): fix bug on empty operand to dm/pm-with narrow operator
  @override
  ApiNarrow apiEncode() => [ApiNarrowDm(allRecipientIds)];

  @override
  String toString() => 'DmNarrow(allRecipientIds: $allRecipientIds)';

  @override
  bool operator ==(Object other) {
    if (other is! DmNarrow) return false;
    assert(other._selfUserId == _selfUserId,
      'Two [Narrow]s belonging to different accounts were compared with `==`.  '
      'This is a bug, because a [Narrow] does not contain information to '
      'reliably detect such a comparison, so it may produce false positives.');
    return other._key == _key;
  }

  @override
  int get hashCode => Object.hash('DmNarrow', _key);
}

class MentionsNarrow extends Narrow {
  const MentionsNarrow();

  @override
  bool containsMessage(MessageBase message) {
    if (message is! Message) return false;
    return message.flags.any((flag) {
      switch (flag) {
        case MessageFlag.mentioned:
        case MessageFlag.wildcardMentioned:
          return true;

        case MessageFlag.read:
        case MessageFlag.starred:
        case MessageFlag.collapsed:
        case MessageFlag.hasAlertWord:
        case MessageFlag.historical:
        case MessageFlag.unknown:
          return false;
      }
    });
  }

  @override
  ApiNarrow apiEncode() => [ApiNarrowIs(IsOperand.mentioned)];

  @override
  bool operator ==(Object other) {
    if (other is! MentionsNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'MentionsNarrow'.hashCode;
}

class StarredMessagesNarrow extends Narrow {
  const StarredMessagesNarrow();

  @override
  ApiNarrow apiEncode() => [ApiNarrowIs(IsOperand.starred)];

  @override
  bool containsMessage(MessageBase message) {
    if (message is! Message) return false;
    return message.flags.contains(MessageFlag.starred);
  }

  @override
  bool operator ==(Object other) {
    if (other is! StarredMessagesNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'StarredMessagesNarrow'.hashCode;
}

/// A keyword-search narrow.
///
/// [keyword] must have been trimmed with [String.trim].
class KeywordSearchNarrow extends Narrow {
  KeywordSearchNarrow(this.keyword)
    : assert(keyword.trim() == keyword);

  final String keyword;

  @override
  bool? containsMessage(MessageBase message) => null;

  @override
  ApiNarrow apiEncode() => [ApiNarrowSearch(keyword)];

  @override
  String toString() => 'KeywordSearchNarrow($keyword)';

  @override
  bool operator ==(Object other) {
    if (other is! KeywordSearchNarrow) return false;
    return other.keyword == keyword;
  }

  @override
  int get hashCode => Object.hash('KeywordSearchNarrow', keyword);
}
