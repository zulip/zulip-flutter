import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift/remote.dart';
import 'package:sqlite3/common.dart';

import '../log.dart';
import 'legacy_app_data.dart';
import 'schema_versions.g.dart';
import 'settings.dart';

part 'database.g.dart';

/// The table of one [GlobalSettingsData] record, the user's chosen settings
/// on this client that are independent of account.
///
/// These apply across all the user's accounts on this client (i.e. on this
/// install of the app on this device).
///
/// This table should always have exactly one row (it's created by a migration).
@DataClassName('GlobalSettingsData')
class GlobalSettings extends Table {
  Column<String> get themeSetting => textEnum<ThemeSetting>()
    .nullable()();

  Column<String> get browserPreference => textEnum<BrowserPreference>()
    .nullable()();

  Column<String> get visitFirstUnread => textEnum<VisitFirstUnreadSetting>()
    .nullable()();

  Column<String> get markReadOnScroll => textEnum<MarkReadOnScrollSetting>()
    .nullable()();

  Column<String> get legacyUpgradeState => textEnum<LegacyUpgradeState>()
    .nullable()();

  // If adding a new column to this table, consider whether [BoolGlobalSettings]
  // or [IntGlobalSettings] can do the job instead (by adding a value to the
  // [BoolGlobalSetting] or [IntGlobalSetting] enum).
  // That way is more convenient, when it works, because
  // it avoids a migration and therefore several added copies of our schema
  // in the Drift generated files.
}

/// The table of the user's bool-valued, account-independent settings.
///
/// These apply across all the user's accounts on this client
/// (i.e. on this install of the app on this device).
///
/// Each row is a [BoolGlobalSettingRow],
/// referring to a possible setting from [BoolGlobalSetting].
/// For settings in [BoolGlobalSetting] without a row in this table,
/// the setting's value is that of [BoolGlobalSetting.default_].
///
/// See also:
/// - [IntGlobalSettings], the int-valued counterpart of this table.
@DataClassName('BoolGlobalSettingRow')
class BoolGlobalSettings extends Table {
  /// The setting's name, a possible name from [BoolGlobalSetting].
  ///
  /// The table may have rows where [name] is not the name of any
  /// enum value in [BoolGlobalSetting].
  /// This happens if the app has previously run at a future or modified
  /// version which had additional values in that enum,
  /// and the user set one of those additional settings.
  /// The app ignores any such unknown rows.
  Column<String> get name => text()();

  /// The user's chosen value for the setting.
  ///
  /// This is non-nullable; if the user wants to revert to
  /// following the app's default for the setting,
  /// that can be expressed by deleting the row.
  Column<bool> get value => boolean()();

  @override
  Set<Column<Object>>? get primaryKey => {name};
}

/// The table of the user's int-valued, account-independent settings.
///
/// These apply across all the user's accounts on this client
/// (i.e. on this install of the app on this device).
///
/// Each row is a [IntGlobalSettingRow],
/// referring to a possible setting from [IntGlobalSetting].
/// For settings in [IntGlobalSetting] without a row in this table,
/// the setting's value is `null`.
///
/// See also:
/// - [BoolGlobalSettings], the bool-valued counterpart of this table.
@DataClassName('IntGlobalSettingRow')
class IntGlobalSettings extends Table {
  /// The setting's name, a possible name from [IntGlobalSetting].
  ///
  /// The table may have rows where [name] is not the name of any
  /// enum value in [IntGlobalSetting].
  /// This happens if the app has previously run at a future or modified
  /// version which had additional values in that enum,
  /// and the user set one of those additional settings.
  /// The app ignores any such unknown rows.
  TextColumn get name => text()();

  /// The user's chosen value for the setting.
  IntColumn get value => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {name};
}

/// The table of [Account] records in the app's database.
class Accounts extends Table {
  /// The ID of this account in the app's local database.
  ///
  /// This uniquely identifies the account within this install of the app,
  /// and never changes for a given account.  It has no meaning to the server,
  /// though, or anywhere else outside this install of the app.
  Column<int>    get id => integer().autoIncrement()();

  /// The URL of the Zulip realm this account is on.
  ///
  /// This corresponds to [GetServerSettingsResult.realmUrl].
  /// It never changes for a given account.
  Column<String> get realmUrl => text().map(const UriConverter())();

  /// The Zulip user ID of this account.
  ///
  /// This is the identifier the server uses for the account.
  /// It never changes for a given account.
  Column<int>    get userId => integer()();

  Column<String> get email => text()();
  Column<String> get apiKey => text()();

  Column<String> get zulipVersion => text()();
  Column<String> get zulipMergeBase => text().nullable()();
  Column<int>    get zulipFeatureLevel => integer()();

  Column<String> get ackedPushToken => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {realmUrl, userId},
    {realmUrl, email},
  ];
}

class UriConverter extends TypeConverter<Uri, String> {
  const UriConverter();
  @override String toSql(Uri value) => value.toString();
  @override Uri fromSql(String fromDb) => Uri.parse(fromDb);
}

@DriftDatabase(tables: [GlobalSettings, BoolGlobalSettings, IntGlobalSettings, Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  // When updating the schema:
  //  * Make the change in the table classes, and bump latestSchemaVersion.
  //  * Export the new schema and generate test migrations with drift:
  //    $ tools/check --fix drift
  //    and generate database code with build_runner.
  //    See ../../README.md#generated-files for more
  //    information on using the build_runner.
  //  * Write a migration in `_migrationSteps` below.
  //  * Write tests.
  static const int latestSchemaVersion = 11; // See note.

  @override
  int get schemaVersion => latestSchemaVersion;

  /// Drop all tables, indexes, etc., in the database.
  ///
  /// This includes tables that aren't known to the schema, for example because
  /// they were defined by a future (perhaps experimental) version of the app
  /// before switching back to the version currently running.
  static Future<void> _dropAll(Migrator m) async {
    final query = m.database.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table'");
    for (final row in await query.get()) {
      final data = row.data;
      final tableName = data['name'] as String;
      // Skip sqlite-internal tables.  See for comparison:
      //   https://www.sqlite.org/fileformat2.html#intschema
      //   https://github.com/simolus3/drift/blob/0901c984a/drift_dev/lib/src/services/schema/verifier_common.dart#L9-L22
      if (tableName.startsWith('sqlite_')) continue;
      // No need to worry about SQL injection; this table name
      // was already a table name in the database, not something
      // that should be affected by user data.
      await m.database.customStatement('DROP TABLE $tableName');
    }
  }

  static final MigrationStepWithVersion _migrationSteps = migrationSteps(
    from1To2: (m, schema) async {
      await m.addColumn(schema.accounts, schema.accounts.ackedPushToken);
    },
    from2To3: (m, schema) async {
      await m.createTable(schema.globalSettings);
    },
    from3To4: (m, schema) async {
      await m.addColumn(
        schema.globalSettings, schema.globalSettings.browserPreference);
    },
    from4To5: (m, schema) async {
      // Corresponds to the `into(globalSettings).insert` in `onCreate`.
      // This migration ensures there is a row in GlobalSettings.
      // (If the app already ran at schema 3 or 4, there will be;
      // if not, there won't be before this point.)
      final rows = await m.database.select(schema.globalSettings).get();
      if (rows.isEmpty) {
        await m.database.into(schema.globalSettings).insert(
          // No field values; just use the defaults for both fields.
          // (This is like `GlobalSettingsCompanion.insert()`, but
          // without dependence on the current schema.)
          RawValuesInsertable({}));
      }
    },
    from5To6: (m, schema) async {
      await m.createTable(schema.boolGlobalSettings);
    },
    from6To7: (m, schema) async {
      await m.addColumn(schema.globalSettings,
        schema.globalSettings.visitFirstUnread);
    },
    from7To8: (m, schema) async {
      await m.addColumn(schema.globalSettings,
        schema.globalSettings.markReadOnScroll);
    },
    from8To9: (m, schema) async {
      await m.addColumn(schema.globalSettings,
        schema.globalSettings.legacyUpgradeState);
      // Earlier versions of this app weren't built to be installed over
      // the legacy app.  So if upgrading from an earlier version of this app,
      // assume there wasn't also the legacy app before that.
      await m.database.update(schema.globalSettings).write(
        RawValuesInsertable({'legacy_upgrade_state': Constant('noLegacy')}));
    },
    from9To10: (m, schema) async {
      await m.createTable(schema.intGlobalSettings);
    },
    from10To11: (Migrator m, Schema11 schema) async {
      // To provide a smooth experience for users when they first install a new
      // version of the app with support for the "last visited account" feature,
      // we set the first available account as the last visited one. This way,
      // the user is still taken straight to the first account, just as they
      // were used to before, instead of being shown the "choose account" page.
      final firstAccountId = await (m.database.selectOnly(schema.accounts)
        ..addColumns([schema.accounts.id])
        ..limit(1)
      ).map((row) => row.read(schema.accounts.id)).getSingleOrNull();
      if (firstAccountId == null) return;

      // Like `globalStore.setLastVisitedAccount(firstAccountId)`,
      // as of the schema at the time of this migration.
      await m.database.into(schema.intGlobalSettings).insert(
        RawValuesInsertable({
          'name': Variable('lastVisitedAccountId'),
          'value': Variable(firstAccountId),
        }));
    },
  );

  Future<void> _createLatestSchema(Migrator m) async {
    assert(debugLog('Creating DB schema from scratch.'));
    await m.createAll();
    // Corresponds to `from4to5` above.
    await into(globalSettings).insert(GlobalSettingsCompanion());
    // Corresponds to (but differs from) part of `from8To9` above.
    await migrateLegacyAppData(this);
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: _createLatestSchema,
      onUpgrade: (Migrator m, int from, int to) async {
        if (from > to) {
          // This should only ever happen in dev.  As a dev convenience,
          // drop everything from the database and start over.
          // TODO(log): log schema downgrade as an error
          assert(debugLog('Downgrading DB schema from v$from to v$to.'));

          // In the actual app, the target schema version is always
          // the latest version as of the code that's being run.
          // Migrating to earlier versions is useful only for isolating steps
          // in migration tests; we can forego that for testing downgrades.
          assert(to == latestSchemaVersion);

          await _dropAll(m);
          await _createLatestSchema(m);
          return;
        }
        assert(1 <= from && from <= to && to <= latestSchemaVersion);

        assert(debugLog('Upgrading DB schema from v$from to v$to.'));
        await m.runMigrationSteps(from: from, to: to, steps: _migrationSteps);
      });
  }

  Future<GlobalSettingsData> getGlobalSettings() async {
    // The migrations ensure there is a row.
    return await (select(globalSettings)..limit(1)).getSingle();
  }

  Future<Map<BoolGlobalSetting, bool>> getBoolGlobalSettings() async {
    final result = <BoolGlobalSetting, bool>{};
    final rows = await select(boolGlobalSettings).get();
    for (final row in rows) {
      final setting = BoolGlobalSetting.byName(row.name);
      if (setting == null) continue;
      result[setting] = row.value;
    }
    return result;
  }

  Future<Map<IntGlobalSetting, int>> getIntGlobalSettings() async {
    return {
      for (final row in await select(intGlobalSettings).get())
        if (IntGlobalSetting.byName(row.name) case final setting?)
          setting: row.value
    };
  }

  Future<int> createAccount(AccountsCompanion values) async {
    try {
      return await into(accounts).insert(values);
    } catch (e) {
      // Unwrap cause if it's a remote Drift call. On the app, it's running
      // via a remote, but on local tests, it's running natively so
      // unwrapping is not required.
      final cause = (e is DriftRemoteException) ? e.remoteCause : e;
      if (cause case SqliteException(
              extendedResultCode: SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE)) {
        throw AccountAlreadyExistsException();
      }
      rethrow;
    }
  }
}

class AccountAlreadyExistsException implements Exception {}
