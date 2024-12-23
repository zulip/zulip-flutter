import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/database.dart';

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
  });

  group('migrations', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(GeneratedHelper());
    });

    test('upgrade to v2, empty', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 2);
      await db.close();
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
