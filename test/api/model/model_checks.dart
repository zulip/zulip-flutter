import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';

extension MessageChecks on Subject<Message> {
  Subject<Map<String, dynamic>> get toJson => has((e) => e.toJson(), 'toJson');

  void jsonEquals(Message expected) {
    final expectedJson = expected.toJson();
    expectedJson['reactions'] = it()..isA<List<Reaction>>().jsonEquals(expected.reactions);
    toJson.deepEquals(expectedJson);
  }

  Subject<String> get content => has((e) => e.content, 'content');
  Subject<bool> get isMeMessage => has((e) => e.isMeMessage, 'isMeMessage');
  Subject<int?> get lastEditTimestamp => has((e) => e.lastEditTimestamp, 'lastEditTimestamp');
  Subject<List<Reaction>> get reactions => has((e) => e.reactions, 'reactions');
  Subject<List<String>> get flags => has((e) => e.flags, 'flags');

  // TODO accessors for other fields
}

extension ReactionsChecks on Subject<List<Reaction>> {
  void deepEquals(_) {
    throw UnimplementedError('Tried to call [Subject<List<Reaction>>.deepEquals]. Use jsonEquals instead.');
  }

  void jsonEquals(List<Reaction> expected) {
    // (cast, to bypass this extension's deepEquals implementation, which throws)
    // ignore: unnecessary_cast
    (this as Subject<List>).deepEquals(expected.map((r) => it()..isA<Reaction>().jsonEquals(r)));
  }
}

extension ReactionChecks on Subject<Reaction> {
  Subject<Map<String, dynamic>> get toJson => has((r) => r.toJson(), 'toJson');

  void jsonEquals(Reaction expected) {
    toJson.deepEquals(expected.toJson());
  }

  Subject<String> get emojiName => has((r) => r.emojiName, 'emojiName');
  Subject<String> get emojiCode => has((r) => r.emojiCode, 'emojiCode');
  Subject<ReactionType> get reactionType => has((r) => r.reactionType, 'reactionType');
  Subject<int> get userId => has((r) => r.userId, 'userId');
}

// TODO similar extensions for other types in model
