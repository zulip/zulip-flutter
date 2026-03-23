import 'package:flutter/material.dart';

import '../../../../model/narrow.dart';
import '../../../../utils/constants.dart';
import '../../../compose_box.dart';
import '../../../theme.dart';
import '../buttons/attach_file_button.dart';
import '../buttons/attach_from_camera_button.dart';
import '../buttons/attach_media_button.dart';

/// The text inputs, compose-button row, and send button for the compose box.
abstract class ComposeBoxBody extends StatelessWidget {
  const ComposeBoxBody({super.key});

  /// The narrow on view in the message list.
  Narrow get narrow;

  ComposeBoxController get controller;

  Widget? buildTopicInput();
  Widget buildContentInput();
  bool getComposeButtonsEnabled(BuildContext context);
  Widget? buildSendButton();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final designVariables = DesignVariables.of(context);

    final inputThemeData = themeData.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        // Both [contentPadding] and [isDense] combine to make the layout compact.
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
    );

    // TODO(#417): Disable splash effects for all buttons globally.
    final iconButtonThemeData = IconButtonThemeData(
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        // TODO(#417): The Figma design specifies a different icon color on
        //   pressed, but `IconButton` currently does not have support for
        //   that.  See also:
        //     https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3707-41711&node-type=frame&t=sSYomsJzGCt34D8N-0
        highlightColor: designVariables.editorButtonPressedBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );

    final composeButtonsEnabled = getComposeButtonsEnabled(context);
    final composeButtons = [
      AttachFileButton(controller: controller, enabled: composeButtonsEnabled),
      AttachMediaButton(
        controller: controller,
        enabled: composeButtonsEnabled,
      ),
      AttachFromCameraButton(
        controller: controller,
        enabled: composeButtonsEnabled,
      ),
    ];

    final topicInput = buildTopicInput();
    final sendButton = buildSendButton();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Theme(
            data: inputThemeData,
            child: Column(children: [?topicInput, buildContentInput()]),
          ),
        ),
        SizedBox(
          height: composeButtonSize,
          child: IconButtonTheme(
            data: iconButtonThemeData,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: composeButtons),
                ?sendButton,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
