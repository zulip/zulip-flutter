import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/reaction.dart';

import 'model_checks.dart';

void main() {
  group('Reactions', () {
    // helper to cut out "it()..isA<ReactionWithVotes>()" goo for callers
    Condition<Object?> matchesReactions(List<Reaction> reactions) {
      return (Subject<Object?> it) => it.isA<ReactionWithVotes>().matchesReactions(reactions);
    }

    test('fromJson', () {
      final reaction1Json = {'emoji_name': 'thumbs_up', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji',     'user_id': 1};
      final reaction2Json = {'emoji_name': 'thumbs_up', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji',     'user_id': 2};
      final reaction3Json = {'emoji_name': '+1',        'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji',     'user_id': 3};

      final reaction4Json = {'emoji_name': 'twocents',  'emoji_code': '181',   'reaction_type': 'realm_emoji',       'user_id': 1};
      final reaction5Json = {'emoji_name': 'twocents',  'emoji_code': '181',   'reaction_type': 'realm_emoji',       'user_id': 2};

      final reaction6Json = {'emoji_name': 'zulip',     'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji', 'user_id': 4};
      final reaction7Json = {'emoji_name': 'zulip',     'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji', 'user_id': 5};
      final reaction8Json = {'emoji_name': 'zulip',     'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji', 'user_id': 6};
      final reaction9Json = {'emoji_name': 'zulip',     'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji', 'user_id': 7};

      final reaction1 = Reaction.fromJson(reaction1Json);
      final reaction2 = Reaction.fromJson(reaction2Json);
      final reaction3 = Reaction.fromJson(reaction3Json);
      final reaction4 = Reaction.fromJson(reaction4Json);
      final reaction5 = Reaction.fromJson(reaction5Json);
      final reaction6 = Reaction.fromJson(reaction6Json);
      final reaction7 = Reaction.fromJson(reaction7Json);
      final reaction8 = Reaction.fromJson(reaction8Json);
      final reaction9 = Reaction.fromJson(reaction9Json);

      check(Reactions.fromJson([
        reaction1Json, reaction2Json, reaction3Json, reaction4Json, reaction5Json,
        reaction6Json, reaction7Json, reaction8Json, reaction9Json
      ]))
        ..aggregated.deepEquals([
            matchesReactions([reaction6, reaction7, reaction8, reaction9]),
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction4, reaction5]),
          ])
        ..total.equals(9);
    });

    test('add', () {
      final reaction0 = Reaction(
        reactionType: ReactionType.unicodeEmoji, emojiCode: '1f44d', emojiName: 'thumbs_up', userId: 1);
      final reactions = Reactions([reaction0]);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction0])
          ])
        ..total.equals(1);

      // …Different reactionType
      final reaction1 = Reaction(
        reactionType: ReactionType.realmEmoji, emojiCode: '181', emojiName: 'twocents', userId: 1);
      reactions.add(reaction1);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction0]),
            matchesReactions([reaction1]),
          ])
        ..total.equals(2);

      // …Same reactionType, different emojiCode
      final reaction2 = Reaction(
        reactionType: ReactionType.realmEmoji, emojiCode: '2049', emojiName: 'something', userId: 1);
      reactions.add(reaction2);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction0]),
            matchesReactions([reaction1]),
            matchesReactions([reaction2]),
          ])
        ..total.equals(3);

      // …Same emojiCode, different reactionType
      final reaction3 = Reaction(
        reactionType: ReactionType.unicodeEmoji, emojiCode: '2049', emojiName: 'nuclear', userId: 1);
      reactions.add(reaction3);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction0]),
            matchesReactions([reaction1]),
            matchesReactions([reaction2]),
            matchesReactions([reaction3]),
          ])
        ..total.equals(4);

      // …Same reaction, different user
      final reaction4 = Reaction(
        reactionType: ReactionType.unicodeEmoji, emojiCode: '2049', emojiName: 'nuclear', userId: 2);
      reactions.add(reaction4);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction3, reaction4]), // reordered to sort by number of votes
            matchesReactions([reaction0]),
            matchesReactions([reaction1]),
            matchesReactions([reaction2]),
          ])
        ..total.equals(5);

      final reaction5 = Reaction(
        reactionType: ReactionType.unicodeEmoji, emojiCode: '1f6e0', emojiName: 'working_on_it', userId: 2);
      reactions.add(reaction5);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction3, reaction4]),
            matchesReactions([reaction0]),
            matchesReactions([reaction1]),
            matchesReactions([reaction2]),
            matchesReactions([reaction5]),
          ])
        ..total.equals(6);

      // …Same reactionType and emojiCode, different emojiName
      final reaction6 = Reaction(
        reactionType: ReactionType.unicodeEmoji, emojiCode: '1f6e0', emojiName: 'tools', userId: 3);
      reactions.add(reaction6);
      check(reactions)
        ..aggregated.deepEquals([
          matchesReactions([reaction3, reaction4]),
          matchesReactions([reaction5, reaction6]), // reordered to sort by number of votes
          matchesReactions([reaction0]),
          matchesReactions([reaction1]),
          matchesReactions([reaction2]),
        ])
        ..total.equals(7);
    });

    test('remove', () {
      final reaction1 = Reaction(emojiName: 'thumbs_up', emojiCode: '1f44d', reactionType: ReactionType.unicodeEmoji,    userId: 1);
      final reaction2 = Reaction(emojiName: 'thumbs_up', emojiCode: '1f44d', reactionType: ReactionType.unicodeEmoji,    userId: 2);
      final reaction3 = Reaction(emojiName: 'thumbs_up', emojiCode: '1f44d', reactionType: ReactionType.unicodeEmoji,    userId: 3);

      final reaction4 = Reaction(emojiName: 'twocents',  emojiCode: '181',   reactionType: ReactionType.realmEmoji,      userId: 1);
      final reaction5 = Reaction(emojiName: 'twocents',  emojiCode: '181',   reactionType: ReactionType.realmEmoji,      userId: 2);

      final reaction6 = Reaction(emojiName: 'zulip',     emojiCode: 'zulip', reactionType: ReactionType.zulipExtraEmoji, userId: 4);
      final reaction7 = Reaction(emojiName: 'zulip',     emojiCode: 'zulip', reactionType: ReactionType.zulipExtraEmoji, userId: 5);
      final reaction8 = Reaction(emojiName: 'zulip',     emojiCode: 'zulip', reactionType: ReactionType.zulipExtraEmoji, userId: 6);
      final reaction9 = Reaction(emojiName: 'zulip',     emojiCode: 'zulip', reactionType: ReactionType.zulipExtraEmoji, userId: 7);

      final reactions = Reactions([reaction1, reaction2, reaction3, reaction4,
        reaction5, reaction6, reaction7, reaction8, reaction9]);

      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction6, reaction7, reaction8, reaction9]),
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction4, reaction5]),
          ])
        ..total.equals(9);

      reactions.remove(reactionType: reaction6.reactionType, emojiCode: reaction6.emojiCode, userId: reaction6.userId);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction7, reaction8, reaction9]),
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction4, reaction5]),
          ])
        ..total.equals(8);

      reactions.remove(reactionType: reaction8.reactionType, emojiCode: reaction8.emojiCode, userId: reaction8.userId);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction7, reaction9]), // reordered to sort by number of votes
            matchesReactions([reaction4, reaction5]),
          ])
        ..total.equals(7);

      reactions.remove(reactionType: reaction7.reactionType, emojiCode: reaction7.emojiCode, userId: reaction7.userId);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction4, reaction5]),
            matchesReactions([reaction9]), // reordered to sort by number of votes
          ])
        ..total.equals(6);

      reactions.remove(reactionType: reaction5.reactionType, emojiCode: reaction5.emojiCode, userId: reaction5.userId);
      check(reactions)
        ..aggregated.deepEquals([
            matchesReactions([reaction1, reaction2, reaction3]),
            matchesReactions([reaction4]),
            matchesReactions([reaction9]),
          ])
        ..total.equals(5);

      reactions.remove(reactionType: reaction1.reactionType, emojiCode: reaction1.emojiCode, userId: reaction1.userId);
      reactions.remove(reactionType: reaction2.reactionType, emojiCode: reaction2.emojiCode, userId: reaction2.userId);
      reactions.remove(reactionType: reaction3.reactionType, emojiCode: reaction3.emojiCode, userId: reaction3.userId);
      reactions.remove(reactionType: reaction4.reactionType, emojiCode: reaction4.emojiCode, userId: reaction4.userId);
      reactions.remove(reactionType: reaction9.reactionType, emojiCode: reaction9.emojiCode, userId: reaction9.userId);
      check(reactions)
        ..aggregated.deepEquals([])
        ..total.equals(0);
    });
  });
}
