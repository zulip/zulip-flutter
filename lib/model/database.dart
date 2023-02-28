import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Accounts extends Table {
  Column<int>    get id => integer().autoIncrement()();

  Column<String> get realmUrl => text()();
  Column<int>    get userId => integer()();

  Column<String> get email => text()();
  Column<String> get apiKey => text()();

  Column<String> get zulipVersion => text()();
  Column<int>    get zulipFeatureLevel => integer()();

  Column<String> get ackedPushToken => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {realmUrl, userId},
    {realmUrl, email},
  ];
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // TODO decide if this path is the right one to use
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  AppDatabase.live() : this(_openConnection());

  // When updating the schema:
  //  * Make the change in the table classes, and bump schemaVersion.
  //  * Export the new schema:
  //    $ dart run drift_dev schema dump lib/model/database.dart test/model/schemas/
  //  * Generate test migrations from the schemas:
  //    $ dart run drift_dev schema generate --data-classes --companions test/model/schemas/ test/model/generated_migrations/
  //  * Write a migration in `onUpgrade` below.
  //  * Write tests.
  @override
  int get schemaVersion => 2; // See note.

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2 && 2 <= to) {
          await m.addColumn(accounts, accounts.ackedPushToken);
        }
      }
    );
  }

  Future<int> createAccount(AccountsCompanion values) {
    return into(accounts).insert(values);
  }
}
