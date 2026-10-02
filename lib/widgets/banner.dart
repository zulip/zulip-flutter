import 'dart:ui';

import 'package:flutter/material.dart';

import 'button.dart';
import 'text.dart';
import 'theme.dart';

/// A banner to show below the app bar.
///
/// This is an evolution of the banner specced for the compose box:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=4010-6425&t=3wvxqQHzHPij90MI-0
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=4031-17025&t=3wvxqQHzHPij90MI-0
/// to serve the server-compat banner on the home page.
///
/// It's a bit like Zulip Web UI Kit's "Banner top" component:
///   https://www.figma.com/design/msWyAJ8cnMHgOMPxi7BUvA/Zulip-Web-UI-kit?node-id=694-3997&m=dev
/// in particular by using regular weight for the text.
/// But the text and action buttons are aligned differently;
/// there may be other differences.
///
/// Relevant design discussion:
///   https://chat.zulip.org/#narrow/channel/530-mobile-design/topic/Design.20of.20banner.20for.20unsupported.20server/near/2428017
class ZulipBanner extends StatelessWidget {
  const ZulipBanner({
    super.key,
    required this.intent,
    required this.label,
    required this.actions,
  });

  final ZulipBannerIntent intent;
  final String label;

  /// A list of actions to show below the label.
  ///
  /// It should include vertical but not horizontal outer padding
  /// for spacing/positioning.
  ///
  /// An interactive element's touchable area should have height at least 44px,
  /// with some of that as "slop" vertical outer padding above and below
  /// what gets painted:
  ///   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023907300
  ///
  /// It is recommended to pass a list of [ZulipWebUiKitButton]
  /// with [ZulipWebUiKitButtonSize.small] for this field.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final (labelColor, backgroundColor) = _intentColors(designVariables, intent);

    final semanticsRole = switch (intent) {
      .info => SemanticsRole.status,
      .warning || .danger => SemanticsRole.alert,
    };

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(width: 1, color: designVariables.borderBar))),
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 8),
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Column(crossAxisAlignment: .start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  style: TextStyle(
                    fontSize: 16,
                    height: 18 / 16,
                    color: labelColor,
                  ).merge(weightVariableTextStyle(context, wght: 400)),
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5),
                  label)),
              Row(mainAxisAlignment: .end, spacing: 8,
                children: actions),
            ]))));

    result = Semantics(
      container: true,
      role: semanticsRole,
      child: result);

    return result;
  }
}

enum ZulipBannerIntent {
  info,
  warning,
  danger,
}

/// The label color and background color for [intent].
(Color, Color) _intentColors(
  DesignVariables designVariables,
  ZulipBannerIntent intent,
) {
  return switch (intent) {
    .info => (
      designVariables.bannerTextIntInfo,
      designVariables.bannerBgIntInfo),
    .warning => (
      designVariables.btnLabelAttMediumIntWarning,
      designVariables.bannerBgIntWarning),
    .danger => (
      designVariables.btnLabelAttMediumIntDanger,
      designVariables.bannerBgIntDanger),
  };
}

/// A banner that floats free of the app bar and the compose box,
/// sized to the width available where it's placed.
///
/// Unlike [ZulipBanner], which sits below the app bar,
/// and the compose box's own banner, which attaches to the compose box,
/// this one is a rounded surface meant to sit inline in a page's content.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=13185-40768&m=dev
class FloatingBanner extends StatelessWidget {
  const FloatingBanner({
    super.key,
    required this.intent,
    required this.label,
  });

  final ZulipBannerIntent intent;
  final String label;

  // TODO(design) Support the action buttons in the design,
  //   like [ZulipBanner.actions].

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final (labelColor, backgroundColor) = _intentColors(designVariables, intent);

    // No SemanticsRole here, unlike [ZulipBanner]: the status and alert roles
    // are for announcing content that appears or changes, and this sits in a
    // page's content, read in the usual order.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6)),
      child: SizedBox(width: double.infinity,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 8, 5),
          child: Text(
            style: TextStyle(
              fontSize: 17,
              height: 1.30,
              color: labelColor,
            ).merge(weightVariableTextStyle(context, wght: 500)),
            label))));
  }
}
