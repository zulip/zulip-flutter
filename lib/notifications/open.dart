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
import '../widgets/home.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';

NotificationPigeonApi get _notifPigeonApi => ZulipBinding.instance.notificationPigeonApi;

/// Responds to the user opening a notification.
class NotificationOpenService {
  static NotificationOpenService get instance => (_instance ??= NotificationOpenService._());
  static NotificationOpenService? _instance;

  NotificationOpenService._();

  /// Reset the state of the [NotificationNavigationService], for testing.
  static void debugReset() {
    _instance = null;
  }

  NotificationDataFromLaunch? _notifDataFromLaunch;

  /// A [Future] that completes to signal that the initialization of
  /// [NotificationNavigationService] has completed
  /// (with either success or failure).
  ///
  /// Null if [start] hasn't been called.
  Future<void>? get initialized => _initializedSignal?.future;

  Completer<void>? _initializedSignal;

  Future<void> start() async {
    assert(_initializedSignal == null);
    _initializedSignal = Completer<void>();
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          _notifDataFromLaunch = await _notifPigeonApi.getNotificationDataFromLaunch();
          _notifPigeonApi.notificationTapEventsStream()
            .listen(_navigateForNotification);

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
  /// an error occurs while determining the route for the notification.
  /// In the latter case an error dialog is also shown.
  ///
  /// The context argument should be a descendant of the app's main [Navigator].
  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    final data = _notifDataFromLaunch;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));

    final notifNavData = _tryParseIosApnsPayload(context, data.payload);
    if (notifNavData == null) return null; // TODO(log)

    return routeForNotification(context: context, data: notifNavData);
  }

  /// Provides the route to open by parsing the notification payload.
  ///
  /// Returns null and shows an error dialog if the associated account is not
  /// found in the global store.
  ///
  /// The context argument should be a descendant of the app's main [Navigator].
  static AccountRoute<void>? routeForNotification({
    required BuildContext context,
    required NotificationOpenPayload data,
  }) {
    final globalStore = GlobalStoreWidget.of(context);

    final account = globalStore.accounts.firstWhereOrNull(
      (account) => account.realmUrl.origin == data.realmUrl.origin
                && account.userId == data.userId);
    if (account == null) { // TODO(log)
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountNotFound);
      return null;
    }

    return MessageListPage.buildRoute(
      accountId: account.id,
      // TODO(#1565): Open at specific message, not just conversation
      narrow: data.narrow);
  }

  /// Navigate appropriately for opening the given notification.
  static void _navigateForNotificationPayload(
      NavigatorState navigator, NotificationOpenPayload data) {
    assert(navigator.mounted);
    final context = navigator.context;

    final route = routeForNotification(context: context, data: data);
    if (route == null) return; // TODO(log)

    if (ZulipApp.navigationStack!.currentAccountId != route.accountId) {
      HomePage.navigate(context, accountId: route.accountId);
    }
    unawaited(navigator.push(route));
  }

  /// Navigate appropriately for opening the notification described by
  /// the given [NotificationTapEvent].
  static Future<void> _navigateForNotification(NotificationTapEvent event) async {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    assert(debugLog('opened notif: ${jsonEncode(event.payload)}'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final notifNavData = _tryParseIosApnsPayload(context, event.payload);
    if (notifNavData == null) return; // TODO(log)
    _navigateForNotificationPayload(navigator, notifNavData);
  }

  /// Navigate appropriately for opening the notification described by
  /// the given `zulip://notification/…` Android intent data URL.
  ///
  /// The URL should have been generated with
  /// [NotificationOpenPayload.buildAndroidNotificationUrl]
  /// when creating the notification.
  static Future<void> navigateForAndroidNotificationUrl(Uri url) async {
    assert(defaultTargetPlatform == TargetPlatform.android);
    assert(debugLog('opened notif: url: $url'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    assert(url.scheme == 'zulip' && url.host == 'notification');
    final data = tryParseAndroidNotificationUrl(context: context, url: url);
    if (data == null) return; // TODO(log)
    _navigateForNotificationPayload(navigator, data);
  }

  static NotificationOpenPayload? _tryParseIosApnsPayload(
    BuildContext context,
    Map<Object?, Object?> payload,
  ) {
    try {
      return NotificationOpenPayload.parseIosApnsPayload(payload);
    } on FormatException catch (e, st) {
      assert(debugLog('$e\n$st'));
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle);
      return null;
    }
  }

  static NotificationOpenPayload? tryParseAndroidNotificationUrl({
    required BuildContext context,
    required Uri url,
  }) {
    try {
      return NotificationOpenPayload.parseAndroidNotificationUrl(url);
    } on FormatException catch (e, st) {
      assert(debugLog('$e\n$st'));
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle);
      return null;
    }
  }
}

/// The data from a notification that describes what to do
/// when the user opens the notification.
class NotificationOpenPayload {
  final Uri realmUrl;
  final int userId;
  final Narrow narrow;

  NotificationOpenPayload({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  });

  /// Parses the iOS APNs payload and retrieves the information
  /// required for navigation.
  factory NotificationOpenPayload.parseIosApnsPayload(Map<Object?, Object?> payload) {
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

      final realmUrl = switch (zulipData) {
        {'realm_url': final String value} => value,
        {'realm_uri': final String value} => value,
        _ => throw const FormatException(),
      };

      final narrow = switch (zulipData) {
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
              .toList(growable: false)
              ..sort(),
            selfUserId: userId),

        {'recipient_type': 'private'} =>
          DmNarrow.withUser(senderId, selfUserId: userId),

        _ => throw const FormatException(),
      };

      return NotificationOpenPayload(
        realmUrl: Uri.parse(realmUrl),
        userId: userId,
        narrow: narrow);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }

  /// Parses the internal Android notification url, that was created using
  /// [buildAndroidNotificationUrl], and retrieves the information required
  /// for navigation.
  factory NotificationOpenPayload.parseAndroidNotificationUrl(Uri url) {
    if (url case Uri(
      scheme: 'zulip',
      host: 'notification',
      queryParameters: {
        'realm_url': var realmUrlStr,
        'user_id': var userIdStr,
        'narrow_type': var narrowType,
        // In case of narrowType == 'topic':
        // 'channel_id' and 'topic' handled below.

        // In case of narrowType == 'dm':
        // 'all_recipient_ids' handled below.
      },
    )) {
      final realmUrl = Uri.parse(realmUrlStr);
      final userId = int.parse(userIdStr, radix: 10);

      final Narrow narrow;
      switch (narrowType) {
        case 'topic':
          final channelIdStr = url.queryParameters['channel_id']!;
          final channelId = int.parse(channelIdStr, radix: 10);
          final topicStr = url.queryParameters['topic']!;
          narrow = TopicNarrow(channelId, TopicName(topicStr));
        case 'dm':
          final allRecipientIdsStr = url.queryParameters['all_recipient_ids']!;
          final allRecipientIds = allRecipientIdsStr.split(',')
            .map((idStr) => int.parse(idStr, radix: 10))
            .toList(growable: false);
          narrow = DmNarrow(allRecipientIds: allRecipientIds, selfUserId: userId);
        default:
          throw const FormatException();
      }

      return NotificationOpenPayload(
        realmUrl: realmUrl,
        userId: userId,
        narrow: narrow,
      );
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }

  Uri buildAndroidNotificationUrl() {
    return Uri(
      scheme: 'zulip',
      host: 'notification',
      queryParameters: <String, String>{
        'realm_url': realmUrl.toString(),
        'user_id': userId.toString(),
        ...(switch (narrow) {
          TopicNarrow(streamId: var channelId, :var topic) => {
            'narrow_type': 'topic',
            'channel_id': channelId.toString(),
            'topic': topic.apiName,
          },
          DmNarrow(:var allRecipientIds) => {
            'narrow_type': 'dm',
            'all_recipient_ids': allRecipientIds.join(','),
          },
          _ => throw UnsupportedError('Found an unexpected Narrow of type ${narrow.runtimeType}.'),
        })
      },
    );
  }
}
