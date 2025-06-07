import 'dart:convert';
import 'package:drift/drift.dart';

import 'migration_utils.dart' as utils;


class LegacyDatabase extends GeneratedDatabase {
  LegacyDatabase(super.e);

  @override
  Iterable<TableInfo<Table,dynamic>> get allTables => [];

  @override
  int get schemaVersion => 1;

  Future<List<Map<String, dynamic>>> rawQuery(String query) {
    return customSelect(query).map((row) => row.data).get();
  }

  Future<int> getVersion() async {
    String? item = await getItem('reduxPersist:migrations');
    if (item == null) {
      return -1;
    }
    var decodedValue = jsonDecode(item);
    var version = decodedValue['version'] as int;
    return version;
  }
  // This method is from the legacy RN codebase from
  // src\storage\CompressedAsyncStorage.js and src\storage\AsyncStorage.js
  Future<String?> getItem(String key) async {
    final query = 'SELECT value FROM keyvalue WHERE key = ?';
    final rows = await customSelect(query, variables: [Variable<String>(key)])
        .map((row) => row.data)
        .get();
    String? item =  rows.isNotEmpty ? rows[0]['value'] as String : null;
    if (item == null) return null;
    // It's possible that getItem() is called on uncompressed state, for
    // example when a user updates their app from a version without
    // compression to a version with compression.  So we need to detect that.
    //
    // We can detect compressed states by inspecting the first few
    // characters of `result`.  First, a leading 'z' indicates a
    // "Zulip"-compressed string; otherwise, the string is the only other
    // format we've ever stored, namely uncompressed JSON (which,
    // conveniently, never starts with a 'z').
    //
    // Then, a Zulip-compressed string looks like `z|TRANSFORMS|DATA`, where
    // TRANSFORMS is a space-separated list of the transformations that we
    // applied, in order, to the data to produce DATA and now need to undo.
    // E.g., `zlib base64` means DATA is a base64 encoding of a zlib
    // encoding of the underlying data.  We call the "z|TRANSFORMS|" part
    // the "header" of the string.
    if(item.startsWith('z')) {
      String itemHeader = '${item.split('|').sublist(0, 2).join('|')}|';
      if (itemHeader == utils.header) {
        // The string is compressed, so we need to decompress it.
        String decompressedString = utils.decompress(item);
        return decompressedString;
      } else {
        // Panic! If we are confronted with an unknown format, there is
        // nothing we can do to save the situation. Log an error and ignore
        // the data.  This error should not happen unless a user downgrades
        // their version of the app.
        final err = Exception(
            'No decompression module found for format $itemHeader');
        throw err;
      }
    }
    // Uncompressed state
    return item;

  }
}

class LegacyAppMigrations {
  LegacyAppMigrations();

  /// This method should return the json data of the account in the latest version
  /// of migrations or null if the data can't be migrated.
  static Map<String, dynamic>? applyAccountMigrations(Map<String, dynamic> json, int version) {
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
      // convert json['realm'] from string to Uri.
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

  static Map<String, dynamic>? applySettingMigrations(Map<String,dynamic> json, int version) {
    if (version < 10) {
      // Convert old locale names to new, more-specific locale names.
      final newLocaleNames = {
        'zh': 'zh-Hans',
        'id': 'id-ID',
      };
      if (newLocaleNames.containsKey(json['locale'])) {
        json['locale'] = newLocaleNames[json['locale']];
      }
    }

    if (version < 26) {
      // Rename locale `id-ID` back to `id`.
      if (json['locale'] == 'id-ID') {
        json['locale'] = 'id';
      }
    }

    if (version < 28) {
      // Add "open links with in-app browser" setting.
      json['browser'] = 'default';
    }

    if (version < 30) {
      // Use valid language tag for Portuguese (Portugal).
      if (json['locale'] == 'pt_PT') {
        json['locale'] = 'pt-PT';
      }
    }

    if (version < 31) {
      // rename json['locale'] to json['language'].
      json['language'] = json['locale'];
      json.remove('locale');
    }

    if (version < 32) {
      // Switch to zh-TW as a language option instead of zh-Hant.
      if (json['language'] == 'zh-Hant') {
        json['language'] = 'zh-TW';
      }
    }

    if (version < 37) {
      // Adds `doNotMarkMessagesAsRead` to `settings`. If the property is missing, it defaults to `false`.
      json['doNotMarkMessagesAsRead'] = json['doNotMarkMessagesAsRead'] ?? false;
    }

    if (version < 52) {
      // Change boolean doNotMarkMessagesAsRead to enum markMessagesReadOnScroll.
      if (json['doNotMarkMessagesAsRead'] == true) {
        json['markMessagesReadOnScroll'] = 'never';
      } else {
        json['markMessagesReadOnScroll'] = 'always';
      }
      json.remove('doNotMarkMessagesAsRead');
    }

    return json;
  }
}