import 'package:flutter/material.dart';

import '../widgets/code_block.dart';
import '../widgets/content.dart';
import '../widgets/text.dart';

class ContentTheme extends ThemeExtension<ContentTheme> {
  factory ContentTheme.light(BuildContext context) {
    return ContentTheme._(
      colorCodeBlockBackground: const HSLColor.fromAHSL(0.04, 0, 0, 0).toColor(),
      colorDirectMentionBackground: const HSLColor.fromAHSL(0.2, 240, 0.7, 0.7).toColor(),
      colorGlobalTimeBackground: const HSLColor.fromAHSL(1, 0, 0, 0.93).toColor(),
      colorGlobalTimeBorder: const HSLColor.fromAHSL(1, 0, 0, 0.8).toColor(),
      colorMathBlockBorder: const HSLColor.fromAHSL(0.15, 240, 0.8, 0.5).toColor(),
      colorMessageMediaContainerBackground: const Color.fromRGBO(0, 0, 0, 0.03),
      colorPollNames: const HSLColor.fromAHSL(1, 0, 0, .45).toColor(),
      colorPollVoteCountBackground: const HSLColor.fromAHSL(1, 0, 0, 1).toColor(),
      colorPollVoteCountBorder: const HSLColor.fromAHSL(1, 156, 0.28, 0.7).toColor(),
      colorPollVoteCountText: const HSLColor.fromAHSL(1, 156, 0.41, 0.4).toColor(),
      colorThematicBreak: const HSLColor.fromAHSL(1, 0, 0, .87).toColor(),
      textStylePlainParagraph: _plainParagraphCommon(context).copyWith(
        color: const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor(),
        debugLabel: 'ContentTheme.textStylePlainParagraph'),
      codeBlockTextStyles: CodeBlockTextStyles.light(context),
      textStyleError: const TextStyle(fontSize: kBaseFontSize, color: Colors.red)
        .merge(weightVariableTextStyle(context, wght: 700)),
      textStyleErrorCode: kMonospaceTextStyle
        .merge(const TextStyle(fontSize: kBaseFontSize, color: Colors.red)),
      textStyleInlineCode: kMonospaceTextStyle.merge(TextStyle(
        backgroundColor: const HSLColor.fromAHSL(0.06, 0, 0, 0).toColor())),
      textStyleInlineMath: kMonospaceTextStyle.merge(TextStyle(
        // TODO(#46) this won't be needed
        backgroundColor: const HSLColor.fromAHSL(1, 240, 0.4, 0.93).toColor())),
    );
  }

  factory ContentTheme.dark(BuildContext context) {
    return ContentTheme._(
      colorCodeBlockBackground: const HSLColor.fromAHSL(0.04, 0, 0, 1).toColor(),
      colorDirectMentionBackground: const HSLColor.fromAHSL(0.25, 240, 0.52, 0.6).toColor(),
      colorGlobalTimeBackground: const HSLColor.fromAHSL(0.2, 0, 0, 0).toColor(),
      colorGlobalTimeBorder: const HSLColor.fromAHSL(0.4, 0, 0, 0).toColor(),
      colorMathBlockBorder: const HSLColor.fromAHSL(1, 240, 0.4, 0.4).toColor(),
      colorMessageMediaContainerBackground: const HSLColor.fromAHSL(0.03, 0, 0, 1).toColor(),
      colorPollNames: const HSLColor.fromAHSL(1, 236, .15, .7).toColor(),
      colorPollVoteCountBackground: const HSLColor.fromAHSL(0.2, 0, 0, 0).toColor(),
      colorPollVoteCountBorder: const HSLColor.fromAHSL(1, 185, 0.35, 0.35).toColor(),
      colorPollVoteCountText: const HSLColor.fromAHSL(1, 185, 0.35, 0.65).toColor(),
      colorThematicBreak: const HSLColor.fromAHSL(1, 0, 0, .87).toColor().withValues(alpha: 0.2),
      textStylePlainParagraph: _plainParagraphCommon(context).copyWith(
        color: const HSLColor.fromAHSL(1, 0, 0, 0.85).toColor(),
        debugLabel: 'ContentTheme.textStylePlainParagraph'),
      codeBlockTextStyles: CodeBlockTextStyles.dark(context),
      textStyleError: TextStyle(fontSize: kBaseFontSize, color: Colors.red.shade900)
        .merge(weightVariableTextStyle(context, wght: 700)),
      textStyleErrorCode: kMonospaceTextStyle
        .merge(TextStyle(fontSize: kBaseFontSize, color: Colors.red.shade900)),
      textStyleInlineCode: kMonospaceTextStyle.merge(TextStyle(
        backgroundColor: const HSLColor.fromAHSL(0.08, 0, 0, 1).toColor())),
      textStyleInlineMath: kMonospaceTextStyle.merge(TextStyle(
        // TODO(#46) this won't be needed
        backgroundColor: const HSLColor.fromAHSL(1, 240, 0.4, 0.4).toColor())),
    );
  }

  ContentTheme._({
    required this.colorCodeBlockBackground,
    required this.colorDirectMentionBackground,
    required this.colorGlobalTimeBackground,
    required this.colorGlobalTimeBorder,
    required this.colorMathBlockBorder,
    required this.colorMessageMediaContainerBackground,
    required this.colorPollNames,
    required this.colorPollVoteCountBackground,
    required this.colorPollVoteCountBorder,
    required this.colorPollVoteCountText,
    required this.colorThematicBreak,
    required this.textStylePlainParagraph,
    required this.codeBlockTextStyles,
    required this.textStyleError,
    required this.textStyleErrorCode,
    required this.textStyleInlineCode,
    required this.textStyleInlineMath,
  });

  /// The [ContentTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [ContentTheme] in [ThemeData.extensions].
  static ContentTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ContentTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color colorCodeBlockBackground;
  final Color colorDirectMentionBackground;
  final Color colorGlobalTimeBackground;
  final Color colorGlobalTimeBorder;
  final Color colorMathBlockBorder; // TODO(#46) this won't be needed
  final Color colorMessageMediaContainerBackground;
  final Color colorPollNames;
  final Color colorPollVoteCountBackground;
  final Color colorPollVoteCountBorder;
  final Color colorPollVoteCountText;
  final Color colorThematicBreak;

  /// The complete [TextStyle] we use for plain, unstyled paragraphs.
  ///
  /// Also the base style that all other text content should inherit from.
  ///
  /// This is the complete style for plain paragraphs. Plain-paragraph content
  /// should not need styles from other sources, such as Material defaults.
  final TextStyle textStylePlainParagraph;

  final CodeBlockTextStyles codeBlockTextStyles;
  final TextStyle textStyleError;
  final TextStyle textStyleErrorCode;

  /// The [TextStyle] for inline code, excluding font-size adjustment.
  ///
  /// Inline code should use this and also apply [kInlineCodeFontSizeFactor]
  /// to the font size of the surrounding text
  /// (which might be a Paragraph, a Heading, etc.).
  final TextStyle textStyleInlineCode;

  /// The [TextStyle] for inline math, excluding font-size adjustment.
  ///
  /// Inline math should use this and also apply [kInlineCodeFontSizeFactor]
  /// to the font size of the surrounding text
  /// (which might be a Paragraph, a Heading, etc.).
  final TextStyle textStyleInlineMath;

  /// [ContentTheme.textStylePlainParagraph] attributes independent of theme.
  static TextStyle _plainParagraphCommon(BuildContext context) => TextStyle(
    inherit: false,

    fontSize: kBaseFontSize,
    letterSpacing: 0,
    textBaseline: localizedTextBaseline(context),
    height: (22 / kBaseFontSize),
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
    fontFamily: kDefaultFontFamily,
    fontFamilyFallback: defaultFontFamilyFallback,
  )
    .merge(weightVariableTextStyle(context));

  @override
  ContentTheme copyWith({
    Color? colorCodeBlockBackground,
    Color? colorDirectMentionBackground,
    Color? colorGlobalTimeBackground,
    Color? colorGlobalTimeBorder,
    Color? colorMathBlockBorder,
    Color? colorMessageMediaContainerBackground,
    Color? colorPollNames,
    Color? colorPollVoteCountBackground,
    Color? colorPollVoteCountBorder,
    Color? colorPollVoteCountText,
    Color? colorThematicBreak,
    TextStyle? textStylePlainParagraph,
    CodeBlockTextStyles? codeBlockTextStyles,
    TextStyle? textStyleError,
    TextStyle? textStyleErrorCode,
    TextStyle? textStyleInlineCode,
    TextStyle? textStyleInlineMath,
  }) {
    return ContentTheme._(
      colorCodeBlockBackground: colorCodeBlockBackground ?? this.colorCodeBlockBackground,
      colorDirectMentionBackground: colorDirectMentionBackground ?? this.colorDirectMentionBackground,
      colorGlobalTimeBackground: colorGlobalTimeBackground ?? this.colorGlobalTimeBackground,
      colorGlobalTimeBorder: colorGlobalTimeBorder ?? this.colorGlobalTimeBorder,
      colorMathBlockBorder: colorMathBlockBorder ?? this.colorMathBlockBorder,
      colorMessageMediaContainerBackground: colorMessageMediaContainerBackground ?? this.colorMessageMediaContainerBackground,
      colorPollNames: colorPollNames ?? this.colorPollNames,
      colorPollVoteCountBackground: colorPollVoteCountBackground ?? this.colorPollVoteCountBackground,
      colorPollVoteCountBorder: colorPollVoteCountBorder ?? this.colorPollVoteCountBorder,
      colorPollVoteCountText: colorPollVoteCountText ?? this.colorPollVoteCountText,
      colorThematicBreak: colorThematicBreak ?? this.colorThematicBreak,
      textStylePlainParagraph: textStylePlainParagraph ?? this.textStylePlainParagraph,
      codeBlockTextStyles: codeBlockTextStyles ?? this.codeBlockTextStyles,
      textStyleError: textStyleError ?? this.textStyleError,
      textStyleErrorCode: textStyleErrorCode ?? this.textStyleErrorCode,
      textStyleInlineCode: textStyleInlineCode ?? this.textStyleInlineCode,
      textStyleInlineMath: textStyleInlineMath ?? this.textStyleInlineMath,
    );
  }

  @override
  ContentTheme lerp(ContentTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return ContentTheme._(
      colorCodeBlockBackground: Color.lerp(colorCodeBlockBackground, other.colorCodeBlockBackground, t)!,
      colorDirectMentionBackground: Color.lerp(colorDirectMentionBackground, other.colorDirectMentionBackground, t)!,
      colorGlobalTimeBackground: Color.lerp(colorGlobalTimeBackground, other.colorGlobalTimeBackground, t)!,
      colorGlobalTimeBorder: Color.lerp(colorGlobalTimeBorder, other.colorGlobalTimeBorder, t)!,
      colorMathBlockBorder: Color.lerp(colorMathBlockBorder, other.colorMathBlockBorder, t)!,
      colorMessageMediaContainerBackground: Color.lerp(colorMessageMediaContainerBackground, other.colorMessageMediaContainerBackground, t)!,
      colorPollNames: Color.lerp(colorPollNames, other.colorPollNames, t)!,
      colorPollVoteCountBackground: Color.lerp(colorPollVoteCountBackground, other.colorPollVoteCountBackground, t)!,
      colorPollVoteCountBorder: Color.lerp(colorPollVoteCountBorder, other.colorPollVoteCountBorder, t)!,
      colorPollVoteCountText: Color.lerp(colorPollVoteCountText, other.colorPollVoteCountText, t)!,
      colorThematicBreak: Color.lerp(colorThematicBreak, other.colorThematicBreak, t)!,
      textStylePlainParagraph: TextStyle.lerp(textStylePlainParagraph, other.textStylePlainParagraph, t)!,
      codeBlockTextStyles: CodeBlockTextStyles.lerp(codeBlockTextStyles, other.codeBlockTextStyles, t),
      textStyleError: TextStyle.lerp(textStyleError, other.textStyleError, t)!,
      textStyleErrorCode: TextStyle.lerp(textStyleErrorCode, other.textStyleErrorCode, t)!,
      textStyleInlineCode: TextStyle.lerp(textStyleInlineCode, other.textStyleInlineCode, t)!,
      textStyleInlineMath: TextStyle.lerp(textStyleInlineMath, other.textStyleInlineMath, t)!,
    );
  }
}
