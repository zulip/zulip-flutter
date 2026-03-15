import 'package:flutter/material.dart';

import 'inset_shadow.dart';
import 'theme.dart';

/// A space to use for [InputDecoration.helperText] so the layout doesn't jump.
///
/// In particular, U+200B ZERO WIDTH SPACE.
///
/// See [FormField.validator] :
/// >  Alternating between error and normal state can cause the height of the
/// >  [TextFormField] to change if no other subtext decoration is set on the
/// >  field. To create a field whose height is fixed regardless of whether or
/// >  not an error is displayed, either wrap the  [TextFormField] in a fixed
/// >  height parent like [SizedBox], or set the [InputDecoration.helperText]
/// >  parameter to a space.
// TODO(upstream?): This contentless `helperText` shouldn't get its own node
//   in the semantics tree. Empirically, it does: iOS VoiceOver's focus can land
//   on it, and when it does, nothing gets read.
const String kLayoutPinningHelperText = '\u200b';

/// Figma's "pop-menu" component for compose autocomplete:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3732-28971&m=dev
// TODO(#1972) use this style in report-message dropdown, perhaps with help from
//   a [MenuStyle] representation of the style.
class PopupMenuList extends StatelessWidget {
  const PopupMenuList({
    super.key,
    required this.scrollController,
    required this.maxHeight,
    required this.itemCount,
    required this.itemBuilder,
  });

  final ScrollController? scrollController;
  final double maxHeight;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  /// The vertical content padding.
  ///
  /// See [_verticalShadowInset], which is related.
  static const _verticalPadding   = EdgeInsets.symmetric(vertical: 2);

  /// The horizontal content padding.
  static const _horizontalPadding = EdgeInsets.symmetric(horizontal: 2);

  /// How far the shadow effect should extend from the top and bottom
  /// of the viewport.
  ///
  /// Normally we pad the scrollable content by this amount too,
  /// so that the first and last items can come to rest --
  /// and the first item initializes -- entirely out of the shaded area.
  ///
  /// In this case the design calls for 2px content padding
  /// and 8px shadow insets:
  ///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3860-12988&m=dev
  ///
  /// To avoid shading a 2px strip of autocomplete-item content,
  /// we choose 6px for this instead of 8px,
  /// noticing that autocomplete items always pad their content by at least 4px.
  /// (Touch feedback is still affected, but at least that's a temporary state.)
  static const _verticalShadowInset = EdgeInsets.symmetric(vertical: 6);

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Material(
      color: designVariables.contextMenuBg,
      clipBehavior: .hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: designVariables.contextMenuBorder)),
      elevation: 4.0, // TODO tune the shadow effect
      child: Padding(
        padding: _horizontalPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: InsetShadowBox(
            top: _verticalShadowInset.top, bottom: _verticalShadowInset.bottom,
            color: designVariables.contextMenuBg,
            child: ListView.builder(
              controller: scrollController,
              padding: _verticalPadding,
              shrinkWrap: true,
              itemCount: itemCount,
              itemBuilder: itemBuilder)))));
  }
}
