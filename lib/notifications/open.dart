
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../host/notifications.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/narrow.dart';
import '../widgets/app.dart';
import '../widgets/dialog.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';

NotificationPigeonApi get _notifPigeonApi => ZulipBinding.instance.notificationPigeonApi;

/// Service for handling notification navigation.
class NotificationOpenManager {
  static NotificationOpenManager get instance => (_instance ??= NotificationOpenManager._());
  static NotificationOpenManager? _instance;

  NotificationOpenManager._();

  NotificationPayloadForOpen? _notifLaunchData;

  Completer<void>? _intializedSignal;
  Future<void>? get intializationFuture => _intializedSignal?.future;

  Future<void> init() async {
    _intializedSignal = Completer();
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          _notifLaunchData = await _notifPigeonApi.getNotificationDataFromLaunch();
          _notifPigeonApi.notificationTapEventsStream()
            .listen(_navigateForNotification);

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          // Do nothing; we don't offer notifications on these platforms.
          break;
      }
    } finally {
      _intializedSignal!.complete();
    }
  }

  /// Provides the route to open if the app was launched through a tap on
  /// the notification.
  ///
  /// Returns null if app launch wasn't triggered by a notification, or if
  /// an error occurs while determining the route for the notification, in
  /// which case an error dialog is also shown.
  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    final data = _notifLaunchData;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));
    return _routeForNotification(context, data);
  }

  /// Provides the route to open by parsing the notification payload.
  ///
  /// Returns null and shows an error dialog if the associated account is not
  /// found in the global store.
  AccountRoute<void>? _routeForNotification(BuildContext context, NotificationPayloadForOpen payload) {
    final globalStore = GlobalStoreWidget.of(context);
    final openData = NotificationDataForOpen.fromNotificationPayload(payload.payload);

    final account = globalStore.accounts.firstWhereOrNull(
      (account) => account.realmUrl.origin == openData.realmUrl.origin
                && account.userId == openData.userId);
    if (account == null) { // TODO(log)
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountMissing);
      return null;
    }

    return MessageListPage.buildRoute(
      accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      narrow: openData.narrow);
  }

  /// Navigates to the [MessageListPage] of the specific conversation
  /// for the provided payload that was attached while creating the
  /// notification.
  Future<void> _navigateForNotification(NotificationPayloadForOpen payload) async {
    assert(debugLog('opened notif: ${jsonEncode(payload.payload)}'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final route = _routeForNotification(context, payload);
    if (route == null) return; // TODO(log)

    // TODO(nav): Better interact with existing nav stack on notif open
    unawaited(navigator.push(route));
  }
}

class NotificationDataForOpen {
  final Uri realmUrl;
  final int userId;
  final Narrow narrow;

  NotificationDataForOpen({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  }) : assert(narrow is TopicNarrow || narrow is DmNarrow);

  /// Parses the iOS APNs payload and retrieves the information
  /// required for navigation.
  factory NotificationDataForOpen.fromNotificationPayload(Map<Object?, Object?> payload) {
    if (payload case {
      'zulip': {
        'user_id': final int userId,
        'sender_id': final int senderId,
      } && final zulipData,
    }) {
      final String realmUrl;
      switch (zulipData) {
        case {'realm_url': final String value}:
          realmUrl = value;
        case {'realm_uri': final String value}:
          realmUrl = value;
        default:
          throw const FormatException();
      }

      final Narrow narrow = switch (zulipData) {
        {
          'recipient_type': 'stream',
          'stream_id': final int streamId,
          'topic': final String topic,
        } =>
          TopicNarrow(streamId, TopicName(topic)),

        {'recipient_type': 'private', 'pm_users': final String pmUsers} =>
          DmNarrow(
            allRecipientIds: pmUsers
              .split(',')
              .map((e) => int.parse(e, radix: 10))
              .toList(growable: false)..sort(),
            selfUserId: userId),

        {'recipient_type': 'private'} =>
          DmNarrow(
            allRecipientIds: [senderId, userId]..sort(),
            selfUserId: userId),

        _ => throw const FormatException(),
      };

      return NotificationDataForOpen(
        realmUrl: Uri.parse(realmUrl),
        userId: userId,
        narrow: narrow);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }
}
