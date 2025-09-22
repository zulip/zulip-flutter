import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'notifications.g.dart';

/// https://zulip.com/api/register-push-device
///
/// The request's parameters are grouped here into [key] and [token]
/// to reflect the API's structure where each of those groups must be
/// either entirely absent or entirely present.
Future<void> registerPushDevice(ApiConnection connection, {
  required int deviceId,
  RegisterPushDeviceKey? key,
  RegisterPushDeviceToken? token,
}) {
  assert(key != null || token != null);
  assert(connection.zulipFeatureLevel! >= 468); // TODO(server-12)
  return connection.post('registerPushDevice', (_) {}, 'mobile_push/register', {
    'device_id': deviceId,
    if (key != null) ...{
      'push_key_id': key.pushKeyId,
      'push_key': RawParameter(key.pushKey),
    },
    if (token != null) ...{
      'token_kind': RawParameter(token.tokenKind.toJson()),
      'token_id': RawParameter(token.tokenId),
      'bouncer_public_key': RawParameter(token.bouncerPublicKey),
      'encrypted_push_registration': RawParameter(token.encryptedPushRegistration),
    },
  });
}

/// The parameters to [registerPushDevice] for setting a push key.
class RegisterPushDeviceKey {
  final int pushKeyId;
  final String pushKey;

  RegisterPushDeviceKey({required this.pushKeyId, required this.pushKey});
}

/// The parameters to [registerPushDevice] for setting a push token.
///
/// For constructing [encryptedPushRegistration], see [PushRegistration].
class RegisterPushDeviceToken {
  final PushTokenKind tokenKind;
  final String tokenId;
  final String bouncerPublicKey;
  final String encryptedPushRegistration;

  RegisterPushDeviceToken({
    required this.tokenKind,
    required this.tokenId,
    required this.bouncerPublicKey,
    required this.encryptedPushRegistration,
  });
}

/// As in [RegisterPushDeviceToken.tokenKind].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum PushTokenKind {
  fcm,
  apns;

  String toJson() => _$PushTokenKindEnumMap[this]!;
}

/// The plaintext for [RegisterPushDeviceToken.encryptedPushRegistration].
///
/// See https://zulip.com/api/register-push-device#parameter-encrypted_push_registration
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class PushRegistration {
  final PushTokenKind tokenKind;
  final String token;
  final int timestamp;

  PushRegistration({
    required this.tokenKind,
    required this.token,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => _$PushRegistrationToJson(this);
}

/// https://zulip.com/api/add-fcm-token
Future<void> addFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.post('addFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/remove-fcm-token
Future<void> removeFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/add-apns-token
Future<void> addApnsToken(ApiConnection connection, {
  required String token,
  required String appid,
}) {
  return connection.post('addApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
    'appid': RawParameter(appid),
  });
}

/// https://zulip.com/api/remove-apns-token
Future<void> removeApnsToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
  });
}
