import 'package:checks/checks.dart';
import 'package:zulip/model/content.dart';

extension ContentNodeChecks on Subject<ContentNode> {
  void equalsNode(ContentNode expected) {
    if (expected is ZulipContent) {
      isA<ZulipContent>()
        .nodes.deepEquals(expected.nodes.map(
          (e) => it()..isA<BlockContentNode>().equalsNode(e)));
        // A shame we need the dynamic `isA` there.  This
        // version hits a runtime type error:
        //   .nodes.deepEquals(expected.nodes.map(
        //     (e) => it<BlockContentNode>()..equalsNode(e)));
        // and with `it()` with no type argument, it doesn't type-check.
        // TODO: report that as API feedback on deepEquals
    } else if (expected is ParagraphNode) {
      isA<ParagraphNode>()
        ..wasImplicit.equals(expected.wasImplicit)
        ..nodes.deepEquals(expected.nodes.map(
          (e) => it()..isA<InlineContentNode>().equalsNode(e)));
    } else {
      // TODO handle remaining ContentNode subclasses that lack structural ==
      equals(expected);
    }
  }
}

extension ZulipContentChecks on Subject<ZulipContent> {
  Subject<List<BlockContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}

extension ParagraphNodeChecks on Subject<ParagraphNode> {
  Subject<bool> get wasImplicit => has((n) => n.wasImplicit, 'wasImplicit');
  Subject<List<InlineContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}

extension TextNodeChecks on Subject<TextNode> {
  Subject<String> get text => has((n) => n.text, 'text');
}

// TODO write similar extensions for the rest of the content node classes
