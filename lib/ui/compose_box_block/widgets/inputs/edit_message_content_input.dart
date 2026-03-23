// Редактировать сообщение
import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../../compose_box.dart';
import 'content_input.dart';

class EditMessageContentInput extends StatelessWidget {
  const EditMessageContentInput({
    super.key,
    required this.narrow,
    required this.controller,
  });

  final Narrow narrow;
  final EditMessageComposeBoxController controller;

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
      hintText: awaitingRawContent
          ? zulipLocalizations.preparingEditMessageContentInput
          : null,
    );
  }
}
