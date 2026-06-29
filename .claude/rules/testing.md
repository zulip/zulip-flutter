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

Tests belong in the file corresponding to where the **logic** lives,
not where the call site or trigger is.
For example, for logic that lives in `push_key.dart` but is triggered
from `push_device.dart`, the tests go in `push_key_test.dart`.


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

Descriptions are **short fragments** (not sentences), lowercase, no trailing period.
Use bare imperative verbs, not third-person: "generate key", not "generates key".
For negative cases, use "no" prefix: "no delete non-superseded keys", "no re-mark already-superseded keys".
Example:
```dart
group('generate new key', () {
  test('generate key when no keys exist', () { ... });
  test('generate key when latest is old enough', () { ... });
  test('no new key when latest is recent', () { ... });
});
```

Tests are typically nested under 1–2 levels of groups.
The top level groups by feature or method name;
deeper levels group by subcategory or edge case.


### `test()` vs `testWidgets()`

Use `test()` for model tests, API tests, and anything without a widget tree.
Use `testWidgets()` only when the test pumps widgets via `WidgetTester`.


### Async

Tests are `async` when they call async functions (store methods, API calls).
Tests that are purely synchronous omit `async`.


## Test data setup

### `test/example_data.dart` (the `eg` module)

All test fixtures come from builder functions in this file,
accessed via the `eg` alias.
Builders use optional named parameters with sensible defaults:

```dart
final stream = eg.stream(name: 'my-channel');
final message = eg.streamMessage(stream: stream, sender: eg.otherUser);
final snapshot = eg.initialSnapshot(streams: [stream]);
```

Key pre-built User objects: `eg.selfUser`, `eg.otherUser`, `eg.thirdUser`.
Key pre-built Account objects: `eg.selfAccount`, `eg.otherAccount`.
These are just pre-made calls to `eg.user()` and `eg.account()`.

IDs are generally auto-generated with distinct values
on each call to a builder function.
So for example `eg.account(user: eg.selfUser)` will have a different
account ID from `eg.selfAccount`.

The auto-generated IDs are random but increasing.
So e.g. three calls to `eg.dmMessage` will have increasing message IDs,
just like three real messages sent in that order.

When there isn't already a suitable builder function in
`test/example_data.dart`, add one.
Make as many of the function's parameters optional as possible,
choosing defaults that are boring and representative so that
tests that aren't about any given field don't need to
say anything about it that field.


### Setting up a store

In model tests, create a fresh per-account store with `eg.store()`:
```dart
final store = eg.store(initialSnapshot: eg.initialSnapshot(
  streams: [stream1, stream2],
  subscriptions: [eg.subscription(stream1)],
));
```

When control over the global store is needed,
create one with `eg.globalStore()`.
Then use `TestGlobalStore.add` to set up a per-account store there,
and `GlobalStore.perAccount` to retrieve it:
```dart
  final globalStore = eg.globalStore(accounts: [eg.selfAccount]);
  await globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
  final store = await globalStore.perAccount(eg.selfAccount.id);
```

In widget tests, use `testBinding.globalStore` to access
the same global store that widgets will see,
and create per-account stores there:
```dart
testWidgets('description', (tester) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
```
Always call `addTearDown(testBinding.reset)` in tests that use `testBinding`.


### Adding data to a store

After creating a per-account store, add data incrementally
with extension helpers from `test/model/test_store.dart`:
```dart
await store.addUser(user);
await store.addStream(stream);
await store.addSubscription(eg.subscription(stream));
await store.addMessage(message);
```

These helpers internally dispatch the appropriate events to the store.
Use `store.handleEvent` directly when there isn't a relevant extension helper.


### API requests

When tests need to prepare API responses or inspect requests,
use `connection.prepare()` and `connection.takeRequests()`,
which are methods on `FakeApiConnection`:

```dart
connection.prepare(json: someResult.toJson());
// ... trigger action that makes API call ...
check(connection.takeRequests()).single.isA<http.Request>()
  ..method.equals('POST')
  ..url.path.equals('/api/v1/some_endpoint');
```

The `connection.prepare` method takes other options too.
To make the request fail, pass `httpException` or `apiException`
instead of `json`.
To make the request take time to finish, pass `delay`, and then use
either `awaitFakeAsync` or `testWidgets` to manipulate time.


### Setting up widget tests

Widget tests follow this pattern:
```dart
testWidgets('description', (tester) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  final connection = store.connection as FakeApiConnection;

  // Add data to store
  await store.addStream(stream);
  // ...

  // Pump the widget
  await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
    child: MyWidget()));
  await tester.pump();
});
```


### Setup helper functions

When several tests share setup logic,
extract a helper function at the group level or top level.

Often this helper will set `late` variables to share the
`PerAccountStore`, `FakeApiConnection`, and sometimes other data,
for the test cases to access.  For example:

```dart
group('my feature', () {
  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<void> prepare(WidgetTester tester, {
    required List<ZulipStream> channels,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(...));
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;
    // ...
  }

  testWidgets('empty list', (tester) async {
    await prepare(tester, channels: []); // set up data
    await store.handleEvent(...); // now use the store
    connection.prepare(...); // and use the connection
    // ...
  });
});
```

If every test calls a setup helper then immediately does
the same follow-up step (e.g., `async.flushMicrotasks()`),
fold that step into the helper.

For a local helper function, keep the doc comment very short or leave it out.
Don't document every parameter when names are self-explanatory.


### Local fixture helpers

When many tests in a group or a file create similar fixtures
varying only a few fields, extract a local helper:
```dart
PushKey mkKey(int createdTimestamp, {int? supersededTimestamp}) {
  return eg.pushKey(
    account: eg.selfAccount,
    createdTimestamp: createdTimestamp,
    supersededTimestamp: supersededTimestamp,
  );
}
```

Even if a given type of data appears only once,
determine whether it has more than two or three fields
containing boring data
(data where the details aren't relevant to understanding the test).
If it does, then factor it out to a helper.

This keeps test bodies focused on just the data that's important.


### Controlling time and async with `awaitFakeAsync`

When testing non-widgets code that uses any of the following:
* timers;
* time-based logic;
* asynchronous tasks which are unawaited in the code
  (so a caller can't simply `await` to wait for them to finish);

then wrap the test in `awaitFakeAsync`.
Keep it on the same line as `test(`:
```dart
test('register on startup', () => awaitFakeAsync((async) async {
  prepareStore();
  connection.prepare(json: {});
  await model.debugUnpauseRegisterToken();
  async.flushMicrotasks();
  check(connection.takeRequests()).single.isA<http.Request>();
}));
```

Call `async.flushMicrotasks()` to process pending asynchronous tasks
that aren't waiting for any time to pass,
or `async.elapse(duration)` to advance the fake clock and run timers.

Widgets tests don't need `awaitFakeAsync`
because `testWidgets` already provides fake async.
In widgets tests, use `tester.pump` instead of `flushMicrotasks` or `elapse`.

When the steps in the code can happen in different orders
depending on external factors like how long an API request takes,
the code's tests should make sure to exercise different orderings.
For example, to control when an API request finishes in a test,
use `connection.prepare(delay: Duration(...), ...)`.


## Assertions with `package:checks`

All assertions use `package:checks`.
Never use `expect()`.


### Basic checks
```dart
check(value).equals(expected);
check(value).isNull();
check(value).isNotNull();
check(value).isTrue();
check(list).isEmpty();
check(list).length.equals(3);
```


### Non-null checks

Keep non-null checks simple.

When you know the value is non-null and that's
not the point of the test, use `!` (inside the parens):
`check(value!).isNotEmpty();`.

When the null check is part of what the test is testing,
use `isNotNull`:
`check(value).isNotNull().isNotEmpty();`.

Don't use `isA<T>()` for just a null check.


### Cascading property checks

Use Dart's cascade operator (`..`) to check multiple properties:
```dart
check(store).savedSnippets.values.single
  ..id.equals(102)
  ..title.equals('bar title')
  ..content.equals('bar content');
```


### Collection checks with conditions

Use `deepEquals` with a `Condition<Object?>` list for
checking details of each element in a list or other iterable:
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


### Checks-extensions (`*_checks.dart` files)

Custom checks-extensions expose typed property access via `has()`:
```dart
extension SavedSnippetChecks on Subject<SavedSnippet> {
  Subject<int> get id => has((x) => x.id, 'id');
  Subject<String> get title => has((x) => x.title, 'title');
}
```

The extension is named `{TypeName}Checks`, on `Subject<TypeName>`.
Each property is a getter using `has()` with a name string matching the field name.

Whenever a checks-extension doesn't yet exist, go ahead and add it.


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

Note `return FakeApiConnection.with_(...)` — the future is
returned from the test, not awaited at the top level.

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

When testing a substore which is a ChangeNotifier,
be sure to test the notification behavior:
listeners are notified when they should be,
and not when they shouldn't.

For writing such a test, use the `checkNotified` pattern.
See the helpers named `checkNotified` and `checkNotNotified`
in existing test files.


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

After a gesture like `tester.tap`, use `tester.pump`
to give the widget a chance to handle the gesture:
```dart
connection.prepare(json: {});  // prepare response before the action
await tester.tap(find.text('Submit'));
await tester.pump();
check(connection.takeRequests()).isA<http.Request>()
  // ...
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

- Long argument lists break with each named argument on its own line,
  but short calls stay on one line.

- Place checks immediately after the action that sets up
  the situation they check — no blank lines in between:
  ```dart
  initStore(async, pushKeys: [oldKey, newKey],
    ackedPushKeyId: newKey.pushKeyId);
  check(getPushKeyById(oldKey.pushKeyId)!).supersededTimestamp.equals(now);
  ```


## Writing tests for a given piece of code

- **Study existing tests first.** Before writing tests, read how
  nearby existing tests exercise the same or similar code.
  Understand the entry points, test file organization, and helper
  patterns before writing any test code.

- **Test through the normal entry points, not internal methods.**
  Except for getters and read-only methods,
  most methods on substores are internal implementation details;
  the external interface is to create a store and handle events.
  Even when testing a substore mutator method like `handleFooEvent`,
  don't call it directly;
  stick to `eg.initialSnapshot` and `store.handleEvent`.

- **When writing tests for a change, verify they actually test it.**
  After writing tests for a commit, check: would these tests fail if
  the commit's changes were reverted?
  If not, the tests don't cover the commit.

- **When a test is specifically about some property, pass it explicitly**
  even if it matches the default — this documents the test's intent.

- **Don't write redundant tests.** One boundary test is enough — don't also
  add a "well within the range" test that covers the same code path.
  Don't write "all steps together" integration tests when each step
  is already individually tested,
  unless the steps interact with each other
  (in which case test the specific interaction).

- **Use realistic values.** Time offsets and other data in tests
  should reflect realistic scenarios, not arbitrary small numbers.

- Avoid a name that's just a number, like `thirtyDays`.
  Instead, define a meaningful constant like `const secondsPerDay = 86400`
  and write `30 * secondsPerDay`.

- **Only include relevant setup.** Don't add teardowns, debug flags, or
  other setup that isn't needed for the logic being tested.


## Regression tests

When a test is a regression test for a specific bug,
add a comment linking to the issue:
```dart
test('unsubscribed then subscribed by events', () async {
  // Regression test for: https://github.com/zulip/zulip-flutter/issues/...
```
