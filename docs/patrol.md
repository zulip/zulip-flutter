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


### Refinements

By default `patrol develop` and `patrol test` will prompt
to ask which device to use.
You may find it convenient to tell it up front on the command line,
with `-d`.  For example:
```
$ patrol develop -d emulator-5554 -t patrol_test/example_test.dart
```

Both `patrol develop` and `patrol test` will uninstall the app
in order to then install the test app.
This may be inconvenient if using a device where you also actually
use the app, because it will lose your accounts and settings.
TODO: use a different app ID for Patrol vs. the app.


## One-time setup

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
