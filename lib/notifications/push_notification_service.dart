import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../api/core.dart';
import '../api/route/notifications.dart';
import '../get/services/global_service.dart';
import '../get/services/store_service.dart';

class PushNotificationService extends GetxService {
  static PushNotificationService get to => Get.find<PushNotificationService>();

  String? _apnsToken;
  static const _channel = MethodChannel('zulip/push_tokens');

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onApnsTokenReceived':
        final token = call.arguments as String?;
        if (token != null) {
          setApnsToken(token);
        }
        return null;
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  void setApnsToken(String token) {
    _apnsToken = token;
    debugPrint('APNs token received: $token');
    _registerTokenIfNeeded();
  }

  void _registerTokenIfNeeded() {
    if (_apnsToken == null) return;

    final accountId = StoreService.to.accountId;
    if (accountId == null) return;

    registerDeviceForPushNotifications(accountId);
  }

  Future<void> registerDeviceForPushNotifications(int accountId) async {
    if (_apnsToken == null) {
      debugPrint('APNs token not available yet');
      return;
    }

    final account = GlobalService.to.getAccount(accountId);
    if (account == null) {
      debugPrint('Account not found for push registration');
      return;
    }

    final connection = GlobalService.to.createConnectionFromAccount(account);
    try {
      // For APNs, we use token registration
      // This is a simplified version - the full implementation would need
      // proper encryption and token handling as per Zulip API docs
      await registerPushDevice(
        connection,
        deviceId: accountId,
        token: RegisterPushDeviceToken(
          tokenKind: PushTokenKind.apns,
          tokenId: _apnsToken!,
          bouncerPublicKey: '', // TODO: Get from server
          encryptedPushRegistration: '', // TODO: Encrypt properly
        ),
      );
      debugPrint('Successfully registered push device: $accountId');
    } catch (e) {
      debugPrint('Failed to register push device: $e');
    } finally {
      connection.close();
    }
  }

  Future<void> unregisterDevice(int accountId) async {
    final account = GlobalService.to.getAccount(accountId);
    if (account == null) return;

    final connection = GlobalService.to.createConnectionFromAccount(account);
    try {
      await unregisterPushDevice(connection, accountId);
      debugPrint('Successfully unregistered push device: $accountId');
    } catch (e) {
      debugPrint('Failed to unregister push device: $e');
    } finally {
      connection.close();
    }
  }
}

Future<void> unregisterPushDevice(ApiConnection connection, int deviceId) {
  return connection.post(
    'unregisterPushDevice',
    (_) {},
    'mobile_push/unregister',
    {'device_id': deviceId},
  );
}
