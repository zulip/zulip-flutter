import '../core.dart';

/// https://zulip.com/api/create-saved-snippet
Future<void> createSavedSnippet(ApiConnection connection, {
  required String title,
  required String content,
}) {
  return connection.post('createSavedSnippet', (_) {}, 'saved_snippets', {
    'title': RawParameter(title),
    'content': RawParameter(content),
  });
}
