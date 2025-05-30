import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/migration/migration_db.dart';

import '../stdlib_checks.dart';


void main() {
  group('LegacyAppMigrations.applyAccountMigrations', () {
    final baseAccount = <String, dynamic>{
      'email': 'me@example.com',
      'apiKey': '1234',
      'realm': 'https://chat.example',
    };

    test('version 3 to final version', () {
      final migrated = LegacyAppMigrations.applyAccountMigrations(
        {...baseAccount},
        3,
      );

      check(migrated).deepEquals({
        'email': 'me@example.com',
        'apiKey': '1234',
        'realm': Uri.parse('https://chat.example'),
        'ackedPushToken': null,
        'zulipFeatureLevel': null,
        'zulipVersion': null,
        'lastDismissedServerPushSetupNotice': null,
        'userId': null,
        'silenceServerPushSetupWarnings': false,
        'lastDismissedServerNotifsExpiringBanner': null,
      });
    });

    test('version 27 removes accounts with empty email', () {
      final input = <Map<String, dynamic>>[
        {...baseAccount},
        {'email': '', 'apiKey': '9999', 'realm': 'https://bad.example'},
      ];
      final migrated = input
          .map((a) => LegacyAppMigrations.applyAccountMigrations(a, 3))
          .where((a) => a != null)
          .toList();

      check(migrated.length).equals(1);
      check(migrated.first!['email']).equals('me@example.com');
    });

    test('version 58 removes any account which has a missing requiredKeys',() {
      final migrated = LegacyAppMigrations.applyAccountMigrations(
        {...baseAccount},
        57,
      );

      check(migrated).isNull();
    });
  });

  group('LegacyAppMigrations.applySettingMigrations', () {
    final baseSettings = <String, dynamic>{
      'locale': 'en',
      'theme': 'default',
      'offlineNotification': true,
      'onlineNotification': true,
      'experimentalFeaturesEnabled': false,
      'streamNotification': false,
    };

    test('version 3 to final version', () {
      final migrated = LegacyAppMigrations.applySettingMigrations(
        {...baseSettings},
        3,
      );

      check(migrated).deepEquals({
        'language': 'en',
        'theme': 'default',
        'offlineNotification': true,
        'onlineNotification': true,
        'experimentalFeaturesEnabled': false,
        'streamNotification': false,
        'browser': 'default',
        'markMessagesReadOnScroll': 'always',
      });
    });

    test('version 26 renames locale "id-ID" to language "id"', () {
      final migrated = LegacyAppMigrations.applySettingMigrations(
        {
          ...baseSettings,
          'locale': 'id-ID',
        },
        25,
      );
      check(migrated!['language']).equals('id');
      check(migrated).not((it) => it.containsKey('locale'));
    });

    test('version 52: doNotMarkMessagesAsRead to markMessagesReadOnScroll', () {
      final migrated = LegacyAppMigrations.applySettingMigrations(
        {
          ...baseSettings,
          'doNotMarkMessagesAsRead': false,
        },
        51,
      );

      check(migrated!['markMessagesReadOnScroll']).equals('always');
    });
  });
}
