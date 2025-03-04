
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

class NotificationOpenManager {
  static NotificationOpenManager get instance => (_instance ??= NotificationOpenManager._());
  static NotificationOpenManager? _instance;

  NotificationOpenManager._();

  NotificationPayloadForOpen? _notifLaunchData;

  Future<void> init() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        _notifLaunchData = await _notifPigeonApi.getNotificationDataFromLaunch();
        _notifPigeonApi.notificationTapEventsStream()
          .listen(_navigateForNotification);

      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
  }

  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    final data = _notifLaunchData;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));
    return _routeForNotification(context, data);
  }

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

  Future<void> _navigateForNotification(NotificationPayloadForOpen data) async {
    assert(debugLog('opened notif: ${jsonEncode(data.payload)}'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final route = _routeForNotification(context, data);
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

  factory NotificationDataForOpen.fromNotificationPayload(Map<Object?, Object?> payload) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => NotificationDataForOpen._fromAndroid(payload),
      TargetPlatform.iOS => NotificationDataForOpen._fromIos(payload),
      _ => throw UnsupportedError('Unsupported target platform: "$defaultTargetPlatform"'),
    };
  }

  factory NotificationDataForOpen._fromIos(Map<Object?, Object?> payload) {
    if (payload case {'aps': {'custom': {
      'zulip': {
        'user_id': final int userId,
        'sender_id': final int senderId,
      } && final zulipData,
    }}}) {
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

  factory NotificationDataForOpen._fromAndroid(Map<Object?, Object?> payload) {
    if (payload case {
      'realm_url': final String realmUrlStr,
      'user_id': final String userIdStr,
    } && final data) {
      final userId = int.parse(userIdStr, radix: 10);

      final narrow = switch (data) {
        {
          'narrow_type': 'topic',
          'channel_id': final String channelIdStr,
          'topic': final String topicStr,
        } =>
          TopicNarrow(
            int.parse(channelIdStr, radix: 10),
            TopicName.fromJson(topicStr)),

        {
          'narrow_type': 'dm',
          'all_recipient_ids': final String allRecipientIdsStr,
        } =>
          DmNarrow(
            allRecipientIds: allRecipientIdsStr
              .split(',')
              .map((e) => int.parse(e, radix: 10))
              .toList(growable: false)..sort(),
            selfUserId: userId),

        _ => throw const FormatException(),
      };

      return NotificationDataForOpen(
        realmUrl: Uri.parse(realmUrlStr),
        userId: userId,
        narrow: narrow);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }

  Map<String, String> toAndroidMap() {
    return {
      'realm_url': realmUrl.toString(),
      'user_id': userId.toString(),
      ...(switch (narrow) {
        TopicNarrow(streamId: final channelId, :final topic) => {
          'narrow_type': 'topic',
          'channel_id': channelId.toString(),
          'topic': topic.toJson(),
        },
        DmNarrow(:final allRecipientIds) => {
          'narrow_type': 'dm',
          'all_recipient_ids': allRecipientIds.join(','),
        },
        // This case should be unreachable.
        _ => throw UnsupportedError('Unknown narrow of type "${narrow.runtimeType}"'),
      }),
    };
  }
}
