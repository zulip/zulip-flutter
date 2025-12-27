// Override `flutter test`'s default timeout
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/content.dart';

import '../../test/model/binding.dart';
import 'model.dart';

void main() async {
  TestZulipBinding.ensureInitialized();

  Future<void> checkForKatexFailuresInFile(File file) async {
    int totalMessageCount = 0;
    final Set<int> katexMessageIds = <int>{};
    final Set<int> failedKatexMessageIds = <int>{};
    int totalMathBlockNodes = 0;
    int failedMathBlockNodes = 0;
    int totalMathInlineNodes = 0;
    int failedMathInlineNodes = 0;

    final failedMessageIdsByReason = <String, Set<int>>{};
    final failedMathNodesByReason = <String, Set<MathNode>>{};

    void walk(int messageId, DiagnosticsNode node) {
      final value = node.value;
      if (value is UnimplementedNode) return;

      for (final child in node.getChildren()) {
        walk(messageId, child);
      }

      if (value is! MathNode) return;
      katexMessageIds.add(messageId);
      switch (value) {
        case MathBlockNode(): totalMathBlockNodes++;
        case MathInlineNode(): totalMathInlineNodes++;
      }

      if (value.nodes != null) return;
      failedKatexMessageIds.add(messageId);
      switch (value) {
        case MathBlockNode(): failedMathBlockNodes++;
        case MathInlineNode(): failedMathInlineNodes++;
      }

      final hardFailReason = value.debugHardFailReason;
      final softFailReason = value.debugSoftFailReason;
      int failureCount = 0;

      if (hardFailReason != null) {
        final message = hardFailReason.message
          ?? 'unknown reason at ${_inmostFrame(hardFailReason.stackTrace)}';
        final reason = 'hard fail: $message';
        (failedMessageIdsByReason[reason] ??= {}).add(messageId);
        (failedMathNodesByReason[reason] ??= {}).add(value);
        failureCount++;
      }

      if (softFailReason != null) {
        for (final cssClass in softFailReason.unsupportedCssClasses) {
          final reason = 'unsupported css class: $cssClass';
          (failedMessageIdsByReason[reason] ??= {}).add(messageId);
          (failedMathNodesByReason[reason] ??= {}).add(value);
          failureCount++;
        }
        for (final cssProp in softFailReason.unsupportedInlineCssProperties) {
          final reason = 'unsupported inline css property: $cssProp';
          (failedMessageIdsByReason[reason] ??= {}).add(messageId);
          (failedMathNodesByReason[reason] ??= {}).add(value);
          failureCount++;
        }
      }

      if (failureCount == 0) {
        final reason = 'unknown';
        (failedMessageIdsByReason[reason] ??= {}).add(messageId);
        (failedMathNodesByReason[reason] ??= {}).add(value);
      }
    }

    await for (final message in readMessagesFromJsonl(file)) {
      totalMessageCount++;
      walk(message.id, parseContent(message.content).toDiagnosticsNode());
    }

    final buf = StringBuffer();
    buf.writeln();
    buf.writeln('Out of $totalMessageCount total messages,'
      ' ${katexMessageIds.length} of them were KaTeX containing messages'
      ' and ${failedKatexMessageIds.length} of those failed.');
    buf.writeln('There were $totalMathBlockNodes math block nodes out of which $failedMathBlockNodes failed.');
    buf.writeln('There were $totalMathInlineNodes math inline nodes out of which $failedMathInlineNodes failed.');
    buf.writeln();

    for (final MapEntry(key: reason, value: messageIds)
         in failedMessageIdsByReason.entries.sorted((a, b) {
           // Sort by number of failed messages descending, then by reason.
           final r = - a.value.length.compareTo(b.value.length);
           if (r != 0) return r;
           return a.key.compareTo(b.key);
         })) {
      final failedMathNodes = failedMathNodesByReason[reason]!.toList();
      failedMathNodes.shuffle();
      final oldestId = messageIds.reduce(min);
      final newestId = messageIds.reduce(max);

      buf.writeln('Because of $reason:');
      buf.writeln('  ${messageIds.length} messages failed.');
      buf.writeln('  Oldest message: $oldestId, Newest message: $newestId');
      if (!_verbose) {
        buf.writeln();
        continue;
      }

      buf.writeln('  Message IDs (up to 100): ${messageIds.take(100).join(', ')}');
      buf.writeln('  TeX source (up to 30):');
      for (final node in failedMathNodes.take(30)) {
        switch (node) {
          case MathBlockNode():
            buf.writeln('    ```math');
            for (final line in node.texSource.split('\n')) {
              buf.writeln('    $line');
            }
            buf.writeln('    ```');
          case MathInlineNode():
            buf.writeln('    \$\$ ${node.texSource} \$\$');
        }
      }
      buf.writeln('  HTML (up to 3):');
      for (final node in failedMathNodes.take(3)) {
        buf.writeln('    ${node.debugHtmlText}');
      }
      buf.writeln();
    }

    check(failedKatexMessageIds.length, because: buf.toString()).equals(0);
  }

  final corpusFiles = _getCorpusFiles();

  if (corpusFiles.isEmpty) {
    throw Exception('No corpus found in directory "$_corpusDirPath" to check'
                    ' for katex failures.');
  }

  group('Check for katex failures in', () {
    for (final file in corpusFiles) {
      test(file.path, () => checkForKatexFailuresInFile(file));
    }
  });
}

/// The innermost frame of the given stack trace,
/// e.g. the line where an exception was thrown.
///
/// Inevitably this is a bit heuristic, given the lack of any API guarantees
/// on the structure of [StackTrace].
String _inmostFrame(StackTrace stackTrace) {
  final firstLine = stackTrace.toString().split('\n').first;
  return firstLine.replaceFirst(RegExp(r'^#\d+\s+'), '');
}

const String _corpusDirPath = String.fromEnvironment('corpusDir');

const bool _verbose = int.fromEnvironment('verbose', defaultValue: 0) != 0;

Iterable<File> _getCorpusFiles() {
  final corpusDir = Directory(_corpusDirPath);
  return corpusDir.existsSync() ? corpusDir.listSync().whereType<File>() : [];
}
