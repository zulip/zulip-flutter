
import '../api/model/narrow.dart';
import 'narrow.dart';
import 'store.dart';

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
  final apiNarrow = narrow.apiEncode();
  final fragment = StringBuffer('narrow');
  for (ApiNarrowElement element in apiNarrow) {
    fragment.write('/');
    if (element.negated) {
      fragment.write('-');
    }

    if (element is ApiNarrowDm) {
      final supportsOperatorDm = store.connection.zulipFeatureLevel! >= 177; // TODO(server-7)
      element = element.resolve(legacy: !supportsOperatorDm);
    }

    fragment.write('${element.operator}/');

    switch (element) {
      case ApiNarrowStream():
        final streamId = element.operand;
        final name = store.streams[streamId]?.name ?? 'unknown';
        final slugifiedName = _encodeHashComponent(name.replaceAll(' ', '-'));
        fragment.write('$streamId-$slugifiedName');
      case ApiNarrowTopic():
        fragment.write(_encodeHashComponent(element.operand));
      case ApiNarrowDmModern():
        final suffix = element.operand.length >= 3 ? 'group' : 'dm';
        fragment.write('${element.operand.join(',')}-$suffix');
      case ApiNarrowPmWith():
        final suffix = element.operand.length >= 3 ? 'group' : 'pm';
        fragment.write('${element.operand.join(',')}-$suffix');
      case ApiNarrowDm():
        assert(false, 'ApiNarrowDm should have been resolved');
      case ApiNarrowMessageId():
        fragment.write(element.operand.toString());
    }
  }

  if (nearMessageId != null) {
    fragment.write('/near/$nearMessageId');
  }

  return store.account.realmUrl.replace(fragment: fragment.toString());
}

/// Create a new `Uri` object in relation to a given realmUrl.
///
/// Returns `null` if `urlString` could not be parsed as a `Uri`.
Uri? tryResolveOnRealmUrl(String urlString, Uri realmUrl) {
  try {
    return realmUrl.resolve(urlString);
  } on FormatException {
    return null;
  }
}
