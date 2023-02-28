import 'package:test/test.dart';
import 'package:zulip/model/content.dart';

void main() {
  test('parse a plain-text paragraph', () {
    // TODO find a way to make these more concise, so we can more easily have many of them
    final result = parseContent('<p>hello world</p>');
    expect(result.nodes.length, 1);
    final node = result.nodes.single;
    expect(node, const TypeMatcher<ParagraphNode>());
    expect((node as ParagraphNode).wasImplicit, false);
    expect(node.nodes.length, 1);
    final span = node.nodes.single;
    expect(span, const TypeMatcher<TextNode>());
    expect((span as TextNode).text, 'hello world');
  });

  // TODO write more tests for this code
}
