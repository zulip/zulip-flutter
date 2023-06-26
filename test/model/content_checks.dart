import 'package:checks/checks.dart';
import 'package:zulip/model/content.dart';

extension ContentNodeChecks on Subject<ContentNode> {
  void equalsNode(ContentNode expected) {
    // TODO: Make equalsNode output clearer on failure, applying Diagnosticable.
    //   In particular (a) show the top-level expected node in one piece
    //   (as well as the actual); (a') ideally, suppress on the "expected" side
    //   the various predicates below, which should be redundant with just
    //   the expected node; (b) show expected for the specific `equals` leaf.
    //   See also comment on [ContentNode.toString].
    if (expected is ZulipContent) {
      isA<ZulipContent>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is UnimplementedBlockContentNode) {
      isA<UnimplementedBlockContentNode>()
        .debugHtmlText.equals(expected.debugHtmlText);
    } else if (expected is ParagraphNode) {
      isA<ParagraphNode>()
        ..wasImplicit.equals(expected.wasImplicit)
        ..nodes.equalsNodes(expected.nodes);
    } else if (expected is HeadingNode) {
      isA<HeadingNode>()
        ..level.equals(expected.level)
        ..nodes.equalsNodes(expected.nodes);
    } else if (expected is ListNode) {
      isA<ListNode>()
        ..style.equals(expected.style)
        ..items.deepEquals(expected.items.map(
          (item) => it()..isA<List<BlockContentNode>>().equalsNodes(item)));
    } else if (expected is QuotationNode) {
      isA<QuotationNode>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is UnimplementedInlineContentNode) {
      isA<UnimplementedInlineContentNode>()
        .debugHtmlText.equals(expected.debugHtmlText);
    } else if (expected is StrongNode) {
      isA<StrongNode>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is EmphasisNode) {
      isA<EmphasisNode>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is InlineCodeNode) {
      isA<InlineCodeNode>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is LinkNode) {
      isA<LinkNode>()
        .nodes.equalsNodes(expected.nodes);
    } else if (expected is UserMentionNode) {
      isA<UserMentionNode>()
        .nodes.equalsNodes(expected.nodes);
    } else {
      // The remaining node types have structural `==`.  Use that.
      equals(expected);
    }
  }

  Subject<String> get debugHtmlText => has((n) => n.debugHtmlText, 'debugHtmlText');
}

extension ZulipContentChecks on Subject<ZulipContent> {
  Subject<List<BlockContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}

extension BlockContentNodeListChecks on Subject<List<BlockContentNode>> {
  void equalsNodes(List<BlockContentNode> expected) {
    deepEquals(expected.map(
      (e) => it()..isA<BlockContentNode>().equalsNode(e)));
    // A shame we need the dynamic `isA` there.  This
    // version hits a runtime type error:
    //   .nodes.deepEquals(expected.nodes.map(
    //     (e) => it<BlockContentNode>()..equalsNode(e)));
    // and with `it()` with no type argument, it doesn't type-check.
    // TODO(checks): report that as API feedback on deepEquals
  }
}

extension BlockInlineContainerNodeChecks on Subject<BlockInlineContainerNode> {
  Subject<List<InlineContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}

extension ParagraphNodeChecks on Subject<ParagraphNode> {
  Subject<bool> get wasImplicit => has((n) => n.wasImplicit, 'wasImplicit');
}

extension HeadingNodeChecks on Subject<HeadingNode> {
  Subject<HeadingLevel> get level => has((n) => n.level, 'level');
}

extension ListNodeChecks on Subject<ListNode> {
  Subject<ListStyle> get style => has((n) => n.style, 'style');
  Subject<List<List<BlockContentNode>>> get items => has((n) => n.items, 'items');
}

extension QuotationNodeChecks on Subject<QuotationNode> {
  Subject<List<BlockContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}

extension InlineContentNodeListChecks on Subject<List<InlineContentNode>> {
  void equalsNodes(List<InlineContentNode> expected) {
    deepEquals(expected.map(
      (e) => it()..isA<InlineContentNode>().equalsNode(e)));
  }
}

extension InlineContainerNodeChecks on Subject<InlineContainerNode> {
  Subject<List<InlineContentNode>> get nodes => has((n) => n.nodes, 'nodes');
}
