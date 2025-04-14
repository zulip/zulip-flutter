import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'migration_db.dart';
import 'migration_utils.dart' as utils;

class LegacyAppData {
  static late LegacyDatabase db;
  static late int version;
  LegacyAppData();

  /// Initializes the migration process by opening the database and checking its version.
  static Future<bool> init() async {
    try {
      // this should map to /data/data/com.zulipmobile/files/SQLite/zulip.db
      // its not tested yet.
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'SQLite', 'zulip.db');
      final executor = NativeDatabase(File(dbPath));
      db = LegacyDatabase(executor);
      version = await db.getVersion();
      if (version == -1) {
        return false;
      }
    }
    catch (e) {
      log('Legacy Migration Error: $e');
      return false;
    }
    return true;
  }

  static Future<void> close() async {
    await db.close();
  }

  /// gets the accounts stored in the legacy app database and apply necessary migrations.
  static Future<List<LegacyAccount>?> getAccountsData() async {
    try {
      var accounts = await db.getItem('reduxPersist:accounts');
      if (accounts == null) {
        return null;
      }
      List<LegacyAccount> accountsList = [];
      final accountList = jsonDecode(accounts, reviver: utils.reviver) as List<dynamic>;
      for(var i = 0; i < accountList.length; i++) {
        final account = accountList[i] as Map<String,dynamic>;
        var res = LegacyAppMigrations.applyAccountMigrations(account, version);
        if (res != null ) {

          LegacyAccount accountData = LegacyAccount.fromJson(account);
          accountsList.add(accountData);
        }
      }
      if (accountsList.isNotEmpty) {
        return accountsList;
      }
    } catch (e) {
      log('Legacy Migration Error: $e');
    }
    return null;
  }

  /// gets the settings stored in the legacy app database and apply necessary migrations.
  static Future<Map<String, dynamic>?> getSettingsData() async {
    try {
      var jsonSettings = await db.getItem('reduxPersist:settings');
      if (jsonSettings == null) {
        return null;
      }
      var settings = jsonDecode(jsonSettings) as Map<String,dynamic>;
      var res = LegacyAppMigrations.applySettingMigrations(settings, version);
      if (res != null) {
        return res;
      }
    } catch (e) {
      log('Legacy Migration Error: $e');
    }
    return null;
  }
}


class LegacyAccount {
  final Uri? realm;
  final String? apiKey;
  final String? email;
  final int? userId;
  final String? zulipVersion;
  final int? zulipFeatureLevel;
  final String? ackedPushToken;
  final DateTime? lastDismissedServerPushSetupNotice;
  final DateTime? lastDismissedServerNotifsExpiringBanner;
  final bool? silenceServerPushSetupWarnings;

  LegacyAccount({
    this.realm,
    this.apiKey,
    this.email,
    this.userId,
    this.zulipVersion,
    this.zulipFeatureLevel,
    this.ackedPushToken,
    this.lastDismissedServerPushSetupNotice,
    this.lastDismissedServerNotifsExpiringBanner,
    this.silenceServerPushSetupWarnings,
  });

  factory LegacyAccount.fromJson(
      Map<String, dynamic> json, {
        ValueSerializer? serializer,
      }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyAccount(
      realm: serializer.fromJson<Uri?>(json['realm']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      email: serializer.fromJson<String?>(json['email']),
      userId: serializer.fromJson<int?>(json['userId']),
      zulipVersion: serializer.fromJson<String?>(json['zulipVersion']),
      zulipFeatureLevel: serializer.fromJson<int?>(json['zulipFeatureLevel']),
      ackedPushToken: serializer.fromJson<String?>(json['ackedPushToken']),
      lastDismissedServerPushSetupNotice: serializer.fromJson<DateTime?>(
          json['lastDismissedServerPushSetupNotice']),
      lastDismissedServerNotifsExpiringBanner: serializer.fromJson<DateTime?>(
          json['lastDismissedServerNotifsExpiringBanner']),
      silenceServerPushSetupWarnings: serializer.fromJson<bool?>(
          json['silenceServerPushSetupWarnings']),
    );
  }

  @override
  String toString() {
    return 'LegacyAccount{realm: $realm, apiKey: $apiKey,'
        ' email: $email, userId: $userId, zulipVersion: $zulipVersion,'
        ' zulipFeatureLevel: $zulipFeatureLevel, ackedPushToken: $ackedPushToken,'
        ' lastDismissedServerPushSetupNotice: $lastDismissedServerPushSetupNotice,'
        ' lastDismissedServerNotifsExpiringBanner: $lastDismissedServerNotifsExpiringBanner,'
        ' silenceServerPushSetupWarnings: $silenceServerPushSetupWarnings}';
  }
}