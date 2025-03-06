import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'saved_snippets.g.dart';

/// https://zulip.com/api/create-saved-snippet
Future<CreateSavedSnippetResult> createSavedSnippet(ApiConnection connection, {
  required String title,
  required String content,
}) {
  assert(connection.zulipFeatureLevel! >= 297); // TODO(server-10)
  return connection.post('createSavedSnippet', CreateSavedSnippetResult.fromJson, 'saved_snippets', {
    'title': RawParameter(title),
    'content': RawParameter(content),
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateSavedSnippetResult {
  final int savedSnippetId;

  CreateSavedSnippetResult({
    required this.savedSnippetId,
  });

  factory CreateSavedSnippetResult.fromJson(Map<String, dynamic> json) =>
    _$CreateSavedSnippetResultFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSavedSnippetResultToJson(this);
}
