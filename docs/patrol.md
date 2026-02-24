# Integration tests with Patrol

## Why and when to use Patrol

Patrol is a tool for writing integration tests of Flutter apps.
Unlike widget tests (which are the mainstay of our UI tests),
Patrol tests run on a real physical or emulated device, and
interact with the real device platform (Android or iOS).

This makes them a lot slower, and tends to make them flakier, than
the normal Flutter tests found in `test/` and run by `flutter test`.
Whenever possible, we prefer to test any given aspect of the app
in normal Flutter tests.  Patrol tests are useful for things that
normal Flutter tests can't cover, where we would otherwise resort
to manual testing.

Specifically, when we're interacting with the device platform's APIs,
or with our own Kotlin or Swift code, those aren't present in Flutter
tests.  We use either `ZulipBinding` or Flutter's own "binding"
classes to abstract them away, and to replace them in tests with fake
implementations.  This works great for most things; but when there's
enough complexity in the API, we can't be confident our fakes are
entirely accurate.  Patrol tests can exercise our code with the real
implementation from the device platform.


### Types of Patrol test

There are a few different types of Patrol tests we can write, based on
the implementation of `ZulipBinding` they use:

 * *Live* Patrol tests use `LiveZulipBinding`, the same implementation
   as the actual app.
   (Specifically they use `PatrolLiveZulipBinding`, a subclass which
   adds some convenience features.)
   This means they talk to a real Zulip server
   and store their data in a real local database file,
   as well as using the real device platform.

   This is useful where the Zulip server, too, has complexity we're
   not entirely confident of modeling in our tests.  Zulip's main
   server API has high-quality structured docs, automatically
   validated by the server's own test suite; so this applies to
   interactions outside that main API.  Examples:
   * notifications, where the server has to send a payload through the
     push bouncer and then Google's or Apple's push services;
   * web auth, where we open up a browser pointing at a URL on the
     server, and it typically redirects the user to an external auth
     provider which later redirects back.

   On the other hand, these are inconvenient because a Zulip server
   is required.

 * Some Patrol tests use `TestZulipBinding`, the same implementation
   as our normal Flutter tests.  Like all Patrol tests, though, they
   use the live `WidgetsFlutterBinding` implementation of the Flutter
   bindings.

   This is useful when the relevant aspects of the device platform
   interact through Flutter's binding classes but not `ZulipBinding`.
   Example: keyboard interactions.
   We could use Patrol to write regression tests for issues like
   [#552](https://github.com/zulip/zulip-flutter/issues/552),
   [#743](https://github.com/zulip/zulip-flutter/issues/743),
   [#591](https://github.com/zulip/zulip-flutter/issues/591),
   [#546](https://github.com/zulip/zulip-flutter/issues/546),
   [#1100](https://github.com/zulip/zulip-flutter/issues/1100),
   [#1753](https://github.com/zulip/zulip-flutter/issues/1753),
   or [#1974](https://github.com/zulip/zulip-flutter/issues/1974).

 * We could also write Patrol tests that are a hybrid: we could make a
   `ZulipBinding` implementation that takes its interactions with the
   server and perhaps the database from `TestZulipBinding`, but its
   interactions with the device platform from `LiveZulipBinding`.

   This would be useful when the Zulip server interactions are all
   through the main Zulip API as usual, but there are other relevant
   interactions that go through `ZulipBinding`.
   Example: share-to-Zulip.


### Limitations

Patrol's architecture is that the test is driven from
inside a build of the app.
(This design is described in the [Patrol 1.0 blog post][].)
This causes two notable limitations:

 * A test can't continue after quitting the app.  This is tracked as
   Patrol's [issue #1374](https://github.com/leancodepl/patrol/issues/1374).

   This means that for notifications, we can test only two of the
   three contexts for receiving a notification: when the app is in the
   foreground or the background, but not when it wasn't running.

 * There's no way to take a screenshot from within a Patrol test.
   This is tracked as Patrol's [issue #534](https://github.com/leancodepl/patrol/issues/534).

   (In principle this might be solvable with the inside-the-app
   architecture.  A previous version of Patrol with a different
   architecture had this feature, though, as seen in the thread;
   as the syntax `tester.host.takeScreenshot(…)` indicates, it
   involved code running on the host machine, outside the device.
   See also their [issue #584](https://github.com/leancodepl/patrol/issues/584).)

[Patrol 1.0 blog post]: https://leancode.co/blog/patrol-1-0-powerful-flutter-ui-testing-framework


## Writing tests

See various upstream guide-level docs:
https://patrol.leancode.co/documentation/write-your-first-test
https://patrol.leancode.co/feature-guide
https://patrol.leancode.co/articles

and the upstream API docs:
https://pub.dev/documentation/patrol/latest/patrol/
https://pub.dev/documentation/patrol_finders/latest/patrol_finders/


## Running tests

### Running a test you're writing or editing

Normal usage when writing tests:
```
$ patrol develop -t patrol_test/example_test.dart
```

You'll need either an emulator or physical device running.

This will build the app, install it on the device, and run the
tests from the given file on it.
Then it will pause; you can edit the code, then hit `r` to
rerun the tests using Flutter hot restart.
This saves a lot of time compared to a fresh `patrol test`,
which rebuilds the whole app from scratch.

Upstream docs: https://patrol.leancode.co/cli-commands


### Running tests in batch

To run more tests, but without the convenience of hot restart:
```
$ patrol test
```

This command also accepts `-t` to target specific test files,
but by default it runs all our Patrol tests.

Upstream docs: https://patrol.leancode.co/cli-commands/test


### Tip: specify the device

By default `patrol develop` and `patrol test` will prompt
to ask which device to use.
You may find it convenient to tell it up front on the command line,
with `-d`.  For example:
```
$ patrol develop -d emulator-5554 -t patrol_test/example_test.dart
```


### Be aware the app will get uninstalled

Both `patrol develop` and `patrol test` will uninstall the app
in order to then install the test app.
This may be inconvenient if using a device where you also actually
use the app, because it will lose your accounts and settings.
TODO: use a different app ID for Patrol vs. the app.


## Troubleshooting

### When app was already installed

There seems to be a bug in the `patrol` tool with the following
symptom: you try running `patrol develop`; it spends some time
building; and then before actually running any tests, it aborts
with the message `App shut down on request`.

One cause of this symptom occurs when an old copy of the app had been
installed (e.g. by a previous Patrol run), and Patrol uninstalled it.
There seems to be a race where the uninstall happens out of order
relative to Patrol starting the app for testing.

To work around the issue, uninstall the app explicitly before starting
Patrol.  For example:
```
$ adb uninstall com.zulipmobile; patrol develop -t patrol_test/example_test.dart
```


### Later tests may or may not share state from previous

The documented, normal behavior of `patrol test` or `patrol develop`
is that it installs the app once and then runs all the test cases.
This means that any state left behind by early tests will remain as
later tests are running.

As a result, each test should generally clean up any state it touches,
just like in our normal Flutter tests.

Conversely, it may sometimes be convenient to exploit this behavior
by having an early test case leave behind some state that a later test
will make use of.
Unfortunately for that approach, this behavior seems to be
inconsistent: sometimes `patrol test` instead
[uninstalls and reinstalls][] the app between test cases.
It's not clear just what circumstances that happens in.
It's therefore best to avoid relying on any shared state:
instead, if the setup in an early test is useful for later tests,
pull it out into a helper function, invoke that function from each
test that needs it, and have each test clean up its state as usual.

[uninstalls and reinstalls]: https://github.com/zulip/zulip-flutter/pull/2171#discussion_r2853854928


### Need to specify iOS version

When running on iOS, the test might fail to start with the output
looking like this:
```
• Running app with entrypoint test_bundle.dart for iOS simulator on simulator iPhone 15 Pro Max...
Hot Restart: logs connected
[WARN] Hot Restart: not attached to the app yet
✓ App shut down on request (3.4s)
```

One cause of this symptom is an issue where the `patrol` tool defaults
to telling `xcodebuild` it must run on the iOS version "latest".
This is true even when you specify a particular device with `-d`,
and that device has some other iOS version which isn't the latest;
and in that case, `xcodebuild` will fail.

(The detailed `xcodebuild` command and error output can be seen by
adding `--verbose` to the Patrol command.)

To deal with the issue, add an argument like `--ios=17.0` to your
`patrol develop` or `patrol test` command, with whatever iOS version
is on the device you're using.


### iOS: "isn't a member of the specified test plan or scheme"

When running on iOS, the test might fail to start with the output
ending like this (with `--verbose`):
```
Hot Restart: logs connected
[WARN] Hot Restart: not attached to the app yet
	Showing iPhone 15 Pro Max logs:
	xcodebuild: error: Failed to build workspace Runner with scheme Runner.: Tests in the target “RunnerUITests” can’t be run because “RunnerUITests” isn’t a member of the specified test plan or scheme.
✓ App shut down on request (2.5s)
```

The cause of this appears to be that there are two `*.xctestrun`
files lying around, one of which is near empty, and the wrong one
gets used:
```
$ ls -Al build/ios_integ/Build/Products/
total 8
drwxr-xr-x 42 greg staff 1344 Feb 23 12:12 Debug-iphonesimulator/
-rw-r--r--  1 greg staff 3944 Feb 23 12:16 Runner_iphonesimulator18.2-arm64-x86_64.xctestrun
-rw-r--r--  1 greg staff  443 Feb 23 11:49 Runner_iphonesimulator18.2.xctestrun
```

As a workaround, deleting `build/ios_integ/` and rerunning seems to
work.  (Likely deleting just the one file would suffice.)


## One-time setup

### Patrol

Upstream docs: https://patrol.leancode.co/documentation

1. Install the `patrol` CLI tool:

   ```
   $ flutter pub global activate patrol_cli
   ```

2. Verify success:

   ```
   $ patrol doctor
   ```

   (If it complains `ANDROID_HOME` is unset, that seems to be harmless.
   Similarly if it complains `ideviceinstaller` is not found.)


### Live login credentials

In order to run the tests in `patrol_test/live/`, create a
file `.patrol.env` at the root of the project tree, like so:
```
REALM_URL=https://chat.example.com
EMAIL=user@example.com
PASSWORD=hunter2
OTHER_EMAIL=other.user@example.com
OTHER_API_KEY=asdf1234
```

with the realm URL of some real Zulip server, and credentials for
two different test accounts there.  (The second account is used for
sending messages to the first account, to cause notifications.)

The tests will log into those real accounts and interact there.
Avoid using chat.zulip.org or any other realm that people use
for real human conversations;
instead use a Zulip development server, or a test realm.
