import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

void main() {
  PerAccountStore prepare({
    Map<String, RealmEmojiItem> realmEmoji = const {},
    bool addServerDataForPopular = true,
    Map<String, List<String>>? unicodeEmoji,
  }) {
    final store = eg.store(
      initialSnapshot: eg.initialSnapshot(realmEmoji: realmEmoji));

    if (addServerDataForPopular || unicodeEmoji != null) {
      final extraEmojiData = ServerEmojiData(codeToNames: unicodeEmoji ?? {});
      final emojiData = addServerDataForPopular
        ? eg.serverEmojiDataPopularPlus(extraEmojiData)
        : extraEmojiData;
      store.setServerEmojiData(emojiData);
    }
    return store;
  }

  group('emojiDisplayFor', () {
    test('Unicode emoji', () {
      check(eg.store().emojiDisplayFor(emojiType: ReactionType.unicodeEmoji,
        emojiCode: '1f642', emojiName: 'slight_smile')
      ).isA<UnicodeEmojiDisplay>()
        ..emojiName.equals('slight_smile')
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

  final popularCandidates = (
    eg.store()..setServerEmojiData(eg.serverEmojiDataPopular)
  ).popularEmojiCandidates();
  assert(popularCandidates.length == 6);

  Condition<Object?> isUnicodeCandidate(String? emojiCode, List<String>? names) {
    return (it_) {
      final it = it_.isA<EmojiCandidate>();
      it.emojiType.equals(ReactionType.unicodeEmoji);
      if (emojiCode != null) it.emojiCode.equals(emojiCode);
      if (names != null) {
        it.emojiName.equals(names.first);
        it.aliases.deepEquals(names.sublist(1));
      }
    };
  }

  Condition<Object?> isRealmCandidate({String? emojiCode, String? emojiName}) {
    return (it_) {
      final it = it_.isA<EmojiCandidate>();
      it.emojiType.equals(ReactionType.realmEmoji);
      if (emojiCode != null) it.emojiCode.equals(emojiCode);
      if (emojiName != null) it.emojiName.equals(emojiName);
      it.aliases.isEmpty();
    };
  }

  Condition<Object?> isZulipCandidate() {
    return (it) => it.isA<EmojiCandidate>()
      ..emojiType.equals(ReactionType.zulipExtraEmoji)
      ..emojiCode.equals('zulip')
      ..emojiName.equals('zulip')
      ..aliases.isEmpty();
  }

  List<Condition<Object?>> arePopularCandidates = popularCandidates.map(
    (c) => isUnicodeCandidate(c.emojiCode, null)).toList();

  group('allEmojiCandidates', () {
    // TODO test emojiDisplay of candidates matches emojiDisplayFor

    test('popular emoji appear in their canonical order', () {
      // In the server's emoji data, have the popular emoji in a permuted order,
      // and interspersed with other emoji.
      assert(popularCandidates.length == 6);
      final store = prepare(addServerDataForPopular: false, unicodeEmoji: {
        '1f603': ['smiley'],
        for (final candidate in popularCandidates.skip(3))
          candidate.emojiCode: [candidate.emojiName, ...candidate.aliases],
        '1f34a': ['orange', 'tangerine', 'mandarin'],
        for (final candidate in popularCandidates.take(3))
          candidate.emojiCode: [candidate.emojiName, ...candidate.aliases],
        '1f516': ['bookmark'],
      });
      // In the allEmojiCandidates result, the popular emoji come first
      // and are in their canonical order, even though the other Unicode emoji
      // are in the same order they were given in.
      check(store.allEmojiCandidates()).deepEquals([
        for (final candidate in popularCandidates)
          isUnicodeCandidate(candidate.emojiCode,
            [candidate.emojiName, ...candidate.aliases]),
        isUnicodeCandidate('1f603', ['smiley']),
        isUnicodeCandidate('1f34a', ['orange', 'tangerine', 'mandarin']),
        isUnicodeCandidate('1f516', ['bookmark']),
        isZulipCandidate(),
      ]);
    });

    test('realm emoji included only when active', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'abc', deactivated: true),
        '2': eg.realmEmojiItem(emojiCode: '2', emojiName: 'abcd'),
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isRealmCandidate(emojiCode: '2', emojiName: 'abcd'),
        isZulipCandidate(),
      ]);
    });

    test('realm emoji tolerate name collisions', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'test', deactivated: true),
        '2': eg.realmEmojiItem(emojiCode: '2', emojiName: 'try', deactivated: true),
        '3': eg.realmEmojiItem(emojiCode: '3', emojiName: 'try', deactivated: true),
        '4': eg.realmEmojiItem(emojiCode: '4', emojiName: 'try'),
        '5': eg.realmEmojiItem(emojiCode: '5', emojiName: 'test', deactivated: true),
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isRealmCandidate(emojiCode: '4', emojiName: 'try'),
        isZulipCandidate(),
      ]);
    });

    test('realm emoji overrides Unicode emoji', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'smiley'),
      }, unicodeEmoji: {
        '1f516': ['bookmark'],
        '1f603': ['smiley'],
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isUnicodeCandidate('1f516', ['bookmark']),
        isRealmCandidate(emojiCode: '1', emojiName: 'smiley'),
        isZulipCandidate(),
      ]);
    });

    test('deactivated realm emoji cause no override of Unicode emoji', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'ant', deactivated: true),
      }, unicodeEmoji: {
        '1f41c': ['ant'],
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isUnicodeCandidate('1f41c', ['ant']),
        isZulipCandidate(),
      ]);
    });

    test('Unicode emoji with overridden aliases survives with remaining names', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'tangerine'),
      }, unicodeEmoji: {
        '1f34a': ['orange', 'tangerine', 'mandarin'],
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isUnicodeCandidate('1f34a', ['orange', 'mandarin']),
        isRealmCandidate(emojiCode: '1', emojiName: 'tangerine'),
        isZulipCandidate(),
      ]);
    });

    test('Unicode emoji with overridden primary name survives with remaining names', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'orange'),
      }, unicodeEmoji: {
        '1f34a': ['orange', 'tangerine', 'mandarin'],
      });
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isUnicodeCandidate('1f34a', ['tangerine', 'mandarin']),
        isRealmCandidate(emojiCode: '1', emojiName: 'orange'),
        isZulipCandidate(),
      ]);
    });

    test('updates on setServerEmojiData', () {
      final store = prepare(unicodeEmoji: null, addServerDataForPopular: false);
      check(store.debugServerEmojiData).isNull();
      check(store.allEmojiCandidates()).deepEquals([
        isZulipCandidate(),
      ]);

      store.setServerEmojiData(eg.serverEmojiDataPopularPlus(
        ServerEmojiData(codeToNames: {
          '1f516': ['bookmark'],
        })));
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isUnicodeCandidate('1f516', ['bookmark']),
        isZulipCandidate(),
      ]);
    });

    test('updates on RealmEmojiUpdateEvent', () async {
      final store = prepare();
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isZulipCandidate(),
      ]);

      await store.handleEvent(RealmEmojiUpdateEvent(id: 1, realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'happy'),
      }));
      check(store.allEmojiCandidates()).deepEquals([
        ...arePopularCandidates,
        isRealmCandidate(emojiCode: '1', emojiName: 'happy'),
        isZulipCandidate(),
      ]);
    });

    test('memoizes result', () {
      final store = prepare(realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'happy'),
      }, unicodeEmoji: {
        '1f516': ['bookmark'],
      });
      final candidates = store.allEmojiCandidates();
      check(store.allEmojiCandidates()).identicalTo(candidates);
    });
  });

  group('popularEmojiCandidates', () {
    test('memoizes result, before setServerEmojiData', () {
      final store = eg.store();
      check(store.debugServerEmojiData).isNull();
      final candidates = store.popularEmojiCandidates();
      check(store.popularEmojiCandidates())
        ..isEmpty()..identicalTo(candidates);
    });

    test('memoizes result, after setServerEmojiData', () {
      final store = prepare();
      check(store.debugServerEmojiData).isNotNull();
      final candidates = store.popularEmojiCandidates();
      check(store.popularEmojiCandidates())
        ..isNotEmpty()..identicalTo(candidates);
    });

    test('updates on first and subsequent setServerEmojiData', () {
      final store = eg.store();
      check(store.debugServerEmojiData).isNull();

      final candidates1 = store.popularEmojiCandidates();
      check(candidates1).isEmpty();

      store.setServerEmojiData(eg.serverEmojiDataPopularLegacy);
      final candidates2 = store.popularEmojiCandidates();
      check(candidates2)
        ..isNotEmpty()
        ..not((it) => it.identicalTo(candidates1));

      store.setServerEmojiData(eg.serverEmojiDataPopular);
      final candidates3 = store.popularEmojiCandidates();
      check(candidates3)
        ..isNotEmpty()
        ..not((it) => it.identicalTo(candidates2));
    });
  });

  group('getUnicodeEmojiNameByCode', () {
    test('happy path', () {
      final store = prepare(unicodeEmoji: {
        '1f4c5': ['calendar'],
        '1f34a': ['orange', 'tangerine', 'mandarin'],
      });
      check(store.getUnicodeEmojiNameByCode('1f4c5')).equals('calendar');
      check(store.getUnicodeEmojiNameByCode('1f34a')).equals('orange');
    });

    test('server emoji data present, emoji code not present', () {
      final store = prepare(unicodeEmoji: {
        '1f4c5': ['calendar'],
      });
      check(store.getUnicodeEmojiNameByCode('1f34a')).isNull();
    });

    test('server emoji data is not present', () {
      final store = prepare(addServerDataForPopular: false);
      check(store.debugServerEmojiData).isNull();
      check(store.getUnicodeEmojiNameByCode('1f516')).isNull();
    });
  });

  group('EmojiAutocompleteView', () {
    Condition<Object?> isUnicodeResult({String? emojiCode, List<String>? names}) {
      return (it) => it.isA<EmojiAutocompleteResult>().candidate.which(
        isUnicodeCandidate(emojiCode, names));
    }

    Condition<Object?> isRealmResult({String? emojiCode, String? emojiName}) {
      return (it) => it.isA<EmojiAutocompleteResult>().candidate.which(
        isRealmCandidate(emojiCode: emojiCode, emojiName: emojiName));
    }

    Condition<Object?> isZulipResult() {
      return (it) => it.isA<EmojiAutocompleteResult>().candidate.which(
        isZulipCandidate());
    }

    List<Condition<Object?>> arePopularResults = popularCandidates.map(
      (c) => isUnicodeResult(emojiCode: c.emojiCode)).toList();

    test('results can include all three emoji types', () async {
      final store = prepare(
        realmEmoji: {'1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'happy')},
        unicodeEmoji: {'1f516': ['bookmark']},
      );
      final view = EmojiAutocompleteView.init(store: store,
        query: EmojiAutocompleteQuery(''));
      bool done = false;
      view.addListener(() { done = true; });
      await Future(() {});
      check(done).isTrue();
      check(view.results).deepEquals([
        ...arePopularResults,
        isRealmResult(emojiName: 'happy'),
        isZulipResult(),
        isUnicodeResult(names: ['bookmark']),
      ]);
    });

    test('results update after query change', () async {
      final store = prepare(
        realmEmoji: {'1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'happy')},
        unicodeEmoji: {'1f516': ['bookmark']});
      final view = EmojiAutocompleteView.init(store: store,
        query: EmojiAutocompleteQuery('hap'));
      bool done = false;
      view.addListener(() { done = true; });
      await Future(() {});
      check(done).isTrue();
      check(view.results).single.which(
        isRealmResult(emojiName: 'happy'));

      done = false;
      view.query = EmojiAutocompleteQuery('bo');
      await Future(() {});
      check(done).isTrue();
      check(view.results).single.which(
        isUnicodeResult(names: ['bookmark']));
    });

    Future<Iterable<EmojiAutocompleteResult>> resultsOf(
      String query, {
      Map<String, RealmEmojiItem> realmEmoji = const {},
      Map<String, List<String>>? unicodeEmoji,
    }) async {
      final store = prepare(realmEmoji: realmEmoji, unicodeEmoji: unicodeEmoji);
      final view = EmojiAutocompleteView.init(store: store,
        query: EmojiAutocompleteQuery(query));
      bool done = false;
      view.addListener(() { done = true; });
      await Future(() {});
      check(done).isTrue();
      return view.results;
    }

    test('results preserve order of popular emoji within each rank', () async {
      // In other words, the sorting by rank is a stable sort.

      // Full results list matches allEmojiCandidates.
      check(prepare().allEmojiCandidates())
        .deepEquals([...arePopularCandidates, isZulipCandidate()]);
      check(await resultsOf(''))
        .deepEquals([...arePopularResults, isZulipResult()]);

      // Same list written out explicitly, for comparison with the cases below.
      check(await resultsOf('')).deepEquals([
        isUnicodeResult(names: ['+1', 'thumbs_up', 'like']),
        isUnicodeResult(names: ['tada']),
        isUnicodeResult(names: ['slight_smile']),
        isUnicodeResult(names: ['heart', 'love', 'love_you']),
        isUnicodeResult(names: ['working_on_it', 'hammer_and_wrench', 'tools']),
        isUnicodeResult(names: ['octopus']),
        isZulipResult(),
      ]);

      check(await resultsOf('t')).deepEquals([
        // prefix
        isUnicodeResult(names: ['+1', 'thumbs_up', 'like']),
        isUnicodeResult(names: ['tada']),
        isUnicodeResult(names: ['working_on_it', 'hammer_and_wrench', 'tools']),
        // other
        isUnicodeResult(names: ['slight_smile']),
        isUnicodeResult(names: ['heart', 'love', 'love_you']),
        isUnicodeResult(names: ['octopus']),
      ]);

      check(await resultsOf('h')).deepEquals([
        // prefix
        isUnicodeResult(names: ['heart', 'love', 'love_you']),
        isUnicodeResult(names: ['working_on_it', 'hammer_and_wrench', 'tools']),
        // other
        isUnicodeResult(names: ['+1', 'thumbs_up', 'like']),
        isUnicodeResult(names: ['slight_smile']),
      ]);
    });

    test('results end-to-end', () async {
      // (See more detailed rank tests below, on EmojiAutocompleteQuery.)

      final unicodeEmoji = {
        '1f4d3': ['notebook'], '1f516': ['bookmark'], '1f4d6': ['book']};

      // Empty query -> base ordering.
      check(await resultsOf('', unicodeEmoji: unicodeEmoji)).deepEquals([
        ...arePopularResults,
        isZulipResult(),
        isUnicodeResult(names: ['notebook']),
        isUnicodeResult(names: ['bookmark']),
        isUnicodeResult(names: ['book']),
      ]);

      // With query, exact match precedes prefix match precedes other.
      check(await resultsOf('book', unicodeEmoji: unicodeEmoji)).deepEquals([
        isUnicodeResult(names: ['book']),
        isUnicodeResult(names: ['bookmark']),
        isUnicodeResult(names: ['notebook']),
      ]);
    });
  });

  group('EmojiAutocompleteQuery', () {
    EmojiCandidate unicode(List<String> names, {String? emojiCode}) {
      emojiCode ??= '10ffff';
      return EmojiCandidate(emojiType: ReactionType.unicodeEmoji,
        emojiCode: emojiCode,
        emojiName: names.first, aliases: names.sublist(1),
        emojiDisplay: UnicodeEmojiDisplay(
          emojiName: names.first,
          emojiUnicode: tryParseEmojiCodeToUnicode(emojiCode)!));
    }

    EmojiMatchQuality? matchOf(String query, EmojiCandidate candidate) {
      return EmojiAutocompleteQuery(query).match(candidate);
    }

    EmojiMatchQuality? matchOfNames(String query, List<String> names) {
      return matchOf(query, unicode(names));
    }

    EmojiMatchQuality? matchOfName(String query, String emojiName) {
      return matchOfNames(query, [emojiName]);
    }

    test('one-word query matches anywhere in name', () {
      check(matchOfName('', 'smile')).prefix;
      check(matchOfName('s', 'smile')).prefix;
      check(matchOfName('sm', 'smile')).prefix;
      check(matchOfName('smile', 'smile')).exact;
      check(matchOfName('m', 'smile')).other;
      check(matchOfName('mile', 'smile')).other;
      check(matchOfName('e', 'smile')).other;

      check(matchOfName('smiley', 'smile')).none;
      check(matchOfName('a', 'smile')).none;

      check(matchOfName('o', 'open_book')).prefix;
      check(matchOfName('open', 'open_book')).prefix;
      check(matchOfName('pe', 'open_book')).other;
      check(matchOfName('boo', 'open_book')).wordAligned;
      check(matchOfName('ok', 'open_book')).other;
    });

    test('multi-word query matches from start of a word', () {
      check(matchOfName('open_', 'open_book')).prefix;
      check(matchOfName('open_b', 'open_book')).prefix;
      check(matchOfName('open_book', 'open_book')).exact;

      check(matchOfName('pen_', 'open_book')).none;
      check(matchOfName('n_b', 'open_book')).none;

      check(matchOfName('blue_dia', 'large_blue_diamond')).wordAligned;
    });

    test('spaces in query behave as underscores', () {
      check(matchOfName('open ', 'open_book')).prefix;
      check(matchOfName('open b', 'open_book')).prefix;
      check(matchOfName('open book', 'open_book')).exact;

      check(matchOfName('pen ', 'open_book')).none;
      check(matchOfName('n b', 'open_book')).none;

      check(matchOfName('blue dia', 'large_blue_diamond')).wordAligned;
    });

    test('query is lower-cased', () {
      check(matchOfName('Smi', 'smile')).prefix;
    });

    test('query matches aliases same way as primary name', () {
      check(matchOfNames('a', ['a', 'b'])).exact;
      check(matchOfNames('b', ['a', 'b'])).exact;
      check(matchOfNames('c', ['a', 'b'])).none;

      check(matchOfNames('pe', ['x', 'open_book'])).other;
      check(matchOfNames('ok', ['x', 'open_book'])).other;

      check(matchOfNames('open_', ['x', 'open_book'])).prefix;
      check(matchOfNames('open b', ['x', 'open_book'])).prefix;
      check(matchOfNames('pen_', ['x', 'open_book'])).none;

      check(matchOfNames('blue_dia', ['x', 'large_blue_diamond'])).wordAligned;

      check(matchOfNames('Smi', ['x', 'smile'])).prefix;
    });

    test('best match among name and aliases prevails', () {
      check(matchOfNames('a', ['ab', 'a', 'b_a', 'ba', 'x'])).exact;
      check(matchOfNames('a', ['ba', 'ab', 'b_a', 'x'])).prefix;
      check(matchOfNames('a', ['ba', 'ab', 'b_a'])).prefix;
      check(matchOfNames('a', ['ba', 'b_a', 'x'])).wordAligned;
      check(matchOfNames('a', ['b_a', 'ba'])).wordAligned;
      check(matchOfNames('a', ['ba', 'x'])).other;
      check(matchOfNames('a', ['x', 'y', 'z'])).none;
    });

    test('query matches literal Unicode value', () {
      EmojiMatchQuality? matchOfLiteral(String query, String emojiCode, {
          required String aka}) {
        assert(aka == query);
        return matchOf(query, unicode(['asdf'], emojiCode: emojiCode));
      }

      // Matching the code, in hex, doesn't count.
      check(matchOfLiteral('1f642', aka: '1f642', '1f642')).none;

      // Matching the Unicode value the code describes does count…
      check(matchOfLiteral('🙂', aka: '\u{1f642}', '1f642')).exact;
      // … and failing to match it doesn't make a match.
      check(matchOfLiteral('🙁', aka: '\u{1f641}', '1f642')).none;

      // Multi-code-point emoji work fine.
      check(matchOfLiteral('🏳‍🌈', aka: '\u{1f3f3}\u{200d}\u{1f308}',
        '1f3f3-200d-1f308')).exact;
      // Only exact matches count; no partial matches.
      check(matchOfLiteral('🏳', aka: '\u{1f3f3}',
        '1f3f3-200d-1f308')).none;
      check(matchOfLiteral('‍🌈', aka: '\u{200d}\u{1f308}',
        '1f3f3-200d-1f308')).none;
      check(matchOfLiteral('🏳‍🌈', aka: '\u{1f3f3}\u{200d}\u{1f308}',
        '1f3f3')).none;
    });

    EmojiCandidate realmCandidate(String emojiName) {
      return EmojiCandidate(
        emojiType: ReactionType.realmEmoji,
        emojiCode: '1', emojiName: emojiName, aliases: null,
        emojiDisplay: ImageEmojiDisplay(
          emojiName: emojiName,
          resolvedUrl: eg.realmUrl.resolve('/emoji/1.png'),
          resolvedStillUrl: eg.realmUrl.resolve('/emoji/1-still.png')));
    }

    test('can match realm emoji', () {
      check(matchOf('eqeq', realmCandidate('eqeq'))).exact;
      check(matchOf('open_', realmCandidate('open_book'))).prefix;
      check(matchOf('n_b', realmCandidate('open_book'))).none;
      check(matchOf('blue dia', realmCandidate('large_blue_diamond'))).wordAligned;
      check(matchOf('Smi', realmCandidate('smile'))).prefix;
    });

    EmojiCandidate zulipCandidate() {
      final store = eg.store();
      return EmojiCandidate(
        emojiType: ReactionType.zulipExtraEmoji,
        emojiCode: 'zulip', emojiName: 'zulip', aliases: null,
        emojiDisplay: store.emojiDisplayFor(
          emojiType: ReactionType.zulipExtraEmoji,
          emojiCode: 'zulip', emojiName: 'zulip'));
    }

    test('can match Zulip extra emoji', () {
      check(matchOf('z', zulipCandidate())).prefix;
      check(matchOf('Zulip', zulipCandidate())).exact;
      check(matchOf('p', zulipCandidate())).other;
      check(matchOf('x', zulipCandidate())).none;
    });

    int? rankOf(String query, EmojiCandidate candidate) {
      return EmojiAutocompleteQuery(query).testCandidate(candidate)?.rank;
    }

    void checkPrecedes(String query, EmojiCandidate a, EmojiCandidate b) {
      check(rankOf(query, a)!).isLessThan(rankOf(query, b)!);
    }

    void checkSameRank(String query, EmojiCandidate a, EmojiCandidate b) {
      check(rankOf(query, a)!).equals(rankOf(query, b)!);
    }

    final octopus = unicode(['octopus'], emojiCode: '1f419');
    final workingOnIt = unicode(['working_on_it'], emojiCode: '1f6e0');
    final love = unicode(['love'], emojiCode: '2764'); // aka :heart:

    test('ranks match quality exact/prefix/word-aligned/other', () {
      checkPrecedes('o', unicode(['o']), unicode(['onion']));
      checkPrecedes('o', unicode(['onion']), unicode(['squared_ok']));
      checkPrecedes('o', unicode(['squared_ok']), unicode(['book']));
    });

    test('ranks popular before realm before other Unicode', () {
      checkPrecedes('o', octopus, realmCandidate('open_book'));
      checkPrecedes('o', realmCandidate('open_book'), unicode(['ok']));
    });

    test('ranks Zulip extra emoji same as realm emoji', () {
      checkSameRank('z', zulipCandidate(), realmCandidate('zounds'));
    });

    test('ranks exact-vs-not more significant than popular/custom/other', () {
      // Generic Unicode exact beats popular prefix…
      checkPrecedes('o', unicode(['o']), octopus);
      // … which really does count as popular, beating realm prefix.
      checkPrecedes('o', octopus, realmCandidate('open_book'));
    });

    test('ranks popular-vs-not more significant than prefix/word-aligned', () {
      // Popular word-aligned beats realm prefix.
      checkPrecedes('o', workingOnIt, realmCandidate('open_book'));
    });

    test('ranks popular as if generic when non-word-aligned', () {
      // Generic word-aligned beats popular other.
      checkPrecedes('o', unicode(['squared_ok']), love);
      // Popular other ranks below even custom other…
      checkPrecedes('o', realmCandidate('yo'), love);
      // … and same as generic Unicode other.
      checkSameRank('o', love, unicode(['book']));

      // And that emoji really does count as popular,
      // beating custom emoji when both have a prefix match.
      checkPrecedes('l', love, realmCandidate('logs'));
    });

    test('ranks custom/other more significant than prefix/word-aligned', () {
      // Custom word-aligned beats generic prefix.
      checkPrecedes('o', realmCandidate('laughing_blue_octopus'),
                         unicode(['ok']));
    });

    test('ranks word-aligned/other more significant than custom/other', () {
      // Generic Unicode word-aligned beats realm other.
      checkPrecedes('o', unicode(['squared_ok']), realmCandidate('yo'));
    });

    test('full list of ranks', () {
      check([
        rankOf('o', unicode(['o'])),              // exact (generic)
        rankOf('o', octopus),                     // prefix popular
        rankOf('o', workingOnIt),                 // word-aligned popular
        rankOf('o', realmCandidate('open_book')), // prefix realm
        rankOf('z', zulipCandidate()),            //  == prefix :zulip:
        rankOf('y', realmCandidate('thank_you')), // word-aligned realm
            // (word-aligned :zulip: is impossible because the name is one word)
        rankOf('o', unicode(['ok'])),             // prefix generic
        rankOf('o', unicode(['squared_ok'])),     // word-aligned generic
        rankOf('o', realmCandidate('yo')),        // other realm
        rankOf('p', zulipCandidate()),            //  == other :zulip:
        rankOf('o', unicode(['book'])),           // other generic
        rankOf('o', love),                        //  == other popular
      ]).deepEquals([0, 1, 2, 3, 3, 4, 5, 6, 7, 7, 8, 8]);
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

extension EmojiCandidateChecks on Subject<EmojiCandidate> {
  Subject<ReactionType> get emojiType => has((x) => x.emojiType, 'emojiType');
  Subject<String> get emojiCode => has((x) => x.emojiCode, 'emojiCode');
  Subject<String> get emojiName => has((x) => x.emojiName, 'emojiName');
  Subject<Iterable<String>> get aliases => has((x) => x.aliases, 'aliases');
  Subject<EmojiDisplay> get emojiDisplay => has((x) => x.emojiDisplay, 'emojiDisplay');
}

extension EmojiMatchQualityChecks on Subject<EmojiMatchQuality?> {
  void get exact => equals(EmojiMatchQuality.exact);
  void get prefix => equals(EmojiMatchQuality.prefix);
  void get wordAligned => equals(EmojiMatchQuality.wordAligned);
  void get other => equals(EmojiMatchQuality.other);
  void get none => isNull();
}

extension EmojiAutocompleteResultChecks on Subject<EmojiAutocompleteResult> {
  Subject<EmojiCandidate> get candidate => has((x) => x.candidate, 'candidate');
}
