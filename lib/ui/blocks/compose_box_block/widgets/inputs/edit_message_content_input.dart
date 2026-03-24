// Редактировать сообщение
import 'package:flutter/material.dart';

import '../../../../../api/route/messages.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../model/narrow.dart';
import '../../compose_box.dart';
import 'content_input.dart';

class EditMessageContentInput extends StatelessWidget {
  const EditMessageContentInput({
    super.key,
    required this.narrow,
    required this.controller,
    required this.getDestination,
  });

  final Narrow narrow;
  final EditMessageComposeBoxController controller;
  final MessageDestination Function() getDestination;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final awaitingRawContent = ComposeBoxInheritedWidget.of(
      context,
    ).awaitingRawMessageContentForEdit;
    return ContentInput(
      narrow: narrow,
      controller: controller,
      enabled: !awaitingRawContent,
      getDestination: getDestination,
      hintText: awaitingRawContent
          ? zulipLocalizations.preparingEditMessageContentInput
          : null,
    );
  }
}
