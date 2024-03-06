# Zulip Flutter (beta)

A Zulip client for Android and iOS, using Flutter.

This app is currently [in beta][beta].
When it's ready, it [will become the new][] official mobile Zulip client.
To see what work is planned before that launch,
see the [milestones][] and the [project board][].

[beta]: https://chat.zulip.org/#narrow/stream/2-general/topic/Flutter/near/1708728
[will become the new]: https://chat.zulip.org/#narrow/stream/2-general/topic/Flutter/near/1582367
[milestones]: https://github.com/zulip/zulip-flutter/milestones?direction=asc&sort=title
[project board]: https://github.com/orgs/zulip/projects/5/views/4


## Using Zulip

To use Zulip on iOS or Android, install the [official mobile Zulip client][].

You can also [try out this beta app][beta].

[official mobile Zulip client]: https://github.com/zulip/zulip-mobile#readme


## Contributing

Contributions to this app are welcome.

If you're looking to participate in Google Summer of Code with Zulip,
this is one of the projects we're [accepting GSoC 2024 applications][]
for.

[accepting GSoC 2024 applications]: https://zulip.readthedocs.io/en/latest/outreach/gsoc.html#mobile-app


### Picking an issue to work on

First, see the Zulip project guide to [your first codebase contribution][].
Follow the instructions there for joining the Zulip community server,
reading about [what makes a great Zulip contributor][],
browsing through recent commits and the codebase,
and the Zulip guide to Git.

To find possible issues to work on, see our [project board][].
Look for issues up through the "Launch" milestone,
and that aren't already assigned.

Follow the Zulip guide to [picking an issue to work on][],
trying several issues until you find one you're confident
you'll be able to take on effectively.

*After you've done that*, claim the issue by posting a comment
on the issue thread, saying you'd like to work on it
and describing your progress.

[your first codebase contribution]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#your-first-codebase-contribution
[what makes a great Zulip contributor]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#what-makes-a-great-zulip-contributor
[picking an issue to work on]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#picking-an-issue-to-work-on


### Submitting a pull request

Follow the Zulip project's guide to your first codebase contribution
for [working on an issue][] and [submitting a pull request][].
It's important to take the time to make your work as
easy as possible for others to review.

Two specific points to expand on:

 * Before we can review your PR in detail, your changes will need
   tests.  See ["Writing tests"](#writing-tests) below.

   It will also need all new and existing tests to be passing.
   See ["Tests"](#tests) below about running the tests.

 * Your changes will need to be organized into
   [clear and coherent commits][commit-style],
   following [Zulip's commit style guide][commit-style].

   This is always required before we can merge your PR.  Depending on
   your changes' complexity, it may also be required before we can
   review it in detail.  (The main exception is that if the change
   should be a single commit, we can review it even with a messier
   commit structure.)

[working on an issue]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#working-on-an-issue
[submitting a pull request]: https://zulip.readthedocs.io/en/latest/contributing/review-process.html
[commit-style]: https://zulip.readthedocs.io/en/latest/contributing/commit-discipline.html


## Getting started in developing this beta app

### Setting up

1. Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install)
   for your platform of choice.
2. Switch to the latest version of Flutter by running `flutter channel main`
   and `flutter upgrade` (see [Flutter version](#flutter-version) below).
3. Ensure Flutter is correctly configured by running `flutter doctor`.
4. Start the app with `flutter run`, or from your IDE.


### Flutter version

While in the beta phase, we use the latest Flutter from Flutter's
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

We write tests for all changes to the Dart code in the app.
Because Flutter and Dart have excellent facilities for testing,
we're able to efficiently write tests even for kinds of code
that often go untested: UI code, and code that makes network
requests or calls external APIs.

You may sometimes find code that doesn't have tests.
This is generally code from the early prototype phase;
when we make changes to it, we write tests for the changes,
and often take the opportunity to write tests for the
existing logic too.

When it's time to write a test, look around at existing tests in the
same test file or at our existing tests for similar code, and follow
the patterns we use there.  Notes on specific kinds of tests:

 * For UI code, we use Flutter's standard `testWidgets` function.
   Many widgets will interact with the user's data; see docs on
   our `TestZulipBinding` and `TestGlobalStore`, and existing
   tests that use `testBinding.globalStore`, for how to manipulate
   test data there.

 * For code that makes Zulip API requests, use `FakeApiConnection`;
   see its docs and the existing tests that use it.

 * For code that makes other network requests, look for similar
   existing tests; or see our `FakeHttpClient`, and use
   `withHttpClient` from `package:http` to cause the code under test
   to use it.

 * For code that invokes Flutter plugins or otherwise calls external
   APIs, see our `ZulipBinding` class.  If there isn't an existing
   member of that class that wraps the API you're using, then you'll
   need to add one; follow the existing examples.


#### `check` vs. `expect`

For our tests, we use [the `checks` package][package-checks].
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

In particular the CocoaPods lockfiles
`ios/Podfile.lock` and `macos/Podfile.lock`
frequently need an update when dependencies change.
This can only be done in a macOS development environment.

If you have access to a Mac,
then for upgrading dependencies, use the script `tools/upgrade`.
Or after adding a new dependency, run the commands
`(cd ios && pod update) && (cd macos && pod update)`
to apply any needed updates to the CocoaPods lockfiles.

If you don't have convenient access to a Mac, then just mention
clearly in your PR that the upgrade needs syncing for CocoaPods,
and someone else can do it before merging the PR.

(Ideally we would validate these automatically in CI: [#329][].
Several other kinds of generated files are already validated in CI.)

[#329]: https://github.com/zulip/zulip-flutter/issues/329


### Code formatting

Like the [upstream Flutter project itself][flutter-no-dartfmt],
we [don't use `dart format`][zulip-no-dartfmt]
or other auto-formatters.
Instead, follow the style you see in the existing code.

It's OK if in your first few PRs you haven't yet picked up all the
nuances of our style.  Reviewers will point out nits as they see them.

If your editor or IDE automatically reformats the existing code,
you'll want to turn that off.  Please also mention it in Zulip
on chat.zulip.org and describe what editor you were using;
we'd like to include such configuration directly in the repo
so it's automatic for the next person.  We already have that
[for VS Code][vscode-disable-reformat], and it seems to be the
default for Android Studio / IntelliJ, but when there are cases
we haven't covered we'd like to know about them.

[flutter-no-dartfmt]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#formatting
[zulip-no-dartfmt]: https://github.com/zulip/zulip-flutter/issues/229#issuecomment-1642807019
[vscode-disable-reformat]: https://github.com/zulip/zulip-flutter/pull/230


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
