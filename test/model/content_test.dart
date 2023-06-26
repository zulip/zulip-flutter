import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/content.dart';

import 'content_checks.dart';

void testParse(String name, String html, List<BlockContentNode> nodes) {
  test(name, () {
    check(parseContent(html))
      .equalsNode(ZulipContent(nodes: nodes));
  });
}

void main() {
  testParse('parse a plain-text paragraph',
    '<p>hello world</p>', const [
      ParagraphNode(nodes: [TextNode('hello world')]),
    ]);

  testParse('parse two plain-text paragraphs',
    '<p>hello</p><p>world</p>', const [
      ParagraphNode(nodes: [TextNode('hello')]),
      ParagraphNode(nodes: [TextNode('world')]),
    ]);

  // TODO write more tests for this code
}
