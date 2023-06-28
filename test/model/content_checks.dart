import 'package:checks/context.dart';
import 'package:flutter/foundation.dart';
import 'package:zulip/model/content.dart';

extension ContentNodeChecks on Subject<ContentNode> {
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

  return null;
}
