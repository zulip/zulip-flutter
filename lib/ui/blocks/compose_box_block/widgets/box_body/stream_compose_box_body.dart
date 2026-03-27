import 'package:flutter/material.dart';

import '../../../../../api/model/model.dart';
import '../../../../../api/route/messages.dart';
import '../../../../../model/narrow.dart';
import '../../compose_box.dart';
import '../inputs/stream_content_input.dart';
import '../inputs/topic_input.dart';
import '../buttons/send_button.dart';
import 'compose_box_body.dart';

class StreamComposeBoxBody extends ComposeBoxBody {
  const StreamComposeBoxBody({
    super.key,
    required this.narrow,
    required this.controller,
  });

  @override
  final ChannelNarrow narrow;

  @override
  final StreamComposeBoxController controller;

  @override
  Widget buildTopicInput() =>
      TopicInput(streamId: narrow.streamId, controller: controller);

  @override
  Widget buildContentInput(Widget sendButton) => StreamContentInput(
    narrow: narrow,
    controller: controller,
    getDestination: () => StreamDestination(
      narrow.streamId,
      TopicName(controller.topic.textNormalized),
    ),
  );

  @override
  bool getComposeButtonsEnabled(BuildContext context) => true;

  @override
  Widget buildSendButton() => SendButton(
    controller: controller,
    getDestination: () => StreamDestination(
      narrow.streamId,
      TopicName(controller.topic.textNormalized),
    ),
  );
}
