/// Logic for reading from the legacy app's data, on upgrade to this app.
///
/// Many of the details here correspond to specific parts of the
/// legacy app's source code.
/// See <https://github.com/zulip/zulip-mobile>.
// TODO(#1593): write tests for this file
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../log.dart';
import 'database.dart';
import 'settings.dart';

part 'legacy_app_data.g.dart';

Future<void> migrateLegacyAppData(AppDatabase db) async {
  assert(debugLog("Migrating legacy app data..."));
  final legacyData = await readLegacyAppData();
  if (legacyData == null) {
    assert(debugLog("... no legacy app data found."));
    await _setLegacyUpgradeState(db, LegacyUpgradeState.noLegacy);
    return;
  }

  assert(debugLog("Found settings: ${legacyData.settings?.toJson()}"));
  await _setLegacyUpgradeState(db, LegacyUpgradeState.found);
  final settings = legacyData.settings;
  if (settings != null) {
    await db.update(db.globalSettings).write(GlobalSettingsCompanion(
      // TODO(#1139) apply settings.language
      themeSetting: switch (settings.theme) {
        // The legacy app has just two values for this setting: light and dark,
        // where light is the default.  Map that default to the new default,
        // which is to follow the system-wide setting.
        // We planned the same change for the legacy app (but were
        // foiled by React Native):
        //   https://github.com/zulip/zulip-mobile/issues/5533
        // More-recent discussion:
        //   https://github.com/zulip/zulip-flutter/pull/1588#discussion_r2147418577
        LegacyAppThemeSetting.default_ => drift.Value.absent(),
        LegacyAppThemeSetting.night => drift.Value(ThemeSetting.dark),
      },
      browserPreference: switch (settings.browser) {
        LegacyAppBrowserPreference.embedded => drift.Value(BrowserPreference.inApp),
        LegacyAppBrowserPreference.external => drift.Value(BrowserPreference.external),
        LegacyAppBrowserPreference.default_ => drift.Value.absent(),
      },
      markReadOnScroll: switch (settings.markMessagesReadOnScroll) {
        // The legacy app's default was "always".
        // In this app, that would mix poorly with the VisitFirstUnreadSetting
        // default of "conversations"; so translate the old default
        // to the new default of "conversations".
        LegacyAppMarkMessagesReadOnScroll.always =>
          drift.Value(MarkReadOnScrollSetting.conversations),
        LegacyAppMarkMessagesReadOnScroll.never =>
          drift.Value(MarkReadOnScrollSetting.never),
        LegacyAppMarkMessagesReadOnScroll.conversationViewsOnly =>
          drift.Value(MarkReadOnScrollSetting.conversations),
      },
    ));
  }

  assert(debugLog("Found ${legacyData.accounts?.length} accounts:"));
  for (final account in legacyData.accounts ?? <LegacyAppAccount>[]) {
    assert(debugLog("  account: ${account.toJson()..['apiKey'] = 'redacted'}"));
    if (account.apiKey.isEmpty) {
      // This represents the user having logged out of this account.
      // (See `Auth.apiKey` in src/api/transportTypes.js .)
      // In this app, when a user logs out of an account,
      // the account is removed from the accounts list.  So remove this account.
      assert(debugLog("    (account ignored because had been logged out)"));
      continue;
    }
    if (account.userId == null
        || account.zulipVersion == null
        || account.zulipFeatureLevel == null) {
      // The legacy app either never loaded server data for this account,
      // or last did so on an ancient version of the app.
      // (See docs and comments on these properties in src/types.js .
      // Specifically, the latest added of these was userId, in commit 4fdefb09b
      // (#M4968), released in v27.170 in 2021-09.)
      // Drop the account.
      assert(debugLog("    (account ignored because missing metadata)"));
      continue;
    }
    try {
      await db.createAccount(AccountsCompanion.insert(
        realmUrl: account.realm,
        // no realmName; legacy app didn't record it
        // no realmIcon; legacy app didn't record it
        userId: account.userId!,
        email: account.email,
        apiKey: account.apiKey,
        zulipVersion: account.zulipVersion!,
        // no zulipMergeBase; legacy app didn't record it
        zulipFeatureLevel: account.zulipFeatureLevel!,
        // This app doesn't yet maintain ackedPushToken (#322), so avoid recording
        // a value that would then be allowed to get stale.  See discussion:
        //   https://github.com/zulip/zulip-flutter/pull/1588#discussion_r2148817025
        // TODO(#322): apply ackedPushToken
        // ackedPushToken: drift.Value(account.ackedPushToken),
      ));
    } on AccountAlreadyExistsException {
      // There's one known way this can actually happen: the legacy app doesn't
      // prevent duplicates on (realm, userId), only on (realm, email).
      //
      // So if e.g. the user changed their email on an account at some point
      // in the past, and didn't go and delete the old version from the
      // list of accounts, then the old version (the one later in the list,
      // since the legacy app orders accounts by recency) will get dropped here.
      assert(debugLog("    (account ignored because duplicate)"));
      continue;
    }
  }

  assert(debugLog("Done migrating legacy app data."));
  await _setLegacyUpgradeState(db, LegacyUpgradeState.migrated);
}

Future<void> _setLegacyUpgradeState(AppDatabase db, LegacyUpgradeState value) async {
  await db.update(db.globalSettings).write(GlobalSettingsCompanion(
    legacyUpgradeState: drift.Value(value)));
}

Future<LegacyAppData?> readLegacyAppData() async {
  final LegacyAppDatabase db;
  try {
    final sqlDb = sqlite3.open(await LegacyAppDatabase._filename());

    // For writing tests (but more refactoring needed):
    // sqlDb = sqlite3.openInMemory();

    db = LegacyAppDatabase(sqlDb);
  } catch (_) {
    // Presumably the legacy database just doesn't exist,
    // e.g. because this is a fresh install, not an upgrade from the legacy app.
    return null;
  }

  try {
    if (db.migrationVersion() != 1) {
      // The data is ancient.
      return null; // TODO(log)
    }

    final migrationsState = db.getDecodedItem('reduxPersist:migrations',
      LegacyAppMigrationsState.fromJson);
    final migrationsVersion = migrationsState?.version;
    if (migrationsVersion == null) {
      // The data never got written in the first place,
      // at least not coherently.
      return null; // TODO(log)
    }
    if (migrationsVersion < 58) {
      // The data predates a migration that affected data we'll try to read.
      // Namely migration 58, from commit 49ed2ef5d, PR #5656, 2023-02.
      return null; // TODO(log)
    }
    if (migrationsVersion > 66) {
      // The data is from a future schema version this app is unaware of.
      return null; // TODO(log)
    }

    final settingsStr = db.getItem('reduxPersist:settings');
    final accountsStr = db.getItem('reduxPersist:accounts');
    try {
      return LegacyAppData.fromJson({
        'settings': settingsStr == null ? null : jsonDecode(settingsStr),
        'accounts': accountsStr == null ? null : jsonDecode(accountsStr),
      });
    } catch (_) {
      return null; // TODO(log)
    }
  } on SqliteException {
    return null; // TODO(log)
  }
}

class LegacyAppDatabase {
  LegacyAppDatabase(this._db);

  final Database _db;

  static Future<String> _filename() async {
    const baseName = 'zulip.db'; // from AsyncStorageImpl._initDb

    final dir = await switch (defaultTargetPlatform) {
      // See node_modules/expo-sqlite/android/src/main/java/expo/modules/sqlite/SQLiteModule.kt
      // and the method SQLiteModule.pathForDatabaseName there:
      // works out to "${mContext.filesDir}/SQLite/$name",
      // so starting from:
      //   https://developer.android.com/reference/kotlin/android/content/Context#getFilesDir()
      // That's what path_provider's getApplicationSupportDirectory gives.
      // (The latter actually has a fallback when Android's getFilesDir
      // returns null.  But the Android docs say that can't happen.  If it does,
      // SQLiteModule would just fail to make a database, and the legacy app
      // wouldn't have managed to store anything in the first place.)
      TargetPlatform.android => getApplicationSupportDirectory(),

      // See node_modules/expo-sqlite/ios/EXSQLite/EXSQLite.m
      // and the method `pathForDatabaseName:` there:
      // works out to "${fileSystem.documentDirectory}/SQLite/$name",
      // The base directory there comes from:
      //   node_modules/expo-modules-core/ios/Interfaces/FileSystem/EXFileSystemInterface.h
      //   node_modules/expo-file-system/ios/EXFileSystem/EXFileSystem.m
      // so ultimately from an expression:
      //   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
      // which means here:
      //   https://developer.apple.com/documentation/foundation/nssearchpathfordirectoriesindomains(_:_:_:)?language=objc
      //   https://developer.apple.com/documentation/foundation/filemanager/searchpathdirectory/documentdirectory?language=objc
      // That's what path_provider's getApplicationDocumentsDirectory gives.
      TargetPlatform.iOS => getApplicationDocumentsDirectory(),

      // On other platforms, there is no Zulip legacy app that this app replaces.
      // So there's nothing to migrate.
      _ => throw Exception(),
    };

    return '${dir.path}/SQLite/$baseName';
  }

  /// The migration version of the AsyncStorage database as a whole
  /// (not to be confused with the version within `state.migrations`).
  ///
  /// This is always 1 since it was introduced,
  /// in commit caf3bf999 in 2022-04.
  ///
  /// Corresponds to portions of AsyncStorageImpl._migrate .
  int migrationVersion() {
    final rows = _db.select('SELECT version FROM migration LIMIT 1');
    return rows.single.values.single as int;
  }

  T? getDecodedItem<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final valueStr = getItem(key);
    if (valueStr == null) return null;

    try {
      return fromJson(jsonDecode(valueStr) as Map<String, Object?>);
    } catch (_) {
      return null; // TODO(log)
    }
  }

  /// Corresponds to CompressedAsyncStorage.getItem.
  String? getItem(String key) {
    final item = getItemRaw(key);
    if (item == null) return null;
    if (item.startsWith('z')) {
      // A leading 'z' marks Zulip compression.
      // (It can't be the original uncompressed value, because all our values
      // are JSON, and no JSON encoding starts with a 'z'.)

      if (defaultTargetPlatform != TargetPlatform.android) {
        return null; // TODO(log)
      }

      /// Corresponds to `header` in android/app/src/main/java/com/zulipmobile/TextCompression.kt .
      const header = 'z|zlib base64|';
      if (!item.startsWith(header)) {
        return null; // TODO(log)
      }

      // These steps correspond to `decompress` in android/app/src/main/java/com/zulipmobile/TextCompression.kt .
      final encodedSplit = item.substring(header.length);
      // Not sure how newlines get there into the data; but empirically
      // they do, after each 76 characters of `encodedSplit`.
      final encoded = encodedSplit.replaceAll('\n', '');
      try {
        final compressedBytes = base64Decode(encoded);
        final uncompressedBytes = zlib.decoder.convert(compressedBytes);
        return utf8.decode(uncompressedBytes);
      } catch (_) {
        return null; // TODO(log)
      }
    }
    return item;
  }

  /// Corresponds to AsyncStorageImpl.getItem.
  String? getItemRaw(String key) {
    final rows = _db.select('SELECT value FROM keyvalue WHERE key = ?', [key]);
    final row = rows.firstOrNull;
    if (row == null) return null;
    return row.values.single as String;
  }

  /// Corresponds to AsyncStorageImpl.getAllKeys.
  List<String> getAllKeys() {
    final rows = _db.select('SELECT key FROM keyvalue');
    return [for (final r in rows) r.values.single as String];
  }
}

/// Represents the data from the legacy app's database,
/// so far as it's relevant for this app.
///
/// The full set of data in the legacy app's in-memory store is described by
/// the type `GlobalState` in src/reduxTypes.js .
/// Within that, the data it stores in the database is the data at the keys
/// listed in `storeKeys` and `cacheKeys` in src/boot/store.js .
/// The data under `cacheKeys` lives on the server and the app re-fetches it
/// upon each startup anyway;
/// so only the data under `storeKeys` is relevant for migrating to this app.
///
/// Within the data under `storeKeys`, some portions are also ignored
/// for specific reasons described explicitly in comments on these types.
@JsonSerializable()
class LegacyAppData {
  // The `state.migrations` data gets read and used before attempting to
  // deserialize the data that goes into this class.
  // final LegacyAppMigrationsState migrations; // handled separately

  final LegacyAppGlobalSettingsState? settings;
  final List<LegacyAppAccount>? accounts;

  // final Map<??, String> drafts; // ignore; inherently transient

  // final List<??> outbox; // ignore; inherently transient

  LegacyAppData({
    required this.settings,
    required this.accounts,
  });

  factory LegacyAppData.fromJson(Map<String, Object?> json) =>
    _$LegacyAppDataFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppDataToJson(this);
}

/// Corresponds to type `MigrationsState` in src/reduxTypes.js .
@JsonSerializable()
class LegacyAppMigrationsState {
  final int? version;

  LegacyAppMigrationsState({required this.version});

  factory LegacyAppMigrationsState.fromJson(Map<String, Object?> json) =>
    _$LegacyAppMigrationsStateFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppMigrationsStateToJson(this);
}

/// Corresponds to type `GlobalSettingsState` in src/reduxTypes.js .
///
/// The remaining data found at key `settings` in the overall data,
/// described by type `PerAccountSettingsState`, lives on the server
/// in the same way as the data under the keys in `cacheKeys`,
/// and so is ignored here.
@JsonSerializable()
class LegacyAppGlobalSettingsState {
  final String language;
  final LegacyAppThemeSetting theme;
  final LegacyAppBrowserPreference browser;

  // Ignored because the legacy app hadn't used it since 2017.
  // See discussion in commit zulip-mobile@761e3edb4 (from 2018).
  // final bool experimentalFeaturesEnabled; // ignore

  final LegacyAppMarkMessagesReadOnScroll markMessagesReadOnScroll;

  LegacyAppGlobalSettingsState({
    required this.language,
    required this.theme,
    required this.browser,
    required this.markMessagesReadOnScroll,
  });

  factory LegacyAppGlobalSettingsState.fromJson(Map<String, Object?> json) =>
    _$LegacyAppGlobalSettingsStateFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppGlobalSettingsStateToJson(this);
}

/// Corresponds to type `ThemeSetting` in src/reduxTypes.js .
enum LegacyAppThemeSetting {
  @JsonValue('default')
  default_,
  night;
}

/// Corresponds to type `BrowserPreference` in src/reduxTypes.js .
enum LegacyAppBrowserPreference {
  embedded,
  external,
  @JsonValue('default')
  default_,
}

/// Corresponds to the type `GlobalSettingsState['markMessagesReadOnScroll']`
/// in src/reduxTypes.js .
@JsonEnum(fieldRename: FieldRename.kebab)
enum LegacyAppMarkMessagesReadOnScroll {
  always, never, conversationViewsOnly,
}

/// Corresponds to type `Account` in src/types.js .
@JsonSerializable()
class LegacyAppAccount {
  // These three come from type Auth in src/api/transportTypes.js .
  @_LegacyAppUrlJsonConverter()
  final Uri realm;
  final String apiKey;
  final String email;

  final int? userId;

  @_LegacyAppZulipVersionJsonConverter()
  final String? zulipVersion;

  final int? zulipFeatureLevel;

  final String? ackedPushToken;

  // These three are ignored because this app doesn't currently have such
  // notices or banners for them to control; and because if we later introduce
  // such things, it's a pretty mild glitch to have them reappear, once,
  // after a once-in-N-years major upgrade to the app.
  // final DateTime? lastDismissedServerPushSetupNotice; // ignore
  // final DateTime? lastDismissedServerNotifsExpiringBanner; // ignore
  // final bool silenceServerPushSetupWarnings; // ignore

  LegacyAppAccount({
    required this.realm,
    required this.apiKey,
    required this.email,
    required this.userId,
    required this.zulipVersion,
    required this.zulipFeatureLevel,
    required this.ackedPushToken,
  });

  factory LegacyAppAccount.fromJson(Map<String, Object?> json) =>
    _$LegacyAppAccountFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppAccountToJson(this);
}

/// This and its subclasses correspond to portions of src/storage/replaceRevive.js .
///
/// (The rest of the conversions in that file are for types that don't appear
/// in the portions of the legacy app's state we care about.)
sealed class _LegacyAppJsonConverter<T> extends JsonConverter<T, Map<String, dynamic>> {
  const _LegacyAppJsonConverter();

  String get serializedTypeName;

  T fromJsonData(Object? json);

  Object? toJsonData(T value);

  /// Corresponds to `SERIALIZED_TYPE_FIELD_NAME`.
  static const _serializedTypeFieldName = '__serializedType__';

  @override
  T fromJson(Map<String, dynamic> json) {
    final actualTypeName = json[_serializedTypeFieldName];
    if (actualTypeName != serializedTypeName) {
      throw FormatException("unexpected $_serializedTypeFieldName: $actualTypeName");
    }
    return fromJsonData(json['data']);
  }

  @override
  Map<String, dynamic> toJson(T object) {
    return {
      _serializedTypeFieldName: serializedTypeName,
      'data': toJsonData(object),
    };
  }
}

class _LegacyAppUrlJsonConverter extends _LegacyAppJsonConverter<Uri> {
  const _LegacyAppUrlJsonConverter();

  @override
  String get serializedTypeName => 'URL';

  @override
  Uri fromJsonData(Object? json) => Uri.parse(json as String);

  @override
  Object? toJsonData(Uri value) => value.toString();
}

/// Corresponds to type `ZulipVersion`.
///
/// This new app skips the parsing logic of the legacy app's ZulipVersion type,
/// and just uses the raw string.
class _LegacyAppZulipVersionJsonConverter extends _LegacyAppJsonConverter<String> {
  const _LegacyAppZulipVersionJsonConverter();

  @override
  String get serializedTypeName => 'ZulipVersion';

  @override
  String fromJsonData(Object? json) => json as String;

  @override
  Object? toJsonData(String value) => value;
}
