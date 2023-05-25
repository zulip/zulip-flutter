
import '../api/model/model.dart';

/// A Zulip narrow.
sealed class Narrow {
  /// This const constructor allows subclasses to have const constructors.
  const Narrow();

  bool containsMessage(Message message);
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
    // TODO implement muting; will need containsMessage to take more params
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other is! AllMessagesNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'AllMessagesNarrow'.hashCode;
}

// TODO other narrow types
