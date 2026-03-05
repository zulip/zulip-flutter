import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/core.dart';
import '../notifications/display.dart';
import '../notifications/receive.dart';
import 'store.dart';

// TODO: Make this a part of GlobalStore
Future<void> logOutAccount(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // Unawaited, to not block removing the account on this request.
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
  try {
    await _unregisterToken(account, connection);
  } finally {
    connection.close();
  }
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

  try {
    await NotificationService.unregisterToken(connection, token: token);
  } catch (e) {
    // TODO retry? handle failures?
  }
}
