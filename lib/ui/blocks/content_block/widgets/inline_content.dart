import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import '../../../values/constants.dart';
import '../../../values/text.dart';
import '../../../widgets/katex.dart';
import '../content.dart';
import 'global_time.dart';
import 'helpers.dart';
import 'inline_image.dart';
import 'mention.dart';
import 'message_image_emoji.dart';

class InlineContent extends StatelessWidget {
  InlineContent({
    super.key,
    required this.recognizer,
    required this.linkRecognizers,
    required this.style,
    required this.nodes,
    this.textAlign,
  }) {
    assert(style.fontSize != null);
    assert(
      style.debugLabel!.contains('weightVariableTextStyle')
          // ([ContentTheme.textStylePlainParagraph] applies [weightVariableTextStyle])
          ||
          style.debugLabel!.contains('ContentTheme.textStylePlainParagraph') ||
          style.debugLabel!.contains('bolderWghtTextStyle'),
    );
    _builder = _InlineContentBuilder(this);
  }

  final GestureRecognizer? recognizer;
  final Map<LinkNode, GestureRecognizer>? linkRecognizers;

  /// A [TextStyle] applied to this content and provided to descendants.
  ///
  /// Must set [TextStyle.fontSize]. Some descendant spans will consume it,
  /// e.g., to make their content slightly smaller than surrounding text.
  /// Similarly must set a font weight using [weightVariableTextStyle].
  final TextStyle style;

  /// A [TextAlign] applied to this content.
  final TextAlign? textAlign;

  final List<InlineContentNode> nodes;

  late final _InlineContentBuilder _builder;

  @override
  Widget build(BuildContext context) {
    return Text.rich(_builder.build(context), textAlign: textAlign);
  }
}

class _InlineContentBuilder {
  _InlineContentBuilder(this.widget) : _recognizer = widget.recognizer;

  final InlineContent widget;

  InlineSpan build(BuildContext context) {
    assert(_context == null);
    _context = context;
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    final result = _buildNodes(widget.nodes, style: widget.style);
    assert(identical(_context, context));
    _context = null;
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    return result;
  }

  BuildContext? _context;

  // Why do we have to track `recognizer` here, rather than apply it
  // once at the top of the affected span?  Because the events don't bubble
  // within a paragraph:
  //   https://github.com/flutter/flutter/issues/10623
  //   https://github.com/flutter/flutter/issues/10623#issuecomment-308030170
  GestureRecognizer? _recognizer;

  List<GestureRecognizer?>? _recognizerStack;

  void _pushRecognizer(GestureRecognizer? newRecognizer) {
    (_recognizerStack ??= []).add(_recognizer);
    _recognizer = newRecognizer;
  }

  void _popRecognizer() {
    _recognizer = _recognizerStack!.removeLast();
  }

  InlineSpan _buildNodes(
    List<InlineContentNode> nodes, {
    required TextStyle? style,
  }) {
    return TextSpan(
      style: style,
      children: nodes.map(_buildNode).toList(growable: false),
    );
  }

  InlineSpan _buildNode(InlineContentNode node) {
    switch (node) {
      case TextNode():
        return TextSpan(text: node.text, recognizer: _recognizer);

      case LineBreakInlineNode():
        // Each `<br/>` is followed by a newline, which browsers apparently ignore
        // and our parser doesn't.  So don't do anything here.
        return const TextSpan(text: "");

      case StrongNode():
        return _buildNodes(
          node.nodes,
          style: bolderWghtTextStyle(widget.style, by: 200),
        );

      case DeletedNode():
        return _buildNodes(
          node.nodes,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        );

      case EmphasisNode():
        return _buildNodes(
          node.nodes,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );

      case LinkNode():
        final recognizer = widget.linkRecognizers?[node];
        assert(recognizer != null);
        _pushRecognizer(recognizer);
        final result = _buildNodes(
          node.nodes,
          style: TextStyle(color: ContentTheme.of(_context!).colorLink),
        );
        _popRecognizer();
        return result;

      case InlineCodeNode():
        return _buildInlineCode(node);

      case MentionNode():
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Mention(ambientTextStyle: widget.style, node: node),
        );

      case UnicodeEmojiNode():
        return TextSpan(
          text: node.emojiUnicode,
          recognizer: _recognizer,
          style: ContentTheme.of(_context!).textStyleEmoji,
        );

      case ImageEmojiNode():
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: MessageImageEmoji(node: node),
        );

      case InlineImageNode():
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InlineImage(node: node, ambientTextStyle: widget.style),
        );

      case MathInlineNode():
        final nodes = node.nodes;
        return nodes == null
            ? TextSpan(
                style: ContentTheme.of(_context!).textStyleInlineMath.copyWith(
                  fontSize: widget.style.fontSize! * kInlineCodeFontSizeFactor,
                ),
                children: [TextSpan(text: node.texSource)],
              )
            : WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: KatexWidget(textStyle: widget.style, nodes: nodes),
              );

      case GlobalTimeNode():
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GlobalTime(node: node, ambientTextStyle: widget.style),
        );

      case UnimplementedInlineContentNode():
        return contentErrorUnimplemented(node, context: _context!);
    }
  }

  InlineSpan _buildInlineCode(InlineCodeNode node) {
    // TODO `code` elements: border, padding -- seems hard
    //
    // Hard because this is an inline span, which we want to be able to break
    // between lines when wrapping paragraphs.  That means we can't just make it a
    // widget; it needs to be a [TextSpan].  And in that inline setting, Flutter
    // does not appear to have an equivalent for CSS's `border` or `padding`:
    //   https://api.flutter.dev/flutter/painting/TextStyle-class.html
    //
    // One attempt was to use [TextDecoration] for the top and bottom,
    // passing this to the [TextStyle] constructor:
    //   decoration: TextDecoration.combine([TextDecoration.overline, TextDecoration.underline]),
    // (Then we could handle the left and right borders with 1px-wide [WidgetSpan]s.)
    // The overline comes out OK, but sadly the underline is, well, where a normal
    // text underline should go: it cuts right through descenders.
    //
    // Another option would be to break the text up on whitespace ourselves, and
    // make a [WidgetSpan] for each word and space.
    //
    // Or we could find a different design for displaying inline code.
    // One such alternative is implemented below.

    // TODO `code`: find equivalent of web's `unicode-bidi: embed; direction: ltr`

    return _buildNodes(
      style: ContentTheme.of(_context!).textStyleInlineCode.copyWith(
        fontSize: widget.style.fontSize! * kInlineCodeFontSizeFactor,
      ),
      node.nodes,
    );

    // Another fun solution -- we can in fact have a border!  Like so:
    //   TextStyle(
    //     background: Paint()..color = Color(0xff000000)
    //                        ..style = PaintingStyle.stroke,
    //     // … fontSize, fontFamily, …
    // The trouble is that this border hugs the text tightly -- no padding.
    // That doesn't come out looking good.

    // Here's a more different solution: add delimiters.
    // return TextSpan(children: [
    //   // TO.DO(selection): exclude these brackets from text selection
    //   const TextSpan(text: _kInlineCodeLeftBracket),
    //   TextSpan(style: _kCodeStyle, children: _buildInlineList(element.nodes)),
    //   const TextSpan(text: _kInlineCodeRightBracket),
    // ]);
  }
}
