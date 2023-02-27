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

  @override
  int get schemaVersion => 1; // TODO migrations

  Future<int> createAccount(AccountsCompanion values) {
    return into(accounts).insert(values);
  }
}
