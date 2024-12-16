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

void main() {
  group('non-migration tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await database.close();
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

    test('initialize GlobalSettings with defaults', () async {
      check(await database.ensureGlobalSettings())
        .themeSetting.equals(ThemeSetting.unset);
    });

    test('ensure single GlobalSettings row', () async {
      check(await database.select(database.globalSettings).getSingleOrNull())
        .isNull();

      final globalSettings = await database.ensureGlobalSettings();
      check(await database.select(database.globalSettings).getSingle())
        .equals(globalSettings);

      // Subsequent calls to `ensureGlobalSettings` do not insert new rows.
      check(await database.ensureGlobalSettings()).equals(globalSettings);
      check(await database.select(database.globalSettings).getSingle())
        .equals(globalSettings);
    });
  });

  group('migrations', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(GeneratedHelper());
    });

    test('downgrading', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 1);
      await db.close();
    }, skip: true); // TODO(#1172): unskip this

    group('migrate without data', () {
      // These simple tests verify all possible schema updates with a simple (no
      // data) migration. This is a quick way to ensure that written database
      // migrations properly alter the schema.
      const versions = GeneratedHelper.versions;
      for (final (i, fromVersion) in versions.indexed) {
        group('from $fromVersion', () {
          for (final toVersion in versions.skip(i + 1)) {
            test('to $toVersion', () async {
              final schema = await verifier.schemaAt(fromVersion);
              final db = AppDatabase(schema.newConnection());
              await verifier.migrateAndValidate(db, toVersion);
              await db.close();
            });
          }
        });
      }
    });

    // Testing this can be useful for migrations that change existing columns
    // (e.g. by alterating their type or constraints). Migrations that only add
    // tables or columns typically don't need these advanced tests. For more
    // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
    group('migrate with data', () {
      test('upgrade to v2', () async {
        late final v1.AccountsData oldAccountData;
        await verifier.testWithDataIntegrity(
          oldVersion: 1, createOld: v1.DatabaseAtV1.new,
          newVersion: 2, createNew: v2.DatabaseAtV2.new,
          openTestedDatabase: AppDatabase.new,
          createItems: (batch, oldDb) async {
            await oldDb.into(oldDb.accounts).insert(v1.AccountsCompanion.insert(
              realmUrl: 'https://chat.example/',
              userId: 1,
              email: 'asdf@example.org',
              apiKey: '1234',
              zulipVersion: '6.0',
              zulipMergeBase: const Value('6.0'),
              zulipFeatureLevel: 42,
            ));
            oldAccountData = await oldDb.select(oldDb.accounts).watchSingle().first;
          },
          validateItems: (newDb) async {
            final account = await newDb.select(newDb.accounts).getSingle();
            check(account.toJson()).deepEquals({
              ...oldAccountData.toJson(),
              'ackedPushToken': null,
            });
          });
      });
    });

    test('upgrade to v3', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 3);
      await db.close();
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

extension GlobalSettingsDataChecks on Subject<GlobalSettingsData> {
  Subject<ThemeSetting> get themeSetting => has((x) => x.themeSetting, 'themeSetting');
}
