import '../api/core.dart';
import '../api/exception.dart';
import '../api/model/initial_snapshot.dart';
import '../api/route/realm.dart';
import 'database.dart';

/// The fields 'zulip_version', 'zulip_merge_base', and 'zulip_feature_level'
/// from a /server_settings or /register response.
class ZulipVersionData {
  const ZulipVersionData({
    required this.zulipVersion,
    required this.zulipMergeBase,
    required this.zulipFeatureLevel,
  });

  factory ZulipVersionData.fromServerSettings(GetServerSettingsResult serverSettings) =>
    ZulipVersionData(
      zulipVersion: serverSettings.zulipVersion,
      zulipMergeBase: serverSettings.zulipMergeBase,
      zulipFeatureLevel: serverSettings.zulipFeatureLevel);

  factory ZulipVersionData.fromInitialSnapshot(InitialSnapshot initialSnapshot) =>
    ZulipVersionData(
      zulipVersion: initialSnapshot.zulipVersion,
      zulipMergeBase: initialSnapshot.zulipMergeBase,
      zulipFeatureLevel: initialSnapshot.zulipFeatureLevel);

  /// Make a [ZulipVersionData] from a [MalformedServerResponseException],
  /// if the body was readable/valid JSON and contained the data, else null.
  ///
  /// May be used for the /server_settings or the /register response.
  ///
  /// If there's a zulip_version but no zulip_feature_level,
  /// we infer it's indeed a Zulip server,
  /// just an ancient one before feature levels were introduced in Zulip 3.0,
  /// and we set 0 for zulipFeatureLevel.
  static ZulipVersionData? fromMalformedServerResponseException(MalformedServerResponseException e) {
    try {
      final data = e.data!;
      return ZulipVersionData(
        zulipVersion: data['zulip_version'] as String,
        zulipMergeBase: data['zulip_merge_base'] as String?,
        zulipFeatureLevel: data['zulip_feature_level'] as int? ?? 0);
    } catch (inner) {
      return null;
    }
  }

  final String zulipVersion;

  // The `zulip_merge_base` field was added in server-5, feature level 88.
  // We leave it nullable on this class because if a user attempts to connect
  // to an ancient Zulip server missing this field, we still want to capture
  // the rest of the version data for use in the error message.
  final String? zulipMergeBase;

  final int zulipFeatureLevel;

  bool matchesAccount(Account account) =>
    zulipVersion == account.zulipVersion
    && zulipMergeBase == account.zulipMergeBase
    && zulipFeatureLevel == account.zulipFeatureLevel;

  bool get isUnsupported => zulipFeatureLevel < kMinSupportedZulipFeatureLevel;
}

class ServerVersionUnsupportedException implements Exception {
  final ZulipVersionData data;

  ServerVersionUnsupportedException(this.data);
}
