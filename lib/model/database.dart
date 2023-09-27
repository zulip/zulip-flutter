import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Accounts extends Table {
  Column<int>    get id => integer().autoIncrement()();

  Column<String> get realmUrl => text().map(const UriConverter())();
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
  //    $ dart run drift_dev schema generate --data-classes --companions test/model/schemas/ test/model/schemas/
  //  * Write a migration in `onUpgrade` below.
  //  * Write tests.
  // TODO encapsulate those `drift_dev schema` commands into tools/check or the like
  @override
  int get schemaVersion => 2; // See note.

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from > to) {
          // TODO(log): log schema downgrade as an error
          // This should only ever happen in dev.  As a dev convenience,
          // drop everything from the database and start over.
          for (final entity in allSchemaEntities) {
            // This will miss any entire tables (or indexes, etc.) that
            // don't exist at this version.  For a dev-only feature, that's OK.
            await m.drop(entity);
          }
          await m.createAll();
          return;
        }
        assert(1 <= from && from <= to && to <= schemaVersion);

        if (from < 2 && 2 <= to) {
          await m.addColumn(accounts, accounts.ackedPushToken);
        }
        // New migrations go here.
      }
    );
  }

  Future<int> createAccount(AccountsCompanion values) {
    return into(accounts).insert(values);
  }
}
