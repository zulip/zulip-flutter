import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../store.dart';
import '../model/initial_snapshot.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue(Account account) async {
  final response = await http.post(
      Uri.parse("${account.realmUrl}/api/v1/register"),
      headers: _headers(account),
      body: {
        'apply_markdown': 'true',
        'slim_presence': 'true',
        'client_capabilities': jsonEncode({
          'notification_settings_null': true,
          'bulk_message_deletion': true,
          'user_avatar_url_field_optional': true,
          'stream_typing_notifications': false, // TODO implement
          'user_settings_object': true,
        }),
      });
  if (response.statusCode != 200) {
    throw Exception("registerQueue: status ${response.statusCode}");
  }
  final json = jsonDecode(response.body);
  return InitialSnapshot.fromJson(json);
}

Map<String, String> _headers(Account account) {
  final authBytes = utf8.encode("${account.email}:${account.apiKey}");
  return {
    'Authorization': 'Basic ${base64.encode(authBytes)}',
  };
}
