import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/emoji.dart';

import '../example_data.dart' as eg;

void main() {
  group('emojiDisplayFor', () {
    test('Unicode emoji', () {
      check(eg.store().emojiDisplayFor(emojiType: ReactionType.unicodeEmoji,
        emojiCode: '1f642', emojiName: 'smile')
      ).isA<UnicodeEmojiDisplay>()
        ..emojiName.equals('smile')
        ..emojiUnicode.equals('🙂');
    });

    test('invalid Unicode emoji -> no crash', () {
      check(eg.store().emojiDisplayFor(emojiType: ReactionType.unicodeEmoji,
        emojiCode: 'asdf', emojiName: 'invalid')
      ).isA<TextEmojiDisplay>()
        .emojiName.equals('invalid');
    });

    test('realm emoji', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(realmEmoji: {
        '100': eg.realmEmojiItem(emojiCode: '100', emojiName: 'logo',
            sourceUrl: '/emoji/100.png'),
        '123': eg.realmEmojiItem(emojiCode: '123', emojiName: '100',
            sourceUrl: '/emoji/123.png'),
        '200': eg.realmEmojiItem(emojiCode: '200', emojiName: 'dancing',
            sourceUrl: '/emoji/200.png', stillUrl: '/emoji/200-still.png'),
      }));

      Subject<EmojiDisplay> checkDisplay({
          required String emojiCode, required String emojiName}) {
        return check(store.emojiDisplayFor(emojiType: ReactionType.realmEmoji,
          emojiCode: emojiCode, emojiName: emojiName)
        )..emojiName.equals(emojiName);
      }

      checkDisplay(emojiCode: '100', emojiName: 'logo').isA<ImageEmojiDisplay>()
        ..resolvedUrl.equals(eg.realmUrl.resolve('/emoji/100.png'))
        ..resolvedStillUrl.isNull();

      // Emoji code matches against emoji code, not against emoji name.
      checkDisplay(emojiCode: '123', emojiName: '100').isA<ImageEmojiDisplay>()
        ..resolvedUrl.equals(eg.realmUrl.resolve('/emoji/123.png'))
        ..resolvedStillUrl.isNull();

      // Unexpected name is accepted.
      checkDisplay(emojiCode: '100', emojiName: 'other').isA<ImageEmojiDisplay>()
        ..resolvedUrl.equals(eg.realmUrl.resolve('/emoji/100.png'))
        ..resolvedStillUrl.isNull();

      // Unexpected code falls back to text.
      checkDisplay(emojiCode: '99', emojiName: 'another')
        .isA<TextEmojiDisplay>();

      checkDisplay(emojiCode: '200', emojiName: 'dancing').isA<ImageEmojiDisplay>()
        ..resolvedUrl.equals(eg.realmUrl.resolve('/emoji/200.png'))
        ..resolvedStillUrl.equals(eg.realmUrl.resolve('/emoji/200-still.png'));

      // TODO test URLs not parsing
    });

    test(':zulip:', () {
      check(eg.store().emojiDisplayFor(emojiType: ReactionType.zulipExtraEmoji,
        emojiCode: 'zulip', emojiName: 'zulip')
      ).isA<ImageEmojiDisplay>()
        ..emojiName.equals('zulip')
        ..resolvedUrl.equals(eg.realmUrl.resolve(EmojiStoreImpl.kZulipEmojiUrl))
        ..resolvedStillUrl.isNull();
    });
  });
}

extension EmojiDisplayChecks on Subject<EmojiDisplay> {
  Subject<String> get emojiName => has((x) => x.emojiName, 'emojiName');
}

extension UnicodeEmojiDisplayChecks on Subject<UnicodeEmojiDisplay> {
  Subject<String> get emojiUnicode => has((x) => x.emojiUnicode, 'emojiUnicode');
}

extension ImageEmojiDisplayChecks on Subject<ImageEmojiDisplay> {
  Subject<Uri> get resolvedUrl => has((x) => x.resolvedUrl, 'resolvedUrl');
  Subject<Uri?> get resolvedStillUrl => has((x) => x.resolvedStillUrl, 'resolvedStillUrl');
}
