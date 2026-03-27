import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../model/message_list.dart';
import '../blocks/message_list_block/widgets/message_list/messages_list_service.dart';

class FocusedMenuItem {
  Color? backgroundColor;
  Widget title;
  Widget? trailingIcon;
  Function onPressed;
  bool shouldPop;

  FocusedMenuItem({
    this.backgroundColor,
    required this.trailingIcon,
    required this.title,
    required this.onPressed,
    this.shouldPop = true,
  });
}

class FocusedMessageMenu extends StatefulWidget {
  final Widget child;
  final MessageListMessageItem item;
  final bool isMy;

  const FocusedMessageMenu({
    required this.child,
    required this.item,
    required this.isMy,
    super.key,
  });

  @override
  State<FocusedMessageMenu> createState() => _FocusedMessageMenuState();
}

class _FocusedMessageMenuState extends State<FocusedMessageMenu> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = const Offset(0, 0);
  Size? childSize;

  void getOffset() {
    RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onLongPress: () {
        HapticFeedback.lightImpact();
        openMenu(context);
      },
      onSecondaryTap: () {
        HapticFeedback.lightImpact();
        openMenu(context);
      },
      child: widget.child,
    );
  }

  Future<void> openMenu(BuildContext context) async {
    getOffset();
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 50),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return GestureDetector(
            onTap: () => Get.back(),
            child: FadeTransition(
              opacity: animation,
              child: Builder(
                builder: (context) {
                  //RxBool isDeleting = false.obs;

                  return _FocusedMenuDetails(
                    itemExtent: null,
                    menuBoxDecoration: null,
                    childOffset: childOffset,
                    childSize: childSize,
                    menuItems:
                        // isDeleting.value
                        //     ? <FocusedMenuItem>[
                        //         FocusedMenuItem(
                        //           title: Text(
                        //             'Удалить у всех',
                        //             // style: AppText.semibold14.copyWith(
                        //             //   color: AppColors.high,
                        //             // ),
                        //           ),
                        //           trailingIcon: null,
                        //           onPressed: () {
                        //             // Get.find<DialogController>().deleteMessage(
                        //             //   widget.model,
                        //             //   false,
                        //             // );
                        //           },
                        //         ),
                        //         FocusedMenuItem(
                        //           title: Text(
                        //             'Удалить у себя',
                        //             // style: AppText.semibold14.copyWith(
                        //             //   color: AppColors.high,
                        //             // ),
                        //           ),
                        //           trailingIcon: null,
                        //           onPressed: () {
                        //             // Get.find<DialogController>().deleteMessage(
                        //             //   widget.model,
                        //             //   true,
                        //             // );
                        //           },
                        //         ),
                        //       ]
                        //     :
                        <FocusedMenuItem>[
                          FocusedMenuItem(
                            title: Text(
                              'Ответить',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.question_answer),
                            onPressed: () {
                              MessagesListService.answerMessage(widget.item);
                            },
                          ),
                          FocusedMenuItem(
                            title: Text(
                              'Копировать',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.copy),
                            onPressed: () {
                              MessagesListService.copyMessage(widget.item);
                            },
                          ),
                          FocusedMenuItem(
                            title: Text(
                              'Копировать ссылку',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.link),
                            onPressed: () {
                              MessagesListService.copyMessageLink(widget.item);
                            },
                          ),
                          if (MessagesListService.getShouldShowEditButton(
                            widget.item,
                          ))
                            FocusedMenuItem(
                              title: Text(
                                'Изменить',
                                // style: AppText.semibold14.copyWith(
                                //   color: AppColors.high,
                                // ),
                              ),
                              trailingIcon: Icon(Icons.edit),
                              onPressed: () {
                                MessagesListService.editMessage(widget.item);
                              },
                            ),
                          // FocusedMenuItem(
                          //   title: Text(
                          //     'Удалить',
                          //     // style: AppText.semibold14
                          //     //     .copyWith(color: AppColors.high),
                          //   ),
                          //   trailingIcon: Icon(Icons.delete),
                          //   onPressed: () {
                          //     isDeleting.value = true;
                          //     setState(() {});
                          //   },
                          //   shouldPop: false,
                          // ),
                        ],
                    blurSize: 20,
                    menuWidth: 250,
                    blurBackgroundColor: Colors.black54,
                    bottomOffsetHeight: 100,
                    menuOffset: 8,
                    isLeftPos: !widget.isMy,
                    child: widget.child,
                  );
                },
              ),
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }
}

class FocusedMenu extends StatefulWidget {
  final Widget child;
  final double? menuItemExtent;
  final double? menuWidth;
  final List<FocusedMenuItem> menuItems;
  final BoxDecoration? menuBoxDecoration;
  final Function onPressed;
  final Duration? duration;
  final double? blurSize;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;
  final bool? isLeftPos;

  const FocusedMenu({
    super.key,
    required this.child,
    required this.onPressed,
    required this.menuItems,
    this.duration,
    this.menuBoxDecoration,
    this.menuItemExtent,
    this.blurSize,
    this.blurBackgroundColor,
    this.menuWidth,
    this.bottomOffsetHeight,
    this.menuOffset,
    this.isLeftPos,
  });

  @override
  FocusedMenuState createState() => FocusedMenuState();
}

class FocusedMenuState extends State<FocusedMenu> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = const Offset(0, 0);
  Size? childSize;

  void getOffset() {
    RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onLongPress: () {
        openMenu(context);
      },
      onSecondaryTap: () {
        openMenu(context);
      },
      child: widget.child,
    );
  }

  Future<void> openMenu(BuildContext context) async {
    getOffset();
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            widget.duration ?? const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: _FocusedMenuDetails(
              itemExtent: widget.menuItemExtent,
              menuBoxDecoration: widget.menuBoxDecoration,
              childOffset: childOffset,
              childSize: childSize,
              menuItems: widget.menuItems,
              blurSize: widget.blurSize,
              menuWidth: widget.menuWidth,
              blurBackgroundColor: widget.blurBackgroundColor,
              bottomOffsetHeight: widget.bottomOffsetHeight ?? 0,
              menuOffset: widget.menuOffset ?? 0,
              isLeftPos: widget.isLeftPos,
              child: widget.child,
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }
}

class _FocusedMenuDetails extends StatelessWidget {
  final List<FocusedMenuItem> menuItems;
  final BoxDecoration? menuBoxDecoration;
  final Offset childOffset;
  final double? itemExtent;
  final Size? childSize;
  final Widget child;
  final double? blurSize;
  final double? menuWidth;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;
  final bool? isLeftPos;

  const _FocusedMenuDetails({
    required this.menuItems,
    required this.child,
    required this.childOffset,
    required this.childSize,
    required this.menuBoxDecoration,
    required this.itemExtent,
    required this.blurSize,
    required this.blurBackgroundColor,
    required this.menuWidth,
    required this.isLeftPos,
    this.bottomOffsetHeight,
    this.menuOffset,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final maxMenuHeight = size.height * 0.45;
    final listHeight =
        menuItems.length * (itemExtent ?? 41.0) + (menuItems.length - 1) * 8;

    final maxMenuWidth = menuWidth ?? (size.width * 0.70);
    final menuHeight =
        (listHeight < maxMenuHeight ? listHeight : maxMenuHeight) + 16;
    final isLeft = isLeftPos ?? (childOffset.dx + maxMenuWidth) < size.width;
    final leftOffset = isLeft
        ? childOffset.dx
        : (childOffset.dx - maxMenuWidth + childSize!.width);
    final isBottom =
        (childOffset.dy + menuHeight + childSize!.height) <
        (size.height - bottomOffsetHeight!);
    final topOffset = isBottom
        ? childOffset.dy + childSize!.height + menuOffset!
        : childOffset.dy - menuHeight - menuOffset!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSize ?? 4,
                sigmaY: blurSize ?? 4,
              ),
              child: Container(
                color: (blurBackgroundColor ?? Colors.black).withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: leftOffset,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, double value, Widget? child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              tween: Tween(begin: 0.0, end: 1.0),
              child: Container(
                width: maxMenuWidth,
                height: menuHeight,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(isBottom && !isLeft ? 2 : 16),
                    topLeft: Radius.circular(isBottom && isLeft ? 2 : 16),
                    bottomRight: Radius.circular(!isBottom && !isLeft ? 2 : 16),
                    bottomLeft: Radius.circular(!isBottom && isLeft ? 2 : 16),
                  ),
                ),
                child: ListView.separated(
                  itemCount: menuItems.length,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    FocusedMenuItem item = menuItems[index];

                    return _FocusedMenuCard(item: item);
                  },
                  separatorBuilder: (context, index) => Container(
                    height: 8,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: childOffset.dy,
            left: childOffset.dx,
            child: AbsorbPointer(
              absorbing: true,
              child: SizedBox(
                width: childSize!.width,
                height: childSize!.height,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusedMenuCard extends StatelessWidget {
  final FocusedMenuItem item;
  const _FocusedMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.shouldPop) {
          Navigator.pop(context);
        }
        item.onPressed();
      },
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 1),
        color: item.backgroundColor ?? Colors.black,
        height: 41,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            item.title,
            if (item.trailingIcon != null) ...[item.trailingIcon!],
          ],
        ),
      ),
    );
  }
}
