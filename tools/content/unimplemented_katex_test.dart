@Timeout(Duration(minutes: 10))
library;

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:math';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
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

    void walk(int messageId, MathNode value) {
      katexMessageIds.add(messageId);
      switch (value) {
        case MathBlockNode(): totalMathBlockNodes++;
        case MathInlineNode(): totalMathInlineNodes++;
      }

      if (value.texSource.isNotEmpty) return;
      failedKatexMessageIds.add(messageId);
      switch (value) {
        case MathBlockNode(): failedMathBlockNodes++;
        case MathInlineNode(): failedMathInlineNodes++;
      }

      final reason = 'empty texSource';
      (failedMessageIdsByReason[reason] ??= {}).add(messageId);
      (failedMathNodesByReason[reason] ??= {}).add(value);
    }

    await for (final message in readMessagesFromJsonl(file)) {
      totalMessageCount++;
      final content = parseContent(message.content);
      for (final node in content.nodes) {
        if (node is MathBlockNode || node is MathInlineNode) {
          walk(message.id, node as MathNode);
        }
      }
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

const String _corpusDirPath = String.fromEnvironment('corpusDir');

const bool _verbose = int.fromEnvironment('verbose', defaultValue: 0) != 0;

Iterable<File> _getCorpusFiles() {
  final corpusDir = Directory(_corpusDirPath);
  return corpusDir.existsSync() ? corpusDir.listSync().whereType<File>() : [];
}
