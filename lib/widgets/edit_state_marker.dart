import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/model.dart';
import 'icons.dart';
import 'message_list.dart';
import 'text.dart';

class EditStateMarker extends StatefulWidget {
  const EditStateMarker({
    super.key,
    required this.editState,
    required this.children,
  });

  final MessageEditState editState;
  final List<Widget> children;

  @override
  State<StatefulWidget> createState() => _EditStateMarkerState();
}

class _EditStateMarkerState extends State<EditStateMarker> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // The duration is only used when `_controller.reverse()` is called,
      // i.e.: when the drag is released and the marker gets collapsed.
      duration: const Duration(milliseconds: 200),
      lowerBound: _EditStateMarkerPill.widthCollapsed,
      upperBound: _EditStateMarkerPill.widthExpanded,
      vsync: this)
      ..addListener(() => setState((){}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late AnimationController _controller;

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value += details.delta.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasMarker = widget.editState != MessageEditState.none;

    final content = LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: localizedTextBaseline(context),
          children: [
            hasMarker
              ? _EditStateMarkerPill(
                  editState: widget.editState,
                  animation: _controller)
                : const SizedBox(width: _EditStateMarkerPill.widthCollapsed),
              SizedBox(
                width: constraints.maxWidth - _EditStateMarkerPill.widthCollapsed,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: localizedTextBaseline(context),
                  children: widget.children),
              ),
          ])),
    );

    if (!hasMarker) return content;

    return GestureDetector(
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: content,
    );
   }
}

class _EditStateMarkerPill extends StatelessWidget {
  const _EditStateMarkerPill({required this.editState, required this.animation});

  final MessageEditState editState;
  final Animation<double> animation;

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

  double get _animationProgress => (animation.value - widthCollapsed) / widthExpanded;

  @override
  Widget build(BuildContext context) {
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final IconData icon;
    final String markerText;
    switch (editState) {
      case MessageEditState.none:
        assert(false);
        return const SizedBox(width: widthCollapsed);
      case MessageEditState.edited:
        icon = ZulipIcons.edited;
        markerText = zulipLocalizations.messageIsEdited;
        break;
      case MessageEditState.moved:
        icon = ZulipIcons.message_moved;
        markerText = zulipLocalizations.messageIsMoved;
        break;
    }

    var marker = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(markerText,
            overflow: TextOverflow.clip,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color.lerp(
              messageListTheme.editedMovedMarkerExpanded.withAlpha(0),
              messageListTheme.editedMovedMarkerExpanded,
              _animationProgress)))),
        Transform.translate(
          // This offset is chosen ad hoc, but give a good vertical alignment
          // of the icons with the first line of the message, when the message
          // begins with a paragraph, at default text scaling.  See:
          //   https://github.com/zulip/zulip-flutter/pull/762#issuecomment-2232041922
          offset: const Offset(0, 1),
          child: Icon(icon, size: 16, color: Color.lerp(
              messageListTheme.editedMovedMarkerCollapsed,
              messageListTheme.editedMovedMarkerExpanded,
              _animationProgress)),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: animation.value),
      child: Container(
        margin: EdgeInsets.only(left: lerpDouble(0, 8, _animationProgress)!, right: lerpDouble(0, 3, _animationProgress)!),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Color.lerp(
            messageListTheme.editedMovedMarkerBg.withAlpha(0),
            messageListTheme.editedMovedMarkerBg,
            _animationProgress)),
        child: Padding(
          padding: EdgeInsets.only(left: lerpDouble(0, 3, _animationProgress)!),
          child: marker),
      ),
    );
  }
}
