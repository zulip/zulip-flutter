import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/content.dart';
import '../../values/text.dart';
import 'block_content_list.dart';

class Spoiler extends StatefulWidget {
  const Spoiler({super.key, required this.node});

  final SpoilerNode node;

  @override
  State<Spoiler> createState() => _SpoilerState();
}

class _SpoilerState extends State<Spoiler> with TickerProviderStateMixin {
  bool expanded = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      if (!expanded) {
        _controller.forward();
        expanded = true;
      } else {
        _controller.reverse();
        expanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final header = widget.node.header;
    final effectiveHeader = header.isNotEmpty
        ? header
        : [
            ParagraphNode(
              links: null,
              nodes: [TextNode(zulipLocalizations.spoilerDefaultHeaderText)],
            ),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Web has the same color in light and dark mode.
          border: Border.all(color: const Color(0xff808080)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 2, 8, 2),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleTap,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: weightVariableTextStyle(context, wght: 700),
                          child: BlockContentList(nodes: effectiveHeader),
                        ),
                      ),
                      RotationTransition(
                        turns: _animation.drive(Tween(begin: 0, end: 0.5)),
                        // Web has the same color in light and dark mode.
                        child: const Icon(
                          color: Color(0xffd4d4d4),
                          size: 25,
                          Icons.expand_more,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: _animation,
                child: const SizedBox(
                  height: 0,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        // Web has the same color in light and dark mode.
                        bottom: BorderSide(width: 1, color: Color(0xff808080)),
                      ),
                    ),
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.vertical,
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: BlockContentList(nodes: widget.node.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
