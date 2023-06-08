import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';
import '../model/narrow.dart';

part 'messages.g.dart';

/// https://zulip.com/api/get-message
///
/// This binding only supports feature levels 120+.
// TODO(server-5) remove FL 120+ mention in doc, and the related `assert`
Future<GetMessageResult> getMessage(ApiConnection connection, {
  required int messageId,
  bool? applyMarkdown,
}) {
  assert(connection.zulipFeatureLevel! >= 120);
  return connection.get('getMessage', GetMessageResult.fromJson, 'messages/$messageId', {
    if (applyMarkdown != null) 'apply_markdown': applyMarkdown,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetMessageResult {
  // final String rawContent; // deprecated; ignore
  final Message message;

  GetMessageResult({
    required this.message,
  });

  factory GetMessageResult.fromJson(Map<String, dynamic> json) =>
    _$GetMessageResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetMessageResultToJson(this);
}

/// https://zulip.com/api/get-messages
Future<GetMessagesResult> getMessages(ApiConnection connection, {
  required ApiNarrow narrow,
  required Anchor anchor,
  bool? includeAnchor,
  required int numBefore,
  required int numAfter,
  bool? clientGravatar,
  bool? applyMarkdown,
  // bool? useFirstUnreadAnchor // omitted because deprecated
}) {
  if (narrow.any((element) => element is ApiNarrowDm)) {
    final supportsOperatorDm = connection.zulipFeatureLevel! >= 177; // TODO(server-7)
    narrow = narrow.map((element) => switch (element) {
      ApiNarrowDm() => element.resolve(legacy: !supportsOperatorDm),
      _             => element,
    }).toList();
  }
  return connection.get('getMessages', GetMessagesResult.fromJson, 'messages', {
    'narrow': narrow,
    'anchor': switch (anchor) {
      NumericAnchor(:var messageId) => messageId,
      AnchorCode.newest             => RawParameter('newest'),
      AnchorCode.oldest             => RawParameter('oldest'),
      AnchorCode.firstUnread        => RawParameter('first_unread'),
    },
    if (includeAnchor != null) 'include_anchor': includeAnchor,
    'num_before': numBefore,
    'num_after': numAfter,
    if (clientGravatar != null) 'client_gravatar': clientGravatar,
    if (applyMarkdown != null) 'apply_markdown': applyMarkdown,
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
Future<SendMessageResult> sendMessage(
  ApiConnection connection, {
  required MessageDestination destination,
  required String content,
  String? queueId,
  String? localId,
}) {
  final supportsTypeDirect = connection.zulipFeatureLevel! >= 174; // TODO(server-7)
  return connection.post('sendMessage', SendMessageResult.fromJson, 'messages', {
    if (destination is StreamDestination) ...{
      'type': RawParameter('stream'),
      'to': destination.streamId,
      'topic': RawParameter(destination.topic),
    } else if (destination is DmDestination) ...{
      'type': supportsTypeDirect ? RawParameter('direct') : RawParameter('private'),
      'to': destination.userIds,
    } else ...(
      throw Exception('impossible destination') // TODO(dart-3) show this statically
    ),
    'content': RawParameter(content),
    if (queueId != null) 'queue_id': queueId,
    if (localId != null) 'local_id': localId,
  });
}

/// Which conversation to send a message to, in [sendMessage].
///
/// This is either a [StreamDestination] or a [DmDestination].
sealed class MessageDestination {}

/// A conversation in a stream, for specifying to [sendMessage].
///
/// The server accepts a stream name as an alternative to a stream ID,
/// but this binding currently doesn't.
class StreamDestination extends MessageDestination {
  StreamDestination(this.streamId, this.topic);

  final int streamId;
  final String topic;
}

/// A DM conversation, for specifying to [sendMessage].
///
/// The server accepts a list of Zulip API emails as an alternative to
/// a list of user IDs, but this binding currently doesn't.
class DmDestination extends MessageDestination {
  DmDestination({required this.userIds});

  final List<int> userIds;
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
