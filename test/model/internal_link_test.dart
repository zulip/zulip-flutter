
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/internal_link.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';

PerAccountStore setupStore({
  required Uri realmUrl,
  List<ZulipStream>? streams,
  List<User>? users,
}) {
  final account = eg.selfAccount.copyWith(realmUrl: realmUrl);
  final store = eg.store(account: account);
  if (streams != null) {
    store.addStreams(streams);
  }
  store.addUser(eg.selfUser);
  if (users != null) {
    store.addUsers(users);
  }
  return store;
}

void main() {
  final realmUrl = Uri.parse('https://example.com/');

  void testExpectedNarrows(List<(String, Narrow?)> testCases, {
    List<ZulipStream>? streams,
    List<User>? users,
  }) {
    assert(streams != null || users != null);
    for (final testCase in testCases) {
      final String urlString = testCase.$1;
      final Narrow? expected = testCase.$2;
      test(urlString, () {
        final store = setupStore(realmUrl: realmUrl, streams: streams, users: users);
        final url = store.tryResolveUrl(urlString)!;
        check(parseInternalLink(url, store)).equals(expected);
      });
    }
  }

  group('parseInternalLink', () {
    final streams = [
      eg.stream(streamId: 1, name: 'check'),
    ];
    final testCases = [
      (true, 'legacy: stream name, no ID',
        '#narrow/stream/check', realmUrl),
      (true, 'legacy: stream name, no ID, topic',
        '#narrow/stream/check/topic/topic1', realmUrl),

      (true, 'with numeric stream ID',
        '#narrow/stream/123-check', realmUrl),
      (true, 'with numeric stream ID and topic',
        '#narrow/stream/123-a/topic/topic1', realmUrl),

      (true, 'with numeric pm user IDs (new operator)',
        '#narrow/dm/123-mark', realmUrl),
      (true, 'with numeric pm user IDs (old operator)',
        '#narrow/pm-with/123-mark', realmUrl),

      (false, 'wrong fragment',
        '#nope', realmUrl),
      (false, 'wrong path',
        'user_uploads/#narrow/stream/check', realmUrl),
      (false, 'wrong domain',
        'https://another.com/#narrow/stream/check', realmUrl),

      (false, '#narrowly',
        '#narrowly/stream/check', realmUrl),

      (false, 'double slash',
        'https://example.com//#narrow/stream/check', realmUrl),
      (false, 'triple slash',
        'https://example.com///#narrow/stream/check', realmUrl),

      (true, 'with port',
        'https://example.com:444/#narrow/stream/check',
        Uri.parse('https://example.com:444/')),

      // Dart's [Uri] currently lacks IDNA or Punycode support:
      //   https://github.com/dart-lang/sdk/issues/26284
      //   https://github.com/dart-lang/sdk/issues/29420

      // (true, 'same domain, punycoded host',
      //   'https://example.xn--h2brj9c/#narrow/stream/check',
      //   Uri.parse('https://example.भारत/')), // FAILS

      (true, 'punycodable host',
        'https://example.भारत/#narrow/stream/check',
        Uri.parse('https://example.भारत/')),

      // (true, 'same domain, IDNA-mappable',
      //   'https://ℯⅩªm🄿ₗℰ.ℭᴼⓂ/#narrow/stream/check',
      //   Uri.parse('https://example.com')), // FAILS

      (true, 'ipv4 address',
        'http://192.168.0.1/#narrow/stream/check',
        Uri.parse('http://192.168.0.1/')),

      // (true, 'same IPv4 address, IDNA-mappable',
      //   'http://１𝟗𝟚。①⁶🯸．₀｡𝟭/#narrow/stream/check',
      //   Uri.parse('http://192.168.0.1/')), // FAILS

      // TODO: Add tests for IPv6.

      // These examples may seem weird, but a previous version of
      // the zulip-mobile code accepted most of them.

      // This one, except possibly the fragment, is a 100% realistic link
      // for innocent normal use.  The buggy old version narrowly avoided
      // accepting it... but would accept all the variations below.
      (false, 'wrong domain, realm-like path, narrow-like fragment',
        'https://web.archive.org/web/*/${realmUrl.resolve('#narrow/stream/check')}',
        realmUrl),
      (false, 'odd scheme, wrong domain, realm-like path, narrow-like fragment',
        'ftp://web.archive.org/web/*/${realmUrl.resolve('#narrow/stream/check')}',
        realmUrl),
      (false, 'same domain, realm-like path, narrow-like fragment',
        'web/*/${realmUrl.resolve('#narrow/stream/check')}',
        realmUrl),
    ];
    for (final testCase in testCases) {
      final bool expected = testCase.$1;
      final String description = testCase.$2;
      final String urlString = testCase.$3;
      final Uri realmUrl = testCase.$4;
      test('${expected ? 'accepts': 'rejects'} $description: $urlString', () {
        final store = setupStore(realmUrl: realmUrl, streams: streams);
        final url = store.tryResolveUrl(urlString)!;
        final result = parseInternalLink(url, store);
        check(result != null).equals(expected);
      });
    }
  });

  group('parseInternalLink', () {
    final streams = [
      eg.stream(streamId: 1,   name: 'check'),
      eg.stream(streamId: 3,   name: 'mobile'),
      eg.stream(streamId: 5,   name: 'stream'),
      eg.stream(streamId: 123, name: 'topic'),
    ];

    group('"/#narrow/stream/<...>" returns expected StreamNarrow', () {
      const testCases = [
        ('/#narrow/stream/check',   StreamNarrow(1)),
        ('/#narrow/stream/stream/', StreamNarrow(5)),
        ('/#narrow/stream/topic/',  StreamNarrow(123)),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/stream/<...>/topic/<...>" returns expected TopicNarrow', () {
      const testCases = [
        ('/#narrow/stream/check/topic/test',                 TopicNarrow(1, 'test')),
        ('/#narrow/stream/mobile/subject/topic/near/378333', TopicNarrow(3, 'topic')),
        ('/#narrow/stream/mobile/topic/topic/',              TopicNarrow(3, 'topic')),
        ('/#narrow/stream/stream/topic/topic/near/1',        TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic/near/1',      TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic',             TopicNarrow(5, 'topic')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/dm/<...>" returns expected DmNarrow', () {
      final expectedNarrow = DmNarrow.withUsers([1, 2],
        selfUserId: eg.selfUser.userId);
      final testCases = [
        ('/#narrow/dm/1,2-group',                        expectedNarrow),
        ('/#narrow/dm/1,2-group/near/1',                 expectedNarrow),
        ('/#narrow/dm/a.40b.2Ecom.2Ec.2Ed.2Ecom/near/3', null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/pm-with/<...>" returns expected DmNarrow', () {
      final expectedNarrow = DmNarrow.withUsers([1, 2],
        selfUserId: eg.selfUser.userId);
      final testCases = [
        ('/#narrow/pm-with/1,2-group',                        expectedNarrow),
        ('/#narrow/pm-with/1,2-group/near/1',                 expectedNarrow),
        ('/#narrow/pm-with/a.40b.2Ecom.2Ec.2Ed.2Ecom/near/3', null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('unexpected link shapes are rejected', () {
      final testCases = [
        ('/#narrow/stream/name/topic/',           null), // missing operand
        ('/#narrow/stream/name/unknown/operand/', null), // unknown operator
      ];
      testExpectedNarrows(testCases, streams: streams);
    });
  });

  group('decodeHashComponent', () {
    group('correctly decodes MediaWiki-style dot-encoded strings', () {
      final testCases = [
        ['some_text', 'some_text'],
        ['some.20text', 'some text'],
        ['some.2Etext', 'some.text'],

        ['na.C3.AFvet.C3.A9', 'naïveté'],
        ['.C2.AF.5C_(.E3.83.84)_.2F.C2.AF', r'¯\_(ツ)_/¯'],
      ];
      for (final [testCase, expected] in testCases) {
        test('"$testCase"', () =>
          check(decodeHashComponent(testCase)).equals(expected));
      }

      final malformedTestCases = [
        // malformed dot-encoding
        'some.text',
        'some.2gtext',
        'some.arbitrary_text',

        // malformed UTF-8
        '.88.99.AA.BB',
      ];
      for (final testCase in malformedTestCases) {
        test('"$testCase"', () =>
          check(decodeHashComponent(testCase)).isNull());
      }
    });

    group('parses correctly in stream and topic operands', () {
      final streams = [
        eg.stream(streamId: 1, name: 'some_stream'),
        eg.stream(streamId: 2, name: 'some stream'),
        eg.stream(streamId: 3, name: 'some.stream'),
      ];
      const testCases = [
        ('/#narrow/stream/some_stream',                    StreamNarrow(1)),
        ('/#narrow/stream/some.20stream',                  StreamNarrow(2)),
        ('/#narrow/stream/some.2Estream',                  StreamNarrow(3)),
        ('/#narrow/stream/some_stream/topic/some_topic',   TopicNarrow(1, 'some_topic')),
        ('/#narrow/stream/some_stream/topic/some.20topic', TopicNarrow(1, 'some topic')),
        ('/#narrow/stream/some_stream/topic/some.2Etopic', TopicNarrow(1, 'some.topic')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });
  });

  group('parseInternalLink edge cases', () {
    void testExpectedStreamNarrow(String testCase, int? streamId) {
      final streamNarrow = (streamId != null) ? StreamNarrow(streamId) : null;
      testExpectedNarrows([(testCase, streamNarrow)], streams: [
        eg.stream(streamId: 1, name: "general"),
      ]);
    }

    group('basic', () {
      testExpectedStreamNarrow('#narrow/stream/1-general',         1);
    });

    group('if stream not found, use stream ID anyway', () {
      testExpectedStreamNarrow('#narrow/stream/123-topic',         123);
    });

    group('on stream link with wrong name, ID wins', () {
      testExpectedStreamNarrow('#narrow/stream/1-nonsense',        1);
      testExpectedStreamNarrow('#narrow/stream/1-',                1);
    });

    group('on malformed stream link: reject', () {
      testExpectedStreamNarrow('#narrow/stream/-1',                null);
      testExpectedStreamNarrow('#narrow/stream/1nonsense-general', null);
      testExpectedStreamNarrow('#narrow/stream/-general',          null);
    });
  });

  group('parseInternalLink with historic links', () {
    group('for stream with hyphens or even looking like new-style', () {
      final streams = [
        eg.stream(streamId: 1, name: 'test-team'),
        eg.stream(streamId: 2, name: '311'),
        eg.stream(streamId: 3, name: '311-'),
        eg.stream(streamId: 4, name: '311-help'),
        eg.stream(streamId: 5, name: '--help'),
      ];
      const testCases = [
        ('#narrow/stream/test-team/', StreamNarrow(1)),
        ('#narrow/stream/311/',       StreamNarrow(2)),
        ('#narrow/stream/311-/',      StreamNarrow(3)),
        ('#narrow/stream/311-help/',  StreamNarrow(4)),
        ('#narrow/stream/--help/',    StreamNarrow(5)),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('on ambiguous new- or old-style: new wins', () {
      final streams = [
        eg.stream(streamId: 1,   name: '311'),
        eg.stream(streamId: 2,   name: '311-'),
        eg.stream(streamId: 3,   name: '311-help'),
        eg.stream(streamId: 311, name: 'collider'),
      ];
      const testCases = [
        ('#narrow/stream/311/',      StreamNarrow(311)),
        ('#narrow/stream/311-/',     StreamNarrow(311)),
        ('#narrow/stream/311-help/', StreamNarrow(311)),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('on old stream link', () {
      final streams = [
        eg.stream(streamId: 1, name: 'check'),
        eg.stream(streamId: 2, name: 'bot testing'),
        eg.stream(streamId: 3, name: 'check.API'),
        eg.stream(streamId: 4, name: 'stream'),
        eg.stream(streamId: 5, name: 'topic'),
      ];
      const testCases = [
        ('#narrow/stream/check/',         StreamNarrow(1)),
        ('#narrow/stream/bot.20testing/', StreamNarrow(2)),
        ('#narrow/stream/check.2EAPI/',   StreamNarrow(3)),
        ('#narrow/stream/stream/',        StreamNarrow(4)),
        ('#narrow/stream/topic/',         StreamNarrow(5)),

        ('#narrow/stream/check.API/',     null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });
  });

  group('parseInternalLink', () {
    group('topic link parsing', () {
      final stream = eg.stream(name: "general");

      group('basic', () {
        String mkUrlString(operand) {
          return '#narrow/stream/${stream.streamId}-${stream.name}/topic/$operand';
        }
        final testCases = [
          (mkUrlString('(no.20topic)'), TopicNarrow(stream.streamId, '(no topic)')),
          (mkUrlString('lunch'),        TopicNarrow(stream.streamId, 'lunch')),
        ];
        testExpectedNarrows(testCases, streams: [stream]);
      });

      group('on old topic link, with dot-encoding', () {
        String mkUrlString(operand) {
          return '#narrow/stream/${stream.name}/topic/$operand';
        }
        final testCases = [
          (mkUrlString('(no.20topic)'), TopicNarrow(stream.streamId, '(no topic)')),
          (mkUrlString('google.2Ecom'), TopicNarrow(stream.streamId, 'google.com')),
          (mkUrlString('google.com'),   null),
          (mkUrlString('topic.20name'), TopicNarrow(stream.streamId, 'topic name')),
          (mkUrlString('stream'),       TopicNarrow(stream.streamId, 'stream')),
          (mkUrlString('topic'),        TopicNarrow(stream.streamId, 'topic')),
        ];
        testExpectedNarrows(testCases, streams: [stream]);
      });
    });

    group('DM link parsing', () {
      void testExpectedDmNarrow(String testCase) {
        final expectedNarrow = DmNarrow.withUsers([1, 2],
          selfUserId: eg.selfUser.userId);
        testExpectedNarrows([(testCase, expectedNarrow)], users: [
          eg.user(userId: 1),
          eg.user(userId: 2),
        ]);
      }

      group('on group PM link', () {
        testExpectedDmNarrow('#narrow/dm/1,2-group');
        testExpectedDmNarrow('#narrow/pm-with/1,2-group');
      });

      group('on group PM link including self', () {
        // The webapp doesn't generate these, but best to handle them anyway.
        testExpectedDmNarrow('#narrow/dm/1,2,${eg.selfUser.userId}-group');
        testExpectedDmNarrow('#narrow/pm-with/1,2,${eg.selfUser.userId}-group');
      });
    });
  });
}
