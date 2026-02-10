---
paths:
  - "lib/model/**/*"
  - "lib/api/model/**/*"
  - "lib/widgets/store.dart"
  - "test/model/**/*"
  - "test/api/model/**/*"
  - "test/widgets/*store*"
---

# Data Store Architecture

## 1. `lib/model/store.dart` — Core Store Classes

**GlobalStore** (abstract, extends `ChangeNotifier`):
- App-wide singleton managing accounts (`Map<int, Account>`), global settings (`GlobalSettingsStore`), and a cache of per-account stores.
- Key methods: `perAccount(accountId)` (async load-or-get), `perAccountSync(accountId)`, `insertAccount()`, `updateAccount()`, `removeAccount()`.

**CorePerAccountStore** — non-ChangeNotifier helper holding `ApiConnection`, `queueId`, `accountId`, `selfUserId`, and a reference to the `GlobalStore`.

**PerAccountStoreBase** (abstract) — base for PerAccountStore and all substores. Provides access to `CorePerAccountStore` via a protected `core` field, exposing `realmUrl`, `selfUserId`, `zulipFeatureLevel`, `connection`, `queueId`, etc.

**PerAccountStore** (concrete, extends `PerAccountStoreBase` with `ChangeNotifier` + many mixins):
- The central per-account data store. Composed of domain-specific substores:
  - `_groups` (UserGroupStoreImpl), `_realm` (RealmStoreImpl), `_emoji` (EmojiStoreImpl), `_users` (UserStoreImpl), `_channels` (ChannelStoreImpl), `_messages` (MessageStoreImpl), `_savedSnippets` (SavedSnippetStoreImpl)
  - Plus: `unreads`, `presence`, `typingStatus`, `typingNotifier`, `topics`, `recentDmConversationsView`, `recentSenders`, `pushDevices`
- Factory: `fromInitialSnapshot()` builds the full store from an `InitialSnapshot`.
- `handleEvent(Event)` — large switch statement dispatching ~20+ event types to the appropriate substores.

## 2. Other Files in `lib/model/`

Each substore domain has its own file: `user.dart`, `channel.dart`, `message.dart`, `realm.dart`, `user_group.dart`, `emoji.dart`, `unreads.dart`, `presence.dart`, `typing_status.dart`, `topics.dart`, `recent_dm_conversations.dart`, `recent_senders.dart`, `saved_snippet.dart`.

Infrastructure files: `database.dart` (Drift ORM), `binding.dart` (ZulipBinding singleton).

Other model files: `settings.dart`, `message_list.dart`, `narrow.dart`, `actions.dart`, `autocomplete.dart`, `server_support.dart`.

## 3. Substore Inheritance Hierarchy

```
PerAccountStoreBase (abstract)
  ├── PerAccountStore (concrete, main class)
  └── Substores via helper base classes:
      HasUserGroupStore extends PerAccountStoreBase + UserGroupStore + ProxyUserGroupStore
      HasRealmStore extends HasUserGroupStore + RealmStore + ProxyRealmStore
      HasUserStore extends HasRealmStore + UserStore + ProxyUserStore
      HasChannelStore extends HasUserStore + ChannelStore + ProxyChannelStore
```

This chain means a substore like `MessageStoreImpl` (which extends `HasChannelStore`) automatically gets access to channel, user, realm, and user-group data from the parent store. Each `Proxy*Store` mixin delegates to the parent via `core`. The pattern allows substores to depend on other substores' data without circular references.

## 4. API Model Types (`lib/api/model/`)

- **`initial_snapshot.dart`**: `InitialSnapshot` — the full server state from `/register`. Contains users, channels, subscriptions, messages, unreads, emoji, user groups, settings, topics, etc.
- **`events.dart`**: Sealed `Event` class with 20+ subtypes (`MessageEvent`, `UpdateMessageEvent`, `DeleteMessageEvent`, `RealmUserAddEvent`, etc.), all constructed by the `Event.fromJson` factory.
- **`model.dart`**: Core types — `User`, `Message`, `ZulipStream`, `Subscription`, `UserGroup`, etc. All constructor params are `required` (even nullable ones).
- Other files: `reaction.dart`, `submessage.dart`, `narrow.dart`, `permission.dart`.

## 5. Data Flow: InitialSnapshot → Store → Events

**Initial load** (`UpdateMachine.load()`):
1. Calls `/register` API → returns `InitialSnapshot` JSON
2. `PerAccountStore.fromInitialSnapshot()` constructs the entire store: builds user maps, channel maps, emoji data, unreads, etc. from the snapshot fields
3. `UpdateMachine` wraps the store and starts polling `/events`

**Event updates** (`UpdateMachine.poll()` → `PerAccountStore.handleEvent()`):
- Each event type dispatches to the appropriate substore handler(s) — often multiple substores in a defined order. For example, `MessageEvent` updates `_messages`, `unreads`, `recentDmConversationsView`, `recentSenders`, and `topics`.
- After processing, `notifyListeners()` fires, causing dependent widgets to rebuild.

## 6. Test Infrastructure (`test/model/`)

- **`binding.dart`**: `TestZulipBinding` — fakes all external dependencies
- **`test_store.dart`**: `TestGlobalStore` — uses `FakeApiConnection` and in-memory account storage (no real database). Also `UpdateMachineTestGlobalStore` for event-polling tests.
- **`store_checks.dart`**: Custom check functions for store assertions using `package:checks`.

## 7. `test/example_data.dart`

Provides builder functions for all common test fixtures: `selfUser`, `otherUser`, `selfAccount`, `otherAccount`, `serverSettings()`, `customProfileField()`, etc. All use named parameters with sensible defaults — tests customize only what's relevant.

## 8. Widget Store Access (`lib/widgets/store.dart`)

- **`GlobalStoreWidget`**: `InheritedNotifier`-based widget. Access via `GlobalStoreWidget.of(context)`.
- **`PerAccountStoreWidget`**: Loads `PerAccountStore` from `GlobalStore`. Access via `PerAccountStoreWidget.of(context)`.
- **`PerAccountStoreAwareStateMixin`**: Mixin for widgets that need to handle store replacement (e.g., when the event queue expires and a fresh store is loaded). Provides an `onNewStore()` callback.

## 9. Architecture Diagram

```
Widget Tree (GlobalStoreWidget / PerAccountStoreWidget)
    │  InheritedNotifier dependency
    ▼
GlobalStore (ChangeNotifier)
    │  perAccount() / perAccountSync()
    ▼
PerAccountStore (ChangeNotifier + domain substores)
    │  handleEvent() dispatcher
    ▼
UpdateMachine (poll loop)
    │
    ▼
Zulip Server (/register → InitialSnapshot, /events → Event stream)
```
