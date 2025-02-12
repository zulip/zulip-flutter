import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';

extension UserChecks on Subject<User> {
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<String?> get deliveryEmail => has((x) => x.deliveryEmail, 'deliveryEmail');
  Subject<String> get email => has((x) => x.email, 'email');
  Subject<String> get fullName => has((x) => x.fullName, 'fullName');
  Subject<String> get dateJoined => has((x) => x.dateJoined, 'dateJoined');
  Subject<bool> get isActive => has((x) => x.isActive, 'isActive');
  Subject<bool?> get isBillingAdmin => has((x) => x.isBillingAdmin, 'isBillingAdmin');
  Subject<bool> get isBot => has((x) => x.isBot, 'isBot');
  Subject<int?> get botType => has((x) => x.botType, 'botType');
  Subject<int?> get botOwnerId => has((x) => x.botOwnerId, 'botOwnerId');
  Subject<UserRole> get role => has((x) => x.role, 'role');
  Subject<String> get timezone => has((x) => x.timezone, 'timezone');
  Subject<String?> get avatarUrl => has((x) => x.avatarUrl, 'avatarUrl');
  Subject<int> get avatarVersion => has((x) => x.avatarVersion, 'avatarVersion');
  Subject<Map<int, ProfileFieldUserData>?> get profileData => has((x) => x.profileData, 'profileData');
  Subject<bool> get isSystemBot => has((x) => x.isSystemBot, 'isSystemBot');
}

extension ZulipStreamChecks on Subject<ZulipStream> {
}

extension MessageChecks on Subject<Message> {
  Subject<String> get client => has((e) => e.client, 'client');
  Subject<String> get content => has((e) => e.content, 'content');
  Subject<String> get contentType => has((e) => e.contentType, 'contentType');
  Subject<int> get id => has((e) => e.id, 'id');
  Subject<bool> get isMeMessage => has((e) => e.isMeMessage, 'isMeMessage');
  Subject<int?> get lastEditTimestamp => has((e) => e.lastEditTimestamp, 'lastEditTimestamp');
  Subject<MessageEditState> get editState => has((e) => e.editState, 'editState');
  Subject<Reactions?> get reactions => has((e) => e.reactions, 'reactions');
  Subject<int> get recipientId => has((e) => e.recipientId, 'recipientId');
  Subject<String> get senderEmail => has((e) => e.senderEmail, 'senderEmail');
  Subject<String> get senderFullName => has((e) => e.senderFullName, 'senderFullName');
  Subject<int> get senderId => has((e) => e.senderId, 'senderId');
  Subject<String> get senderRealmStr => has((e) => e.senderRealmStr, 'senderRealmStr');
  Subject<Poll?> get poll => has((e) => e.poll, 'poll');
  Subject<int> get timestamp => has((e) => e.timestamp, 'timestamp');
  Subject<String> get type => has((e) => e.type, 'type');
  Subject<List<MessageFlag>> get flags => has((e) => e.flags, 'flags');
  Subject<String?> get matchContent => has((e) => e.matchContent, 'matchContent');
  Subject<String?> get matchTopic => has((e) => e.matchTopic, 'matchTopic');
}

extension TopicNameChecks on Subject<TopicName> {
  Subject<String> get apiName => has((x) => x.apiName, 'apiName');
  Subject<String> get displayName => has((x) => x.displayName, 'displayName');
}

extension StreamMessageChecks on Subject<StreamMessage> {
  Subject<String?> get displayRecipient => has((e) => e.displayRecipient, 'displayRecipient');
  Subject<TopicName> get topic => has((e) => e.topic, 'topic');
}

extension ReactionsChecks on Subject<Reactions> {
  Subject<int> get total => has((e) => e.total, 'total');
  Subject<List<ReactionWithVotes>> get aggregated => has((e) => e.aggregated, 'aggregated');
}

extension ReactionWithVotesChecks on Subject<ReactionWithVotes> {
  Subject<ReactionType> get reactionType => has((r) => r.reactionType, 'reactionType');
  Subject<String> get emojiCode => has((r) => r.emojiCode, 'emojiCode');
  Subject<String> get emojiName => has((r) => r.emojiName, 'emojiName');
  Subject<Set<int>> get userIds => has((r) => r.userIds, 'userIds');

  /// Whether this [ReactionWithVotes] corresponds to the given same-emoji [reactions].
  void matchesReactions(List<Reaction> reactions) {
    assert(reactions.isNotEmpty);
    final first = reactions.first;

    // Same emoji for all reactions
    assert(reactions.every((r) => r.reactionType == first.reactionType && r.emojiCode == first.emojiCode));

    final userIds = Set<int>.from(reactions.map((r) => r.userId));

    // No double-votes from one person (we don't expect this from servers)
    assert(userIds.length == reactions.length);

    return which((it) => it
      ..reactionType.equals(first.reactionType)
      ..emojiCode.equals(first.emojiCode)
      ..userIds.deepEquals(userIds)
    );
  }
}

extension ReactionChecks on Subject<Reaction> {
  Subject<String> get emojiName => has((r) => r.emojiName, 'emojiName');
  Subject<String> get emojiCode => has((r) => r.emojiCode, 'emojiCode');
  Subject<ReactionType> get reactionType => has((r) => r.reactionType, 'reactionType');
  Subject<int> get userId => has((r) => r.userId, 'userId');
}

// TODO similar extensions for other types in model
