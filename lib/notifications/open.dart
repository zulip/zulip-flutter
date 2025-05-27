import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/narrow.dart';
import '../widgets/app.dart';
import '../widgets/dialog.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';

/// Responds to the user opening a notification.
class NotificationOpenService {

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
    assert(defaultTargetPlatform == TargetPlatform.android);

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

  /// Navigates to the [MessageListPage] of the specific conversation
  /// given the `zulip://notification/…` Android intent data URL,
  /// generated with [NotificationOpenPayload.buildAndroidNotificationUrl]
  /// while creating the notification.
  static Future<void> navigateForAndroidNotificationUrl(Uri url) async {
    assert(defaultTargetPlatform == TargetPlatform.android);
    assert(debugLog('opened notif: url: $url'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    assert(url.scheme == 'zulip' && url.host == 'notification');
    final data = NotificationOpenPayload.parseAndroidNotificationUrl(url);
    final route = routeForNotification(context: context, data: data);
    if (route == null) return; // TODO(log)

    // TODO(nav): Better interact with existing nav stack on notif open
    unawaited(navigator.push(route));
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
