import '../../model/narrow.dart';

class NotificationOpenPayload {
  final Uri realm;
  final int userId;
  final Narrow narrow;

  NotificationOpenPayload({
    required this.realm,
    required this.userId,
    required this.narrow,
  }): assert((narrow is TopicNarrow) ^ (narrow is DmNarrow));

  factory NotificationOpenPayload.parse(Uri url) {
    if (url case Uri(
      scheme: 'zulip',
      host: 'notification_open',
      queryParameters: {
        'realm': String realmStr,
        'user_id': String userIdStr,
        'narrow_type': String narrowType,
      },
    )) {
      final realm = Uri.tryParse(realmStr);
      if (realm == null) throw const FormatException();

      final userId = int.tryParse(userIdStr, radix: 10);
      if (userId == null) throw const FormatException();

      final Narrow narrow;
      switch (narrowType) {
        case 'topic':
          final streamIdStr = url.queryParameters['stream_id'];
          if (streamIdStr == null) throw const FormatException();
          final streamId = int.tryParse(streamIdStr, radix: 10);
          if (streamId == null) throw const FormatException();

          final topic = url.queryParameters['topic'];
          if (topic == null) throw const FormatException();

          narrow = TopicNarrow(streamId, topic);
        case 'dm':
          final allRecipientIdsStr = url.queryParameters['all_recipient_ids'];
          if (allRecipientIdsStr == null) throw const FormatException();
          final List<int> allRecipientIds = allRecipientIdsStr
            .split(',')
            .map((String idStr) {
              final id = int.tryParse(idStr, radix: 10);
              if (id == null) throw const FormatException();
              return id;
            })
            .toList();

          narrow = DmNarrow(allRecipientIds: allRecipientIds, selfUserId: userId);
        default:
          throw const FormatException();
      }

      return NotificationOpenPayload(
        realm: realm,
        userId: userId,
        narrow: narrow,
      );
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }

  Uri toUri() {
    var queryParameters = <String, String>{
      'realm': realm.toString(),
      'user_id': userId.toString(),
    };

    switch (narrow) {
      case TopicNarrow(:final streamId, :final topic):
        queryParameters = {
          ...queryParameters,
          'narrow_type': 'topic',
          'stream_id': streamId.toString(),
          'topic': topic.toString(),
        };
      case DmNarrow(:final allRecipientIds):
        queryParameters = {
          ...queryParameters,
          'narrow_type': 'dm',
          'all_recipient_ids': allRecipientIds.join(','),
        };
      default:
        throw UnimplementedError();
    }

    return Uri(
      scheme: 'zulip',
      host: 'notification_open',
      queryParameters: queryParameters,
    );
  }
}
