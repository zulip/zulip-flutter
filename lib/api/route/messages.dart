import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';

part 'messages.g.dart';

/// https://zulip.com/api/get-messages
Future<GetMessagesResult> getMessages(ApiConnection connection, {
  required Anchor anchor,
  required int numBefore,
  required int numAfter,
}) {
  return connection.get('getMessages', GetMessagesResult.fromJson, 'messages', {
    // 'narrow': [], // TODO parametrize
    'anchor': switch (anchor) {
      NumericAnchor(:var messageId) => messageId,
      AnchorCode.newest             => RawParameter('newest'),
      AnchorCode.oldest             => RawParameter('oldest'),
      AnchorCode.firstUnread        => RawParameter('first_unread'),
    },
    'num_before': numBefore,
    'num_after': numAfter,
  });
}

/// An anchor value for [getMessages].
///
/// https://zulip.com/api/get-messages#parameter-anchor
sealed class Anchor {
  /// This const constructor allows subclasses to have const constructors.
  const Anchor();
}

/// An anchor value for [getMessages] other than a specific message ID.
///
/// https://zulip.com/api/get-messages#parameter-anchor
enum AnchorCode implements Anchor { newest, oldest, firstUnread }

/// A specific message ID, used as an anchor in [getMessages].
class NumericAnchor extends Anchor {
  const NumericAnchor(this.messageId);
  final int messageId;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetMessagesResult {
  final int anchor;
  final bool foundNewest;
  final bool foundOldest;
  final bool foundAnchor;
  final bool historyLimited;
  final List<Message> messages;

  GetMessagesResult({
    required this.anchor,
    required this.foundNewest,
    required this.foundOldest,
    required this.foundAnchor,
    required this.historyLimited,
    required this.messages,
  });

  factory GetMessagesResult.fromJson(Map<String, dynamic> json) =>
      _$GetMessagesResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetMessagesResultToJson(this);
}

// https://zulip.com/api/send-message#parameter-topic
const int kMaxTopicLength = 60;

// https://zulip.com/api/send-message#parameter-content
const int kMaxMessageLengthCodePoints = 10000;

/// The topic servers understand to mean "there is no topic".
///
/// This should match
///   https://github.com/zulip/zulip/blob/6.0/zerver/actions/message_edit.py#L940
/// or similar logic at the latest `main`.
// This is hardcoded in the server, and therefore untranslated; that's
// zulip/zulip#3639.
const String kNoTopicTopic = '(no topic)';

/// https://zulip.com/api/send-message
// TODO currently only handles stream messages; fix
Future<SendMessageResult> sendMessage(
  ApiConnection connection, {
  required String content,
  required String topic,
}) {
  // assert() is less verbose but would have no effect in production, I think:
  //   https://dart.dev/guides/language/language-tour#assert
  if (connection.realmUrl.origin != 'https://chat.zulip.org') {
    throw Exception('This binding can currently only be used on https://chat.zulip.org.');
  }

  return connection.post('sendMessage', SendMessageResult.fromJson, 'messages', {
    'type': RawParameter('stream'), // TODO parametrize
    'to': 7, // TODO parametrize; this is `#test here`
    'topic': RawParameter(topic),
    'content': RawParameter(content),
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SendMessageResult {
  final int id;
  final String? deliverAt;

  SendMessageResult({
    required this.id,
    this.deliverAt,
  });

  factory SendMessageResult.fromJson(Map<String, dynamic> json) =>
    _$SendMessageResultFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageResultToJson(this);
}

/// https://zulip.com/api/upload-file
Future<UploadFileResult> uploadFile(
  ApiConnection connection, {
  required Stream<List<int>> content,
  required int length,
  required String filename,
}) {
  return connection.postFileFromStream('uploadFile', UploadFileResult.fromJson, 'user_uploads',
    content, length, filename: filename);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UploadFileResult {
  final String uri;

  UploadFileResult({
    required this.uri,
  });

  factory UploadFileResult.fromJson(Map<String, dynamic> json) =>
    _$UploadFileResultFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileResultToJson(this);
}
