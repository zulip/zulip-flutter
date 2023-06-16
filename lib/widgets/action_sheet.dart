import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api/model/model.dart';
import 'draggable_scrollable_modal_bottom_sheet.dart';

void showMessageActionSheet({required BuildContext context, required Message message}) {
  showDraggableScrollableModalBottomSheet(
    context: context,
    builder: (BuildContext _) {
      return Column(children: [
        ShareButton(message: message),
      ]);
    });
}

abstract class MessageActionSheetMenuItemButton extends StatelessWidget {
  const MessageActionSheetMenuItemButton({
    super.key,
    required this.message,
  });

  IconData get icon;
  String get label;
  void Function(BuildContext) get onPressed;

  final Message message;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      leadingIcon: Icon(icon),
      onPressed: () => onPressed(context),
      child: Text(label));
  }
}

class ShareButton extends MessageActionSheetMenuItemButton {
  const ShareButton({
    super.key,
    required super.message,
  });

  @override get icon => Icons.adaptive.share;

  @override get label => 'Share';

  @override get onPressed => (BuildContext context) async {
    // Close the message action sheet; we're about to show the share
    // sheet. (We could do this after the sharing Future settles, but
    // on iOS I get impatient with how slowly our action sheet
    // dismisses in that case.)
    // TODO(#24): Fix iOS bug where this call causes the keyboard to
    //   reopen (if it was open at the time of this
    //   `showMessageActionSheet` call) and cover a large part of the
    //   share sheet.
    Navigator.of(context).pop();

    // TODO: to support iPads, we're asked to give a
    //   `sharePositionOrigin` param, or risk crashing / hanging:
    //     https://pub.dev/packages/share_plus#ipad
    //   Perhaps a wart in the API; discussion:
    //     https://github.com/zulip/zulip-flutter/pull/12#discussion_r1130146231
    // TODO: Share raw Markdown, not HTML
    await Share.shareWithResult(message.content);
  };
}
