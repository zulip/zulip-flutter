import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:flutter/foundation.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/model/content.dart';

extension ContentNodeChecks on Subject<ContentNode> {
  // In [expected], for the `links` field of [ParagraphNode] or
  // any other [BlockInlineContainerNode] subclass, use `null`.
  // This field will be ignored in [expected], and instead the
  // field's value in [actual] will be checked for accuracy against
  // the [BlockInlineContainerNode.nodes] field on the same node.
  void equalsNode(ContentNode expected) {
    return context.expect(() => prefixFirst('equals ', literal(expected)), (actual) {
      final which = _compareDiagnosticsNodes(
        actual.toDiagnosticsNode(), expected.toDiagnosticsNode());
      return which == null ? null : Rejection(which: [
        'differs in that it:',
        ...indent(which),
      ]);
    });
  }
}

Iterable<String>? _compareDiagnosticsNodes(DiagnosticsNode actual, DiagnosticsNode expected) {
  assert(actual is DiagnosticableTreeNode && expected is DiagnosticableTreeNode);

  if (actual.value.runtimeType != expected.value.runtimeType) {
    return [
      'has type ${actual.value.runtimeType}',
      'expected: ${expected.value.runtimeType}',
    ];
  }

  final actualProperties = actual.getProperties();
  final expectedProperties = expected.getProperties();
  assert(actualProperties.length == expectedProperties.length);
  for (int i = 0; i < actualProperties.length; i++) {
    assert(actualProperties[i].name == expectedProperties[i].name);
    if (actualProperties[i].value != expectedProperties[i].value) {
      return [
        'has ${actualProperties[i].name} that:',
        ...indent(prefixFirst('is ',        literal(actualProperties[i].value))),
        ...indent(prefixFirst('expected: ', literal(expectedProperties[i].value)))
      ];
    }
  }

  final actualChildren = actual.getChildren();
  final expectedChildren = expected.getChildren();
  if (actualChildren.length != expectedChildren.length) {
    return [
      'has ${actualChildren.length} children',
      'expected: ${expectedChildren.length} children',
    ];
  }
  for (int i = 0; i < actualChildren.length; i++) {
    final failure = _compareDiagnosticsNodes(actualChildren[i], expectedChildren[i]);
    if (failure != null) {
      final diagnosticable = actualChildren[i].value as Diagnosticable;
      return [
        'has child $i (${diagnosticable.toStringShort()}) that:',
        ...indent(failure),
      ];
    }
  }

  if (actual.value is BlockInlineContainerNode) {
    final failure = _checkLinks(actual.value as BlockInlineContainerNode);
    if (failure != null) {
      return failure;
    }
  }

  return null;
}

Iterable<String>? _checkLinks(BlockInlineContainerNode node) {
  final foundLinks = _findLinkNodes(node.nodes).toList();
  final which = () {
    var actualLinks = node.links;
    if (actualLinks != null && actualLinks.isEmpty) {
      return ['has empty non-null links'];
    }
    actualLinks ??= [];
    if (actualLinks.length != foundLinks.length) {
      return ['has ${actualLinks.length} links while nodes has ${foundLinks.length}'];
    }
    for (int i = 0; i < foundLinks.length; i++) {
      if (!identical(actualLinks[i], foundLinks[i])) {
        return ['has a mismatch in links at element $i'];
      }
    }
  }();

  if (which == null) return null;

  return [
    ...which,
    'Actual links property:',
    ...indent(literal(node.links)),
    'Expected links, from actual nodes:',
    ...indent(literal(foundLinks)),
  ];
}

Iterable<LinkNode> _findLinkNodes(Iterable<InlineContentNode> nodes) {
  return nodes.expand((node) {
    if (node is! InlineContainerNode) return const [];
    if (node is LinkNode) {
      // HTML disallows `a` as a descendant of `a`:
      //   https://html.spec.whatwg.org/#the-a-element (see "Content model")
      // and Dart's HTML parser seems not to produce it in the DOM.
      assert(_findLinkNodes(node.nodes).isEmpty);
      return [node];
    }
    return _findLinkNodes(node.nodes);
  });
}

extension PollContentChecks on Subject<PollContent> {
  Subject<Poll> get poll => has((x) => x.poll, 'poll');
}
