/// Logic for reading from the legacy app's data, on upgrade to this app.
///
/// Many of the details here correspond to specific parts of the
/// legacy app's source code.
/// See <https://github.com/zulip/zulip-mobile>.
library;

import 'package:json_annotation/json_annotation.dart';

part 'legacy_app_data.g.dart';

/// Represents the data from the legacy app's database,
/// so far as it's relevant for this app.
///
/// The full set of data in the legacy app's in-memory store is described by
/// the type `GlobalState` in src/reduxTypes.js .
/// Within that, the data it stores in the database is the data at the keys
/// listed in `storeKeys` and `cacheKeys` in src/boot/store.js .
/// The data under `cacheKeys` lives on the server and the app re-fetches it
/// upon each startup anyway;
/// so only the data under `storeKeys` is relevant for migrating to this app.
///
/// Within the data under `storeKeys`, some portions are also ignored
/// for specific reasons described explicitly in comments on these types.
@JsonSerializable()
class LegacyAppData {
  // The `state.migrations` data gets read and used before attempting to
  // deserialize the data that goes into this class.
  // final LegacyAppMigrationsState migrations; // handled separately

  final LegacyAppGlobalSettingsState? settings;
  final List<LegacyAppAccount>? accounts;

  // final Map<??, String> drafts; // ignore; inherently transient

  // final List<??> outbox; // ignore; inherently transient

  LegacyAppData({
    required this.settings,
    required this.accounts,
  });

  factory LegacyAppData.fromJson(Map<String, Object?> json) =>
    _$LegacyAppDataFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppDataToJson(this);
}

/// Corresponds to type `MigrationsState` in src/reduxTypes.js .
@JsonSerializable()
class LegacyAppMigrationsState {
  final int? version;

  LegacyAppMigrationsState({required this.version});

  factory LegacyAppMigrationsState.fromJson(Map<String, Object?> json) =>
    _$LegacyAppMigrationsStateFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppMigrationsStateToJson(this);
}

/// Corresponds to type `GlobalSettingsState` in src/reduxTypes.js .
///
/// The remaining data found at key `settings` in the overall data,
/// described by type `PerAccountSettingsState`, lives on the server
/// in the same way as the data under the keys in `cacheKeys`,
/// and so is ignored here.
@JsonSerializable()
class LegacyAppGlobalSettingsState {
  final String language;
  final LegacyAppThemeSetting theme;
  final LegacyAppBrowserPreference browser;

  // Ignored because the legacy app hadn't used it since 2017.
  // See discussion in commit zulip-mobile@761e3edb4 (from 2018).
  // final bool experimentalFeaturesEnabled; // ignore

  final LegacyAppMarkMessagesReadOnScroll markMessagesReadOnScroll;

  LegacyAppGlobalSettingsState({
    required this.language,
    required this.theme,
    required this.browser,
    required this.markMessagesReadOnScroll,
  });

  factory LegacyAppGlobalSettingsState.fromJson(Map<String, Object?> json) =>
    _$LegacyAppGlobalSettingsStateFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppGlobalSettingsStateToJson(this);
}

/// Corresponds to type `ThemeSetting` in src/reduxTypes.js .
enum LegacyAppThemeSetting {
  @JsonValue('default')
  default_,
  night;
}

/// Corresponds to type `BrowserPreference` in src/reduxTypes.js .
enum LegacyAppBrowserPreference {
  embedded,
  external,
  @JsonValue('default')
  default_,
}

/// Corresponds to the type `GlobalSettingsState['markMessagesReadOnScroll']`
/// in src/reduxTypes.js .
@JsonEnum(fieldRename: FieldRename.kebab)
enum LegacyAppMarkMessagesReadOnScroll {
  always, never, conversationViewsOnly,
}

/// Corresponds to type `Account` in src/types.js .
@JsonSerializable()
class LegacyAppAccount {
  // These three come from type Auth in src/api/transportTypes.js .
  @_LegacyAppUrlJsonConverter()
  final Uri realm;
  final String apiKey;
  final String email;

  final int? userId;

  @_LegacyAppZulipVersionJsonConverter()
  final String? zulipVersion;

  final int? zulipFeatureLevel;

  final String? ackedPushToken;

  // These three are ignored because this app doesn't currently have such
  // notices or banners for them to control; and because if we later introduce
  // such things, it's a pretty mild glitch to have them reappear, once,
  // after a once-in-N-years major upgrade to the app.
  // final DateTime? lastDismissedServerPushSetupNotice; // ignore
  // final DateTime? lastDismissedServerNotifsExpiringBanner; // ignore
  // final bool silenceServerPushSetupWarnings; // ignore

  LegacyAppAccount({
    required this.realm,
    required this.apiKey,
    required this.email,
    required this.userId,
    required this.zulipVersion,
    required this.zulipFeatureLevel,
    required this.ackedPushToken,
  });

  factory LegacyAppAccount.fromJson(Map<String, Object?> json) =>
    _$LegacyAppAccountFromJson(json);

  Map<String, Object?> toJson() => _$LegacyAppAccountToJson(this);
}

/// This and its subclasses correspond to portions of src/storage/replaceRevive.js .
///
/// (The rest of the conversions in that file are for types that don't appear
/// in the portions of the legacy app's state we care about.)
sealed class _LegacyAppJsonConverter<T> extends JsonConverter<T, Map<String, dynamic>> {
  const _LegacyAppJsonConverter();

  String get serializedTypeName;

  T fromJsonData(Object? json);

  Object? toJsonData(T value);

  /// Corresponds to `SERIALIZED_TYPE_FIELD_NAME`.
  static const _serializedTypeFieldName = '__serializedType__';

  @override
  T fromJson(Map<String, dynamic> json) {
    final actualTypeName = json[_serializedTypeFieldName];
    if (actualTypeName != serializedTypeName) {
      throw FormatException("unexpected $_serializedTypeFieldName: $actualTypeName");
    }
    return fromJsonData(json['data']);
  }

  @override
  Map<String, dynamic> toJson(T object) {
    return {
      _serializedTypeFieldName: serializedTypeName,
      'data': toJsonData(object),
    };
  }
}

class _LegacyAppUrlJsonConverter extends _LegacyAppJsonConverter<Uri> {
  const _LegacyAppUrlJsonConverter();

  @override
  String get serializedTypeName => 'URL';

  @override
  Uri fromJsonData(Object? json) => Uri.parse(json as String);

  @override
  Object? toJsonData(Uri value) => value.toString();
}

/// Corresponds to type `ZulipVersion`.
///
/// This new app skips the parsing logic of the legacy app's ZulipVersion type,
/// and just uses the raw string.
class _LegacyAppZulipVersionJsonConverter extends _LegacyAppJsonConverter<String> {
  const _LegacyAppZulipVersionJsonConverter();

  @override
  String get serializedTypeName => 'ZulipVersion';

  @override
  String fromJsonData(Object? json) => json as String;

  @override
  Object? toJsonData(String value) => value;
}
