import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../exception.dart';
import '../model/model.dart';
import '../model/narrow.dart';

part 'messages.g.dart';

/// Convenience function to get a single message from any server.
///
/// This encapsulates a server-feature check.
///
/// Gives null if the server reports that the message doesn't exist.
// TODO(server-5) Simplify this away; just use getMessage.
Future<Message?> getMessageCompat(ApiConnection connection, {
  required int messageId,
  bool? applyMarkdown,
}) async {
  final useLegacyApi = connection.zulipFeatureLevel! < 120;
  if (useLegacyApi) {
    final response = await getMessages(connection,
      narrow: [ApiNarrowMessageId(messageId)],
      anchor: NumericAnchor(messageId),
      numBefore: 0,
      numAfter: 0,
      applyMarkdown: applyMarkdown,

      // Hard-code this param to `true`, as the new single-message API
      // effectively does:
      //   https://chat.zulip.org/#narrow/stream/378-api-design/topic/.60client_gravatar.60.20in.20.60messages.2F.7Bmessage_id.7D.60/near/1418337
      clientGravatar: true,
    );
    return response.messages.firstOrNull;
  } else {
    try {
      final response = await getMessage(connection,
        messageId: messageId,
        applyMarkdown: applyMarkdown,
      );
      return response.message;
    } on ZulipApiException catch (e) {
      if (e.code == 'BAD_REQUEST') {
        // Servers use this code when the message doesn't exist, according to
        // the example in the doc.
        return null;
      }
      rethrow;
    }
  }
}

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
  return connection.get('getMessages', GetMessagesResult.fromJson, 'messages', {
    'narrow': resolveDmElements(narrow, connection.zulipFeatureLevel!),
    'anchor': RawParameter(anchor.toJson()),
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
    if (queueId != null) 'queue_id': queueId, // TODO should this use RawParameter?
    if (localId != null) 'local_id': localId, // TODO should this use RawParameter?
    if (readBySender != null) 'read_by_sender': readBySender,
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
  final String uri;

  UploadFileResult({
    required this.uri,
  });

  factory UploadFileResult.fromJson(Map<String, dynamic> json) =>
    _$UploadFileResultFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileResultToJson(this);
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
///
/// This binding only supports feature levels 155+.
// TODO(server-6) remove FL 155+ mention in doc, and the related `assert`
Future<UpdateMessageFlagsForNarrowResult> updateMessageFlagsForNarrow(ApiConnection connection, {
  required Anchor anchor,
  bool? includeAnchor,
  required int numBefore,
  required int numAfter,
  required ApiNarrow narrow,
  required UpdateMessageFlagsOp op,
  required MessageFlag flag,
}) {
  assert(connection.zulipFeatureLevel! >= 155);
  return connection.post('updateMessageFlagsForNarrow', UpdateMessageFlagsForNarrowResult.fromJson, 'messages/flags/narrow', {
    'anchor': RawParameter(anchor.toJson()),
    if (includeAnchor != null) 'include_anchor': includeAnchor,
    'num_before': numBefore,
    'num_after': numAfter,
    'narrow': resolveDmElements(narrow, connection.zulipFeatureLevel!),
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

/// https://zulip.com/api/mark-all-as-read
///
/// This binding is deprecated, in FL 155+ use
/// [updateMessageFlagsForNarrow] instead.
// TODO(server-6): Remove as deprecated by updateMessageFlagsForNarrow
//
// For FL < 153 this call was atomic on the server and would
// not mark any messages as read if it timed out.
// From FL 153 and onward the server started processing
// in batches so progress could still be made in the event
// of a timeout interruption. Thus, in FL 153 this call
// started returning `result: partially_completed` and
// `code: REQUEST_TIMEOUT` for timeouts.
//
// In FL 211 the `partially_completed` variant of
// `result` was removed, the string `code` field also
// removed, and a boolean `complete` field introduced.
//
// For full support of this endpoint we would need three
// variants of the return structure based on feature
// level (`{}`, `{code: string}`, and `{complete: bool}`)
// as well as handling of `partially_completed` variant
// of `result` in `lib/api/core.dart`. For simplicity we
// ignore these return values.
//
// We don't use this method for FL 155+ (it is replaced
// by `updateMessageFlagsForNarrow`) so there are only
// two versions (FL 153 and FL 154) affected.
Future<void> markAllAsRead(ApiConnection connection) {
  return connection.post('markAllAsRead', (_) {}, 'mark_all_as_read', {});
}

/// https://zulip.com/api/mark-stream-as-read
///
/// This binding is deprecated, in FL 155+ use
/// [updateMessageFlagsForNarrow] instead.
// TODO(server-6): Remove as deprecated by updateMessageFlagsForNarrow
Future<void> markStreamAsRead(ApiConnection connection, {
  required int streamId,
}) {
  return connection.post('markStreamAsRead', (_) {}, 'mark_stream_as_read', {
    'stream_id': streamId,
  });
}

/// https://zulip.com/api/mark-topic-as-read
///
/// This binding is deprecated, in FL 155+ use
/// [updateMessageFlagsForNarrow] instead.
// TODO(server-6): Remove as deprecated by updateMessageFlagsForNarrow
Future<void> markTopicAsRead(ApiConnection connection, {
  required int streamId,
  required TopicName topicName,
}) {
  return connection.post('markTopicAsRead', (_) {}, 'mark_topic_as_read', {
    'stream_id': streamId,
    'topic_name': RawParameter(topicName.apiName),
  });
}
