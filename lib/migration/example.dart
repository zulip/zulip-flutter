import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:drift/native.dart';

import 'legacy_account.dart';
import 'migration_db.dart';
import 'migration_utils.dart' as utils;

var base = """
[{
"realm":"https://chat.example/",
"email":"me@example.com",
"apiKey":"1234"
}]
""";

var base12 = """
[{
"realm":"https://chat.example/",
"email":"me@example.com",
"apiKey":"1234",
"zulipVersion":"10.0-119-g111c1357ad"
}]
""";

var base13 = """
[{
"realm":"https://chat.example/",
"email":"me@example.com",
"apiKey":"1234",
"zulipVersion":{"data":"10.0-119-g111c1357ad","__serializedType__":"ZulipVersion"}
}]
""";

main() async {
  // Example usage
  // should be /data/data/com.zulipmobile/files/SQLite/zulip.db
  // var path = 'E:\\zulip_data\\zulipmobile_backup\\apps\\com.zulipmobile\\f\\SQLite\\zulip.db';
  // final executor = NativeDatabase(File(path));
  // final db = MinimalDatabase(executor);
  // String? accounts;
  // int version = -1;
  // try {
  //   version = await db.getVersion();
  //   accounts = await db.getItem('reduxPersist:accounts');
  // } catch (e) {
  //   log('Error: $e');
  // } finally {
  //   // Clean up by closing the database
  //   await db.close();
  // }
  dynamic json = jsonDecode(base, reviver: utils.reviver);
  Map<String,dynamic> jsonMap = json[0] as Map<String,dynamic>;
  var res = LegacyAccount.applyMigrations(jsonMap, 6);
  if (res != null) {
    LegacyAccount account = LegacyAccount.fromJson(jsonMap);
    print(account);
  }
}
