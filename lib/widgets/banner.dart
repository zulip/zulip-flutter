import 'package:flutter/material.dart';

import 'text.dart';
import 'theme.dart';

/// The banner component from Zulip Mobile Figma design.
///
/// Must have a [PageRoot] ancestor.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=13185-40768&t=PoSiHHfRtGL9EqtO-0
class ZulipBanner extends StatelessWidget {
  const ZulipBanner({
    super.key,
    required this.intent,
    required this.label,
    this.useSmallerText = false,
    this.trailing,
    this.padEnd = true, // ignore: unused_element_parameter
  });

  final ZulipBannerIntent intent;
  final String label;

  /// Whether to decrease the label's font size and line height slightly.
  ///
  /// When [label] is so long
  /// that it doesn't fit on a single line in common device configurations,
  /// consider passing `true` for this,
  /// and consider shrinking [trailing], e.g. with [ZulipWebUiKitButton.size].
  final bool useSmallerText;

  /// An optional trailing element.
  ///
  /// It should include vertical but not horizontal outer padding
  /// for spacing/positioning.
  ///
  /// An interactive element's touchable area should have height at least 44px,
  /// with some of that as "slop" vertical outer padding above and below
  /// what gets painted:
  ///   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023907300
  ///
  /// To control the element's distance from the end edge, use [padEnd].
  // An "x" button could go here.
  // 24px square with 8px touchable padding in all directions?
  // and `padEnd: false`; see Figma:
  //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=4031-17029&m=dev
  final Widget? trailing;

  /// Whether to apply `end: 8` in [SafeArea.minimum].
  ///
  /// Pass `false` when the [trailing] element
  /// is meant to abut the edge of the screen
  /// in the common case that there are no horizontal device insets.
  ///
  /// Defaults to `true`.
  final bool padEnd;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final (labelColor, backgroundColor) = switch (intent) {
      ZulipBannerIntent.info =>
        (designVariables.bannerTextIntInfo, designVariables.bannerBgIntInfo),
      ZulipBannerIntent.warning =>
        (designVariables.btnLabelAttMediumIntWarning, designVariables.bannerBgIntWarning),
      ZulipBannerIntent.danger =>
        (designVariables.btnLabelAttMediumIntDanger, designVariables.bannerBgIntDanger),
    };

    final labelTextStyle = TextStyle(
      fontSize: useSmallerText
        ? 16
        : 17,
      height: useSmallerText
        ? 18 / 16
        : 22 / 17,
      color: labelColor,
    ).merge(weightVariableTextStyle(context, wght: 600));

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: SafeArea(
        minimum: EdgeInsetsDirectional.only(start: 8, end: padEnd ? 8 : 0)
          // (SafeArea.minimum doesn't take an EdgeInsetsDirectional)
          .resolve(Directionality.of(context)),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    style: labelTextStyle,
                    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5),
                    label))),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ]))));
  }
}

enum ZulipBannerIntent {
  info,
  warning,
  danger,
}
