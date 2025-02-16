import 'dart:async';

import '../notifications/receive.dart';
import 'store.dart';

// TODO: Make this a part of GlobalStore
Future<void> logOutAccount(GlobalStore globalStore, int accountId) async {
  final account = globalStore.getAccount(accountId);
  if (account == null) return; // TODO(log)

  // Unawaited, to not block removing the account on this request.
  unawaited(unregisterToken(globalStore, accountId));

  await globalStore.removeAccount(accountId);
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
