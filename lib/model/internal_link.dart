import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../api/model/model.dart';
import '../api/model/narrow.dart';
import 'narrow.dart';
import 'store.dart';
import 'channel.dart';

part 'internal_link.g.dart';

const _hashReplacements = {
  "%": ".",
  "(": ".28",
  ")": ".29",
  ".": ".2E",
};

final _encodeHashComponentRegex = RegExp(r'[%().]');

// Corresponds to encodeHashComponent in Zulip web;
// see web/shared/src/internal_url.ts.
String _encodeHashComponent(String str) {
  return Uri.encodeComponent(str)
    .replaceAllMapped(_encodeHashComponentRegex, (Match m) => _hashReplacements[m[0]!]!);
}

/// Decode a dot-encoded string; return null if malformed.
// The Zulip webapp uses this encoding in narrow-links:
// https://github.com/zulip/zulip/blob/1577662a6/static/js/hash_util.js#L18-L25
@visibleForTesting
String? decodeHashComponent(String str) {
  try {
    return Uri.decodeComponent(str.replaceAll('.', '%'));
  } on ArgumentError {
    // as with '%1': Invalid argument(s): Truncated URI
    return null;
  } on FormatException {
    // as with '%FF': FormatException: Invalid UTF-8 byte (at offset 0)
    return null;
  }
}

/// A URL to the given [Narrow], on `store`'s realm.
///
/// To include /near/{messageId} in the link, pass a non-null [nearMessageId].
// Why take [nearMessageId] in a param, instead of looking for it in [narrow]?
//
// A reasonable question: after all, the "near" part of a near link (e.g., for
// quote-and-reply) does take the same form as other operator/operand pairs
// that we represent with [ApiNarrowElement]s, like "/stream/48-mobile".
//
// But unlike those other elements, we choose not to give the "near" element
// an [ApiNarrowElement] representation, because it doesn't have quite that role:
// it says where to look in a list of messages, but it doesn't filter the list down.
// In fact, from a brief look at server code, it seems to be *ignored*
// if you include it in the `narrow` param in get-messages requests.
// When you want to point the server to a location in a message list, you
// you do so by passing the `anchor` param.
Uri narrowLink(PerAccountStore store, Narrow narrow, {int? nearMessageId}) {
  final fragment = narrowLinkFragment(store, narrow, nearMessageId: nearMessageId);
  Uri result = store.realmUrl.replace(fragment: fragment);
  if (result.path.isEmpty) {
    // Always ensure that there is a '/' right after the hostname.
    // A generated URL without '/' looks odd,
    // and if used in a Zulip message does not get automatically linkified.
    result = result.replace(path: '/');
  }
  return result;
}

String narrowLinkFragment(PerAccountStore store, Narrow narrow, {int? nearMessageId}) {
  // TODO(server-7)
  final apiNarrow = resolveApiNarrowForServer(
    narrow.apiEncode(), store.zulipFeatureLevel);
  final fragment = StringBuffer('narrow');
  for (ApiNarrowElement element in apiNarrow) {
    fragment.write('/');
    if (element.negated) {
      fragment.write('-');
    }

    fragment.write('${element.operator}/');

    switch (element) {
      case ApiNarrowChannel():
        final streamId = element.operand;
        final name = store.streams[streamId]?.name ?? 'unknown';
        final slugifiedName = _encodeHashComponent(name.replaceAll(' ', '-'));
        fragment.write('$streamId-$slugifiedName');
      case ApiNarrowTopic():
        fragment.write(_encodeHashComponent(element.operand.apiName));
      case ApiNarrowDmModern():
        final suffix = element.operand.length >= 3 ? 'group' : 'dm';
        fragment.write('${element.operand.join(',')}-$suffix');
      case ApiNarrowPmWith():
        final suffix = element.operand.length >= 3 ? 'group' : 'pm';
        fragment.write('${element.operand.join(',')}-$suffix');
      case ApiNarrowDm():
        assert(false, 'ApiNarrowDm should have been resolved');
      case ApiNarrowWith():
        fragment.write(element.operand.toString());
      case ApiNarrowIs():
        fragment.write(element.operand.toString());
      case ApiNarrowMessageId():
        fragment.write(element.operand.toString());
      case ApiNarrowSearch():
        fragment.write(_encodeHashComponent(element.operand));
    }
  }

  if (nearMessageId != null) {
    fragment.write('/near/$nearMessageId');
  }

  return fragment.toString();
}

/// The result of parsing some URL within a Zulip realm,
/// when the URL corresponds to some page in this app.
sealed class InternalLink {
  InternalLink({required this.realmUrl});

  final Uri realmUrl;
}

/// The result of parsing some URL that points to a narrow on a Zulip realm,
/// when the narrow is of a type that this app understands.
class NarrowLink extends InternalLink {
  NarrowLink(this.narrow, this.nearMessageId, {required super.realmUrl});

  final Narrow narrow;
  final int? nearMessageId;
}

/// A parsed link to an uploaded file in Zulip.
///
/// The structure mirrors the data required for [getFileTemporaryUrl]:
///   https://zulip.com/api/get-file-temporary-url
class UserUploadLink extends InternalLink {
  UserUploadLink(this.realmId, this.path, {required super.realmUrl});

  static UserUploadLink? _tryParse(String urlPath, Uri realmUrl) {
    final match = _urlPathRegexp.matchAsPrefix(urlPath);
    if (match == null) return null;
    final realmId = int.parse(match.group(1)!, radix: 10);
    return UserUploadLink(realmId, match.group(2)!, realmUrl: realmUrl);
  }

  static const _urlPathPrefix = '/user_uploads/';
  static final _urlPathRegexp = RegExp(r'^/user_uploads/(\d+)/(.+)$');

  final int realmId;

  /// The remaining path components after the realm ID.
  ///
  /// This value excludes the slash that separates the realm ID from the
  /// next component, but includes the rest of the URL path after that slash.
  ///
  /// This value should only be used as part of a URL, not elsewhere
  /// in the Zulip API.  Other uses are likely to cause a new version
  /// of the following issue:
  ///   https://github.com/zulip/zulip-flutter/issues/1709
  /// Concretely, this string might differ from the corresponding substring of
  /// the original URL string (e.g., one found in the HTML of a Zulip message):
  /// if there were non-ASCII characters in the original string,
  /// then [Uri.parse] will have converted them to percent-encoded form.
  /// This is fine as part of a URL, because then the HTTP client would
  /// otherwise have had to percent-encode those characters anyway.
  ///
  /// This corresponds to `filename` in the arguments to [getFileTemporaryUrl];
  /// but it's typically several path components,
  /// not just one as that name would suggest.
  final String path;
}

/// Try to parse the given URL as a page in this app, on `store`'s realm.
///
/// `url` must already be a result from [PerAccountStore.tryResolveUrl]
/// on `store`.
///
/// Returns null if the URL isn't on this realm,
/// or isn't a valid Zulip URL,
/// or isn't currently supported as leading to a page in this app.
///
/// In particular this will return null if `url` is a `/#narrow/…` URL
/// and any of the operator/operand pairs are invalid.
/// Since narrow links can combine operators in ways our [Narrow] type can't
/// represent, this can also return null for valid narrow links.
///
/// This can also return null for some valid narrow links that our Narrow
/// type *could* accurately represent. We should try to understand these
/// better, but some kinds will be rare, even unheard-of.  For example:
///   #narrow/stream/1-announce/stream/1-announce (duplicated operator)
// TODO(#1661): handle all valid narrow links, returning a search narrow
InternalLink? parseInternalLink(Uri url, PerAccountStore store) {
  if (!_sameOrigin(url, store.realmUrl)) return null;

  if ((url.hasEmptyPath || url.path == '/')) {
    if (url.hasQuery) return null;
    if (!url.hasFragment) return null;
    // The URL is of the form `/#…` relative to the realm URL,
    // the shape used for representing a state within the web app.
    final (category, segments) = _getCategoryAndSegmentsFromFragment(url.fragment);
    switch (category) {
      case 'narrow':
        if (segments.isEmpty || !segments.length.isEven) return null;
        return _interpretNarrowSegments(segments, store);
    }
  } else if (url.path.startsWith(UserUploadLink._urlPathPrefix)) {
    return UserUploadLink._tryParse(url.path, store.realmUrl);
  }

  return null;
}

/// Check if `url` has the same origin as `realmUrl`.
bool _sameOrigin(Uri url, Uri realmUrl) {
  try {
    return url.origin == realmUrl.origin;
  } on StateError {
    // The getter [Uri.origin] throws if the scheme is not "http" or "https".
    // (Also if the URL is relative or certain kinds of malformed, but those
    // should be impossible as `url` came from [PerAccountStore.tryResolveUrl]).
    // In that case `url` has no "origin", and certainly not the realm's origin.
    return false;
  }
}

/// Split `fragment` of arbitrary segments and handle trailing slashes
(String, List<String>) _getCategoryAndSegmentsFromFragment(String fragment) {
  final [category, ...segments] = fragment.split('/');
  if (segments.length > 1 && segments.last == '') segments.removeLast();
  return (category, segments);
}

NarrowLink? _interpretNarrowSegments(List<String> segments, PerAccountStore store) {
  assert(segments.isNotEmpty);
  assert(segments.length.isEven);

  ApiNarrowChannel? channelElement;
  ApiNarrowTopic? topicElement;
  ApiNarrowDm? dmElement;
  ApiNarrowWith? withElement;
  Set<IsOperand> isElementOperands = {};
  int? nearMessageId;

  for (var i = 0; i < segments.length; i += 2) {
    final (operator, negated) = _parseOperator(segments[i]);
    if (negated) return null;
    final operand = segments[i + 1];
    switch (operator) {
      case _NarrowOperator.stream:
      case _NarrowOperator.channel:
        if (channelElement != null) return null;
        final streamId = _parseStreamOperand(operand, store);
        if (streamId == null) return null;
        channelElement = ApiNarrowChannel(streamId, negated: negated);

      case _NarrowOperator.topic:
      case _NarrowOperator.subject:
        if (topicElement != null) return null;
        final String? topic = decodeHashComponent(operand);
        if (topic == null) return null;
        topicElement = ApiNarrowTopic(TopicName(topic), negated: negated);

      case _NarrowOperator.dm:
      case _NarrowOperator.pmWith:
        if (dmElement != null) return null;
        final dmIds = _parseDmOperand(operand);
        if (dmIds == null) return null;
        dmElement = ApiNarrowDm(dmIds, negated: negated);

      case _NarrowOperator.with_:
        if (withElement != null) return null;
        final messageId = int.tryParse(operand, radix: 10);
        if (messageId == null) return null;
        withElement = ApiNarrowWith(messageId);

      case _NarrowOperator.is_:
        // It is fine to have duplicates of the same [IsOperand].
        isElementOperands.add(IsOperand.fromRawString(operand));

      case _NarrowOperator.near:
        if (nearMessageId != null) return null;
        final messageId = int.tryParse(operand, radix: 10);
        if (messageId == null) return null;
        nearMessageId = messageId;

      case _NarrowOperator.unknown:
        return null;
    }
  }

  final Narrow? narrow;
  if (isElementOperands.isNotEmpty) {
    if (channelElement != null || topicElement != null || dmElement != null || withElement != null) {
      return null;
    }
    if (isElementOperands.length > 1) return null;
    switch (isElementOperands.single) {
      case IsOperand.mentioned:
        narrow = const MentionsNarrow();
      case IsOperand.starred:
        narrow = const StarredMessagesNarrow();
      case IsOperand.dm:
      case IsOperand.private:
      case IsOperand.alerted:
      case IsOperand.followed:
      case IsOperand.resolved:
      case IsOperand.unread:
      case IsOperand.unknown:
        return null;
    }
  } else if (dmElement != null) {
    if (channelElement != null || topicElement != null || withElement != null) return null;
    narrow = DmNarrow.withUsers(dmElement.operand, selfUserId: store.selfUserId);
  } else if (channelElement != null) {
    final streamId = channelElement.operand;
    if (topicElement != null) {
      narrow = TopicNarrow(streamId, topicElement.operand, with_: withElement?.operand);
    } else {
      if (withElement != null) return null;
      narrow = ChannelNarrow(streamId);
    }
  } else {
    return null;
  }

  return NarrowLink(narrow, nearMessageId, realmUrl: store.realmUrl);
}

@JsonEnum(fieldRename: FieldRename.kebab, alwaysCreate: true)
enum _NarrowOperator {
  // 'dm' is new in server-7.0; means the same as 'pm-with'
  dm,
  near,
  // cannot use `with` as it is a reserved keyword in Dart
  @JsonValue('with')
  with_,
  // cannot use `is` as it is a reserved keyword in Dart
  @JsonValue('is')
  is_,
  pmWith,
  stream,
  channel,
  subject,
  topic,
  unknown;

  static _NarrowOperator fromRawString(String raw) => _byRawString[raw] ?? unknown;

  static final _byRawString = _$_NarrowOperatorEnumMap.map((key, value) => MapEntry(value, key));
}

(_NarrowOperator, bool) _parseOperator(String input) {
  final String operator;
  final bool negated;
  if (input.startsWith('-')) {
    operator = input.substring(1);
    negated = true;
  } else {
    operator = input;
    negated = false;
  }
  return (_NarrowOperator.fromRawString(operator), negated);
}

/// Parse the operand of a `stream` operator, returning a stream ID.
///
/// The ID might point to a stream that's hidden from our user (perhaps
/// doesn't exist). If so, most likely the user doesn't have permission to
/// see the stream's existence -- like with a guest user for any stream
/// they're not in, or any non-admin with a private stream they're not in.
/// Could be that whoever wrote the link just made something up.
///
/// Returns null if the operand has an unexpected shape, or has the old shape
/// (stream name but no ID) and we don't know of a stream by the given name.
int? _parseStreamOperand(String operand, ChannelStore store) {
  // "New" (2018) format: ${stream_id}-${stream_name} .
  final match = RegExp(r'^(\d+)(?:-.*)?$').firstMatch(operand);
  final newFormatStreamId = (match != null) ? int.parse(match.group(1)!, radix: 10) : null;
  if (newFormatStreamId != null && store.streams.containsKey(newFormatStreamId)) {
    return newFormatStreamId;
  }

  // Old format: just stream name.  This case is relevant indefinitely,
  // so that links in old conversations continue to work.
  final String? streamName = decodeHashComponent(operand);
  if (streamName == null) return null;
  final stream = store.streamsByName[streamName];
  if (stream != null) return stream.streamId;

  if (newFormatStreamId != null) {
    // Neither format found a stream, so it's hidden or doesn't exist. But
    // at least we have a stream ID; give that to the caller.
    return newFormatStreamId;
  }

  // Unexpected shape, or the old shape and we don't know of a stream with
  // the given name.
  return null;
}

List<int>? _parseDmOperand(String operand) {
  final rawIds = operand.split('-')[0].split(',');
  try {
    return rawIds.map((rawId) => int.parse(rawId, radix: 10)).toList();
  } on FormatException {
    return null;
  }
}
