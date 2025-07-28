# Zulip Flutter

The official Zulip app for Android and iOS, built with Flutter.

This app [was launched][] as the main Zulip mobile app
in June 2025.
It replaced the [previous Zulip mobile app][] built with React Native.

[was launched]: https://blog.zulip.com/flutter-mobile-app-launch
[previous Zulip mobile app]: https://github.com/zulip/zulip-mobile#readme


## Get the app

Release versions of the app are available here:
* [Zulip for iOS](https://apps.apple.com/app/zulip/id1203036395)
  on Apple's App Store
* [Zulip for Android](https://play.google.com/store/apps/details?id=com.zulipmobile)
  on the Google Play Store
  * Or if you don't use Google Play, you can
    [download an APK](https://github.com/zulip/zulip-flutter/releases/latest)
    from the official build we post on GitHub.


## Contributing

Contributions to this app are welcome.

If you're looking to participate in Google Summer of Code with Zulip,
this was among the projects we accepted [GSoC applications][gsoc] for
in 2024 and 2025.

[gsoc]: https://zulip.readthedocs.io/en/latest/outreach/gsoc.html#mobile-app


### Picking an issue to work on

First, see the Zulip project guide to [your first codebase contribution][].
Follow the instructions there for joining the Zulip community server,
reading about [what makes a great Zulip contributor][],
browsing through recent commits and the codebase,
and the Zulip guide to Git.

To find possible issues to work on, see our [project board][].
Look for issues in the earliest milestone,
and that aren't already assigned.

Follow the Zulip guide to [picking an issue to work on][],
trying several issues until you find one you're confident
you'll be able to take on effectively.

*After you've done that*, claim the issue by posting a comment
on the issue thread, saying you'd like to work on it
and describing your progress.

[your first codebase contribution]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#your-first-codebase-contribution
[what makes a great Zulip contributor]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#what-makes-a-great-zulip-contributor
[project board]: https://github.com/orgs/zulip/projects/5/views/4
[picking an issue to work on]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#picking-an-issue-to-work-on


<div id="getting-help" />

### Asking questions, getting help

To ask for help with working on this codebase, use the
[`#mobile-dev-help`][mobile-dev-help] channel on chat.zulip.org.
Before participating there for the first time,
be sure to take a minute to read our
[community norms][norms-getting-help].

For more in-depth advice on how to go beyond the minimum
represented by our community norms, see
Zulip's [guide to asking great questions][]
and the resources linked from there.

[mobile-dev-help]: https://chat.zulip.org/#narrow/stream/516-mobile-dev-help
[norms-getting-help]: https://zulip.com/development-community/#getting-help
[guide to asking great questions]: https://zulip.readthedocs.io/en/latest/contributing/asking-great-questions.html


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
   (Use Greg's ["secret" to using `git log -p`][git-log-p-secret]
   and/or a graphical Git client to see examples of mergeable commits.)

   This is always required before we can merge your PR.  Depending on
   your changes' complexity, it may also be required before we can
   review it in detail.  (The main exception is that if the change
   should be a single commit, we can review it even with a messier
   commit structure.)

[working on an issue]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#working-on-an-issue
[submitting a pull request]: https://zulip.readthedocs.io/en/latest/contributing/review-process.html
[commit-style]: https://zulip.readthedocs.io/en/latest/contributing/commit-discipline.html
[git-log-p-secret]: https://github.com/zulip/zulip-mobile/blob/main/docs/howto/git.md#git-log-secret


## Getting started in developing

### Setting up

Running the app requires only a standard Flutter setup,
using the Flutter `main` channel:

1. Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install)
   for your platform of choice.
2. Switch to the latest version of Flutter by running `flutter channel main`
   and `flutter upgrade` (see [Flutter version](#flutter-version) below).
3. Ensure Flutter is correctly configured by running `flutter doctor`.
4. Start the app with `flutter run`, or from your IDE.

Parts of our test suite require an additional dependency:

5. Install SQLite, for example by running `sudo apt install libsqlite3-dev`.

Developing on Windows requires
an [additional step](docs/setup.md#autocrlf):

6. Run `git config core.autocrlf input`.

For more details and help with unusual configurations,
see our [full setup guide](docs/setup.md).

If you're having trouble or seeing errors, take a look through our
[troubleshooting section](docs/setup.md#troubleshooting).
If that doesn't resolve the issue, see the section above on
[how to ask for help](#getting-help).


### Flutter version

We use the latest Flutter from Flutter's main branch.
Use `flutter channel main` and `flutter upgrade`.

Because each version of Flutter provides its own version of the
Dart SDK, this also means we use the latest Dart SDK.

Using the latest versions is the same thing Google does with
their own Flutter apps.  It's valuable to us because it means
when there's something we want to fix in Flutter,
or a feature we want to add,
we can send a PR upstream and then use it as soon as it's merged.

We don't pin a specific Flutter version,
because Flutter itself doesn't offer a way to do so.
So far that hasn't been a problem.  When it becomes one,
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

### UI design

For issues that call for building new UI, we typically have a
design in Figma which will be linked from the issue description.

When there is a design in Figma, a PR implementing the issue
should match the design exactly, except where there's a
good reason to make things different.
Like with any difference between a PR and previous plans,
you should [explain the difference](https://zulip.readthedocs.io/en/latest/contributing/reviewable-prs.html#explain-your-changes)
clearly in your PR description.

For colors, padding, font sizes, and similar design details,
it's rare to have a good reason to differ from the
design in Figma.
When [reviewing your work](https://zulip.readthedocs.io/en/latest/contributing/reviewable-prs.html#review-your-own-work)
(which you should do before every PR),
take some time to look closely through all the details of
the design in Figma
and confirm that they're matched in your PR.

In our code, many colors and other details appear on `DesignVariables`
or similar classes like `ContentTheme`.  If you need a Figma variable
which doesn't yet appear in our code, please add it.


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

#### Server compatibility

We support Zulip Server 7.0 and later.

For API features added in newer versions, use `TODO(server-N)`
comments (like those you see in the existing code.)


#### Require all parameters in API constructors

In our API types, constructors should generally avoid default values for
their parameters, even `null`.  This means writing e.g. `required this.foo`
rather than just `this.foo`, even when `foo` is nullable.

We do this because it's common in the Zulip API for a null or missing value
to be quite salient in meaning, and not a boring value appropriate for a
default, so that it's best to ensure callers make an explicit choice.

If passing explicit values in tests is cumbersome, a factory function
in `test/example_data.dart` is an appropriate way to share defaults.


#### Generated files

When editing any of the type definitions in our API, you'll need to
keep up to date the corresponding generated code
(which handles converting JSON to and from our types).

To do this, run the following command:
```
$ dart run build_runner watch --delete-conflicting-outputs
```

That `build_runner watch` command watches for changes
in relevant files and updates the generated code as needed.

When the `build_runner watch` command has finished its work and
is waiting for more changes, you may find it convenient to
suspend it by pressing Ctrl+Z before you edit the code further.
While suspended, the command will not run.
After editing the source files further, you can update the
generated files again by running the command `fg` in the
terminal where `build_runner watch` had been running.
The `fg` command causes the suspended command to resume running
(in the foreground, hence the name `fg`), just like it was doing
before Ctrl+Z.

If a PR is missing required updates to these generated files,
CI will fail at the `build_runner` suite.


### Upgrading Flutter

We regularly increment our lower bounds on Flutter and Dart versions,
to make sure there's not too much divergence in the versions people
are using.

When there's a new beta (which happens a couple of times per month),
that's a good prompt to do this.  We also do this when there's a
new PR merged that we particularly want to take.

To update the version bounds:
* Use `flutter upgrade` to upgrade your local Flutter and Dart.
* Run `tools/upgrade flutter-local`, which makes a commit updating
  `pubspec.yaml` and `pubspec.lock` to match your local Flutter.
* Build and run the app for a quick smoke-check.
* Send the changes as a PR.


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


### Desktop support

This app is intended for use on mobile platforms, specifically
Android and iOS.

On desktop platforms, we support running the app for development
but not for general use.  In particular this means:

 * The layout and UI are designed for mobile.  We don't spend time
   on adapting the app to desktop UI features or paradigms.

 * External platform integrations (like opening a link,
   taking a photo, etc.) are built only for Android and iOS.
   We don't spend time making them work on other platforms.

 * On the other hand the app runs, and core functionality works,
   on at least Linux and macOS.  Currently no regular contributor
   uses it on Windows, but we accept fixes to keep it running there too.

The reason we support desktop platforms at all is that
for development it's sometimes useful to run the app on desktop.
For example, this makes it easy to resize the window arbitrarily,
which can be helpful for testing layout behavior.


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
