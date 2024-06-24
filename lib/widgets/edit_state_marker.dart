import 'package:flutter/material.dart';

import '../api/model/model.dart';
import 'icons.dart';
import 'text.dart';
import 'theme.dart';

class EditStateMarker extends StatelessWidget {
  const EditStateMarker({
    super.key,
    required this.editState,
    required this.children,
  });

  final MessageEditState editState;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hasMarker = editState != MessageEditState.none;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: localizedTextBaseline(context),
      children: [
        hasMarker
          ? _EditStateMarkerPill(editState: editState)
          : const SizedBox(width: _EditStateMarkerPill.widthCollapsed),
        ...children,
      ],
    );
  }
}

class _EditStateMarkerPill extends StatelessWidget {
  const _EditStateMarkerPill({required this.editState});

  final MessageEditState editState;

  /// The minimum width of the marker.
  // Currently, only the collapsed state of the marker has been implemented,
  // where only the marker icon, not the marker text, is visible.
  static const double widthCollapsed = 16;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final IconData icon;
    final Offset offset;
    switch (editState) {
      case MessageEditState.none:
        assert(false);
        return const SizedBox(width: widthCollapsed);
      case MessageEditState.edited:
        icon = ZulipIcons.edited;
        // These offsets are chosen ad hoc, but give a good vertical alignment
        // of the icons with the first line of the message, when the message
        // begins with a paragraph, at default text scaling.  See:
        //   https://github.com/zulip/zulip-flutter/pull/762#issuecomment-2232041922
        offset = const Offset(0, 2);
      case MessageEditState.moved:
        icon = ZulipIcons.message_moved;
        offset = const Offset(0, 3);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: widthCollapsed),
      child: Transform.translate(
        offset: offset,
        child: Icon(
          icon, size: 16, color: designVariables.editedMovedMarkerCollapsed)));
  }
}
