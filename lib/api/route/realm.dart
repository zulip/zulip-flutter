import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'realm.g.dart';

/// https://zulip.com/api/get-server-settings
///
/// Despite the name, this is really a home for certain realm-specific
/// settings, as well as some information about the server as a whole.
///
/// The Zulip server offers this endpoint at the root domain of a server,
/// even when there is no Zulip realm at that domain.  This binding, however,
/// only operates on an actual Zulip realm.
// TODO(#107): Perhaps detect realmless root domain, for more specific onboarding feedback.
//   See thread, and the zulip-mobile code and chat thread it links to:
//     https://github.com/zulip/zulip-flutter/pull/55#discussion_r1160267577
Future<GetServerSettingsResult> getServerSettings(ApiConnection connection) {
  return connection.get('getServerSettings', GetServerSettingsResult.fromJson, 'server_settings', null);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetServerSettingsResult {
  // This is marked as deprecated, but we still need it to answer some
  // questions:
  // - Do we offer dev login? (Yes if it has `dev: true`.)
  // - Do we offer password login? (Yes if it has `password: true` or `ldap: true`.)
  // - Do we offer a "Log in with SSO" button? (Yes if it has `remoteuser: true`.)
  //
  // Discussion: https://chat.zulip.org/#narrow/stream/378-api-design/topic/.60authentication_methods.60.20in.20server.20settings/near/1722986
  final Map<String, bool> authenticationMethods;

  final List<ExternalAuthenticationMethod> externalAuthenticationMethods;

  final int zulipFeatureLevel;
  final String zulipVersion;
  final String? zulipMergeBase; // TODO(server-5)

  final bool pushNotificationsEnabled;
  final bool isIncompatible;

  final bool emailAuthEnabled;
  final bool requireEmailFormatUsernames;

  @JsonKey(name: 'realm_uri')
  final Uri realmUrl;

  final String realmName;
  final String realmIcon;
  final String realmDescription;
  final bool? realmWebPublicAccessEnabled; // TODO(server-5)

  GetServerSettingsResult({
    required this.authenticationMethods,
    required this.externalAuthenticationMethods,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    required this.zulipMergeBase,
    required this.pushNotificationsEnabled,
    required this.isIncompatible,
    required this.emailAuthEnabled,
    required this.requireEmailFormatUsernames,
    required this.realmUrl,
    required this.realmName,
    required this.realmIcon,
    required this.realmDescription,
    required this.realmWebPublicAccessEnabled,
  });

  factory GetServerSettingsResult.fromJson(Map<String, dynamic> json) =>
    _$GetServerSettingsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetServerSettingsResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ExternalAuthenticationMethod {
  final String name;
  final String displayName;
  final String? displayIcon;
  final String loginUrl;
  final String signupUrl;

  ExternalAuthenticationMethod({
    required this.name,
    required this.displayName,
    required this.displayIcon,
    required this.loginUrl,
    required this.signupUrl,
  });

  factory ExternalAuthenticationMethod.fromJson(Map<String, dynamic> json) =>
    _$ExternalAuthenticationMethodFromJson(json);

  Map<String, dynamic> toJson() => _$ExternalAuthenticationMethodToJson(this);
}
