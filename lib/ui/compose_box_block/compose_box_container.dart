import 'package:flutter/material.dart';

import 'compose_box.dart';
import '../values/theme.dart';

class ComposeBoxContainer extends StatelessWidget {
  const ComposeBoxContainer({super.key, required this.body, this.banner})
    : assert(body != null || banner != null);

  /// The text inputs, compose-button row, and send button.
  ///
  /// This widget does not need a [SafeArea] to consume any device insets.
  ///
  /// Can be null, but only if [banner] is non-null.
  final Widget? body;

  /// A bar that goes at the top.
  ///
  /// This may be present on its own or with a [body].
  /// If [body] is null this must be present.
  ///
  /// This widget should use a [SafeArea] to pad the left, right,
  /// and bottom device insets.
  /// (A bottom inset may occur if [body] is null.)
  final Widget? banner;

  Widget _paddedBody() {
    assert(body != null);
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 8),
      child: body!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final List<Widget> children = switch ((banner, body)) {
      (Widget(), Widget()) => [
        // _paddedBody() already pads the bottom inset,
        // so make sure the banner doesn't double-pad it.
        MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: banner!,
        ),
        _paddedBody(),
      ],
      (Widget(), null) => [banner!],
      (null, Widget()) => [_paddedBody()],
      (null, null) => throw UnimplementedError(), // not allowed, see dartdoc
    };

    // TODO(design): Maybe put a max width on the compose box, like we do on
    //   the message list itself; if so, remember to update ComposeBox's dartdoc.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: designVariables.borderBar)),
        boxShadow: ComposeBoxTheme.of(context).boxShadow,
      ),
      child: Material(
        color: designVariables.composeBoxBg,
        child: Column(children: children),
      ),
    );
  }
}
