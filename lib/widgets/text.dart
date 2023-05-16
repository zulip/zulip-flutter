import 'dart:io';
import 'package:flutter/widgets.dart';

/// A mergeable [TextStyle] with 'Source Code Pro' and platform-aware fallbacks.
///
/// Example:
///
/// ```dart
/// kMonospaceTextStyle.merge(const TextStyle(color: Colors.red))
/// ```
final TextStyle kMonospaceTextStyle = TextStyle(
  fontFamily: 'Source Code Pro', // TODO supply font

  // Oddly, iOS doesn't handle 'monospace':
  //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20monospace.20font.20fallback/near/1570622
  fontFamilyFallback: Platform.isIOS ? ['Menlo', 'Courier'] : ['monospace'],

  inherit: true,
);
