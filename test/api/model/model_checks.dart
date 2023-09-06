import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';

extension MessageChecks on Subject<Message> {
  Subject<String> get content => has((e) => e.content, 'content');
  Subject<bool> get isMeMessage => has((e) => e.isMeMessage, 'isMeMessage');
  Subject<int?> get lastEditTimestamp => has((e) => e.lastEditTimestamp, 'lastEditTimestamp');
  Subject<List<Reaction>> get reactions => has((e) => e.reactions, 'reactions');
  Subject<List<MessageFlag>> get flags => has((e) => e.flags, 'flags');

  // TODO accessors for other fields
}

extension ReactionsChecks on Subject<List<Reaction>> {
  void deepEquals(_) {
    throw UnimplementedError('Tried to call [Subject<List<Reaction>>.deepEquals]. Use jsonEquals instead.');
  }
}

extension ReactionChecks on Subject<Reaction> {
  Subject<String> get emojiName => has((r) => r.emojiName, 'emojiName');
  Subject<String> get emojiCode => has((r) => r.emojiCode, 'emojiCode');
  Subject<ReactionType> get reactionType => has((r) => r.reactionType, 'reactionType');
  Subject<int> get userId => has((r) => r.userId, 'userId');
}

// TODO similar extensions for other types in model
