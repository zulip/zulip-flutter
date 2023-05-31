
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

// TODO other narrow types: PMs/DMs; starred, mentioned; searches; arbitrary
