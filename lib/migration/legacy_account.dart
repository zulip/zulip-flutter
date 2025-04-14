import 'package:drift/drift.dart';

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


  /// This method should return the json data of the account in the latest version
  /// of migrations or null if the data can't be migrated.
  static Map<String, dynamic>? applyMigrations(Map<String, dynamic> json, int version) {
    if (version < 9) {
      // json['ackedPushToken'] should be set to null
      json['ackedPushToken'] = null;
    }

    if (version < 11) {
      // removes multiple trailing slashes from json['realm'].
      json['realm'] = json['realm'].replaceAll(RegExp(r'/+$'), '');
    }

    if (version < 12) {
      // Add zulipVersion to accounts.
      json['zulipVersion'] = null;
    }

    // if (version < 13) {
    // this should convert json['zulipVersion'] from `string | null` to `ZulipVersion | null`
    // but we already have it as `string | null` in this app so no point of
    // doing this then making it string back
    // }

    if (version < 14) {
      // Add zulipFeatureLevel to accounts.
      json['zulipFeatureLevel'] = null;
    }

    if (version < 15) {
      // json['realm'] is a string not uri
      json['realm'] = Uri.parse(json['realm'] as String);
    }

    if (version < 27) {
      // Remove accounts with "in-progress" login state (empty json['email'])
      // make all fields null
      if (json['email'] == null || json['email'] == '') {
        return null;
      }
    }

    if (version < 33) {
      // Add userId to accounts.
      json['userId'] = null;
    }

    if (version < 36) {
      // Add lastDismissedServerPushSetupNotice to accounts.
      json['lastDismissedServerPushSetupNotice'] = null;

    }

    if (version < 58) {
      const requiredKeys = [
        'realm',
        'apiKey',
        'email',
        'userId',
        'zulipVersion',
        'zulipFeatureLevel',
        'ackedPushToken',
        'lastDismissedServerPushSetupNotice',
      ];
      bool hasAllRequiredKeys = requiredKeys.every((key) => json.containsKey(key));
      if (!hasAllRequiredKeys) {
        return null;
      }
    }

    if (version < 62) {
      // Add silenceServerPushSetupWarnings to accounts.
      json['silenceServerPushSetupWarnings'] = false;
    }

    if (version < 66) {
      // Add lastDismissedServerNotifsExpiringBanner to accounts.
      json['lastDismissedServerNotifsExpiringBanner'] = null;
    }
    return json;
  }
}