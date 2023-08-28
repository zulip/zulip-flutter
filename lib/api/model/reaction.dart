import 'package:json_annotation/json_annotation.dart';

part 'reaction.g.dart';

/// As in [Message.reactions].
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
}
