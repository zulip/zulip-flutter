import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'realm.g.dart';

/// https://zulip.com/api/get-server-settings
///
/// Despite the name, this is really a home for certain realm-specific
/// settings, as well as some information about the server as a whole.
///
/// The Zulip server offers this endpoint at the root domain of a server,
/// even when there is no Zulip realm at that domain.  This binding, however,
/// only operates on an actual Zulip realm.
// TODO(#35): Perhaps detect realmless root domain, for more specific onboarding feedback.
//   See thread, and the zulip-mobile code and chat thread it links to:
//     https://github.com/zulip/zulip-flutter/pull/55#discussion_r1160267577
Future<GetServerSettingsResult> getServerSettings({
  required Uri realmUrl,
}) async {
  final request = http.Request('GET', realmUrl.replace(path: "/api/v1/server_settings"));

  // TODO dedupe with LiveApiConnection; make this function testable
  final client = http.Client();
  final http.Response response;
  try {
    response = await http.Response.fromStream(await client.send(request));
  } finally {
    client.close();
  }

  if (response.statusCode != 200) {
    throw Exception('error on GET server_settings: status ${response.statusCode}');
  }
  final data = utf8.decode(response.bodyBytes);

  final json = jsonDecode(data);
  return GetServerSettingsResult.fromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetServerSettingsResult {
  final Map<String, bool> authenticationMethods;
  // final List<ExternalAuthenticationMethod> external_authentication_methods; // TODO handle

  final int zulipFeatureLevel;
  final String zulipVersion;
  final String? zulipMergeBase; // TODO(server-5)

  final bool pushNotificationsEnabled;
  final bool isIncompatible;

  final bool emailAuthEnabled;
  final bool requireEmailFormatUsernames;
  final Uri realmUri;
  final String realmName;
  final String realmIcon;
  final String realmDescription;
  final bool? realmWebPublicAccessEnabled; // TODO(server-5)

  GetServerSettingsResult({
    required this.authenticationMethods,
    required this.zulipFeatureLevel,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.pushNotificationsEnabled,
    required this.isIncompatible,
    required this.emailAuthEnabled,
    required this.requireEmailFormatUsernames,
    required this.realmUri,
    required this.realmName,
    required this.realmIcon,
    required this.realmDescription,
    this.realmWebPublicAccessEnabled,
  });

  factory GetServerSettingsResult.fromJson(Map<String, dynamic> json) =>
    _$GetServerSettingsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetServerSettingsResultToJson(this);
}
