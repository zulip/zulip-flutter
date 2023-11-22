import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';

extension ZulipStreamChecks on Subject<ZulipStream> {
  Subject<int?> get canRemoveSubscribersGroup => has((e) => e.canRemoveSubscribersGroup, 'canRemoveSubscribersGroup');
}

extension StreamColorSwatchChecks on Subject<StreamColorSwatch> {
  Subject<Color> get base => has((s) => s.base, 'base');
  Subject<Color> get unreadCountBadgeBackground => has((s) => s.unreadCountBadgeBackground, 'unreadCountBadgeBackground');
  Subject<Color> get iconOnPlainBackground => has((s) => s.iconOnPlainBackground, 'iconOnPlainBackground');
  Subject<Color> get iconOnBarBackground => has((s) => s.iconOnBarBackground, 'iconOnBarBackground');
  Subject<Color> get barBackground => has((s) => s.barBackground, 'barBackground');
}

extension MessageChecks on Subject<Message> {
  Subject<int> get id => has((e) => e.id, 'id');
  Subject<String> get content => has((e) => e.content, 'content');
  Subject<bool> get isMeMessage => has((e) => e.isMeMessage, 'isMeMessage');
  Subject<int?> get lastEditTimestamp => has((e) => e.lastEditTimestamp, 'lastEditTimestamp');
  Subject<Reactions?> get reactions => has((e) => e.reactions, 'reactions');
  Subject<List<MessageFlag>> get flags => has((e) => e.flags, 'flags');

  // TODO accessors for other fields
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

    final userIds = Set.from(reactions.map((r) => r.userId));

    // No double-votes from one person (we don't expect this from servers)
    assert(userIds.length == reactions.length);

    return which(it()
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
