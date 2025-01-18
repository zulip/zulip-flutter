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
  // TODO(server-7)
  final apiNarrow = resolveDmElements(
    narrow.apiEncode(), store.connection.zulipFeatureLevel!);
  final fragment = StringBuffer('narrow');
  for (ApiNarrowElement element in apiNarrow) {
    fragment.write('/');
    if (element.negated) {
      fragment.write('-');
    }

    fragment.write('${element.operator}/');

    switch (element) {
      case ApiNarrowStream():
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
      case ApiNarrowIs():
        fragment.write(element.operand.toString());
      case ApiNarrowMessageId():
        fragment.write(element.operand.toString());
    }
  }

  if (nearMessageId != null) {
    fragment.write('/near/$nearMessageId');
  }

  Uri result = store.realmUrl.replace(fragment: fragment.toString());
  if (result.path.isEmpty) {
    // Always ensure that there is a '/' right after the hostname.
    // A generated URL without '/' looks odd,
    // and if used in a Zulip message does not get automatically linkified.
    result = result.replace(path: '/');
  }
  return result;
}

/// A [Narrow] from a given URL, on `store`'s realm.
///
/// `url` must already be a result from [PerAccountStore.tryResolveUrl]
/// on `store`.
///
/// Returns `null` if any of the operator/operand pairs are invalid.
///
/// Since narrow links can combine operators in ways our [Narrow] type can't
/// represent, this can also return null for valid narrow links.
///
/// This can also return null for some valid narrow links that our Narrow
/// type *could* accurately represent. We should try to understand these
/// better, but some kinds will be rare, even unheard-of:
///   #narrow/stream/1-announce/stream/1-announce (duplicated operator)
// TODO(#252): handle all valid narrow links, returning a search narrow
Narrow? parseInternalLink(Uri url, PerAccountStore store) {
  if (!_isInternalLink(url, store.realmUrl)) return null;

  final (category, segments) = _getCategoryAndSegmentsFromFragment(url.fragment);
  switch (category) {
    case 'narrow':
      if (segments.isEmpty || !segments.length.isEven) return null;
      return _interpretNarrowSegments(segments, store);
  }
  return null;
}

/// Check if `url` is an internal link on the given `realmUrl`.
bool _isInternalLink(Uri url, Uri realmUrl) {
  try {
    if (url.origin != realmUrl.origin) return false;
  } on StateError {
    return false;
  }
  return (url.hasEmptyPath || url.path == '/')
    && !url.hasQuery
    && url.hasFragment;
}

/// Split `fragment` of arbitrary segments and handle trailing slashes
(String, List<String>) _getCategoryAndSegmentsFromFragment(String fragment) {
  final [category, ...segments] = fragment.split('/');
  if (segments.length > 1 && segments.last == '') segments.removeLast();
  return (category, segments);
}

Narrow? _interpretNarrowSegments(List<String> segments, PerAccountStore store) {
  assert(segments.isNotEmpty);
  assert(segments.length.isEven);

  ApiNarrowStream? streamElement;
  ApiNarrowTopic? topicElement;
  ApiNarrowDm? dmElement;
  Set<IsOperand> isElementOperands = {};

  for (var i = 0; i < segments.length; i += 2) {
    final (operator, negated) = _parseOperator(segments[i]);
    if (negated) return null;
    final operand = segments[i + 1];
    switch (operator) {
      case _NarrowOperator.stream:
      case _NarrowOperator.channel:
        if (streamElement != null) return null;
        final streamId = _parseStreamOperand(operand, store);
        if (streamId == null) return null;
        streamElement = ApiNarrowStream(streamId, negated: negated);

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

      case _NarrowOperator.is_:
        // It is fine to have duplicates of the same [IsOperand].
        isElementOperands.add(IsOperand.fromRawString(operand));

      case _NarrowOperator.near: // TODO(#82): support for near
      case _NarrowOperator.with_: // TODO(#683): support for with
        continue;

      case _NarrowOperator.unknown:
        return null;
    }
  }

  if (isElementOperands.isNotEmpty) {
    if (streamElement != null || topicElement != null || dmElement != null) return null;
    if (isElementOperands.length > 1) return null;
    switch (isElementOperands.single) {
      case IsOperand.mentioned:
        return const MentionsNarrow();
      case IsOperand.starred:
        return const StarredMessagesNarrow();
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
    if (streamElement != null || topicElement != null) return null;
    return DmNarrow.withUsers(dmElement.operand, selfUserId: store.selfUserId);
  } else if (streamElement != null) {
    final streamId = streamElement.operand;
    if (topicElement != null) {
      return TopicNarrow(streamId, topicElement.operand);
    } else {
      return ChannelNarrow(streamId);
    }
  }
  return null;
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
