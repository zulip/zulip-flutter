import 'dart:developer';

import 'package:flutter/material.dart';

class CustomSwipeTo extends StatefulWidget {
  final Widget child;

  final Duration animationDuration;
  final IconData iconOnRightSwipe;
  final Widget? rightSwipeWidget;
  final IconData iconOnLeftSwipe;
  final Widget? leftSwipeWidget;
  final double iconSize;
  final Color? iconColor;
  final double offsetDx;
  final GestureDragUpdateCallback? onRightSwipe;
  final GestureDragUpdateCallback? onLeftSwipe;
  final int swipeSensitivity;

  const CustomSwipeTo({
    super.key,
    required this.child,
    this.onRightSwipe,
    this.onLeftSwipe,
    this.iconOnRightSwipe = Icons.reply,
    this.rightSwipeWidget,
    this.iconOnLeftSwipe = Icons.reply,
    this.leftSwipeWidget,
    this.iconSize = 26.0,
    this.iconColor,
    this.animationDuration = const Duration(milliseconds: 150),
    this.offsetDx = 0.3,
    this.swipeSensitivity = 5,
  }) : assert(
         swipeSensitivity >= 5 && swipeSensitivity <= 35,
         "swipeSensitivity value must be between 5 to 35",
       );

  @override
  CustomSwipeToState createState() => CustomSwipeToState();
}

class CustomSwipeToState extends State<CustomSwipeTo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _leftIconAnimation;
  late Animation<double> _rightIconAnimation;
  late GestureDragUpdateCallback _onSwipeLeft;
  late GestureDragUpdateCallback _onSwipeRight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(curve: Curves.decelerate, parent: _controller));
    _leftIconAnimation = _controller.drive(Tween<double>(begin: 0.0, end: 0.0));
    _rightIconAnimation = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.0),
    );
    _onSwipeLeft =
        widget.onLeftSwipe ??
        (details) {
          log("Left Swipe Not Provided");
        };

    _onSwipeRight =
        widget.onRightSwipe ??
        (details) {
          log("Right Swipe Not Provided");
        };
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ///Run animation for child widget
  ///[onRight] value defines animation Offset direction
  void _runAnimation({
    required bool onRight,
    required DragUpdateDetails details,
  }) {
    //set child animation
    _animation = Tween(
      begin: const Offset(0.0, 0.0),
      end: Offset(onRight ? widget.offsetDx : -widget.offsetDx, 0.0),
    ).animate(CurvedAnimation(curve: Curves.decelerate, parent: _controller));
    //set back left/right icon animation
    if (onRight) {
      _leftIconAnimation = Tween(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(curve: Curves.decelerate, parent: _controller));
    } else {
      _rightIconAnimation = Tween(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(curve: Curves.decelerate, parent: _controller));
    }
    //Forward animation
    _controller.forward().whenComplete(() {
      _controller.reverse().whenComplete(() {
        if (onRight) {
          //keep left icon visibility to 0.0 until onRightSwipe triggers again
          _leftIconAnimation = _controller.drive(Tween(begin: 0.0, end: 0.0));
          _onSwipeRight(details);
        } else {
          //keep right icon visibility to 0.0 until onLeftSwipe triggers again
          _rightIconAnimation = _controller.drive(Tween(begin: 0.0, end: 0.0));
          _onSwipeLeft(details);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        if (details.delta.dx > widget.swipeSensitivity &&
            widget.onRightSwipe != null) {
          _runAnimation(onRight: true, details: details);
        }
        if (details.delta.dx < -(widget.swipeSensitivity) &&
            widget.onLeftSwipe != null) {
          _runAnimation(onRight: false, details: details);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AnimatedOpacity(
                opacity: _leftIconAnimation.value,
                duration: widget.animationDuration,
                curve: Curves.decelerate,
                child:
                    widget.rightSwipeWidget ??
                    Icon(
                      widget.iconOnRightSwipe,
                      size: widget.iconSize,
                      color:
                          widget.iconColor ?? Theme.of(context).iconTheme.color,
                    ),
              ),
              AnimatedOpacity(
                opacity: _rightIconAnimation.value,
                duration: widget.animationDuration,
                curve: Curves.decelerate,
                child:
                    widget.leftSwipeWidget ??
                    Icon(
                      widget.iconOnLeftSwipe,
                      size: widget.iconSize,
                      color:
                          widget.iconColor ?? Theme.of(context).iconTheme.color,
                    ),
              ),
            ],
          ),
          SlideTransition(position: _animation, child: widget.child),
        ],
      ),
    );
  }
}
