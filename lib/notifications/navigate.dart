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
class NotificationNavigationService {
  static NotificationNavigationService get instance => (_instance ??= NotificationNavigationService._());
  static NotificationNavigationService? _instance;

  NotificationNavigationService._();

  /// Reset the state of the [NotificationNavigationService], for testing.
  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }

  NotificationDataFromLaunch? _notifDataFromLaunch;

  /// A [Future] that completes to signal that the initialization of
  /// [NotificationNavigationService] has completed or errored.
  ///
  /// Returns null if [start] wasn't called yet.
  Future<void>? get initializationFuture => _initializedSignal?.future;

  Completer<void>? _initializedSignal;

  Future<void> start() async {
    assert(_initializedSignal == null);
    _initializedSignal = Completer<void>();
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
  /// an error occurs while determining the route for the notification.
  /// In the latter case an error dialog is also shown.
  ///
  /// The context argument is used to look up the [Navigator], which is used
  /// to show an error dialog if there is a failure.
  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    final data = _notifDataFromLaunch;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));

    final notifNavData = _tryParsePayload(context, data.payload);
    if (notifNavData == null) return null; // TODO(log)

    return routeForNotification(context, notifNavData);
  }

  /// Provides the route to open by parsing the notification payload.
  ///
  /// Returns null and shows an error dialog if the associated account is not
  /// found in the global store.
  static AccountRoute<void>? routeForNotification(
    BuildContext context,
    NotificationNavigationData data,
  ) {
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
      // TODO(#82): Open at specific message, not just conversation
      narrow: data.narrow);
  }

  static NotificationNavigationData? _tryParsePayload(
    BuildContext context,
    Map<Object?, Object?> payload,
  ) {
    try {
      return NotificationNavigationData.fromIosApnsPayload(payload);
    } on FormatException catch (e, st) {
      assert(debugLog('$e\n$st'));
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle);
      return null;
    }
  }

  static NotificationNavigationData? tryParseAndroidNotificationUrl(
    BuildContext context,
    Uri url,
  ) {
    try {
      return NotificationNavigationData.parseAndroidNotificationUrl(url);
    } on FormatException catch (e, st) {
      assert(debugLog('$e\n$st'));
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle);
      return null;
    }
  }
}

class NotificationNavigationData {
  final Uri realmUrl;
  final int userId;
  final SendableNarrow narrow;

  NotificationNavigationData({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  });

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

      final realmUrl = switch (zulipData) {
        {'realm_url': final String value} => value,
        {'realm_uri': final String value} => value,
        _ => throw const FormatException(),
      };

      final narrow = switch (zulipData) {
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
              .toList(growable: false)
              ..sort(),
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

  /// Parses the internal Android notification url, that was created using
  /// [buildAndroidNotificationUrl], and retrieves the information required
  /// for navigation.
  factory NotificationNavigationData.parseAndroidNotificationUrl(Uri url) {
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

      final SendableNarrow narrow;
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

      return NotificationNavigationData(
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
        })
      },
    );
  }
}
