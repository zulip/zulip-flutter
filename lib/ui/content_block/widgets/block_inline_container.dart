import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../model/content.dart';
import 'helpers.dart';
import 'inline_content.dart';

class BlockInlineContainer extends StatefulWidget {
  const BlockInlineContainer({
    super.key,
    required this.links,
    required this.style,
    required this.nodes,
    this.textAlign,
  });

  final List<LinkNode> links;
  final TextStyle style;
  final List<InlineContentNode> nodes;
  final TextAlign? textAlign;

  @override
  State<BlockInlineContainer> createState() => _BlockInlineContainerState();
}

class _BlockInlineContainerState extends State<BlockInlineContainer> {
  final Map<LinkNode, GestureRecognizer> _recognizers = {};

  void _prepareRecognizers() {
    _recognizers.addEntries(
      widget.links.map(
        (node) => MapEntry(
          node,
          TapGestureRecognizer()
            ..onTap = () => contentLaunchUrl(context, node.url),
        ),
      ),
    );
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void initState() {
    super.initState();
    _prepareRecognizers();
  }

  @override
  void didUpdateWidget(covariant BlockInlineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.links, oldWidget.links)) {
      _disposeRecognizers();
      _prepareRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InlineContent(
      recognizer: null,
      linkRecognizers: _recognizers,
      style: widget.style,
      nodes: widget.nodes,
      textAlign: widget.textAlign,
    );
  }
}
