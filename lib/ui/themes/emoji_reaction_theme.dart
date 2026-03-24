import 'package:flutter/material.dart';

/// Emoji-reaction styles that differ between light and dark themes.
class EmojiReactionTheme extends ThemeExtension<EmojiReactionTheme> {
  static final light = EmojiReactionTheme._(
    bgSelected: Colors.white,

    // TODO shadow effect, following web, which uses `box-shadow: inset`:
    //   https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow#inset
    //   Needs Flutter support for something like that:
    //     https://github.com/flutter/flutter/issues/18636
    //     https://github.com/flutter/flutter/issues/52999
    //   Until then use a solid color; a much-lightened version of the shadow color.
    //   Also adapt by making [borderUnselected] more transparent, so we'll
    //   want to check that against web when implementing the shadow.
    bgUnselected: const HSLColor.fromAHSL(0.08, 210, 0.50, 0.875).toColor(),

    borderSelected: Colors.black.withValues(alpha: 0.45),

    // TODO see TODO on [bgUnselected] about shadow effect
    borderUnselected: Colors.black.withValues(alpha: 0.05),

    textSelected: const HSLColor.fromAHSL(1, 210, 0.20, 0.20).toColor(),
    textUnselected: const HSLColor.fromAHSL(1, 210, 0.20, 0.25).toColor(),
  );

  static final dark = EmojiReactionTheme._(
    bgSelected: Colors.black.withValues(alpha: 0.8),
    bgUnselected: Colors.black.withValues(alpha: 0.3),
    borderSelected: Colors.white.withValues(alpha: 0.75),
    borderUnselected: Colors.white.withValues(alpha: 0.15),
    textSelected: Colors.white.withValues(alpha: 0.85),
    textUnselected: Colors.white.withValues(alpha: 0.75),
  );

  EmojiReactionTheme._({
    required this.bgSelected,
    required this.bgUnselected,
    required this.borderSelected,
    required this.borderUnselected,
    required this.textSelected,
    required this.textUnselected,
  });

  /// The [EmojiReactionTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [EmojiReactionTheme] in [ThemeData.extensions].
  static EmojiReactionTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<EmojiReactionTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color bgSelected;
  final Color bgUnselected;
  final Color borderSelected;
  final Color borderUnselected;
  final Color textSelected;
  final Color textUnselected;

  @override
  EmojiReactionTheme copyWith({
    Color? bgSelected,
    Color? bgUnselected,
    Color? borderSelected,
    Color? borderUnselected,
    Color? textSelected,
    Color? textUnselected,
  }) {
    return EmojiReactionTheme._(
      bgSelected: bgSelected ?? this.bgSelected,
      bgUnselected: bgUnselected ?? this.bgUnselected,
      borderSelected: borderSelected ?? this.borderSelected,
      borderUnselected: borderUnselected ?? this.borderUnselected,
      textSelected: textSelected ?? this.textSelected,
      textUnselected: textUnselected ?? this.textUnselected,
    );
  }

  @override
  EmojiReactionTheme lerp(EmojiReactionTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return EmojiReactionTheme._(
      bgSelected: Color.lerp(bgSelected, other.bgSelected, t)!,
      bgUnselected: Color.lerp(bgUnselected, other.bgUnselected, t)!,
      borderSelected: Color.lerp(borderSelected, other.borderSelected, t)!,
      borderUnselected: Color.lerp(
        borderUnselected,
        other.borderUnselected,
        t,
      )!,
      textSelected: Color.lerp(textSelected, other.textSelected, t)!,
      textUnselected: Color.lerp(textUnselected, other.textUnselected, t)!,
    );
  }
}
