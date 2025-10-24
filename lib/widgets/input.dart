import 'package:flutter/widgets.dart';

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
