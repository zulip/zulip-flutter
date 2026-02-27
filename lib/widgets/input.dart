import 'package:flutter/material.dart';

import 'theme.dart';

/// A base [InputDecoration] for "filled"-style text inputs.
///
/// Callers should use [InputDecoration.copyWith] to add field-specific
/// properties like [InputDecoration.hintText], [InputDecoration.labelText],
/// or [InputDecoration.suffixIcon].
InputDecoration baseFilledInputDecoration(DesignVariables designVariables) {
  return InputDecoration(
    hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
    // TODO(design) is this the right variable?
    errorStyle: TextStyle(color: designVariables.contextMenuItemTextDanger),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
