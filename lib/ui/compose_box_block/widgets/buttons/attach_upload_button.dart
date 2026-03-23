import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../values/constants.dart';
import '../../../extensions/color.dart';
import '../../compose_box.dart';
import '../../../values/theme.dart';

abstract class AttachUploadsButton extends StatelessWidget {
  const AttachUploadsButton({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final ComposeBoxController controller;
  final bool enabled;

  IconData get icon;
  String tooltip(ZulipLocalizations zulipLocalizations);

  /// Request files from the user, in the way specific to this upload type.
  ///
  /// Subclasses should manage the interaction completely, e.g., by catching and
  /// handling any permissions-related exceptions.
  ///
  /// To signal exiting the interaction with no files chosen,
  /// return an empty [Iterable] after showing user feedback as appropriate.
  Future<Iterable<FileToUpload>> getFiles(BuildContext context);

  void _handlePress(BuildContext context) async {
    final files = await getFiles(context);
    if (files.isEmpty) {
      return; // Nothing to do (getFiles handles user feedback)
    }

    // https://github.com/dart-lang/linter/issues/4007
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    await controller.uploadFiles(
      context: context,
      files: files,
      shouldRequestFocus: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return SizedBox(
      width: composeButtonSize,
      child: IconButton(
        icon: Icon(icon, color: designVariables.foreground.withFadedAlpha(0.5)),
        tooltip: tooltip(zulipLocalizations),
        onPressed: enabled ? () => _handlePress(context) : null,
      ),
    );
  }
}
