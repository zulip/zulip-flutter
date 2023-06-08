
import '../api/model/model.dart';
import '../api/model/narrow.dart';

/// A Zulip narrow.
sealed class Narrow {
  /// This const constructor allows subclasses to have const constructors.
  const Narrow();

  // TODO implement muting; will need containsMessage to take more params
  //   This means stream muting, topic un/muting, and user muting.
  bool containsMessage(Message message);

  /// This narrow, expressed as an [ApiNarrow].
  ApiNarrow apiEncode();
}

/// The narrow called "All messages" in the UI.
///
/// This does not literally mean all messages, or even all messages
/// that the user has access to: in particular it excludes muted streams
/// and topics.
class AllMessagesNarrow extends Narrow {
  const AllMessagesNarrow();

  @override
  bool containsMessage(Message message) {
    return true;
  }

  @override
  ApiNarrow apiEncode() => [];

  @override
  bool operator ==(Object other) {
    if (other is! AllMessagesNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'AllMessagesNarrow'.hashCode;
}

class StreamNarrow extends Narrow {
  const StreamNarrow(this.streamId);

  final int streamId;

  @override
  bool containsMessage(Message message) {
    return message is StreamMessage && message.streamId == streamId;
  }

  @override
  ApiNarrow apiEncode() => [ApiNarrowStream(streamId)];

  @override
  bool operator ==(Object other) {
    if (other is! StreamNarrow) return false;
    return other.streamId == streamId;
  }

  @override
  int get hashCode => Object.hash('StreamNarrow', streamId);
}

class TopicNarrow extends Narrow {
  const TopicNarrow(this.streamId, this.topic);

  final int streamId;
  final String topic;

  @override
  bool containsMessage(Message message) {
    return (message is StreamMessage
      && message.streamId == streamId && message.subject == topic);
  }

  @override
  ApiNarrow apiEncode() => [ApiNarrowStream(streamId), ApiNarrowTopic(topic)];

  @override
  bool operator ==(Object other) {
    if (other is! TopicNarrow) return false;
    return other.streamId == streamId && other.topic == topic;
  }

  @override
  int get hashCode => Object.hash('TopicNarrow', streamId, topic);
}

bool _isSortedWithoutDuplicates(List<int> items) {
  final length = items.length;
  if (length == 0) {
    return true;
  }
  int lastItem = items[0];
  for (int i = 1; i < length; i++) {
    final item = items[i];
    if (item <= lastItem) {
      return false;
    }
    lastItem = item;
  }
  return true;
}

/// The narrow for a direct-message conversation.
// Zulip has many ways of representing a DM conversation; for example code
// handling many of them, see zulip-mobile:src/utils/recipient.js .
// Please add more constructors and getters here to handle any of those
// as we turn out to need them.
class DmNarrow extends Narrow {
  DmNarrow({required this.allRecipientIds, required int selfUserId})
    : assert(_isSortedWithoutDuplicates(allRecipientIds)),
      assert(allRecipientIds.contains(selfUserId)),
      _selfUserId = selfUserId;

  /// The user IDs of everyone in the conversation, sorted.
  ///
  /// Each message in the conversation is sent by one of these users
  /// and received by all the other users.
  ///
  /// The self-user is always a member of this list.
  /// It has one element for the self-1:1 thread,
  /// two elements for other 1:1 threads,
  /// and three or more elements for a group DM thread.
  ///
  /// See also:
  /// * [otherRecipientIds], an alternate way of identifying the conversation.
  /// * [DmMessage.allRecipientIds], which provides this same format.
  final List<int> allRecipientIds;

  /// The user ID of the self-user.
  ///
  /// The [DmNarrow] implementation needs this information
  /// for converting between different forms of referring to the narrow,
  /// such as [allRecipientIds] vs. [otherRecipientIds].
  final int _selfUserId;

  /// The user IDs of everyone in the conversation except self, sorted.
  ///
  /// This is empty for the self-1:1 thread,
  /// has one element for other 1:1 threads,
  /// and has two or more elements for a group DM thread.
  ///
  /// See also:
  /// * [allRecipientIds], an alternate way of identifying the conversation.
  late final List<int> otherRecipientIds = allRecipientIds
    .where((userId) => userId != _selfUserId)
    .toList(growable: false);

  /// A string that uniquely identifies the DM conversation (within the account).
  late final String _key = otherRecipientIds.join(',');

  @override
  bool containsMessage(Message message) {
    if (message is! DmMessage) return false;
    if (message.allRecipientIds.length != allRecipientIds.length) return false;
    int i = 0;
    for (final userId in message.allRecipientIds) {
      if (userId != allRecipientIds[i]) return false;
      i++;
    }
    return true;
  }

  // Not [otherRecipientIds], because for the self-1:1 thread that triggers
  // a server bug as of Zulip Server 7 (2023-05): an empty list here
  // causes a 5xx response from the server.
  @override
  ApiNarrow apiEncode() => [ApiNarrowDm(allRecipientIds)];

  @override
  bool operator ==(Object other) {
    if (other is! DmNarrow) return false;
    assert(other._selfUserId == _selfUserId,
      'Two [Narrow]s belonging to different accounts were compared with `==`.  '
      'This is a bug, because a [Narrow] does not contain information to '
      'reliably detect such a comparison, so it may produce false positives.');
    return other._key == _key;
  }

  @override
  int get hashCode => Object.hash('DmNarrow', _key);
}

// TODO other narrow types: starred, mentioned; searches; arbitrary
