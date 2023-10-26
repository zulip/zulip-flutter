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
