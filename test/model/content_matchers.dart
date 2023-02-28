import 'package:test/test.dart';
import 'package:zulip/model/content.dart';

abstract class ContentNodeMatcher extends Matcher {
}

class ZulipContentMatcher extends ContentNodeMatcher {
  ZulipContentMatcher(this.nodes);

  final List<Matcher> nodes;

  @override
  bool matches(covariant ZulipContent item, Map<dynamic, dynamic> matchState) {
    // TODO surely this is common boilerplate we can avoid, right?
    //   ... Well, doesn't seem like the matcher package has a way:
    //     https://pub.dev/documentation/matcher/latest/matcher/matcher-library.html
    //   Maybe try its proposed successor which is in beta?:
    //     https://pub.dev/packages/checks
    if (item.nodes.length != nodes.length) return false;
    for (var i = 0; i < nodes.length; i++) {
      if (!nodes[i].matches(item.nodes[i], matchState)) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    // TODO find how a Matcher.describe should actually work
    //   (Or maybe the `checks` package has a better API here.)
    description.add('ZulipContent with ${nodes.length} children, namely:');
    for (final node in nodes) {
      description.add('\n');
      node.describe(description);
    }
    return description;
  }
}

class ParagraphNodeMatcher extends ContentNodeMatcher {
  ParagraphNodeMatcher({required this.nodes, this.wasImplicit = anything});

  final List<Matcher> nodes;
  final Matcher wasImplicit;

  @override
  bool matches(covariant ParagraphNode item, Map<dynamic, dynamic> matchState) {
    if (item.nodes.length != nodes.length) return false;
    for (var i = 0; i < nodes.length; i++) {
      if (!nodes[i].matches(item.nodes[i], matchState)) {
        return false;
      }
    }
    if (!wasImplicit.matches(item.wasImplicit, matchState)) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('ParagraphNode with wasImplicit: ');
    wasImplicit.describe(description);
    description.add(' and ${nodes.length} children, namely:');
    for (final node in nodes) {
      description.add('\n');
      node.describe(description);
    }
    return description;
  }
}
