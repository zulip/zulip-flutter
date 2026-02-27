import 'package:flutter/material.dart';

import 'theme.dart';

/// A base [InputDecoration] for "filled"-style text inputs.
///
/// Callers should use [InputDecoration.copyWith] to add field-specific
/// properties like [InputDecoration.hintText] or [InputDecoration.suffixIcon].
///
/// The returned decoration won't configure a "label" above the input,
/// for callers building a form, even though [InputDecoration] supports that.
/// That's because we don't have a Figma design for form fields with labels,
/// and we expect it to be quite different from Material's defaults;
/// that's https://github.com/zulip/zulip-flutter/issues/2183 .
/// Until we have that design, callers shouldn't spend significant effort
/// wrangling [InputDecoration.labelStyle] and its friends.
/// (Consider whether hint text by itself is enough,
/// or if Material's default styling is OK temporarily.)
// TODO(#2183) review dartdoc and implementation
InputDecoration baseFilledInputDecoration(DesignVariables designVariables) {
  return InputDecoration(
    hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
    // TODO(design) is this the right variable?
    errorStyle: TextStyle(color: designVariables.contextMenuItemTextDanger),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    filled: true,
    fillColor: designVariables.bgSearchInput,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none));
}

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
