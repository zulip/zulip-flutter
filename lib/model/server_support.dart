import '../api/core.dart';
import '../api/exception.dart';
import '../api/model/initial_snapshot.dart';
import 'database.dart';

/// The fields 'zulip_version', 'zulip_merge_base', and 'zulip_feature_level'
/// from a /register response.
class ZulipVersionData {
  const ZulipVersionData({
    required this.zulipVersion,
    required this.zulipMergeBase,
    required this.zulipFeatureLevel,
  });

  factory ZulipVersionData.fromInitialSnapshot(InitialSnapshot initialSnapshot) =>
    ZulipVersionData(
      zulipVersion: initialSnapshot.zulipVersion,
      zulipMergeBase: initialSnapshot.zulipMergeBase,
      zulipFeatureLevel: initialSnapshot.zulipFeatureLevel);

  /// Make a [ZulipVersionData] from a [MalformedServerResponseException],
  /// if the body was readable/valid JSON and contained the data, else null.
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
