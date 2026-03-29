import 'initial_snapshot.dart';

/// Given a URL string and the realm's linkifiers,
/// returns the shortened reverse-linkified text, or null if no match.
///
/// Example:
///   Input:  'https://github.com/zulip/zulip/pull/123'
///   Output: '#123'
String? tryReverseLinkify(String text, List<RealmLinkifier> linkifiers) {
  final trimmed = text.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return null;

  for (final linkifier in linkifiers) {
    final reverseTemplate = linkifier.reverseTemplate;
    if (reverseTemplate == null) continue;

    // trying main URL template first
    final result = _tryMatchTemplate(
      url: trimmed,
      urlTemplate: linkifier.urlTemplate,
      reverseTemplate: reverseTemplate,
    );
    if (result != null) return result;

    // check alternative URL templates if main does not work
    for (final altTemplate in linkifier.alternativeUrlTemplates) {
      final altResult = _tryMatchTemplate(
        url: trimmed,
        urlTemplate: altTemplate,
        reverseTemplate: reverseTemplate,
      );
      if (altResult != null) return altResult;
    }
  }
  return null;
}

/// The matching logic.
/// Takes the url template like:
///   https://github.com/zulip/zulip/pull/{id}
/// Converts it to a regex:
///   ^https://github\.com/zulip/zulip/pull/([^/]+)$
/// Matches the URL against it.
/// If match found, fills reverseTemplate #{id} with captured value → #123
String? _tryMatchTemplate({
  required String url,
  required String urlTemplate,
  required String reverseTemplate,
}) {
  final variableNames = <String>[];

  // regex to find {var} and {+var} in the URL template
  final variablePattern = RegExp(r'\{(\+?)([a-zA-Z_][a-zA-Z0-9_]*)\}');

  var regexStr = '';
  var lastEnd = 0;


  for (final match in variablePattern.allMatches(urlTemplate)) {
    // Escape the literal text before this variable so it matches exactly
    regexStr += RegExp.escape(urlTemplate.substring(lastEnd, match.start));

    // {+var} allows slashes in the value (e.g. for article paths)
    // {var}  does NOT allow slashes (just a simple segment)
    final allowSlash = match.group(1) == '+';
    regexStr += allowSlash ? r'(.+)' : r'([^/]+)';

    variableNames.add(match.group(2)!);
    lastEnd = match.end;
  }

  // Escape the remaining literal tail
  regexStr += RegExp.escape(urlTemplate.substring(lastEnd));

  final regex = RegExp('^$regexStr\$');
  final urlMatch = regex.firstMatch(url);
  if (urlMatch == null) return null;

  // Fill in the reverse template with captured values
  // e.g. reverseTemplate = '#{id}', captured id = '123' → '#123'
  var result = reverseTemplate;
  for (var i = 0; i < variableNames.length; i++) {
    result = result.replaceAll('{${variableNames[i]}}', urlMatch.group(i + 1) ?? '');
  }
  return result;
}
