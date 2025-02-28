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

  /// Reset the state of the [NotificationOpenManager], for testing.
  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }

  NotificationDataFromLaunch? _notifDataFromLaunch;

  /// A [Future] that completes to signal that the initialization of
  /// [NotificationOpenManager] has completed or errored.
  Future<void>? get initializationFuture => _initializedSignal?.future;

  Completer<void>? _initializedSignal;

  Future<void> init() async {
    assert(_initializedSignal == null);
    _initializedSignal ??= Completer();
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          _notifDataFromLaunch = await _notifPigeonApi.getNotificationDataFromLaunch();

        case TargetPlatform.android:
          // Do nothing; we do notification routing differently on Android.
          // TODO migrate Android to use the new Pigeon API.
          break;

        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          // Do nothing; we don't offer notifications on these platforms.
          break;
      }
    } finally {
      _initializedSignal!.complete();
    }
  }

  /// Provides the route to open if the app was launched through a tap on
  /// a notification.
  ///
  /// Returns null if app launch wasn't triggered by a notification, or if
  /// an error occurs while determining the route for the notification, in
  /// which case an error dialog is also shown.
  ///
  /// The context argument is used to look up [GlobalStoreWidget],
  /// [ZulipLocalizations], the [Navigator] and [Theme], where the latter
  /// three are used to show an error dialog if there is a failure.
  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    final data = _notifDataFromLaunch;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));

    final NotificationNavigationData notifNavData;
    try {
      notifNavData = NotificationNavigationData.fromIosApnsPayload(data.payload);
    } on FormatException catch (e, st) {
      assert(debugLog('$e\n$st'));
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle);
      return null;
    }

    return _routeForNotification(context, notifNavData);
  }

  /// Provides the route to open by parsing the notification payload.
  ///
  /// Returns null and shows an error dialog if the associated account is not
  /// found in the global store.
  AccountRoute<void>? _routeForNotification(BuildContext context, NotificationNavigationData data) {
    final globalStore = GlobalStoreWidget.of(context);

    final account = globalStore.accounts.firstWhereOrNull(
      (account) => account.realmUrl.origin == data.realmUrl.origin
                && account.userId == data.userId);
    if (account == null) { // TODO(log)
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountLoggedOut);
      return null;
    }

    return MessageListPage.buildRoute(
      accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      narrow: data.narrow);
  }
}

class NotificationNavigationData {
  final Uri realmUrl;
  final int userId;
  final Narrow narrow;

  NotificationNavigationData({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  }) : assert(narrow is TopicNarrow || narrow is DmNarrow);

  /// Parses the iOS APNs payload and retrieves the information
  /// required for navigation.
  factory NotificationNavigationData.fromIosApnsPayload(Map<Object?, Object?> payload) {
    if (payload case {
      'zulip': {
        'user_id': final int userId,
        'sender_id': final int senderId,
      } && final zulipData,
    }) {
      final eventType = zulipData['event'];
      if (eventType != null && eventType != 'message') {
        // On Android, we also receive "remove" notification messages, tagged
        // with an `event` field with value 'remove'. As of Zulip Server 10,
        // however, these are not yet sent to iOS devices, and we don't have a
        // way to handle them even if they were.
        //
        // The messages we currently do receive, and can handle, are analogous
        // to Android notification messages of event type 'message'. On the
        // assumption that some future version of the Zulip server will send
        // explicit event types in APNs messages, accept messages with that
        // `event` value, but no other.
        throw const FormatException();
      }

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
          // TODO(server-5) remove this comment.
          // We require 'stream_id' here but that is new from Server 5.0,
          // resulting in failure on pre-5.0 servers.
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
          DmNarrow.withUser(senderId, selfUserId: userId),

        _ => throw const FormatException(),
      };

      return NotificationNavigationData(
        realmUrl: Uri.parse(realmUrl),
        userId: userId,
        narrow: narrow);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }
}
