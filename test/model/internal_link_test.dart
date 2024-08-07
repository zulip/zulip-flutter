
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/model/internal_link.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';

// Using Set instead of List in to avoid any duplicated test urls.
Set<String> getUrlSyntaxVariants(String urlString) {
  final urlWithChannelSyntax = urlString.replaceFirst('#narrow/stream', '#narrow/channel');
  final urlWithStreamSyntax = urlString.replaceFirst('#narrow/channel', '#narrow/stream');
  return {urlWithStreamSyntax, urlWithChannelSyntax};
}

Future<PerAccountStore> setupStore({
  required Uri realmUrl,
  List<ZulipStream>? streams,
  List<User>? users,
}) async {
  final account = eg.selfAccount.copyWith(realmUrl: realmUrl);
  final store = eg.store(account: account);
  if (streams != null) {
    await store.addStreams(streams);
  }
  await store.addUser(eg.selfUser);
  if (users != null) {
    await store.addUsers(users);
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
      for (final urlString in getUrlSyntaxVariants(urlString)) {
        final Narrow? expected = testCase.$2;
        test(urlString, () async {
          final store = await setupStore(realmUrl: realmUrl, streams: streams, users: users);
          final url = store.tryResolveUrl(urlString)!;
          check(parseInternalLink(url, store)).equals(expected);
        });
      }
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
      for (final urlString in getUrlSyntaxVariants(urlString)) {
        test('${expected ? 'accepts': 'rejects'} $description: $urlString', () async {
          final store = await setupStore(realmUrl: realmUrl, streams: streams);
          final url = store.tryResolveUrl(urlString)!;
          final result = parseInternalLink(url, store);
          check(result != null).equals(expected);
        });
      }
    }
  });

  group('parseInternalLink', () {
    final streams = [
      eg.stream(streamId: 1,   name: 'check'),
      eg.stream(streamId: 3,   name: 'mobile'),
      eg.stream(streamId: 5,   name: 'stream'),
      eg.stream(streamId: 123, name: 'topic'),
    ];

    group('"/#narrow/stream/<...>" returns expected ChannelNarrow', () {
      const testCases = [
        ('/#narrow/stream/check',   ChannelNarrow(1)),
        ('/#narrow/stream/stream/', ChannelNarrow(5)),
        ('/#narrow/stream/topic/',  ChannelNarrow(123)),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/stream/<...>/topic/<...>" returns expected TopicNarrow', () {
      const testCases = [
        ('/#narrow/stream/check/topic/test',                 TopicNarrow(1, 'test')),
        ('/#narrow/stream/mobile/subject/topic/near/378333', TopicNarrow(3, 'topic')),
        ('/#narrow/stream/mobile/subject/topic/with/1',      TopicNarrow(3, 'topic')),
        ('/#narrow/stream/mobile/topic/topic/',              TopicNarrow(3, 'topic')),
        ('/#narrow/stream/stream/topic/topic/near/1',        TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/topic/topic/with/22',       TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic/near/1',      TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic/with/333',    TopicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic',             TopicNarrow(5, 'topic')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('Both `stream` and `channel` can be used interchangeably', () {
      const testCases = [
        ('/#narrow/stream/check',                         ChannelNarrow(1)),
        ('/#narrow/channel/check',                        ChannelNarrow(1)),
        ('/#narrow/stream/check/topic/test',              TopicNarrow(1, 'test')),
        ('/#narrow/channel/check/topic/test',             TopicNarrow(1, 'test')),
        ('/#narrow/stream/check/topic/test/near/378333',  TopicNarrow(1, 'test')),
        ('/#narrow/channel/check/topic/test/near/378333', TopicNarrow(1, 'test')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/dm/<...>" returns expected DmNarrow', () {
      final expectedNarrow = DmNarrow.withUsers([1, 2],
        selfUserId: eg.selfUser.userId);
      final testCases = [
        ('/#narrow/dm/1,2-group',                        expectedNarrow),
        ('/#narrow/dm/1,2-group/near/1',                 expectedNarrow),
        ('/#narrow/dm/1,2-group/with/2',                 expectedNarrow),
        ('/#narrow/dm/a.40b.2Ecom.2Ec.2Ed.2Ecom/near/3', null),
        ('/#narrow/dm/a.40b.2Ecom.2Ec.2Ed.2Ecom/with/4', null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/pm-with/<...>" returns expected DmNarrow', () {
      final expectedNarrow = DmNarrow.withUsers([1, 2],
        selfUserId: eg.selfUser.userId);
      final testCases = [
        ('/#narrow/pm-with/1,2-group',                        expectedNarrow),
        ('/#narrow/pm-with/1,2-group/near/1',                 expectedNarrow),
        ('/#narrow/pm-with/1,2-group/with/2',                 expectedNarrow),
        ('/#narrow/pm-with/a.40b.2Ecom.2Ec.2Ed.2Ecom/near/3', null),
        ('/#narrow/pm-with/a.40b.2Ecom.2Ec.2Ed.2Ecom/with/3', null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('/#narrow/is/<...> returns corresponding narrow', () {
      // For these tests, we are more interested in the internal links
      // containing a single effective `is` operator.
      // Internal links with multiple operators should be tested separately.
      for (final operand in IsOperand.values) {
        List<(String, Narrow?)> sharedCases(Narrow? narrow) => [
            ('/#narrow/is/$operand',                                     narrow),
            ('/#narrow/is/$operand/is/$operand',                         narrow),
            ('/#narrow/is/$operand/near/1',                              narrow),
            ('/#narrow/is/$operand/with/2',                              narrow),
            ('/#narrow/channel/7-test-here/is/$operand',                 null),
            ('/#narrow/channel/check/topic/test/is/$operand',            null),
            ('/#narrow/topic/test/is/$operand',                          null),
            ('/#narrow/dm/17327-Chris-Bobbe-(Test-Account)/is/$operand', null),
            ('/#narrow/-is/$operand',                                    null),
          ];
        final List<(String, Narrow?)> testCases;
        switch (operand) {
          case IsOperand.mentioned:
            testCases = sharedCases(const MentionsNarrow());
          case IsOperand.starred:
            testCases = sharedCases(const StarredMessagesNarrow());
          case IsOperand.dm:
          case IsOperand.private:
          case IsOperand.alerted:
          case IsOperand.followed:
          case IsOperand.resolved:
          case IsOperand.unread:
          case IsOperand.unknown:
            // Unsupported operands should not return any narrow.
            testCases = sharedCases(null);
        }
        testExpectedNarrows(testCases, streams: streams);
      }
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
        ('/#narrow/stream/some_stream',                    ChannelNarrow(1)),
        ('/#narrow/stream/some.20stream',                  ChannelNarrow(2)),
        ('/#narrow/stream/some.2Estream',                  ChannelNarrow(3)),
        ('/#narrow/stream/some_stream/topic/some_topic',   TopicNarrow(1, 'some_topic')),
        ('/#narrow/stream/some_stream/topic/some.20topic', TopicNarrow(1, 'some topic')),
        ('/#narrow/stream/some_stream/topic/some.2Etopic', TopicNarrow(1, 'some.topic')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });
  });

  group('parseInternalLink edge cases', () {
    void testExpectedChannelNarrow(String testCase, int? streamId) {
      final channelNarrow = (streamId != null) ? ChannelNarrow(streamId) : null;
      testExpectedNarrows([(testCase, channelNarrow)], streams: [
        eg.stream(streamId: 1, name: "general"),
      ]);
    }

    group('basic', () {
      testExpectedChannelNarrow('#narrow/stream/1-general',         1);
    });

    group('if stream not found, use stream ID anyway', () {
      testExpectedChannelNarrow('#narrow/stream/123-topic',         123);
    });

    group('on stream link with wrong name, ID wins', () {
      testExpectedChannelNarrow('#narrow/stream/1-nonsense',        1);
      testExpectedChannelNarrow('#narrow/stream/1-',                1);
    });

    group('on malformed stream link: reject', () {
      testExpectedChannelNarrow('#narrow/stream/-1',                null);
      testExpectedChannelNarrow('#narrow/stream/1nonsense-general', null);
      testExpectedChannelNarrow('#narrow/stream/-general',          null);
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
        ('#narrow/stream/test-team/', ChannelNarrow(1)),
        ('#narrow/stream/311/',       ChannelNarrow(2)),
        ('#narrow/stream/311-/',      ChannelNarrow(3)),
        ('#narrow/stream/311-help/',  ChannelNarrow(4)),
        ('#narrow/stream/--help/',    ChannelNarrow(5)),
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
        ('#narrow/stream/311/',      ChannelNarrow(311)),
        ('#narrow/stream/311-/',     ChannelNarrow(311)),
        ('#narrow/stream/311-help/', ChannelNarrow(311)),
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
        ('#narrow/stream/check/',         ChannelNarrow(1)),
        ('#narrow/stream/bot.20testing/', ChannelNarrow(2)),
        ('#narrow/stream/check.2EAPI/',   ChannelNarrow(3)),
        ('#narrow/stream/stream/',        ChannelNarrow(4)),
        ('#narrow/stream/topic/',         ChannelNarrow(5)),

        ('#narrow/stream/check.API/',     null),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });
  });

  group('parseInternalLink', () {
    group('topic link parsing', () {
      final stream = eg.stream(name: "general");

      group('basic', () {
        String mkUrlString(String operand) {
          return '#narrow/stream/${stream.streamId}-${stream.name}/topic/$operand';
        }
        final testCases = [
          (mkUrlString('(no.20topic)'), TopicNarrow(stream.streamId, '(no topic)')),
          (mkUrlString('lunch'),        TopicNarrow(stream.streamId, 'lunch')),
        ];
        testExpectedNarrows(testCases, streams: [stream]);
      });

      group('on old topic link, with dot-encoding', () {
        String mkUrlString(String operand) {
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
