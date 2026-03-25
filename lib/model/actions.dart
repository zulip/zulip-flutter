import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/core.dart';
import '../api/exception.dart';
import '../api/route/account.dart';
import '../notifications/display.dart';
import '../notifications/receive.dart';
import 'pending_unregistrations.dart';
import 'store.dart';

// TODO: Make this a part of GlobalStore
Future<void> logOutAccount(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // Unawaited, to not block removing the account on these requests.
  unawaited(unregisterDevice(globalStore, accountId));

  if (defaultTargetPlatform == TargetPlatform.android) {
    unawaited(NotificationDisplayManager.removeNotificationsForAccount(account.realmUrl, account.userId));
  }

  await globalStore.removeAccount(accountId);
}

/// Tell the server this (account on this) device is going away,
/// in particular to stop it trying to send any more notifications.
@visibleForTesting
Future<void> unregisterDevice(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  final connection = globalStore.apiConnectionFromAccount(account);
  bool hasOfflineError = false;

  try {
    await _unregisterToken(account, connection);
  } catch (e) {
    if (e is http.ClientException || e is SocketException || e is NetworkException) {
      hasOfflineError = true;
    }
  }

  try {
    await _unregisterDevice(account, connection);
  } catch (e) {
    if (e is http.ClientException || e is SocketException || e is NetworkException) {
      hasOfflineError = true;
    }
  }

  if (hasOfflineError) {
    await PendingUnregistrationsStore.add(PendingUnregistration(
      realmUrl: account.realmUrl,
      zulipFeatureLevel: account.zulipFeatureLevel,
      email: account.email,
      apiKey: account.apiKey,
      deviceId: account.deviceId,
      token: NotificationService.instance.token.value,
      possibleLegacyPushToken: account.possibleLegacyPushToken,
    ));
  }

  connection.close();
}

/// Tell the server to stop sending legacy non-E2EE notifications for this account.
Future<void> _unregisterToken(Account account, ApiConnection connection) async {
  if (!account.possibleLegacyPushToken) return;

  // We don't know for sure what push token the server might have registered
  // for this device.  (That's fixed in the new push-registration protocol,
  // used for E2EE notifications.)  But the most likely candidate is the token
  // the device currently gives; that's probably the only token this device has
  // ever had, since tokens only infrequently change.
  final token = NotificationService.instance.token.value;
  if (token == null) return;

  await NotificationService.unregisterToken(connection, token: token);
}

/// Tell the server to delete its device record for this device,
/// and so in particular this device's push key for E2EE notifications.
Future<void> _unregisterDevice(Account account, ApiConnection connection) async {
  if (account.deviceId == null) return; // Nothing to unregister.

  if (connection.zulipFeatureLevel! < 470) { // TODO(server-12)
    // The server is in the narrow window where device records exist (FL 468+)
    // but the endpoint to remove them doesn't.  Oh well.
    // The device record will leak, just like it unavoidably would if the user
    // simply uninstalled the app.
    // (Or, less likely: the server *was* previously new enough to make
    // a device record, and has since been downgraded.)
    return;
  }

  await removeClientDevice(connection, deviceId: account.deviceId!);
}
