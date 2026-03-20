import 'package:flutter/material.dart';

import '../../../../model/narrow.dart';
import '../../../compose_box.dart';
import '../inputs/edit_message_content_input.dart';
import 'compose_box_body.dart';

/// A compose box for editing an already-sent message.
class EditMessageComposeBoxBody extends ComposeBoxBody {
  const EditMessageComposeBoxBody({
    super.key,
    required this.narrow,
    required this.controller,
  });

  @override
  final Narrow narrow;

  @override
  final EditMessageComposeBoxController controller;

  @override
  Widget? buildTopicInput() => null;

  @override
  Widget buildContentInput() =>
      EditMessageContentInput(narrow: narrow, controller: controller);

  @override
  bool getComposeButtonsEnabled(BuildContext context) =>
      !ComposeBoxInheritedWidget.of(context).awaitingRawMessageContentForEdit;

  @override
  Widget? buildSendButton() => null;
}
