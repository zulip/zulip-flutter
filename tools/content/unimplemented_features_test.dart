// Override `flutter test`'s default timeout
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/content.dart';

import '../../test/model/binding.dart';
import 'model.dart';

/// Check if there are unimplemented features from the given corpora of HTML
/// contents from Zulip messages.
///
/// This test is meant to be run via `tools/content/check-features <CORPUS_DIR>`.
///
/// where `<CORPUS_DIR>` should be a directory containing files with
/// outputs generated from tools/content/fetch_messages.dart.
///
/// The test writes an overview of unimplemented features at the beginning to
/// standard output, followed by the details of each feature.  To look for live
/// examples, you can search on the Zulip community by message ID from all
/// public channels.
///
/// For example, a search query like "near: 12345 channels: public" would work.
///
/// See also:
/// * lib/model/content.dart, which implements of the content parser.
/// * tools/content/fetch_messages.dart, which produces the corpora.
void main() async {
  // Parsing the HTML content depends on `ZulipBinding` being initialized,
  // specifically KaTeX content parser retrieves the `GlobalSettings` to
  // for the experimental flag.
  TestZulipBinding.ensureInitialized();

  Future<void> checkForUnimplementedFeaturesInFile(File file) async {
    final messageIdsByFeature = <String, Set<int>>{};
    final contentsByFeature = <String, List<String>>{};

    int totalMessageCount = 0;
    await for (final message in readMessagesFromJsonl(file)) {
      totalMessageCount++;
      // `_walk` modifies `messageIdsByFeature` and `contentsByFeature`
      // in-place.
      _walk(message.id, parseContent(message.content).toDiagnosticsNode(),
        messageIdsByFeature: messageIdsByFeature,
        contentsByFeature: contentsByFeature);
    }

    // This buffer allows us to avoid using prints directly.
    final buf = StringBuffer();
    int failedMessageCount = 0;
    if (messageIdsByFeature.isNotEmpty) {
      failedMessageCount = messageIdsByFeature.values.map((x) => x.length).sum;
      buf.writeln('Found unimplemented features in $failedMessageCount out '
                  'of $totalMessageCount public messages:');
    }
    for (final featureName in messageIdsByFeature.keys) {
      Set<int> messageIds = messageIdsByFeature[featureName]!;
      int oldestId = messageIds.reduce(min);
      int newestId = messageIds.reduce(max);
      buf.write(
        '- `$featureName`\n'
        '  Oldest message: $oldestId; newest message: $newestId '
          '(${messageIds.length}/$failedMessageCount)\n'
        '\n');
    }
    buf.writeln();

    final divider = '\n\n${'=' * 80}\n\n';
    int unsupportedCounter = 0;
    for (final MapEntry(key: featureName, value: messageContents) in contentsByFeature.entries) {
      unsupportedCounter++;
      if (!_verbose) continue;
      final messageIds = messageIdsByFeature[featureName]!;
      buf.write(
        'Unsupported feature #$unsupportedCounter: $featureName\n'
        'message IDs (up to 100): ${messageIds.take(100).join(', ')}\n'
        'examples (up to 10):\n${messageContents.take(10).join(divider)}\n'
        '\n\n');
    }
    check(unsupportedCounter, because: buf.toString()).equals(0);
  }

  final corpusFiles = _getCorpusFiles();

  if (corpusFiles.isEmpty) {
    throw Exception('No corpus found in directory "$_corpusDirPath" to check'
                    ' for unimplemented features.');
  }

  group('Check for unimplemented features in', () {
    for (final file in corpusFiles) {
      test(file.path, () => checkForUnimplementedFeaturesInFile(file));
    }
  });
}

// Determine whether details about all messages with unimplemented features
// should be printed.
const bool _verbose = int.fromEnvironment('verbose', defaultValue: 0) != 0;

const String _corpusDirPath = String.fromEnvironment('corpusDir');

Iterable<File> _getCorpusFiles() {
  final corpusDir = Directory(_corpusDirPath);
  return corpusDir.existsSync() ? corpusDir.listSync().whereType<File>() : [];
}

/// Walk the tree looking for unimplemented nodes, and aggregate them by the
/// category of the unimplemented feature.
///
/// This modifies `messageIdsByFeature` and `contentsByFeature` in-place.
void _walk(int messageId, DiagnosticsNode node, {
  required Map<String, Set<int>> messageIdsByFeature,
  required Map<String, List<String>> contentsByFeature,
}) {
  final value = node.value;
  if (value is! UnimplementedNode) {
    for (final child in node.getChildren()) {
      _walk(messageId, child,
        messageIdsByFeature: messageIdsByFeature,
        contentsByFeature: contentsByFeature);
    }
    return;
  }

  // `featureName` is a prettified identifier used for categorizing
  // unimplemented features that are likely closely related.
  final String featureName;
  final htmlNode = value.debugHtmlNode;
  if (htmlNode is dom.Element) {
    if (htmlNode.className.isEmpty) {
      featureName = '<${htmlNode.localName!}>';
    } else {
      featureName = '<${htmlNode.localName!} class="${htmlNode.className}">';
    }
  } else {
    featureName = 'DOM node type: ${htmlNode.nodeType}';
  }
  (messageIdsByFeature[featureName] ??= {}).add(messageId);
  (contentsByFeature[featureName] ??= []).add(value.debugHtmlText);
}
