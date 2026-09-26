import '../core.dart';

/// https://zulip.com/api/remove-attachment
Future<void> removeAttachment(ApiConnection connection, {
  required int attachmentId,
}) {
  return connection.delete('removeAttachment', (_) {}, 'attachments/$attachmentId', {});
}
