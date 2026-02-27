import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';
import '../model/narrow.dart';

part 'messages.g.dart';

/// https://zulip.com/api/get-message
Future<GetMessageResult> getMessage(ApiConnection connection, {
  required int messageId,
  bool? applyMarkdown,
  required bool allowEmptyTopicName,
}) {
  assert(allowEmptyTopicName, '`allowEmptyTopicName` should only be true');
  return connection.get('getMessage', GetMessageResult.fromJson, 'messages/$messageId', {
    'apply_markdown': ?applyMarkdown,
    'allow_empty_topic_name': allowEmptyTopicName,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetMessageResult {
  // final String rawContent; // deprecated; ignore
  @JsonKey(fromJson: Message.fromJson)
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
  required bool allowEmptyTopicName,
  // bool? useFirstUnreadAnchor // omitted because deprecated
}) {
  assert(allowEmptyTopicName, '`allowEmptyTopicName` should only be true');
  return connection.get('getMessages', GetMessagesResult.fromJson, 'messages', {
    'narrow': resolveApiNarrowForServer(narrow, connection.zulipFeatureLevel!),
    'anchor': RawParameter(anchor.toJson()),
    'include_anchor': ?includeAnchor,
    'num_before': numBefore,
    'num_after': numAfter,
    'client_gravatar': ?clientGravatar,
    'apply_markdown': ?applyMarkdown,
    'allow_empty_topic_name': allowEmptyTopicName,
  });
}

/// An anchor value for [getMessages].
///
/// https://zulip.com/api/get-messages#parameter-anchor
sealed class Anchor {
  /// This const constructor allows subclasses to have const constructors.
  const Anchor();

  String toJson();
}

/// An anchor value for [getMessages] other than a specific message ID.
///
/// https://zulip.com/api/get-messages#parameter-anchor
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum AnchorCode implements Anchor {
  newest, oldest, firstUnread;

  @override
  String toJson() => _$AnchorCodeEnumMap[this]!;
}

/// A specific message ID, used as an anchor in [getMessages].
class NumericAnchor extends Anchor {
  const NumericAnchor(this.messageId);
  final int messageId;

  @override
  String toJson() => messageId.toString();
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetMessagesResult {
  final int anchor;
  final bool foundNewest;
  final bool foundOldest;
  final bool foundAnchor;
  final bool historyLimited;
  @JsonKey(fromJson: _messagesFromJson)
  final List<Message> messages;

  GetMessagesResult({
    required this.anchor,
    required this.foundNewest,
    required this.foundOldest,
    required this.foundAnchor,
    required this.historyLimited,
    required this.messages,
  });

  static List<Message> _messagesFromJson(Object json) {
    return (json as List<dynamic>)
      .map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  factory GetMessagesResult.fromJson(Map<String, dynamic> json) =>
      _$GetMessagesResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetMessagesResultToJson(this);
}

// https://zulip.com/api/send-message#parameter-content
const int kMaxMessageLengthCodePoints = 10000;

/// https://zulip.com/api/send-message
Future<SendMessageResult> sendMessage(
  ApiConnection connection, {
  required MessageDestination destination,
  required String content,
  String? queueId,
  String? localId,
  bool? readBySender,
}) {
  final supportsTypeDirect = connection.zulipFeatureLevel! >= 174; // TODO(server-7)
  final supportsReadBySender = connection.zulipFeatureLevel! >= 236; // TODO(server-8)
  return connection.post('sendMessage', SendMessageResult.fromJson, 'messages', {
    ...(switch (destination) {
      StreamDestination() => {
        'type': RawParameter('stream'),
        'to': destination.streamId,
        'topic': RawParameter(destination.topic.apiName),
      },
      DmDestination() => {
        'type': supportsTypeDirect ? RawParameter('direct') : RawParameter('private'),
        'to': destination.userIds,
      }}),
    'content': RawParameter(content),
    if (queueId != null) 'queue_id': RawParameter(queueId),
    if (localId != null) 'local_id': RawParameter(localId),
    'read_by_sender': ?readBySender,
  },
  overrideUserAgent: switch ((supportsReadBySender, readBySender)) {
    // Old servers use the user agent to decide if we're a UI client
    // and so whether the message should be marked as read for its author
    // (see #440). We are a UI client; so, use a value those servers will
    // interpret correctly. With newer servers, passing `readBySender: true`
    // gives the same result.
    // TODO(#467) include platform, platform version, and app version
    (false, _   ) => 'ZulipMobile/flutter',

    // According to the doc, a user-agent heuristic is still used in this case:
    //   https://zulip.com/api/send-message#parameter-read_by_sender
    // TODO find out if our default user agent would work with that.
    // TODO(#467) include platform, platform version, and app version
    (true,  null) => 'ZulipMobile/flutter',

    _             => null,
  });
}

/// Which conversation to send a message to, in [sendMessage].
///
/// This is either a [StreamDestination] or a [DmDestination].
sealed class MessageDestination {
  const MessageDestination();
}

/// A conversation in a stream, for specifying to [sendMessage].
///
/// The server accepts a stream name as an alternative to a stream ID,
/// but this binding currently doesn't.
class StreamDestination extends MessageDestination {
  const StreamDestination(this.streamId, this.topic);

  final int streamId;
  final TopicName topic;
}

/// A DM conversation, for specifying to [sendMessage].
///
/// The server accepts a list of Zulip API emails as an alternative to
/// a list of user IDs, but this binding currently doesn't.
class DmDestination extends MessageDestination {
  const DmDestination({required this.userIds});

  final List<int> userIds;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SendMessageResult {
  final int id;

  SendMessageResult({
    required this.id,
  });

  factory SendMessageResult.fromJson(Map<String, dynamic> json) =>
    _$SendMessageResultFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageResultToJson(this);
}

/// https://zulip.com/api/update-message
Future<UpdateMessageResult> updateMessage(
  ApiConnection connection, {
  required int messageId,
  TopicName? topic,
  PropagateMode? propagateMode,
  bool? sendNotificationToOldThread,
  bool? sendNotificationToNewThread,
  String? content,
  String? prevContentSha256,
  int? streamId,
}) {
  return connection.patch('updateMessage', UpdateMessageResult.fromJson, 'messages/$messageId', {
    if (topic != null) 'topic': RawParameter(topic.apiName),
    if (propagateMode != null) 'propagate_mode': RawParameter(propagateMode.toJson()),
    'send_notification_to_old_thread': ?sendNotificationToOldThread,
    'send_notification_to_new_thread': ?sendNotificationToNewThread,
    if (content != null) 'content': RawParameter(content),
    if (prevContentSha256 != null) 'prev_content_sha256': RawParameter(prevContentSha256),
    'stream_id': ?streamId,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageResult {
  // final List<DetachedUpload> detachedUploads; // TODO handle

  UpdateMessageResult();

  factory UpdateMessageResult.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageResultFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMessageResultToJson(this);
}

/// https://zulip.com/api/delete-message
Future<void> deleteMessage(
  ApiConnection connection, {
  required int messageId,
}) {
  return connection.delete('deleteMessage', (_) {}, 'messages/$messageId', {});
}

/// Report a message to moderators.
///
/// This sends a report to the organization's moderation channel.
/// The feature is only available when the realm has a moderation request
/// channel configured.
///
/// See: https://zulip.com/help/report-a-message
Future<void> reportMessage(
  ApiConnection connection, {
  required int messageId,
  required String reportType,
  String? description,
}) {
  return connection.post('reportMessage', (_) {}, 'messages/$messageId/report', {
    'report_type': RawParameter(reportType),
    if (description != null && description.isNotEmpty)
      'description': RawParameter(description),
  });
}

/// https://zulip.com/api/upload-file
Future<UploadFileResult> uploadFile(
  ApiConnection connection, {
  required Stream<List<int>> content,
  required int length,
  required String filename,
  required String? contentType,
}) {
  return connection.postFileFromStream('uploadFile', UploadFileResult.fromJson, 'user_uploads',
    content, length, filename: filename, contentType: contentType);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UploadFileResult {
  @JsonKey(name: 'uri')
  final String url;

  UploadFileResult({
    required this.url,
  });

  factory UploadFileResult.fromJson(Map<String, dynamic> json) =>
    _$UploadFileResultFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileResultToJson(this);
}

/// https://zulip.com/api/get-file-temporary-url
Future<GetFileTemporaryUrlResult> getFileTemporaryUrl(ApiConnection connection, {
  required int realmId,
  required String filename,
}) {
  return connection.get('getFileTemporaryUrl', GetFileTemporaryUrlResult.fromJson,
    'user_uploads/$realmId/$filename', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetFileTemporaryUrlResult {
  final String url;

  GetFileTemporaryUrlResult({
    required this.url,
  });

  factory GetFileTemporaryUrlResult.fromJson(Map<String, dynamic> json) =>
    _$GetFileTemporaryUrlResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetFileTemporaryUrlResultToJson(this);
}

/// https://zulip.com/api/add-reaction
Future<void> addReaction(ApiConnection connection, {
  required int messageId,
  required ReactionType reactionType,
  required String emojiCode,
  required String emojiName,
}) {
  return connection.post('addReaction', (_) {}, 'messages/$messageId/reactions', {
    'emoji_name': RawParameter(emojiName),
    'emoji_code': RawParameter(emojiCode),
    'reaction_type': RawParameter(reactionType.toJson()),
  });
}

/// https://zulip.com/api/remove-reaction
Future<void> removeReaction(ApiConnection connection, {
  required int messageId,
  required ReactionType reactionType,
  required String emojiCode,
  required String emojiName,
}) {
  return connection.delete('removeReaction', (_) {}, 'messages/$messageId/reactions', {
    'emoji_name': RawParameter(emojiName),
    'emoji_code': RawParameter(emojiCode),
    'reaction_type': RawParameter(reactionType.toJson()),
  });
}

/// https://zulip.com/api/update-message-flags
Future<UpdateMessageFlagsResult> updateMessageFlags(ApiConnection connection, {
  required List<int> messages,
  required UpdateMessageFlagsOp op,
  required MessageFlag flag,
}) {
  return connection.post('updateMessageFlags', UpdateMessageFlagsResult.fromJson, 'messages/flags', {
    'messages': messages,
    'op': RawParameter(op.toJson()),
    'flag': RawParameter(flag.toJson()),
  });
}

/// An `op` value for [updateMessageFlags] and [updateMessageFlagsForNarrow].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum UpdateMessageFlagsOp {
  add,
  remove;

  String toJson() => _$UpdateMessageFlagsOpEnumMap[this]!;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageFlagsResult {
  final List<int> messages;

  UpdateMessageFlagsResult({
    required this.messages,
  });

  factory UpdateMessageFlagsResult.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageFlagsResultFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMessageFlagsResultToJson(this);
}

/// https://zulip.com/api/update-message-flags-for-narrow
Future<UpdateMessageFlagsForNarrowResult> updateMessageFlagsForNarrow(ApiConnection connection, {
  required Anchor anchor,
  bool? includeAnchor,
  required int numBefore,
  required int numAfter,
  required ApiNarrow narrow,
  required UpdateMessageFlagsOp op,
  required MessageFlag flag,
}) {
  return connection.post('updateMessageFlagsForNarrow', UpdateMessageFlagsForNarrowResult.fromJson, 'messages/flags/narrow', {
    'anchor': RawParameter(anchor.toJson()),
    'include_anchor': ?includeAnchor,
    'num_before': numBefore,
    'num_after': numAfter,
    'narrow': resolveApiNarrowForServer(narrow, connection.zulipFeatureLevel!),
    'op': RawParameter(op.toJson()),
    'flag': RawParameter(flag.toJson()),
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateMessageFlagsForNarrowResult {
  final int processedCount;
  final int updatedCount;
  final int? firstProcessedId;
  final int? lastProcessedId;
  final bool foundOldest;
  final bool foundNewest;

  UpdateMessageFlagsForNarrowResult({
    required this.processedCount,
    required this.updatedCount,
    required this.firstProcessedId,
    required this.lastProcessedId,
    required this.foundOldest,
    required this.foundNewest,
  });

  factory UpdateMessageFlagsForNarrowResult.fromJson(Map<String, dynamic> json) =>
    _$UpdateMessageFlagsForNarrowResultFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMessageFlagsForNarrowResultToJson(this);
}

/// https://zulip.com/api/get-read-receipts
Future<GetReadReceiptsResult> getReadReceipts(ApiConnection connection, {
  required int messageId,
}) {
  return connection.get('getReadReceipts', GetReadReceiptsResult.fromJson,
    'messages/$messageId/read_receipts', null);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetReadReceiptsResult {
  const GetReadReceiptsResult({required this.userIds});

  final List<int> userIds;

  factory GetReadReceiptsResult.fromJson(Map<String, dynamic> json) =>
    _$GetReadReceiptsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetReadReceiptsResultToJson(this);
}
