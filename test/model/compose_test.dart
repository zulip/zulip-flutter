import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/compose.dart';

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
@_**Full Name|123** [said](${eg.selfAccount.realmUrl}#narrow/stream/1-test-here/topic/some.20topic/near/${message.id}): *(loading message ${message.id})*
''');

    check(quoteAndReply(store, message: message, rawContent: 'Hello world!')).equals('''
@_**Full Name|123** [said](${eg.selfAccount.realmUrl}#narrow/stream/1-test-here/topic/some.20topic/near/${message.id}):
```quote
Hello world!
```
''');
  });
}
