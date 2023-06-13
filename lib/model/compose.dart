import 'dart:math';

//
// Put functions for nontrivial message-content generation in this file.
//
// If it's complicated enough to need tests, it should go in here.
//

// https://spec.commonmark.org/0.30/#fenced-code-blocks
final RegExp _openingBacktickFenceRegex = (() {
  // Recognize a fence with "up to three spaces of indentation".
  // Servers don't recognize fences that start with spaces, as of Server 7.0:
  //   https://chat.zulip.org/#narrow/stream/6-frontend/topic/quote-and-reply.20fence.20length/near/1588273
  // but that's a bug, since those fences are valid in the spec.
  // Still, it's harmless to make our own fence longer even if the server
  // wouldn't notice the internal fence that we're steering clear of,
  // and if servers *do* start following the spec by noticing indented internal
  // fences, then this client behavior will be nice.
  const lineStart = r'^ {0,3}';

  // The backticks, captured so we can see how many.
  const backticks = r'(`{3,})';

  // The "info string" plus (meaningless) leading or trailing spaces or tabs.
  // It can't contain backticks.
  const trailing = r'[^`]*$';
  return RegExp(lineStart + backticks + trailing, multiLine: true);
})();

/// The shortest backtick fence that's longer than any in [content].
///
/// Expressed as a number of backticks.
///
/// Use this for quote-and-reply or anything else that requires wrapping
/// Markdown in a backtick fence.
///
/// See the CommonMark spec, which Zulip servers should but don't always follow:
///   https://spec.commonmark.org/0.30/#fenced-code-blocks
int getUnusedBacktickFenceLength(String content) {
  final matches = _openingBacktickFenceRegex.allMatches(content);
  int result = 3;
  for (final match in matches) {
    result = max(result, match[1]!.length + 1);
  }
  return result;
}

/// Wrap Markdown [content] with opening and closing backtick fences.
///
/// For example, for this Markdown:
///
///     ```javascript
///     console.log('Hello world!');
///     ```
///
/// this function, with `infoString: 'quote'`, gives
///
///     ````quote
///     ```javascript
///     console.log('Hello world!');
///     ```
///     ````
///
/// See the CommonMark spec, which Zulip servers should but don't always follow:
///   https://spec.commonmark.org/0.30/#fenced-code-blocks
// In [content], indented code blocks
//   ( https://spec.commonmark.org/0.30/#indented-code-blocks )
// and code blocks fenced with tildes should make no difference to the
// backtick fences we choose here; this function ignores them.
String wrapWithBacktickFence({required String content, String? infoString}) {
  assert(infoString == null || !infoString.contains('`'));
  assert(infoString == null || infoString.trim() == infoString);

  StringBuffer resultBuffer = StringBuffer();

  // CommonMark doesn't require closing fences to be paired:
  //   https://github.com/zulip/zulip-flutter/pull/179#discussion_r1228712591
  //
  // - We need our opening fence to be long enough that it won't be closed by
  //   any fence in the content.
  // - We need our closing fence to be long enough that it will close any
  //   outstanding opening fences in the content.
  final fenceLength = getUnusedBacktickFenceLength(content);

  resultBuffer.write('`' * fenceLength);
  if (infoString != null) {
    resultBuffer.write(infoString);
  }
  resultBuffer.write('\n');
  resultBuffer.write(content);
  if (content.isNotEmpty && !content.endsWith('\n')) {
    resultBuffer.write('\n');
  }
  resultBuffer.write('`' * fenceLength);
  resultBuffer.write('\n');
  return resultBuffer.toString();
}

// TODO more, like /near links to messages in conversations
//   (also to be used in quote-and-reply)
