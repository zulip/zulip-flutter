import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/core.dart';
import '../api/route/account.dart';
import '../notifications/display.dart';
import 'store.dart';

// TODO: Make this a part of GlobalStore
Future<void> logOutAccount(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // Unawaited, to not block removing the account on these requests.
  unawaited(unregisterDevice(globalStore, accountId));

  if (defaultTargetPlatform == TargetPlatform.android) {
    unawaited(
      NotificationDisplayManager.removeNotificationsForAccount(
        account.realmUrl,
        account.userId,
      ),
    );
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
  try {
    await _unregisterDevice(account, connection);
  } finally {
    connection.close();
  }
}

/// Tell the server to delete its device record for this device,
/// and so in particular this device's push key for E2EE notifications.
Future<void> _unregisterDevice(
  Account account,
  ApiConnection connection,
) async {
  if (account.deviceId == null) return; // Nothing to unregister.

  if (connection.zulipFeatureLevel! < 470) {
    // TODO(server-12)
    // The server is in the narrow window where device records exist (FL 468+)
    // but the endpoint to remove them doesn't.  Oh well.
    // The device record will leak, just like it unavoidably would if the user
    // simply uninstalled the app.
    // (Or, less likely: the server *was* previously new enough to make
    // a device record, and has since been downgraded.)
    return;
  }

  try {
    await removeClientDevice(connection, deviceId: account.deviceId!);
  } catch (e) {
    // TODO retry? handle failures?
  }
}
