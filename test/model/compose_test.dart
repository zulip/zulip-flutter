import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/internal_link.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';

void main() {
  group('wrapWithBacktickFence', () {
    /// Check `wrapWithBacktickFence` on example input and expected output.
    ///
    /// The intended input (content passed to `wrapWithBacktickFence`)
    /// is straightforward to infer from `expected`.
    /// To do that, this helper takes `expected` and removes the opening and
    /// closing fences.
    ///
    /// Then we have the input to the test, as well as the expected output.
    void checkFenceWrap(String expected, {String? infoString, bool chopNewline = false}) {
      final re = RegExp(r'^.*?\n(.*\n|).*\n$', dotAll: true);
      String content = re.firstMatch(expected)![1]!;
      if (chopNewline) content = content.substring(0, content.length - 1);
      check(wrapWithBacktickFence(content: content, infoString: infoString)).equals(expected);
    }

    test('empty content', () {
      checkFenceWrap('''
```
```
''');
    });

    test('content consisting of blank lines', () {
      checkFenceWrap('''
```



```
''');
    });

    test('single line with no code blocks', () {
      checkFenceWrap('''
```
hello world
```
''');
    });

    test('multiple lines with no code blocks', () {
      checkFenceWrap('''
```
hello
world
```
''');
    });

    test('no code blocks; incomplete final line', () {
      checkFenceWrap(chopNewline: true, '''
```
hello
world
```
''');
    });

    test('three-backtick block', () {
      checkFenceWrap('''
````
hello
```
code
```
world
````
''');
    });

    test('multiple three-backtick blocks; one has info string', () {
      checkFenceWrap('''
````
hello
```
code
```
world
```javascript
// more code
```
````
''');
    });

    test('whitespace around info string', () {
      const infoString = ' javascript ';
      checkFenceWrap('''
````
```$infoString
// hello world
```
````
''');
    });

    test('four-backtick block', () {
      checkFenceWrap('''
`````
````
hello world
````
`````
''');
    });

    test('five-backtick block', () {
      checkFenceWrap('''
``````
`````
hello world
`````
``````
''');
    });

    test('five-backtick block; incomplete final line', () {
      checkFenceWrap(chopNewline: true, '''
``````
`````
hello world
`````
``````
''');
    });

    test('three-, four-, and five-backtick blocks', () {
      checkFenceWrap('''
``````
```
hello world
```

````
hello world
````

`````
hello world
`````
``````
''');
    });

    test('dangling opening fence', () {
      checkFenceWrap('''
`````
````javascript
// hello world
`````
''');
    });

    test('code blocks marked by indentation or tilde fences don\'t affect result', () {
      checkFenceWrap('''
```
    // hello world

~~~~~~
code
~~~~~~
```
''');
    });

    test('backtick fences may be indented up to three spaces', () {
      checkFenceWrap('''
````
 ```
````
''');
      checkFenceWrap('''
````
  ```
````
''');
      checkFenceWrap('''
````
   ```
````
''');
      // but at 4 spaces of indentation it no longer counts:
      checkFenceWrap('''
```
    ```
```
''');
    });

    test('fence ignored if info string has backtick', () {
      checkFenceWrap('''
```
```java`script
hello
```
''');
    });

    test('with info string', () {
      checkFenceWrap(infoString: 'info', '''
`````info
```
hello
```
info
````python
hello
````
`````
''');
    });
  });

  group('narrowLink', () {
    test('CombinedFeedNarrow', () {
      final store = eg.store();
      check(narrowLink(store, const CombinedFeedNarrow()))
        .equals(store.realmUrl.resolve('#narrow'));
      check(narrowLink(store, const CombinedFeedNarrow(), nearMessageId: 1))
        .equals(store.realmUrl.resolve('#narrow/near/1'));
    });

    test('StreamNarrow / TopicNarrow', () {
      void checkNarrow(String expectedFragment, {
        required int streamId,
        required String name,
        String? topic,
        int? nearMessageId,
      }) async {
        assert(expectedFragment.startsWith('#'), 'wrong-looking expectedFragment');
        final store = eg.store();
        await store.addStream(eg.stream(streamId: streamId, name: name));
        final narrow = topic == null
          ? StreamNarrow(streamId)
          : TopicNarrow(streamId, topic);
        check(narrowLink(store, narrow, nearMessageId: nearMessageId))
          .equals(store.realmUrl.resolve(expectedFragment));
      }

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

    // TODO other Narrow subclasses as we add them:
    //   starred, mentioned; searches; arbitrary
  });

  group('mention', () {
    final user = eg.user(userId: 123, fullName: 'Full Name');
    test('not silent', () {
      check(mention(user, silent: false)).equals('@**Full Name|123**');
    });
    test('silent', () {
      check(mention(user, silent: true)).equals('@_**Full Name|123**');
    });
    test('`users` passed; has two users with same fullName', () async {
      final store = eg.store();
      await store.addUsers([user, eg.user(userId: 5), eg.user(userId: 234, fullName: user.fullName)]);
      check(mention(user, silent: true, users: store.users)).equals('@_**Full Name|123**');
    });
    test('`users` passed; has two same-name users but one of them is deactivated', () async {
      final store = eg.store();
      await store.addUsers([user, eg.user(userId: 5), eg.user(userId: 234, fullName: user.fullName, isActive: false)]);
      check(mention(user, silent: true, users: store.users)).equals('@_**Full Name|123**');
    });
    test('`users` passed; user has unique fullName', () async {
      final store = eg.store();
      await store.addUsers([user, eg.user(userId: 234, fullName: 'Another Name')]);
      check(mention(user, silent: true, users: store.users)).equals('@_**Full Name**');
    });
  });

  test('inlineLink', () {
    check(inlineLink('CZO', Uri.parse('https://chat.zulip.org/'))).equals('[CZO](https://chat.zulip.org/)');
    check(inlineLink('Uploading file.txt…', null)).equals('[Uploading file.txt…]()');
    check(inlineLink('IMG_2488.png', Uri.parse('/user_uploads/2/a3/ucEMyjxk90mcNF0y9rmW5XKO/IMG_2488.png')))
      .equals('[IMG_2488.png](/user_uploads/2/a3/ucEMyjxk90mcNF0y9rmW5XKO/IMG_2488.png)');
  });

  test('quoteAndReply / quoteAndReplyPlaceholder', () async {
    final sender = eg.user(userId: 123, fullName: 'Full Name');
    final stream = eg.stream(streamId: 1, name: 'test here');
    final message = eg.streamMessage(sender: sender, stream: stream, topic: 'some topic');
    final store = eg.store();
    await store.addStream(stream);
    await store.addUser(sender);

    check(quoteAndReplyPlaceholder(store, message: message)).equals('''
@_**Full Name|123** [said](${eg.selfAccount.realmUrl}#narrow/channel/1-test-here/topic/some.20topic/near/${message.id}): *(loading message ${message.id})*
''');

    check(quoteAndReply(store, message: message, rawContent: 'Hello world!')).equals('''
@_**Full Name|123** [said](${eg.selfAccount.realmUrl}#narrow/channel/1-test-here/topic/some.20topic/near/${message.id}):
```quote
Hello world!
```
''');
  });
}
