import 'package:test/test.dart';
import 'package:zulip/model/content.dart';

import 'content_matchers.dart';

void main() {
  test('parse a plain-text paragraph', () {
    // TODO try to compact this further
    expect(
      parseContent('<p>hello world</p>'),
      ZulipContentMatcher([
        ParagraphNodeMatcher(
          wasImplicit: equals(false),
          nodes: [equals(const TextNode('hello world'))])
      ]));
  });

  // TODO write more tests for this code
}
