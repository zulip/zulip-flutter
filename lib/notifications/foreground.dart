import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/binding.dart';
import '../model/store.dart';
import '../widgets/app.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import 'conversation_key.dart';

/// Keeps the iOS host informed of which conversation is open in the UI,
/// so foreground push banners/sounds for that same conversation can be
/// suppressed (while other conversations still alert; see #408 / #2306).
///
/// Call [sync] after navigation changes and when a [MessageListPage]'s
/// narrow changes in place.
abstract final class NotificationForegroundSuppression {
  /// Computes the conversation key for the topmost message-list page, if any,
  /// and sends it to the iOS host.
  ///
  /// No-op on non-iOS platforms.
  static void sync(GlobalStore globalStore) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final key = conversationKeyForCurrentOpenMessageList(globalStore);
    unawaited(
      ZulipBinding.instance.notificationPigeonApi
        .setOpenConversationKeyForNotifSuppression(key));
  }

  /// The suppression key for the currently open message-list conversation,
  /// or null if the top page is not a stream+topic / DM message list.
  @visibleForTesting
  static String? conversationKeyForCurrentOpenMessageList(GlobalStore globalStore) {
    final navStack = ZulipApp.navigationStack;
    if (navStack == null) return null;

    final currentPageRoute = navStack.currentPageRoute;
    if (currentPageRoute is! MaterialAccountWidgetRoute) return null;
    if (currentPageRoute.page is! MessageListPage) return null;

    final account = globalStore.getAccount(currentPageRoute.accountId);
    if (account == null) return null;

    final narrow = MessageListPage.currentNarrow(currentPageRoute);
    return conversationKeyForNotifSuppression(
      realmUrl: account.realmUrl,
      userId: account.userId,
      narrow: narrow,
    );
  }
}

/// A [NavigatorObserver] that syncs [NotificationForegroundSuppression]
/// whenever the navigation stack changes.
///
/// Must be registered after the observer that maintains
/// [ZulipApp.navigationStack], so that stack is up to date when we sync.
class SyncOpenConversationForNotifSuppression extends NavigatorObserver {
  SyncOpenConversationForNotifSuppression(this.globalStore);

  final GlobalStore globalStore;

  void _sync() {
    NotificationForegroundSuppression.sync(globalStore);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _sync();
}
