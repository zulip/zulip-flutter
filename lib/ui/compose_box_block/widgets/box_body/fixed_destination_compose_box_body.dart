import 'package:flutter/material.dart';

import '../../../../model/narrow.dart';
import '../../compose_box.dart';
import '../buttons/send_button.dart';
import '../inputs/fixed_destination_content_input.dart';
import 'compose_box_body.dart';

/// A compose box for use in a channel narrow.
///
/// This offers a text input for the topic to send to,
/// in addition to a text input for the message content.
class FixedDestinationComposeBoxBody extends ComposeBoxBody {
  const FixedDestinationComposeBoxBody({
    super.key,
    required this.narrow,
    required this.controller,
  });

  @override
  final SendableNarrow narrow;

  @override
  final FixedDestinationComposeBoxController controller;

  @override
  Widget? buildTopicInput() => null;

  @override
  Widget buildContentInput() =>
      FixedDestinationContentInput(narrow: narrow, controller: controller);

  @override
  bool getComposeButtonsEnabled(BuildContext context) => true;

  @override
  Widget buildSendButton() => SendButton(
    controller: controller,
    getDestination: () => narrow.destination,
  );
}
