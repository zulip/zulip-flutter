# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Zulip Flutter — the official Zulip mobile app for Android and iOS, built with Flutter/Dart. Uses the latest Flutter from Flutter's `main` channel (not stable/beta).

## Common commands

```bash
# Run unit tests
flutter test

# Run a specific test file
flutter test test/foo/bar_test.dart

# Run a specific test by name
flutter test test/foo/bar_test.dart --name 'some test name'

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
- **Server compatibility**: minimum Zulip Server 7.0 (feature level 185). Use `TODO(server-N)` comments for newer features.
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

### i18n

New UI strings go in `assets/l10n/app_en.arb`. Output class is `ZulipLocalizations`. Run `flutter gen-l10n` after editing.

### Database

Uses Drift ORM with SQLite. Schema changes require running `tools/check --fix drift` to update versioned schema files and migration helpers.

### Design

UI designs come from Figma (linked in issues). Match colors, padding, and font sizes exactly. Use `DesignVariables` and `ContentTheme` for theme values.


## Developing changes

- After every edit, run the Flutter analyzer to catch issues early.
  Use this command: `flutter analyze --no-pub 2>&1 | head -20`
