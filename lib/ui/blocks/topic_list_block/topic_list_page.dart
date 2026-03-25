import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'topic_list_controller.dart';
import '../../utils/page.dart';
import 'topic_list_block.dart' as original;

class TopicListPage extends GetView<TopicListController> {
  const TopicListPage({super.key, required this.streamId});

  final int streamId;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required int streamId,
  }) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: TopicListPage(streamId: streamId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return original.TopicListPage(streamId: streamId);
  }
}
