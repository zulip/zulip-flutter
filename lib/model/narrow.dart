
// A Zulip narrow.
abstract class Narrow {
  /// This const constructor allows subclasses to have const constructors.
  const Narrow();
}

/// The narrow called "All messages" in the UI.
///
/// This does not literally mean all messages, or even all messages
/// that the user has access to: in particular it excludes muted streams
/// and topics.
class AllMessagesNarrow extends Narrow {
  const AllMessagesNarrow();

  @override
  bool operator ==(Object other) {
    // Conceptually this is a sealed class, so equality is simplified.
    // TODO(dart-3): Make this actually a sealed class.
    if (other is! AllMessagesNarrow) return false;
    // Conceptually there's only one value of this type.
    return true;
  }

  @override
  int get hashCode => 'AllMessagesNarrow'.hashCode;
}

// TODO other narrow types
