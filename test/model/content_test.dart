import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/content.dart';

import 'content_checks.dart';

void main() {
  test('parse a plain-text paragraph', () {
    check(parseContent('<p>hello world</p>'))
      .equalsNode(const ZulipContent(nodes: [
        ParagraphNode(nodes: [TextNode('hello world')]),
      ]));
  });

  test('parse two plain-text paragraphs', () {
    check(parseContent('<p>hello</p><p>world</p>'))
      .equalsNode(const ZulipContent(nodes: [
        ParagraphNode(nodes: [TextNode('hello')]),
        ParagraphNode(nodes: [TextNode('world')]),
      ]));
  });

  // TODO write more tests for this code
}
