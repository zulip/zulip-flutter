# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Zulip Flutter — the official Zulip mobile app for Android and iOS, built with Flutter/Dart. Uses the latest Flutter from Flutter's `main` channel (not stable/beta).

## Common commands

```bash
# Run unit tests
flutter test --no-pub

# Run a specific test file
flutter test --no-pub test/foo/bar_test.dart

# Run a specific test by name
flutter test --no-pub test/foo/bar_test.dart --name 'some test name'

# Static analysis (type-checking + linting)
flutter analyze --no-pub

# Run all test suites (only changed files vs upstream main)
tools/check

# Regenerate JSON serialization code after editing API types
tools/check --fix build_runner

# Regenerate i18n after editing assets/l10n/app_en.arb
flutter gen-l10n
```

## Architecture

### Binding pattern

`ZulipBinding` (abstract, in `lib/model/binding.dart`) is a singleton that wraps all external services (plugins, platform channels, store creation). Modeled on Flutter's `WidgetsFlutterBinding`.

- **`LiveZulipBinding`** — real implementation used in the app
- **`TestZulipBinding`** (in `test/model/binding.dart`) — test implementation that fakes all external dependencies

### State management

- **`GlobalStore`** (`lib/model/store.dart`) — app-wide state (accounts, global settings). Access via `GlobalStoreWidget.of(context)`.
- **`PerAccountStore`** (`lib/model/store.dart`) — per-account data (messages, users, channels, unreads, etc.). Uses `ChangeNotifier` for reactivity.

See @./rules/data-store.md for detailed conventions and architecture for writing state logic.

### API layer (`lib/api/`)

- **`core.dart`** — `ApiConnection` HTTP client with auth, JSON handling, error handling
- **`route/`** — one file per API endpoint group; top-level async functions taking `ApiConnection` as first param
- **`model/`** — data types with JSON serialization via `json_serializable`; generated `.g.dart` files must be kept up to date

See @./rules/api.md for detailed conventions on writing API bindings.

### Platform layer (`lib/host/`)

Uses Pigeon for type-safe platform channels (Android intents, notifications).

### Key conventions

- **All API type constructor params are `required`**, even nullable ones — no default values. Use `test/example_data.dart` for test defaults.
- **Server compatibility**: the minimum supported server version is `kMinAllowedZulipVersion` in `lib/api/core.dart`. Use `TODO(server-N)` comments for newer features.
- **Tests use `package:checks`** (not `expect`/`matcher`).
- **No `dart format`** — follow existing code style manually. Auto-format is disabled in VS Code settings.
- **Prefer relative imports** within the package.
- **Strict analysis**: strict-inference, strict-raw-types, strict-casts are all enabled.
- **Stream → channel rename**: Use "channel" instead of "stream" for new variable/parameter names (e.g., `channelId` not `streamId`). The API still uses "stream" in many places, but new code in this codebase should use "channel". See #631.

### Testing patterns

- Widget tests: `testWidgets` + `TestZulipBinding` + `testBinding.globalStore`
- API tests: `FakeApiConnection` with `connection.prepare(json: ...)` / `connection.takeRequests()`
- External APIs: wrap in `ZulipBinding`, fake in tests
- Test fixtures: `test/example_data.dart` has builders for all common data types

See @./rules/testing.md for detailed conventions on writing tests.

### i18n

New UI strings go in `assets/l10n/app_en.arb`. Output class is `ZulipLocalizations`. Run `flutter gen-l10n` after editing.

### Database

Uses Drift ORM with SQLite. Schema changes require running `tools/check --fix drift` to update versioned schema files and migration helpers.

### Design

UI designs come from Figma (linked in issues). Match colors, padding, and font sizes exactly. Use `DesignVariables` and `ContentTheme` for theme values.


## Debugging test failures

- Full `flutter test` takes ~60s. Capture output to a temp file on the first run;
  don't re-run the full suite just to find the failure details.
- Once the failing test file is identified, re-run just that file (~3-5s).
- For localized failures (one test, one file), read the test and source directly
  rather than spawning broad codebase searches.


## Developing changes

- After every edit, run the Flutter analyzer to catch issues early.
  Use this command: `flutter analyze --no-pub 2>&1 | head -20`
- When working on an issue, don't try to look at the server/web implementation.
  Stick to the issue's spec and the API docs.
  Exception: for questions about server behavior that the API docs
  don't answer, and for work on API documentation or design itself,
  do read the server code, in `../zulip` if present.


## Writing clear code

- **Keep comments minimal.**
  Don't write comments that restate what the code does
  ("// The old key is now superseded" on `.supersededTimestamp.equals(now)`).
  Use comments only for context not obvious from the code itself
  (e.g., "// A device-update event acks the new key." before a `handleEvent` call).

- **Use semantic line breaks in dartdocs.**
  Break lines at natural prose boundaries
  — commas, end of a clause, end of a sentence —
  not at a fixed column width.
  This keeps diffs minimal when dartdocs change:
  edits to one sentence don't reflow neighboring lines.
  See:
    https://github.com/dart-lang/site-shared/blob/3408a7468/doc/writing-for-dart-and-flutter-websites.md#semantic-line-breaks
    https://rhodesmill.org/brandon/2012/one-sentence-per-line/


## Zulip chat links

- When you encounter a chat.zulip.org narrow URL (in an issue, PR, or
  user message), use the fetch-zulip-messages skill to read the
  conversation. Don't use WebFetch; it can't access Zulip message
  content.


## GitHub in cloud sessions

- On Claude Code on the web, the GitHub API is scoped to the
  session's own repo. To read upstream issues and PRs,
  use the built-in GitHub search tools with `repo:zulip/zulip-flutter`
  in the query, or fetch the item's github.com URL with WebFetch.
  Issue comments are reachable by neither route (PR comments are);
  when an issue's comment thread matters, ask the user to paste it.
  (Limitation tracked as anthropics/claude-code#78277.)

- **Open pull requests only as drafts.**
  A PR is created on behalf of the user's own GitHub account,
  and a session's commits are authored as Claude, with no
  responsible human author. A draft says so: it's a handoff,
  not a submission. After opening one, tell the user the rest
  is theirs — check out the branch locally, revise and take
  authorship (with `--reset-author`), and mark the PR ready
  for review. See docs/howto/claude-web.md ("Trust model").


## Using Git

- **Use `@` instead of `HEAD`** —
  there may be a stray file named `HEAD`,
  which causes `fatal: ambiguous argument 'HEAD'` errors.

- **Don't use `git -C <path>` to operate on this repo** —
  it triggers a permission prompt.
  Run plain `git <subcommand>` from the repository root instead.

- **Always `git add` specific new files** —
  never use `git add -A` or `git add .`.
  The worktree can pick up stray files.
  For adding changes to all existing files, use `git add -u`.

- **Use plain single-quotes for commit messages** —
  write `git commit -m 'message'`, not heredoc `$(cat <<'EOF'...)`.
  Command substitution `$(...)` triggers a permission prompt.

  If the message itself contains a single quote,
  a single quote can be expressed inside a Bash single-quoted string
  with the five characters `'"'"'`.

- **Use `git cherry-pick` for rewriting history** —
  never use `git rebase -i`, as it
  requires an editor, which triggers permission prompts.
  Instead, use `git cherry-pick`
  (with `--no-commit` when modifications are needed)
  to replay commits.

- **Don't commit files that aren't meant for the repo** —
  reports, reviews, drafts, and other output addressed to the
  person you're working with rather than to the codebase.
  Leave these uncommitted unless explicitly asked.
  This matters most on Claude Code on the web, which pushes
  commits to GitHub automatically: a committed security review
  would go public before any human had looked at it.
