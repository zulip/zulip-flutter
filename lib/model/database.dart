import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:sqlite3/common.dart';

import 'schema_versions.g.dart';
import 'settings.dart';

part 'database.g.dart';

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

/// The table of the user's chosen settings independent of account, on this
/// client.
///
/// These apply across all the user's accounts on this client (i.e. on this
/// install of the app on this device).
@DataClassName('GlobalSettingsData')
class GlobalSettings extends Table {
  Column<String> get themeSetting => textEnum<ThemeSetting>()
    .withDefault(const Variable('unset'))();

  Column<String> get browserPreference => textEnum<BrowserPreference>()
    .nullable()();
}

class UriConverter extends TypeConverter<Uri, String> {
  const UriConverter();
  @override String toSql(Uri value) => value.toString();
  @override Uri fromSql(String fromDb) => Uri.parse(fromDb);
}

@DriftDatabase(tables: [Accounts, GlobalSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  // When updating the schema:
  //  * Make the change in the table classes, and bump schemaVersion.
  //  * Export the new schema and generate test migrations with drift:
  //    $ tools/check --fix drift
  //    and generate database code with build_runner.
  //  * Write a migration in `onUpgrade` below.
  //  * Write tests.
  @override
  int get schemaVersion => 4; // See note.

  Future<void> _resetDatabase(Migrator m) async {
    // This should only ever happen in dev.  As a dev convenience,
    // drop everything from the database and start over.
    await m.database.transaction(() async {
      final query = m.database.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'");
      for (final row in await query.get()) {
        final data = row.data;
        final tableName = data['name'] as String;
        // Skip sqlite-internal tables, https://www.sqlite.org/fileformat2.html#intschema
        // https://github.com/simolus3/drift/blob/0901c984a987e54ba0b67e227adbfdcf3c08eeb4/drift_dev/lib/src/services/schema/verifier_common.dart#L9-L22
        if (tableName.startsWith('sqlite_')) continue;
        // SQL injection could be a concern, but the database would've been
        // compromised if the table name is corrupted.
        await m.database.customStatement('DROP TABLE $tableName');
      }
      await m.createAll();
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from > to) {
          // TODO(log): log schema downgrade as an error
          await _resetDatabase(m);
          return;
        }
        assert(1 <= from && from <= to && to <= schemaVersion);

        await m.runMigrationSteps(from: from, to: to,
          steps: migrationSteps(
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
          ));
      });
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

  Future<GlobalSettingsData> ensureGlobalSettings() async {
    final settings = await select(globalSettings).getSingleOrNull();
    // TODO(db): Enforce the singleton constraint more robustly.
    if (settings != null) {
      return settings;
    }

    await into(globalSettings).insert(GlobalSettingsCompanion.insert());
    return select(globalSettings).getSingle();
  }
}

class AccountAlreadyExistsException implements Exception {}
