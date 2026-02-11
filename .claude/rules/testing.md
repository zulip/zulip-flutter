---
paths:
 - "test/**/*"
---

# Testing Conventions

## Test file layout

Test files live under `test/`, mirroring `lib/` structure:
- `test/api/route/` — API route binding tests
- `test/api/model/` — API model deserialization tests
- `test/model/` — tests for everything in lib/model/
- `test/widgets/` — widget tests
- `test/notifications/` — push notification tests

Companion files use naming conventions:
- `*_test.dart` — test files
- `*_checks.dart` — custom `package:checks` extensions for a domain

## Imports

**Non-widget tests** import `package:test/scaffolding.dart` (for `test`, `group`).
**Widget tests** import `package:flutter_test/flutter_test.dart` (for `testWidgets`, `WidgetTester`, etc.).

Both kinds always import `package:checks/checks.dart` for assertions.

Import `test/example_data.dart` with the alias `eg`:
```dart
import '../example_data.dart' as eg;
```

Import order follows groups separated by blank lines:
1. `dart:` stdlib imports
2. `package:` imports (alphabetical)
3. Relative imports (test helpers, checks files; alphabetical)

## Test structure

### `main()` function

Widget and model tests that need TestZulipBinding start with:
```dart
void main() {
  TestZulipBinding.ensureInitialized();
  // ...
}
```

API route tests don't need this — they use `FakeApiConnection.with_` directly.

### `group()` and `test()` naming

Descriptions are **short fragments** (not sentences), lowercase, no trailing period:
```dart
group('handleMessageEvent', () {
  test('smoke', () { ... });
  test('with starred flag', () { ... });
});
```

Tests are typically nested under 1–2 levels of groups. The top level groups by feature or method name; deeper levels group by subcategory or edge case.

### `test()` vs `testWidgets()`

Use `test()` for model tests, API tests, and anything without a widget tree.
Use `testWidgets()` only when the test pumps widgets via `WidgetTester`.

### Async

Tests are `async` when they call async functions (store methods, API calls). Tests that are purely synchronous omit `async`.

## Test data setup

### `test/example_data.dart` (the `eg` module)

All test fixtures come from builder functions in this file, accessed via the `eg` alias. Builders use optional named parameters with sensible defaults:
```dart
final stream = eg.stream(name: 'my-channel');
final message = eg.streamMessage(stream: stream, sender: eg.otherUser);
final snapshot = eg.initialSnapshot(streams: [stream]);
```

Key pre-built User objects: `eg.selfUser`, `eg.otherUser`, `eg.thirdUser`.
Key pre-built Account objects: `eg.selfAccount`, `eg.otherAccount`.

IDs are generally auto-generated with random gaps (never sequential) to avoid tests accidentally depending on specific ID values.

### Setting up stores

For model tests, use `eg.store()`:
```dart
final store = eg.store(initialSnapshot: eg.initialSnapshot(
  streams: [stream1, stream2],
  subscriptions: [eg.subscription(stream1)],
));
```

Then add data incrementally with extension helpers from `test/model/test_store.dart`:
```dart
await store.addUser(user);
await store.addStream(stream);
await store.addSubscription(eg.subscription(stream));
await store.addMessage(message);
```

These helpers internally dispatch the appropriate events to the store. Use `store.handleEvent` directly when there isn't a relevant extension helper.

### Setting up widget tests

Widget tests follow this pattern:
```dart
testWidgets('description', (tester) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  connection = store.connection as FakeApiConnection;

  // Add data to store
  await store.addStream(stream);
  // ...

  // Pump the widget
  await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
    child: MyWidget()));
  await tester.pump();
});
```

Always call `addTearDown(testBinding.reset)` in tests that use `testBinding`.

### Setup helper functions

When several tests share setup logic, extract a helper function at the group level:
```dart
group('my feature', () {
  Future<void> prepare(WidgetTester tester, {
    required List<ZulipStream> channels,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
    // ...
  }

  testWidgets('empty list', (tester) async {
    await prepare(tester, channels: []);
    // ...
  });
});
```

## Assertions with `package:checks`

All assertions use `package:checks`. Never use `expect()` or matchers.

### Basic checks
```dart
check(value).equals(expected);
check(value).isNull();
check(value).isNotNull();
check(value).isTrue();
check(list).isEmpty();
check(list).length.equals(3);
```

### Cascading property checks

Use Dart's cascade operator (`..`) to check multiple properties:
```dart
check(store).savedSnippets.values.single
  ..id.equals(102)
  ..title.equals('bar title')
  ..content.equals('bar content');
```

### Collection checks with conditions

Use `deepEquals` with `Condition<Object?>` lists for ordered collection assertions:
```dart
check(store).savedSnippets.values.deepEquals(<Condition<Object?>>[
  (it) => it.isA<SavedSnippet>().id.equals(101),
  (it) => it.isA<SavedSnippet>()..id.equals(102)
                                ..title.equals('foo title'),
]);
```

### Finder checks

For widget tests, check finders directly:
```dart
check(find.byType(MyWidget)).findsOne();
check(find.text('hello')).findsNothing();
```

### Check extensions (`*_checks.dart` files)

Custom check extensions expose typed property access via `has()`:
```dart
extension SavedSnippetChecks on Subject<SavedSnippet> {
  Subject<int> get id => has((x) => x.id, 'id');
  Subject<String> get title => has((x) => x.title, 'title');
}
```

The extension is named `{TypeName}Checks`, on `Subject<TypeName>`. Each property is a getter using `has()` with a description string matching the field name.

## API route tests

API route tests use `FakeApiConnection.with_`:
```dart
test('smoke', () {
  return FakeApiConnection.with_((connection) async {
    connection.prepare(json: SomeResult(id: 42).toJson());
    final result = await someEndpoint(connection, param: 'value');
    check(connection.takeRequests()).single.isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/some_endpoint')
      ..bodyFields.deepEquals({
        'param': 'value',
      });
    check(result).id.equals(42);
  });
});
```

Note `return FakeApiConnection.with_(...)` — the future is returned from the test, not awaited at the top level.

For testing behavior on specific server versions, pass `zulipFeatureLevel`:
```dart
FakeApiConnection.with_(zulipFeatureLevel: 247, (connection) async { ... });
```

## Model/store tests

### Event handling

Test store updates by dispatching events and checking the result:
```dart
await store.handleEvent(SavedSnippetsAddEvent(id: 1,
  savedSnippet: eg.savedSnippet(id: 102)));
check(store).savedSnippets.length.equals(2);
```

### Change notification

Track listener calls to verify notification behavior:
```dart
int notifiedCount = 0;
model.addListener(() { notifiedCount++; });

await store.handleEvent(someEvent);
check(notifiedCount).equals(1);  // was notified

await store.handleEvent(irrelevantEvent);
check(notifiedCount).equals(1);  // was NOT notified again
```

## Widget interaction testing

### Simulating user actions
```dart
await tester.tap(find.byType(MyButton));
await tester.longPress(find.text('item'));
await tester.enterText(find.byType(TextField), 'input');
await tester.pump();  // process one frame
```

Avoid tester.pumpAndSettle().

### Verifying API requests from widgets
```dart
connection.prepare(json: {});  // prepare response before the action
await tester.tap(find.text('Submit'));
await tester.pump();
check(connection.lastRequest).isA<http.Request>()
  ..method.equals('POST')
  ..url.path.equals('/api/v1/messages');
```

### Dialog assertions

Use helpers from `test/widgets/dialog_checks.dart`:
```dart
final okButton = checkErrorDialog(tester,
  expectedTitle: 'Error', expectedMessage: 'Something went wrong');
await tester.tap(find.byWidget(okButton));
await tester.pump();
checkNoDialog(tester);
```

## Formatting

- Follow the same indentation and style as the production code (no `dart format`).
- Multi-line cascade checks are indented two spaces from the `check(...)` call:
  ```dart
  check(connection.takeRequests()).single.isA<http.Request>()
    ..method.equals('POST')
    ..url.path.equals('/api/v1/messages');
  ```
- Long argument lists break with each named argument on its own line, but short calls stay on one line.
- `late` variables are used at the group level for shared state that gets assigned in setup helpers. `final` is used within test bodies for immutable test data.

## Regression tests

When a test is a regression test for a specific bug, add a comment linking to the issue:
```dart
test('unsubscribed then subscribed by events', () async {
  // Regression test for: https://github.com/zulip/zulip-flutter/issues/...
```
