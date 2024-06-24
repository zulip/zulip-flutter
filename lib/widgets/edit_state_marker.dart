import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/model.dart';
import 'icons.dart';
import 'theme.dart';

class SwipableMessageRow extends StatefulWidget {
  const SwipableMessageRow({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;

  @override
  State<StatefulWidget> createState() => _SwipableMessageRowState();
}

class _SwipableMessageRowState extends State<SwipableMessageRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<DesignVariables>()!;

    // TODO(#157): fix how star marker aligns with message content
    // Design from Figma at:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=813%3A28817&mode=dev .
    var star = Padding(padding: const EdgeInsets.only(top: 5.5),
      child: Icon(ZulipIcons.star_filled, size: 16, color: theme.starColor));
    final hasMarker = widget.message.editState != MessageEditState.none;

    return Stack(
      children: [
        if (hasMarker) Positioned(
          left: 0,
          child: EditStateMarker(editState: widget.message.editState)),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: widget.child),
        if (widget.message.flags.contains(MessageFlag.starred))
          Positioned(
            right: 0,
            child: star),
      ],
    );
  }
}

class EditStateMarker extends StatelessWidget {
  /// The minimum width of the marker.
  ///
  /// Currently, only the collapsed state of the marker has been implemented,
  /// where only the marker icon, not the marker text, is visible.
  static const double widthCollapsed = 16;

  const EditStateMarker({
    super.key,
    required MessageEditState editState,
  }) : _editState = editState;

  final MessageEditState _editState;

  @override
  Widget build(BuildContext context) {
    final theme = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final IconData icon;
    final double iconSize;
    final String markerText;

    switch (_editState) {
      case MessageEditState.none:
        return const SizedBox(width: widthCollapsed);
      case MessageEditState.edited:
        icon = ZulipIcons.edited;
        iconSize = 14;
        markerText = zulipLocalizations.messageIsEdited;
        break;
      case MessageEditState.moved:
        icon = ZulipIcons.message_moved;
        iconSize = 8;
        markerText = zulipLocalizations.messageIsMoved;
        break;
    }

    var marker = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          // For now, [markerText] is not displayed because it is transparent and
          // there is not enough space in the parent ConstrainedBox.
          child: Text('$markerText ',
            overflow: TextOverflow.clip,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: theme.textMarker.withAlpha(0)))),
        // To match the Figma design, we cannot make the collapsed width of the
        // marker larger. We need to explicitly allow the icon to overflow.
        OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          maxWidth: 10,
          child: Icon(icon, size: iconSize, color: theme.textMarkerLight),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: widthCollapsed),
      child: Container(
        margin: const EdgeInsets.only(top: 4, left: 0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: theme.bgMarker.withAlpha(0)),
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: marker),
      ),
    );
  }
}
