import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import 'message_image_preview.dart';

class MessageImagePreviewList extends StatelessWidget {
  const MessageImagePreviewList({super.key, required this.node});

  final ImagePreviewNodeList node;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: node.imagePreviews
          .map((node) => MessageImagePreview(node: node))
          .toList(),
    );
  }
}
