import 'dart:convert';
import 'package:drift/drift.dart';

import 'migration_utils.dart' as utils;




class MinimalDatabase extends GeneratedDatabase {
  MinimalDatabase(super.e);

  @override
  Iterable<TableInfo> get allTables => [];

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