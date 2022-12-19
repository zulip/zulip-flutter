import 'dart:convert';

import '../core.dart';
import '../model/initial_snapshot.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue(ApiConnection connection) async {
  final data = await connection.post('register', {
    'apply_markdown': true,
    'slim_presence': true,
    'client_capabilities': {
      'notification_settings_null': true,
      'bulk_message_deletion': true,
      'user_avatar_url_field_optional': true,
      'stream_typing_notifications': false, // TODO implement
      'user_settings_object': true,
    },
  });
  final json = jsonDecode(data);
  return InitialSnapshot.fromJson(json);
}
