
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
  final account = eg.account(user: eg.selfUser, realmUrl: realmUrl);
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
  group('narrowLink', () {
    test('CombinedFeedNarrow', () {
      final store = eg.store();
      check(narrowLink(store, const CombinedFeedNarrow()))
        .equals(store.realmUrl.resolve('#narrow'));
      check(narrowLink(store, const CombinedFeedNarrow(), nearMessageId: 1))
        .equals(store.realmUrl.resolve('#narrow/near/1'));
    });

    test('MentionsNarrow', () {
      final store = eg.store();
      check(narrowLink(store, const MentionsNarrow()))
        .equals(store.realmUrl.resolve('#narrow/is/mentioned'));
      check(narrowLink(store, const MentionsNarrow(), nearMessageId: 1))
        .equals(store.realmUrl.resolve('#narrow/is/mentioned/near/1'));
    });

    test('StarredMessagesNarrow', () {
      final store = eg.store();
      check(narrowLink(store, const StarredMessagesNarrow()))
        .equals(store.realmUrl.resolve('#narrow/is/starred'));
      check(narrowLink(store, const StarredMessagesNarrow(), nearMessageId: 1))
        .equals(store.realmUrl.resolve('#narrow/is/starred/near/1'));
    });

    group('ChannelNarrow / TopicNarrow', () {
      void checkNarrow(String expectedFragment, {
        required int streamId,
        required String name,
        String? topic,
        int? nearMessageId,
        int? zulipFeatureLevel = eg.futureZulipFeatureLevel,
      }) async {
        assert(expectedFragment.startsWith('#'), 'wrong-looking expectedFragment');
        final store = eg.store()..connection.zulipFeatureLevel = zulipFeatureLevel;
        await store.addStream(eg.stream(streamId: streamId, name: name));
        final narrow = topic == null
          ? ChannelNarrow(streamId)
          : eg.topicNarrow(streamId, topic);
        check(narrowLink(store, narrow, nearMessageId: nearMessageId))
          .equals(store.realmUrl.resolve(expectedFragment));
      }

      test('modern including "channel" operator', () {
        checkNarrow(streamId: 1,   name: 'announce',       '#narrow/channel/1-announce');
        checkNarrow(streamId: 378, name: 'api design',     '#narrow/channel/378-api-design');
        checkNarrow(streamId: 391, name: 'Outreachy',      '#narrow/channel/391-Outreachy');
        checkNarrow(streamId: 415, name: 'chat.zulip.org', '#narrow/channel/415-chat.2Ezulip.2Eorg');
        checkNarrow(streamId: 419, name: 'français',       '#narrow/channel/419-fran.C3.A7ais');
        checkNarrow(streamId: 403, name: 'Hshs[™~}(.',     '#narrow/channel/403-Hshs.5B.E2.84.A2~.7D.28.2E');
        checkNarrow(streamId: 60,  name: 'twitter', nearMessageId: 1570686, '#narrow/channel/60-twitter/near/1570686');

        checkNarrow(streamId: 48,  name: 'mobile', topic: 'Welcome screen UI',
                    '#narrow/channel/48-mobile/topic/Welcome.20screen.20UI');
        checkNarrow(streamId: 243, name: 'mobile-team', topic: 'Podfile.lock clash #F92',
                    '#narrow/channel/243-mobile-team/topic/Podfile.2Elock.20clash.20.23F92');
        checkNarrow(streamId: 377, name: 'translation/zh_tw', topic: '翻譯 "stream"',
                    '#narrow/channel/377-translation.2Fzh_tw/topic/.E7.BF.BB.E8.AD.AF.20.22stream.22');
        checkNarrow(streamId: 42,  name: 'Outreachy 2016-2017', topic: '2017-18 Stream?', nearMessageId: 302690,
                    '#narrow/channel/42-Outreachy-2016-2017/topic/2017-18.20Stream.3F/near/302690');
      });

      test('legacy including "stream" operator', () {
        checkNarrow(streamId: 1,   name: 'announce',       zulipFeatureLevel: 249,
                    '#narrow/stream/1-announce');
        checkNarrow(streamId: 48,  name: 'mobile-team', topic: 'Welcome screen UI',
                    zulipFeatureLevel: 249,
                    '#narrow/stream/48-mobile-team/topic/Welcome.20screen.20UI');
      });
    });

    test('DmNarrow', () {
      void checkNarrow(String expectedFragment, String legacyExpectedFragment, {
        required List<int> allRecipientIds,
        required int selfUserId,
        int? nearMessageId,
      }) {
        assert(expectedFragment.startsWith('#'), 'wrong-looking expectedFragment');
        final store = eg.store();
        final narrow = DmNarrow(allRecipientIds: allRecipientIds, selfUserId: selfUserId);
        check(narrowLink(store, narrow, nearMessageId: nearMessageId))
          .equals(store.realmUrl.resolve(expectedFragment));
        store.connection.zulipFeatureLevel = 176;
        check(narrowLink(store, narrow, nearMessageId: nearMessageId))
          .equals(store.realmUrl.resolve(legacyExpectedFragment));
      }

      checkNarrow(allRecipientIds: [1], selfUserId: 1,
        '#narrow/dm/1-dm',
        '#narrow/pm-with/1-pm');
      checkNarrow(allRecipientIds: [1, 2], selfUserId: 1,
        '#narrow/dm/1,2-dm',
        '#narrow/pm-with/1,2-pm');
      checkNarrow(allRecipientIds: [1, 2, 3], selfUserId: 1,
        '#narrow/dm/1,2,3-group',
        '#narrow/pm-with/1,2,3-group');
      checkNarrow(allRecipientIds: [1, 2, 3, 4], selfUserId: 4,
        '#narrow/dm/1,2,3,4-group',
        '#narrow/pm-with/1,2,3,4-group');
      checkNarrow(allRecipientIds: [1, 2], selfUserId: 1, nearMessageId: 12345,
        '#narrow/dm/1,2-dm/near/12345',
        '#narrow/pm-with/1,2-pm/near/12345');
    });

    test('normalize links to always include a "/" after hostname', () {
      String narrowLinkFor({required String realmUrl}) {
        final store = eg.store(
          account: eg.account(user: eg.selfUser, realmUrl: Uri.parse(realmUrl)));
        return narrowLink(store, const CombinedFeedNarrow()).toString();
      }

      check(narrowLinkFor(realmUrl: 'http://chat.example.com'))
        .equals(                    'http://chat.example.com/#narrow');
      check(narrowLinkFor(realmUrl: 'http://chat.example.com/'))
        .equals(                    'http://chat.example.com/#narrow');
      check(narrowLinkFor(realmUrl: 'http://chat.example.com/path'))
        .equals(                    'http://chat.example.com/path#narrow');
      check(narrowLinkFor(realmUrl: 'http://chat.example.com/path/'))
        .equals(                    'http://chat.example.com/path/#narrow');
    });
  });

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
          final result = parseInternalLink(url, store);
          if (expected == null) {
            check(result).isNull();
          } else {
            check(result).isA<NarrowLink>()
              ..realmUrl.equals(realmUrl)
              ..narrow.equals(expected);
          }
        });
      }
    }
  }

  group('parseInternalLink is-internal', () {
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
          if (result != null) {
            check(result).realmUrl.equals(realmUrl);
          }
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
      final testCases = [
        ('/#narrow/stream/check/topic/test',                 eg.topicNarrow(1, 'test')),
        ('/#narrow/stream/mobile/subject/topic/near/378333', eg.topicNarrow(3, 'topic')),
        ('/#narrow/stream/mobile/subject/topic/with/1',      eg.topicNarrow(3, 'topic', with_: 1)),
        ('/#narrow/stream/mobile/topic/topic/',              eg.topicNarrow(3, 'topic')),
        ('/#narrow/stream/stream/topic/topic/near/1',        eg.topicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/topic/topic/with/22',       eg.topicNarrow(5, 'topic', with_: 22)),
        ('/#narrow/stream/stream/subject/topic/near/1',      eg.topicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic/with/333',    eg.topicNarrow(5, 'topic', with_: 333)),
        ('/#narrow/stream/stream/subject/topic',             eg.topicNarrow(5, 'topic')),
        ('/#narrow/stream/stream/subject/topic/with/asdf',   null), // invalid `with`
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('Both `stream` and `channel` can be used interchangeably', () {
      final testCases = [
        ('/#narrow/stream/check',                         const ChannelNarrow(1)),
        ('/#narrow/channel/check',                        const ChannelNarrow(1)),
        ('/#narrow/stream/check/topic/test',              eg.topicNarrow(1, 'test')),
        ('/#narrow/channel/check/topic/test',             eg.topicNarrow(1, 'test')),
        ('/#narrow/stream/check/topic/test/near/378333',  eg.topicNarrow(1, 'test')),
        ('/#narrow/channel/check/topic/test/near/378333', eg.topicNarrow(1, 'test')),
      ];
      testExpectedNarrows(testCases, streams: streams);
    });

    group('"/#narrow/dm/<...>" returns expected DmNarrow', () {
      final expectedNarrow = DmNarrow.withUsers([1, 2],
        selfUserId: eg.selfUser.userId);
      final testCases = [
        ('/#narrow/dm/1,2-group',                        expectedNarrow),
        ('/#narrow/dm/1,2-group/near/1',                 expectedNarrow),
        ('/#narrow/dm/1,2-group/with/2',                 null),
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
        ('/#narrow/pm-with/1,2-group/with/2',                 null),
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
            ('/#narrow/is/$operand/with/2',                              null),
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

    // TODO(#1570): test parsing /near/ operator

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
      final testCases = [
        ('/#narrow/stream/some_stream',                    const ChannelNarrow(1)),
        ('/#narrow/stream/some.20stream',                  const ChannelNarrow(2)),
        ('/#narrow/stream/some.2Estream',                  const ChannelNarrow(3)),
        ('/#narrow/stream/some_stream/topic/some_topic',   eg.topicNarrow(1, 'some_topic')),
        ('/#narrow/stream/some_stream/topic/some.20topic', eg.topicNarrow(1, 'some topic')),
        ('/#narrow/stream/some_stream/topic/some.2Etopic', eg.topicNarrow(1, 'some.topic')),
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

  group('parseInternalLink again', () { // TODO perhaps unify with tests above
    group('topic link parsing', () {
      final stream = eg.stream(name: "general");

      group('basic', () {
        String mkUrlString(String operand) {
          return '#narrow/stream/${stream.streamId}-${stream.name}/topic/$operand';
        }
        final testCases = [
          (mkUrlString('(no.20topic)'), eg.topicNarrow(stream.streamId, '(no topic)')),
          (mkUrlString('lunch'),        eg.topicNarrow(stream.streamId, 'lunch')),
        ];
        testExpectedNarrows(testCases, streams: [stream]);
      });

      group('on old topic link, with dot-encoding', () {
        String mkUrlString(String operand) {
          return '#narrow/stream/${stream.name}/topic/$operand';
        }
        final testCases = [
          (mkUrlString('(no.20topic)'), eg.topicNarrow(stream.streamId, '(no topic)')),
          (mkUrlString('google.2Ecom'), eg.topicNarrow(stream.streamId, 'google.com')),
          (mkUrlString('google.com'),   null),
          (mkUrlString('topic.20name'), eg.topicNarrow(stream.streamId, 'topic name')),
          (mkUrlString('stream'),       eg.topicNarrow(stream.streamId, 'stream')),
          (mkUrlString('topic'),        eg.topicNarrow(stream.streamId, 'topic')),
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

extension InternalLinkChecks on Subject<InternalLink> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
}

extension NarrowLinkChecks on Subject<NarrowLink> {
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
}
