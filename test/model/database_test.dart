import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/settings.dart';

import 'schemas/schema.dart';
import 'schemas/schema_v1.dart' as v1;
import 'schemas/schema_v2.dart' as v2;
import 'schemas/schema_v3.dart' as v3;
import 'schemas/schema_v4.dart' as v4;
import 'schemas/schema_v5.dart' as v5;
import 'store_checks.dart';

void main() {
  group('non-migration tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await database.close();
    });

    test('initialize GlobalSettings with defaults', () async {
      check(await database.getGlobalSettings()).themeSetting.isNull();
    });

    test('does not crash if multiple global settings rows', () async {
      await database.into(database.globalSettings)
        .insert(const GlobalSettingsCompanion(themeSetting: Value(ThemeSetting.dark)));

      check(await database.select(database.globalSettings).get()).length.equals(2);
      check(await database.getGlobalSettings()).themeSetting.isNull();
    });

    test('GlobalSettings updates work', () async {
      check(await database.getGlobalSettings())
        .themeSetting.isNull();

      // As in doUpdateGlobalSettings.
      await database.update(database.globalSettings)
        .write(GlobalSettingsCompanion(themeSetting: Value(ThemeSetting.dark)));
      check(await database.getGlobalSettings())
        .themeSetting.equals(ThemeSetting.dark);
    });

    test('create account', () async {
      final accountData = AccountsCompanion.insert(
        realmUrl: Uri.parse('https://chat.example/'),
        userId: 1,
        email: 'asdf@example.org',
        apiKey: '1234',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      );
      final accountId = await database.createAccount(accountData);
      final account = await (database.select(database.accounts)
            ..where((a) => a.id.equals(accountId)))
          .watchSingle()
          .first;
      check(account.toCompanion(false).toJson()).deepEquals({
        ...accountData.toJson(),
        'id': (Subject<Object?> it) => it.isA<int>(),
        'acked_push_token': null,
      });
    });

    test('create account with same realm and userId ', () async {
      final accountData = AccountsCompanion.insert(
        realmUrl: Uri.parse('https://chat.example/'),
        userId: 1,
        email: 'asdf@example.org',
        apiKey: '1234',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      );
      final accountDataWithSameUserId = AccountsCompanion.insert(
        realmUrl: Uri.parse('https://chat.example/'),
        userId: 1,
        email: 'otheremail@example.org',
        apiKey: '12345',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      );
      await database.createAccount(accountData);
      await check(database.createAccount(accountDataWithSameUserId))
        .throws<AccountAlreadyExistsException>();
    });

    test('create account with same realm and email', () async {
      final accountData = AccountsCompanion.insert(
        realmUrl: Uri.parse('https://chat.example/'),
        userId: 1,
        email: 'asdf@example.org',
        apiKey: '1234',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      );
      final accountDataWithSameEmail = AccountsCompanion.insert(
        realmUrl: Uri.parse('https://chat.example/'),
        userId: 2,
        email: 'asdf@example.org',
        apiKey: '12345',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      );
      await database.createAccount(accountData);
      await check(database.createAccount(accountDataWithSameEmail))
        .throws<AccountAlreadyExistsException>();
    });
  });

  group('migrations', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(GeneratedHelper());
    });

    test('downgrading', () async {
      final schema = await verifier.schemaAt(2);

      // This simulates the scenario during development when running the app
      // with a future schema version that has additional tables and columns.
      final before = AppDatabase(schema.newConnection());
      await before.customStatement('CREATE TABLE test_extra (num int)');
      await before.customStatement('ALTER TABLE accounts ADD extra_column int');
      await check(verifier.migrateAndValidate(
        before, 2, validateDropped: true)).throws<SchemaMismatch>();
      // Override the schema version by modifying the underlying value
      // drift internally keeps track of in the database.
      // TODO(drift): Expose a better interface for testing this.
      await before.customStatement('PRAGMA user_version = 999;');
      await before.close();

      // Simulate starting up the app, with an older schema version that
      // does not have the extra tables and columns.
      final after = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(after, 2, validateDropped: true);
      await after.close();
    });

    group('migrate without data', () {
      const versions = GeneratedHelper.versions;
      final latestVersion = versions.last;

      int prev = versions.first;
      for (final toVersion in versions.skip(1)) {
        final fromVersion = prev;
        test('from v$fromVersion to v$toVersion', () async {
          final connection = await verifier.startAt(fromVersion);
          final db = AppDatabase(connection);
          await verifier.migrateAndValidate(db, toVersion);
          await db.close();
        });
        prev = toVersion;
      }

      for (final fromVersion in versions) {
        if (fromVersion == latestVersion) break;
        test('from v$fromVersion to latest (v$latestVersion)', () async {
          final connection = await verifier.startAt(fromVersion);
          final db = AppDatabase(connection);
          await verifier.migrateAndValidate(db, latestVersion);
          await db.close();
        });
      }
    });

    test('upgrade to v2, with data', () async {
      final schema = await verifier.schemaAt(1);
      final before = v1.DatabaseAtV1(schema.newConnection());
      await before.into(before.accounts).insert(v1.AccountsCompanion.insert(
        realmUrl: 'https://chat.example/',
        userId: 1,
        email: 'asdf@example.org',
        apiKey: '1234',
        zulipVersion: '6.0',
        zulipMergeBase: const Value('6.0'),
        zulipFeatureLevel: 42,
      ));
      final accountV1 = await before.select(before.accounts).watchSingle().first;
      await before.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
      await db.close();

      final after = v2.DatabaseAtV2(schema.newConnection());
      final account = await after.select(after.accounts).getSingle();
      check(account.toJson()).deepEquals({
        ...accountV1.toJson(),
        'ackedPushToken': null,
      });
      await after.close();
    });

    test('upgrade to v4, with data', () async {
      final schema = await verifier.schemaAt(3);
      final before = v3.DatabaseAtV3(schema.newConnection());
      await before.into(before.globalSettings).insert(
        v3.GlobalSettingsCompanion.insert(
          themeSetting: Value(ThemeSetting.light.name)));
      await before.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);
      await db.close();

      final after = v4.DatabaseAtV4(schema.newConnection());
      final globalSettings = await after.select(after.globalSettings).getSingle();
      check(globalSettings.themeSetting).equals(ThemeSetting.light.name);
      check(globalSettings.browserPreference).isNull();
      await after.close();
    });

    test('upgrade to v5: with existing GlobalSettings row, do nothing', () async {
      final schema = await verifier.schemaAt(4);
      final before = v4.DatabaseAtV4(schema.newConnection());
      await before.into(before.globalSettings).insert(
        v4.GlobalSettingsCompanion.insert(
          themeSetting: Value(ThemeSetting.light.name)));
      await before.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 5);
      await db.close();

      final after = v5.DatabaseAtV5(schema.newConnection());
      final globalSettings = await after.select(after.globalSettings).getSingle();
      check(globalSettings.themeSetting).equals(ThemeSetting.light.name);
      check(globalSettings.browserPreference).isNull();
      await after.close();
    });

    test('upgrade to v5: with no existing GlobalSettings row, insert one', () async {
      final schema = await verifier.schemaAt(4);
      final before = v4.DatabaseAtV4(schema.newConnection());
      check(await before.select(before.globalSettings).get()).isEmpty();
      await before.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 5);
      await db.close();

      final after = v5.DatabaseAtV5(schema.newConnection());
      final globalSettings = await after.select(after.globalSettings).getSingle();
      check(globalSettings.themeSetting).isNull();
      check(globalSettings.browserPreference).isNull();
      await after.close();
    });
  });
}

extension UpdateCompanionExtension<T> on UpdateCompanion<T> {
  Map<String, Object?> toJson() {
    // Compare sketches of this idea in discussion at:
    //   https://github.com/simolus3/drift/issues/1924
    // To go upstream, this would need to handle DateTime
    // and Uint8List variables, and would need a fromJson.
    // Also should document that the keys are column names,
    // not Dart field names.  (The extension is on UpdateCompanion
    // rather than Insertable to avoid confusion with the toJson
    // on DataClass row classes, which use Dart field names.)
    return {
      for (final kv in toColumns(false).entries)
        kv.key: (kv.value as Variable).value
    };
  }
}
