import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/narrow.dart';
import '../widgets/dialog.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';

/// Service for handling notification navigation.
class NotificationNavigationService {

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

/// The data from a notification that describes what to do
/// when the user opens the notification.
class NotificationNavigationData {
  final Uri realmUrl;
  final int userId;
  final SendableNarrow narrow;

  NotificationNavigationData({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  });

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
