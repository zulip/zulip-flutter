# Zulip Flutter (prototype)

A Zulip client for Android and iOS, using Flutter.

This is a prototype, currently [in alpha][].
When it's ready, it [will become the new][] official mobile Zulip client.
To see what work is planned before that launch,
see the [milestones][] and the [project board][].

[in alpha]: https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/zulip-flutter.20releases/near/1626608
[will become the new]: https://chat.zulip.org/#narrow/stream/2-general/topic/Flutter/near/1582367
[milestones]: https://github.com/zulip/zulip-flutter/milestones?direction=asc&sort=title
[project board]: https://github.com/orgs/zulip/projects/5/views/4


## Using Zulip

To use Zulip on iOS or Android, install the [official mobile Zulip client][].

[official mobile Zulip client]: https://github.com/zulip/zulip-mobile#readme


## Getting started in developing this prototype

### Setting up

1. Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install)
   for your platform of choice.
2. Switch to the latest version of Flutter by running `flutter channel main`
   and `flutter upgrade` (see [Flutter version](#flutter-version) below).
3. Ensure Flutter is correctly configured by running `flutter doctor`.
4. Start the app with `flutter run`, or from your IDE.


### Flutter help

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
Specific resources include:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)


### Flutter version

While in the prototype phase, we use the latest Flutter from Flutter's
main branch.  Use `flutter channel main` and `flutter upgrade`.

We don't pin a specific version, because Flutter itself doesn't offer
a way to do so.  So far that hasn't been a problem.  When it becomes one,
we'll figure it out; there are several tools for this in the Flutter
community.  See [issue #15][].

[issue #15]: https://github.com/zulip/zulip-flutter/issues/15


### Tests

You can run all our forms of tests with the `tools/check` script:

```
$ tools/check
```

See `tools/check --help` for more information.

The two major test suites are the Dart analyzer, which performs
type-checking and linting; and our unit tests, located in the `test/`
directory.

You can run these suites directly with the commands `flutter analyze`
and `flutter test` respectively.  Both commands accept a list of file
or directory paths to operate on, and other options.  Particularly
recommended is a command like
```
$ flutter test test/foo/bar_test.dart --name 'baz'
```
which will run only the tests in `test/foo/bar_test.dart`,
and within those only the tests with names matching `baz`.

When editing in an IDE, the IDE should give you the exact same feedback
as `flutter analyze` would.  When editing a test file, the IDE can also
run individual tests for you.
See [upstream docs on `flutter test`][flutter-cookbook-unit-tests].

[flutter-cookbook-unit-tests]: https://docs.flutter.dev/cookbook/testing/unit/introduction


## Notes

### Writing tests

For unit tests, we use [the `checks` package][package-checks].
This is a new package from the Dart team, currently in preview,
which is [intended to replace][package-checks-migration] the
old `matcher` package.

This means that if you see example test code elsewhere that
uses the `expect` function, we'd prefer to translate it into
something in terms of `check`.  For help with that,
see the [`package:checks` migration guide][package-checks-migration]
and the package's [API docs][package-checks-api].

Because `package:checks` is still in preview, the Dart team is
open to feedback on the API to a degree that they won't be
after it reaches 1.0.  So where we find rough edges, now is a
good time to [report them as issues][dart-test-tracker].

[package-checks]: https://pub.dev/packages/checks
[package-checks-api]: https://pub.dev/documentation/checks/latest/checks/checks-library.html
[package-checks-migration]: https://github.com/dart-lang/test/blob/master/pkgs/checks/doc/migrating_from_matcher.md
[dart-test-tracker]: https://github.com/dart-lang/test/issues


### Editing API types

We support Zulip Server 4.0 and later.  For API features added in
newer versions, use `TODO(server-N)` comments (like those you see
in the existing code.)

When editing the files in `lib/api/model/`, use the following command
to keep the generated files up to date:
```
$ dart run build_runner watch --delete-conflicting-outputs
```

In our API types, constructors should generally avoid default values for
their parameters, even `null`.  This means writing e.g. `required this.foo`
rather than just `this.foo`, even when `foo` is nullable.
This is because it's common in the Zulip API for a null or missing value
to be quite salient in meaning, and not a boring value appropriate for a
default, so that it's best to ensure callers make an explicit choice.
If passing explicit values in tests is cumbersome, a factory function
in `test/example_data.dart` is an appropriate way to share defaults.


### Upgrading Flutter

We regularly increment our lower bounds on Flutter and Dart versions,
to make sure there's not too much divergence in the versions people
are using.

When there's a new beta (which happens a couple of times per month),
that's a good prompt to do this.  We also do this when there's a
new PR merged that we particularly want to take.

To update the version bounds:
* Use `flutter upgrade` to upgrade your local Flutter and Dart.
* Update the lower bounds at `environment` in `pubspec.yaml`
  to the new versions, as seen in `flutter --version`.
* Run `flutter pub get`, which will update `pubspec.lock`.
* Make a quick check that things work: `tools/check`,
  and do a quick smoke-test of the app.
* Commit and push the changes in `pubspec.yaml` and `pubspec.lock`.


### Upgrading dependencies

When adding or upgrading dependencies, try to keep our generated files
updated atomically with them.

In particular the files `ios/Podfile.lock` and `macos/Podfile.lock`
frequently need an update when dependencies change.
To update those, run (on a Mac) the commands
`flutter build ios --config-only && flutter build macos --config-only`.

(Ideally we would validate these automatically in CI: [#329][].
Several other kinds of generated files are already validated in CI.)

[#329]: https://github.com/zulip/zulip-flutter/issues/329


### Translations and i18n

When adding new strings in the UI, we set them up to be translated.
For details on how to do this, see the [translation doc](docs/translation.md).


## License

Copyright (c) 2022 Kandra Labs, Inc., and contributors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

The software includes some works released by third parties under other
free and open source licenses. Those works are redistributed under the
license terms under which the works were received.
