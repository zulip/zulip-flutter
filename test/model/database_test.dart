import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await database.close();
  });

  test('create account', () async {
    // TODO use example_data
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
      'id': it(),
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
