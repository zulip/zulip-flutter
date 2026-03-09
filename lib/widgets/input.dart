import 'package:flutter/material.dart';

import 'inset_shadow.dart';
import 'theme.dart';

/// A base [InputDecoration] for "filled"-style text inputs.
///
/// Callers should use [InputDecoration.copyWith] to add field-specific
/// properties like [InputDecoration.hintText], [InputDecoration.labelText],
/// or [InputDecoration.suffixIcon].
///
/// [filledInputTextStyle] is recommended for styling the text-input's value,
/// i.e., the text the user has typed. That's not a job of [InputDecoration].
InputDecoration baseFilledInputDecoration(DesignVariables designVariables) {
  return InputDecoration(
    hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
    // TODO(design) is this the right variable?
    errorStyle: TextStyle(color: designVariables.contextMenuItemTextDanger),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      vertical: 8,
      // Subtracting 4 pixels to account for the internal
      // 4-pixel horizontal padding (_kInputExtraPadding in InputDecorator).
      horizontal: 10 - 4,
    ),
    filled: true,
    fillColor: designVariables.bgSearchInput,

    // "underline" not because we want an underline (we unset it using
    // [BorderSide.none]) but because it causes [InputDecorator] to handle the
    // label text's "floating" state by putting the label in a reserved space
    // inside the input's filled area (see `filled: true`) instead of making it
    // straddle the top edge of the filled area. Requested by Alya:
    //   https://github.com/zulip/zulip-flutter/pull/2184#issuecomment-3993219258
    // When no label text is specified (see [InputDecoration.labelText]),
    // the extra space is not reserved.
    // TODO(#2183) revisit if changing
    border: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none));
}

/// A [TextStyle] for the user-entered text in "filled"-style text inputs.
///
/// This is intended to be paired with [baseFilledInputDecoration].
TextStyle filledInputTextStyle(DesignVariables designVariables) => TextStyle(
  // Font size and height from
  //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=10806-25228&m=dev
  fontSize: 19,
  height: 26 / 19,

  // https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=10867-99284&m=dev
  color: designVariables.textInput,
);

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
