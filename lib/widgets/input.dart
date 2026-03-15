import 'package:flutter/material.dart';

import 'theme.dart';

/// A space to use for [InputDecoration.helperText] so the layout doesn't jump.
///
/// In particular, U+200B ZERO WIDTH SPACE.
///
/// See [FormField.validator] :
/// >  Alternating between error and normal state can cause the height of the
/// >  [TextFormField] to change if no other subtext decoration is set on the
/// >  field. To create a field whose height is fixed regardless of whether or
/// >  not an error is displayed, either wrap the  [TextFormField] in a fixed
/// >  height parent like [SizedBox], or set the [InputDecoration.helperText]
/// >  parameter to a space.
// TODO(upstream?): This contentless `helperText` shouldn't get its own node
//   in the semantics tree. Empirically, it does: iOS VoiceOver's focus can land
//   on it, and when it does, nothing gets read.
const String kLayoutPinningHelperText = '\u200b';

/// Figma's "pop-menu" component for compose autocomplete:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3732-28971&m=dev
// TODO(#1972) use this style in report-message dropdown, perhaps with help from
//   a [MenuStyle] representation of the style.
class PopupMenu extends StatelessWidget {
  const PopupMenu({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return Material(
      color: designVariables.contextMenuBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: designVariables.contextMenuBorder)),
      elevation: 4.0, // TODO tune the shadow effect
      child: Padding(
        padding: EdgeInsets.all(2),
        child: child));
  }
}
