import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reaction.g.dart';

/// A message's reactions, in a convenient data structure.
class Reactions {
  int get total => _total;
  int _total;

  /// A list of [ReactionWithVotes] objects.
  ///
  /// There won't be two items with the same
  /// [ReactionWithVotes.reactionType] and [ReactionWithVotes.emojiCode].
  /// (We don't also key on [ReactionWithVotes.emojiName];
  /// see [ReactionWithVotes].)
  ///
  /// Sorted descending by the size of [ReactionWithVotes.userIds],
  /// i.e., the number of votes.
  late final List<ReactionWithVotes> aggregated;

  Reactions._(this.aggregated, this._total);

  factory Reactions(List<Reaction> unaggregated) {
    final byReaction = LinkedHashMap<Reaction, ReactionWithVotes>(
      equals: (a, b) => a.reactionType == b.reactionType && a.emojiCode == b.emojiCode,
      hashCode: (r) => Object.hash(r.reactionType, r.emojiCode),
    );
    for (final reaction in unaggregated) {
      final current = byReaction[reaction] ??= ReactionWithVotes.empty(reaction);
      current.userIds.add(reaction.userId);
    }

    return Reactions._(
      byReaction.values.sorted(
        // Descending by number of votes
        (a, b) => -a.userIds.length.compareTo(b.userIds.length),
      ),
      unaggregated.length,
    );
  }

  factory Reactions.fromJson(List<dynamic> json) {
    return Reactions(
      json.map((r) => Reaction.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  List<dynamic> toJson() {
    final result = <Reaction>[];
    for (final reactionWithVotes in aggregated) {
      result.addAll(reactionWithVotes.userIds.map((userId) => Reaction(
        reactionType: reactionWithVotes.reactionType,
        emojiCode: reactionWithVotes.emojiCode,
        emojiName: reactionWithVotes.emojiName,
        userId: userId,
      )));
    }
    return result;
  }

  void add(Reaction reaction) {
    final currentIndex = aggregated.indexWhere((r) {
      return r.reactionType == reaction.reactionType && r.emojiCode == reaction.emojiCode;
    });
    if (currentIndex == -1) {
      final newItem = ReactionWithVotes.empty(reaction);
      newItem.userIds.add(reaction.userId);
      aggregated.add(newItem);
    } else {
      final current = aggregated[currentIndex];
      current.userIds.add(reaction.userId);

      // Reposition `current` in list to keep it sorted by number of votes
      final newIndex = 1 + aggregated.lastIndexWhere(
        (item) => item.userIds.length >= current.userIds.length,
        currentIndex - 1,
      );
      if (newIndex < currentIndex) {
        aggregated
          ..setRange(newIndex + 1, currentIndex + 1, aggregated, newIndex)
          ..[newIndex] = current;
      }
    }
    _total++;
  }

  void remove({
    required ReactionType reactionType,
    required String emojiCode,
    required int userId,
  }) {
    final currentIndex = aggregated.indexWhere((r) {
      return r.reactionType == reactionType && r.emojiCode == emojiCode;
    });
    if (currentIndex == -1) { // TODO(log)
      return;
    }
    final current = aggregated[currentIndex];
    current.userIds.remove(userId);
    if (current.userIds.isEmpty) {
      aggregated.removeAt(currentIndex);
    } else {
      final lteIndex = aggregated.indexWhere(
        (item) => item.userIds.length <= current.userIds.length,
        currentIndex + 1,
      );
      final newIndex = lteIndex == -1 ? aggregated.length - 1 : lteIndex - 1;
      if (newIndex > currentIndex) {
        aggregated
          ..setRange(currentIndex, newIndex, aggregated, currentIndex + 1)
          ..[newIndex] = current;
      }
    }
    _total--;
  }
}

/// A data structure identifying a reaction and who has voted for it.
///
/// [emojiName] is not part of the key identifying the reaction.
/// Servers don't key on it (only user, message, reaction type, and emoji code),
/// and we mimic that behavior:
///   https://github.com/zulip/zulip-flutter/pull/256#discussion_r1284865099
/// It's included here so we can display it in UI.
class ReactionWithVotes {
  final ReactionType reactionType;
  final String emojiCode;
  final String emojiName;
  final Set<int> userIds = {};

  ReactionWithVotes.empty(Reaction reaction)
    : reactionType = reaction.reactionType,
      emojiCode    = reaction.emojiCode,
      emojiName    = reaction.emojiName;

  @override
  String toString() => 'ReactionWithVotes(reactionType: $reactionType, emojiCode: $emojiCode, emojiName: $emojiName, userIds: $userIds)';
}

/// A reaction object found inside message objects in the Zulip API.
///
/// E.g., under "reactions:" in <https://zulip.com/api/get-message>.
@JsonSerializable(fieldRename: FieldRename.snake)
class Reaction {
  final String emojiName;
  final String emojiCode;
  final ReactionType reactionType;
  final int userId;
  // final Map<String, dynamic> user; // deprecated; ignore

  Reaction({
    required this.emojiName,
    required this.emojiCode,
    required this.reactionType,
    required this.userId,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) =>
    _$ReactionFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionToJson(this);

  @override
  String toString() => 'Reaction(emojiName: $emojiName, emojiCode: $emojiCode, reactionType: $reactionType, userId: $userId)';
}

/// As in [Reaction.reactionType].
@JsonEnum(fieldRename: FieldRename.snake)
enum ReactionType {
  unicodeEmoji,
  realmEmoji,
  zulipExtraEmoji;

  String toJson() => _$ReactionTypeEnumMap[this]!;

  static ReactionType fromApiValue(String value) => _byApiValue[value]!;

  static final _byApiValue = _$ReactionTypeEnumMap
    .map((key, value) => MapEntry(value, key));
}
