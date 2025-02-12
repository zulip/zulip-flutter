import 'dart:math';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'internal_link.dart';
import 'narrow.dart';
import 'store.dart';

/// The available user wildcard mention options,
/// known to the server as [canonicalString].
///
/// See API docs:
///   https://zulip.com/api/message-formatting#mentions-and-silent-mentions
enum WildcardMentionOption {
  all(canonicalString: 'all'),
  everyone(canonicalString: 'everyone'),
  channel(canonicalString: 'channel'),
  // TODO(server-9): Deprecated in FL 247. Empirically, current servers (FL 339)
  // still parse "@**stream**" in messages though.
  stream(canonicalString: 'stream'),
  topic(canonicalString: 'topic'); // TODO(server-8): New in FL 224.

  const WildcardMentionOption({required this.canonicalString});

  /// The string identifying this option (e.g. "all" as in "@**all**").
  final String canonicalString;

  String get name => throw UnsupportedError('Use [canonicalString] instead.');
}

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

/// An @-mention of an individual user, like @**Chris Bobbe|13313**.
///
/// To omit the user ID part ("|13313") whenever the name part is unambiguous,
/// pass a Map of all users we know about. This means accepting a linear scan
/// through all users; avoid it in performance-sensitive codepaths.
String userMention(User user, {bool silent = false, Map<int, User>? users}) {
  bool includeUserId = users == null
    || users.values.where((u) => u.fullName == user.fullName).take(2).length == 2;

  return '@${silent ? '_' : ''}**${user.fullName}${includeUserId ? '|${user.userId}' : ''}**';
}

/// An @-mention of all the users in a conversation, like @**channel**.
String wildcardMention(WildcardMentionOption wildcardOption, {
  required PerAccountStore store,
}) {
  final isChannelWildcardAvailable = store.account.zulipFeatureLevel >= 247; // TODO(server-9)
  final isTopicWildcardAvailable = store.account.zulipFeatureLevel >= 224; // TODO(server-8)

  String name = wildcardOption.canonicalString;
  switch (wildcardOption) {
    case WildcardMentionOption.all:
    case WildcardMentionOption.everyone:
      break;
    case WildcardMentionOption.channel:
      assert(isChannelWildcardAvailable);
    case WildcardMentionOption.stream:
      if (isChannelWildcardAvailable) {
        name = WildcardMentionOption.channel.canonicalString;
      }
    case WildcardMentionOption.topic:
      assert(isTopicWildcardAvailable);
  }
  return '@**$name**';
}

/// https://spec.commonmark.org/0.30/#inline-link
///
/// The "link text" is made by enclosing [visibleText] in square brackets.
/// If [visibleText] has unexpected features, such as square brackets, the
/// result may be surprising.
///
/// The part between "(" and ")" is just a "link destination" (no "link title").
/// That destination is simply the stringified [destination], if provided.
/// If that has parentheses in it, the result may be surprising.
// TODO: Try harder to guarantee output that creates an inline link,
//   and in particular, the intended one. We could help with this by escaping
//   square brackets, perhaps with HTML character references:
//     https://github.com/zulip/zulip-flutter/pull/201#discussion_r1237951626
//   It's also tricky because nearby content can thwart the inline-link syntax.
//   From the spec:
//   > Backtick code spans, autolinks, and raw HTML tags bind more tightly
//   > than the brackets in link text. Thus, for example, [foo`]` could not be
//   > a link text, since the second ] is part of a code span.
String inlineLink(String visibleText, Uri? destination) {
  return '[$visibleText](${destination?.toString() ?? ''})';
}

/// What we show while fetching the target message's raw Markdown.
String quoteAndReplyPlaceholder(
  ZulipLocalizations zulipLocalizations,
  PerAccountStore store, {
  required Message message,
}) {
  final sender = store.users[message.senderId];
  assert(sender != null);
  final url = narrowLink(store,
    SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
    nearMessageId: message.id);
  // See note in [quoteAndReply] about asking `mention` to omit the |<id> part.
  return '${userMention(sender!, silent: true)} ${inlineLink('said', url)}: ' // TODO(#1285)
    '*${zulipLocalizations.composeBoxLoadingMessage(message.id)}*\n';
}

/// Quote-and-reply syntax.
///
/// The result looks like it does in Zulip web:
///
///     @_**Iago|5** [said](link to message):
///     ```quote
///     message content
///     ```
String quoteAndReply(PerAccountStore store, {
  required Message message,
  required String rawContent,
}) {
  final sender = store.users[message.senderId];
  assert(sender != null);
  final url = narrowLink(store,
    SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
    nearMessageId: message.id);
    // Could ask `mention` to omit the |<id> part unless the mention is ambiguous…
    // but that would mean a linear scan through all users, and the extra noise
    // won't much matter with the already probably-long message link in there too.
    return '${userMention(sender!, silent: true)} ${inlineLink('said', url)}:\n' // TODO(#1285)
      '${wrapWithBacktickFence(content: rawContent, infoString: 'quote')}';
}
