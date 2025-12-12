// List of icons that should flip horizontally in RTL layout.
//
// This is part of the input for generating the [ZulipIcons] class,
// in lib/widgets/icons.dart .  It determines [IconData.matchTextDirection]:
//   https://main-api.flutter.dev/flutter/widgets/IconData/matchTextDirection.html
//
// For guidance on which icons should be included here, see:
//   https://m3.material.io/foundations/layout/understanding-layout/bidirectionality-rtl#ad90d075-6db4-457b-a15b-51fb6653c825
module.exports = [
  "arrow_right",
  "chevron_right",
  "send",
  "arrow_left_right",

  // These two are drawings of specific UI layouts which are directional.
  "message_feed",
  "topics",
];
