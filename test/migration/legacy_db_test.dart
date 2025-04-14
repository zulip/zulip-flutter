import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:drift/native.dart';
import 'package:zulip/migration/legacy_app_data.dart';
import 'package:zulip/migration/migration_db.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/settings.dart';
import '../model/database_test.dart';
import '../stdlib_checks.dart';
import 'text_decompression_test.dart' as decompression_test;

void main() {
  late LegacyDatabase db;
  setUp(() async {
    db = LegacyDatabase(NativeDatabase.memory());
    LegacyAppData.db = db;
    await db.customStatement(
      "CREATE TABLE keyvalue (key TEXT PRIMARY KEY, value TEXT)",
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('LegacyDatabase.getItem', () {
    test('should return uncompressed value', () async {
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('testKey', 'testValue')",
      );
      final result = await db.getItem('testKey');

      check(result).equals('testValue');
    });

    test('should return decompressed value for compressed data', () async {
      final compressedValue = decompression_test.compressedAccountStr;
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('testKey', ?)",
        [compressedValue],
      );
      final result = await db.getItem('testKey');

      check(result).equals(decompression_test.accountStr);
    });

    test('should return null for non-existent key', () async {
      final result = await db.getItem('nonExistentKey');

      check(result).isNull();
    });

    test('should throw exception for unknown compression format', () async {
      final unknownCompressedValue = 'z|unknown|data';
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('testKey', ?)",
        [unknownCompressedValue],
      );

      await expectLater(db.getItem('testKey'), throwsA(isA<Exception>()));
    });
  });

  group('LegacyAppData.getgetAccountsData', () {
    test('Inserting data to the Flutter app DB', () async {
      AppDatabase appDb = AppDatabase(NativeDatabase.memory());
      final accountsData = '''
    [
      {
      "realm":{"data":"https://chat.example","__serializedType__":"URL"},
      "email": "me@example.com",
      "apiKey": "1234",
      "userId": 22,
      "zulipVersion":{"data":"10.0-119-g111c1357ad","__serializedType__":"ZulipVersion"},
      "zulipFeatureLevel": 123,
      "ackedPushToken" : null,
      "lastDismissedServerPushSetupNotice" : null
      },
      {
      "realm":{"data":"https://lolo.example","__serializedType__":"URL"},
      "email": "you@example.com",
      "apiKey": "4567",
      "userId": 23,
      "zulipVersion":{"data":"10.0-119-g111c1357ad","__serializedType__":"ZulipVersion"},
      "zulipFeatureLevel": 123,
      "ackedPushToken" : null,
      "lastDismissedServerPushSetupNotice" : null
      }
    ]
    ''';
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('reduxPersist:accounts', ?)",
        [accountsData],
      );
      LegacyAppData.version = 33;
      final result = await LegacyAppData.getAccountsData();

      check(result).isNotNull();
      check(result!.length).equals(2);
      for (var account in result) {
        final values = AccountsCompanion(
          realmUrl: Value(account.realm!),
          userId:
              account.userId != null ? Value(account.userId!) : Value.absent(),
          email: Value(account.email!),
          apiKey: Value(account.apiKey!),
          zulipVersion:
              account.zulipVersion != null
                  ? Value(account.zulipVersion!)
                  : Value.absent(),
          zulipFeatureLevel:
              account.zulipFeatureLevel != null
                  ? Value(account.zulipFeatureLevel!)
                  : Value.absent(),
          ackedPushToken:
              account.ackedPushToken != null
                  ? Value(account.ackedPushToken!)
                  : Value.absent(),
        );
        // insert the values into the database and get the id
        final accountId = await appDb.createAccount(values);
        // check that the account is inserted successfully
        final insertedAccount =
            await (appDb.select(appDb.accounts)
              ..where((a) => a.id.equals(accountId))).watchSingle().first;
        check(insertedAccount.toCompanion(true).toJson()).deepEquals({
          ...values.toJson(),
          'id': (Subject<Object?> it) => it.isA<int>(),
        });
      }
      await appDb.close();
    });

    test('should return null for null accounts data', () async {
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('reduxPersist:accounts', NULL)",
      );
      final result = await LegacyAppData.getAccountsData();

      check(result).isNull();
    });
  });

  group('LegacyAppData.getSettingsData', () {
    test('should return null for null settings data', () async {
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('reduxPersist:settings', NULL)",
      );
      final result = await LegacyAppData.getSettingsData();

      check(result).isNull();
    });

    test('should return uncompressed settings data', () async {
      final settingsData = '''
    {
      "language":"en",
      "theme":"night",
      "browser":"default",
      "experimentalFeaturesEnabled":false,
      "markMessagesReadOnScroll":"always",
      "offlineNotification":true,
      "onlineNotification":true,
      "streamNotification":false,
      "displayEmojiReactionUsers":true
    }
    ''';
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('reduxPersist:settings', ?)",
        [settingsData],
      );
      LegacyAppData.version = 66;
      final result = await LegacyAppData.getSettingsData();

      check(result).isNotNull();
      check(result).deepEquals({
        "language":"en",
        "theme":"night",
        "browser":"default",
        "experimentalFeaturesEnabled":false,
        "markMessagesReadOnScroll":"always",
        "offlineNotification":true,
        "onlineNotification":true,
        "streamNotification":false,
        "displayEmojiReactionUsers":true
      });
    });

    test('Inserting settings data to Flutter DB', () async {
      AppDatabase appDb = AppDatabase(NativeDatabase.memory());
      final settingsData = '''
      {
      "language":"en",
      "theme":"night",
      "browser":"default",
      "experimentalFeaturesEnabled":false,
      "markMessagesReadOnScroll":"always",
      "offlineNotification":true,
      "onlineNotification":true,
      "streamNotification":false,
      "displayEmojiReactionUsers":true
      }''';
      await db.customStatement(
        "INSERT INTO keyvalue (key, value) VALUES ('reduxPersist:settings', ?)",
        [settingsData],
      );
      LegacyAppData.version = 66;
      final settings = await LegacyAppData.getSettingsData();
      check(settings).isNotNull();
      await appDb.populateLegacySettingsData(settings!);

      final globalSettings = appDb.globalSettings;
      GlobalSettingsCompanion expectedPopulatedSettings = GlobalSettingsCompanion(
        themeSetting: Value(ThemeSetting.dark),
        browserPreference: Value(BrowserPreference.external),
      );
      final actualSettings = await appDb.select(globalSettings).getSingle();
      check(actualSettings.toCompanion(true).toJson()).deepEquals({
        ...expectedPopulatedSettings.toJson(),
      });

      await appDb.close();
    });
  });
}
