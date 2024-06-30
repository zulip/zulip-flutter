import 'dart:ui';

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

class _SwipableMessageRowState extends State<SwipableMessageRow> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // The duration is only used when `_controller.reverse()` is called,
      // i.e.: when the drag is released and the marker gets collapsed.
      duration: const Duration(milliseconds: 200),
      lowerBound: EditStateMarker.widthCollapsed,
      upperBound: EditStateMarker.widthExpanded,
      vsync: this)
      ..addListener(() => setState((){}));
    // This controls the movement of the message content.
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(1, 0))
      .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double get dragOffset => _controller.value - EditStateMarker.widthCollapsed;

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value += details.delta.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<DesignVariables>()!;

    var star = Padding(
      padding: const EdgeInsets.only(top: 5.5),
      child: Row(children: [
          const Text("", style: TextStyle(fontSize: 15)),
          Icon(ZulipIcons.star_filled, size: 16, color: theme.starColor)]));
    final hasMarker = widget.message.editState != MessageEditState.none;

    final content = Stack(
      children: [
        if (hasMarker) Positioned(
          left: 0,
          child: EditStateMarker(
            editState: widget.message.editState,
            animation: _controller)),
        Padding(
          // Adding [EditStateMarker.widthCollapsed] to the right padding
          // cancels out the left offset applied from the initial value of
          // [_slideAnimation] through [Transform.translate]. This is necessary
          // before we can add a padding of 16 pixels for the star.
          padding: const EdgeInsets.only(right: EditStateMarker.widthCollapsed + 16),
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child)),
        if (widget.message.flags.contains(MessageFlag.starred))
          Positioned(
            // Because _controller.value does not start from zero, we subtract
            // its initial value from it so the star is positioned correctly
            // in the beginning.
            right: 0 - (_controller.value - EditStateMarker.widthCollapsed),
            child: star),
      ],
    );

    if (!hasMarker) return content;

    return GestureDetector(
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: content,
    );
  }
}

class EditStateMarker extends StatelessWidget {
  /// The minimum width of the marker.
  ///
  /// This is when no drag has been performed on the message row
  /// where only the moved/edited icon, not the text, is visible.
  static const double widthCollapsed = 16;

  /// The maximum width of the marker.
  ///
  /// This is typically wider than the colored pill when the marker is fully
  /// expanded. At that point only the blank space to the right of the colored
  /// block will grow until the marker reaches this width.
  static const double widthExpanded = 100;

  const EditStateMarker({
    super.key,
    required MessageEditState editState,
    required Animation<double> animation,
  }) : _editState = editState, _animation = animation;

  final MessageEditState _editState;
  final Animation<double> _animation;

  double get _animationProgress => _animation.value / widthExpanded;
  double get _width => _animation.value;

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
          // The trailing space serves as a padding between the marker text and
          // the icon without needing another element in the row.
          child: Text('$markerText ',
            overflow: TextOverflow.clip,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color.lerp(
              theme.textMarker.withAlpha(0),
              theme.textMarker,
              _animationProgress)))),
        // To match the Figma design, we cannot make the collapsed width of the
        // marker larger. We need to explicitly allow the icon to overflow.
        OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          maxWidth: 10,
          child: Icon(icon, size: iconSize, color: Color.lerp(
              theme.textMarkerLight,
              theme.textMarker,
              _animationProgress)),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _width),
      child: Container(
        margin: EdgeInsets.only(top: 4, left: lerpDouble(0, 10, _animationProgress)!),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: Color.lerp(
            theme.bgMarker.withAlpha(0),
            theme.bgMarker,
            _animationProgress)),
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: marker,
        ),
      ),
    );
  }
}
