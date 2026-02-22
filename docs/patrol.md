# Integration tests with Patrol

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

   (If it complains `ANDROID_HOME` is unset, that seems to be harmless.)


### Live login credentials

In order to run the tests in `patrol_test/live_test.dart`, create a
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
