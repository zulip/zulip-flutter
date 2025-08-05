import 'dart:async';

import 'package:flutter/foundation.dart';

import '../notifications/display.dart';
import '../notifications/receive.dart';
import 'settings.dart';
import 'store.dart';

// TODO: Make this a part of GlobalStore
Future<void> logOutAccount(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // Unawaited, to not block removing the account on this request.
  unawaited(unregisterToken(globalStore, accountId));

  if (defaultTargetPlatform == TargetPlatform.android) {
    unawaited(NotificationDisplayManager.removeNotificationsForAccount(account.realmUrl, account.userId));
  }

  await globalStore.removeAccount(accountId);
}

Future<void> removeLastVisitedAccountIfNecessary(GlobalStore store, int loggedOutAccountId) async {
  // If account is not logged out yet, do nothing.
  if (store.getAccount(loggedOutAccountId) != null) return;

  // If the logged-out account is different than the last visited one, do nothing.
  if (loggedOutAccountId != store.settings.getInt(IntGlobalSetting.lastVisitedAccountId)) {
    return;
  }

  await store.settings.setInt(IntGlobalSetting.lastVisitedAccountId, null);
}

Future<void> unregisterToken(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // TODO(#322) use actual acked push token; until #322, this is just null.
  final token = account.ackedPushToken
    // Try the current token as a fallback; maybe the server has registered
    // it and we just haven't recorded that fact in the client.
    ?? NotificationService.instance.token.value;
  if (token == null) return;

  final connection = globalStore.apiConnectionFromAccount(account);
  try {
    await NotificationService.unregisterToken(connection, token: token);
  } catch (e) {
    // TODO retry? handle failures?
  } finally {
    connection.close();
  }
}
