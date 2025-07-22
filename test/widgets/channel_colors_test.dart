import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/channel_colors.dart';

import 'checks.dart';

void main() {
  group('ChannelColorSwatches', () {
    test('.light', () {
      final instance = ChannelColorSwatches.light;

      const base1 = 0xff76ce90;
      final swatch1 = instance.forBaseColor(base1);
      check(swatch1).isSameColorSwatchAs(ChannelColorSwatch.light(base1));
      check(instance.forBaseColor(base1)).identicalTo(swatch1);

      const base2 = 0xfffae589;
      final swatch2 = instance.forBaseColor(base2);
      check(swatch2).isSameColorSwatchAs(ChannelColorSwatch.light(base2));
      check(instance.forBaseColor(base2)).identicalTo(swatch2);
      check(instance.forBaseColor(base1)).identicalTo(swatch1);
    });

    // TODO deduplicate with corresponding light-theme test?
    test('.dark', () {
      final instance = ChannelColorSwatches.dark;

      const base1 = 0xff76ce90;
      final swatch1 = instance.forBaseColor(base1);
      check(swatch1).isSameColorSwatchAs(ChannelColorSwatch.dark(base1));
      check(instance.forBaseColor(base1)).identicalTo(swatch1);

      const base2 = 0xfffae589;
      final swatch2 = instance.forBaseColor(base2);
      check(swatch2).isSameColorSwatchAs(ChannelColorSwatch.dark(base2));
      check(instance.forBaseColor(base2)).identicalTo(swatch2);
      check(instance.forBaseColor(base1)).identicalTo(swatch1);
    });

    group('lerp', () {
      test('on identical instances', () {
        final light = ChannelColorSwatches.light;
        check(ChannelColorSwatches.lerp(light, light, 0.5)).identicalTo(light);

        final dark = ChannelColorSwatches.dark;
        check(ChannelColorSwatches.lerp(dark, dark, 0.5)).identicalTo(dark);
      });

      test('from light to dark', () {
        final instance = ChannelColorSwatches
          .lerp(ChannelColorSwatches.light, ChannelColorSwatches.dark, 0.4);

        const base1 = 0xff76ce90;
        final swatch1 = instance.forBaseColor(base1);
        check(swatch1).isSameColorSwatchAs(ChannelColorSwatch.lerp(
          ChannelColorSwatch.light(base1), ChannelColorSwatch.dark(base1), 0.4)!);
        check(instance.forBaseColor(base1)).identicalTo(swatch1);

        const base2 = 0xfffae589;
        final swatch2 = instance.forBaseColor(base2);
        check(swatch2).isSameColorSwatchAs(ChannelColorSwatch.lerp(
          ChannelColorSwatch.light(base2), ChannelColorSwatch.dark(base2), 0.4)!);
        check(instance.forBaseColor(base2)).identicalTo(swatch2);
        check(instance.forBaseColor(base1)).identicalTo(swatch1);
      });
    });
  });

  group('ChannelColorSwatch', () {
    group('light', () {
      test('base', () {
        check(ChannelColorSwatch.light(0xffffffff))
          .base.isSameColorAs(const Color(0xffffffff));
      });

      test('unreadCountBadgeBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.light(base))
            .unreadCountBadgeBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS and EXTREME_COLORS
        // in <https://replit.com/@VladKorobov/zulip-sidebar#script.js>.
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/371#discussion_r1393643523

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        // ZULIP_ASSIGNMENT_COLORS
        runCheck(0xff76ce90, const Color(0x4d65bd80));
        runCheck(0xfffae589, const Color(0x4dbdab53)); // 0x4dbdaa52
        runCheck(0xffa6c7e5, const Color(0x4d8eafcc)); // 0x4d8fb0cd
        runCheck(0xffe79ab5, const Color(0x4de295b0)); // 0x4de194af
        runCheck(0xffbfd56f, const Color(0x4d9eb551)); // 0x4d9eb450
        runCheck(0xfff4ae55, const Color(0x4de19d45)); // 0x4de09c44
        runCheck(0xffb0a5fd, const Color(0x4daba0f8)); // 0x4daca2f9
        runCheck(0xffaddfe5, const Color(0x4d83b4b9)); // 0x4d83b4ba
        runCheck(0xfff5ce6e, const Color(0x4dcba749)); // 0x4dcaa648
        runCheck(0xffc2726a, const Color(0x4dc2726a));
        runCheck(0xff94c849, const Color(0x4d86ba3c)); // 0x4d86ba3b
        runCheck(0xffbd86e5, const Color(0x4dbd86e5));
        runCheck(0xffee7e4a, const Color(0x4dee7e4a));
        runCheck(0xffa6dcbf, const Color(0x4d82b69b)); // 0x4d82b79b
        runCheck(0xff95a5fd, const Color(0x4d95a5fd));
        runCheck(0xff53a063, const Color(0x4d53a063));
        runCheck(0xff9987e1, const Color(0x4d9987e1));
        runCheck(0xffe4523d, const Color(0x4de4523d));
        runCheck(0xffc2c2c2, const Color(0x4dababab));
        runCheck(0xff4f8de4, const Color(0x4d4f8de4));
        runCheck(0xffc6a8ad, const Color(0x4dc2a4a9)); // 0x4dc1a4a9
        runCheck(0xffe7cc4d, const Color(0x4dc3ab2a)); // 0x4dc2aa28
        runCheck(0xffc8bebf, const Color(0x4db3a9aa));
        runCheck(0xffa47462, const Color(0x4da47462));

        // EXTREME_COLORS
        runCheck(0xFFFFFFFF, const Color(0x4dababab));
        runCheck(0xFF000000, const Color(0x4d474747));
        runCheck(0xFFD3D3D3, const Color(0x4dababab));
        runCheck(0xFFA9A9A9, const Color(0x4da9a9a9));
        runCheck(0xFF808080, const Color(0x4d808080));
        runCheck(0xFFFFFF00, const Color(0x4dacb300)); // 0x4dacb200
        runCheck(0xFFFF0000, const Color(0x4dff0000));
        runCheck(0xFF008000, const Color(0x4d008000));
        runCheck(0xFF0000FF, const Color(0x4d0000ff)); // 0x4d0902ff
        runCheck(0xFFEE82EE, const Color(0x4dee82ee));
        runCheck(0xFFFFA500, const Color(0x4def9800)); // 0x4ded9600
        runCheck(0xFF800080, const Color(0x4d810181)); // 0x4d810281
        runCheck(0xFF00FFFF, const Color(0x4d00c2c3)); // 0x4d00c3c5
        runCheck(0xFFFF00FF, const Color(0x4dff00ff));
        runCheck(0xFF00FF00, const Color(0x4d00cb00));
        runCheck(0xFF800000, const Color(0x4d8d140c)); // 0x4d8b130b
        runCheck(0xFF008080, const Color(0x4d008080));
        runCheck(0xFF000080, const Color(0x4d492bae)); // 0x4d4b2eb3
        runCheck(0xFFFFFFE0, const Color(0x4dadad90)); // 0x4dacad90
        runCheck(0xFFFF69B4, const Color(0x4dff69b4));
      });

      test('iconOnPlainBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.light(base))
            .iconOnPlainBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/381#discussion_r1399319296

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        runCheck(0xff76ce90, const Color(0xff73cb8d));
        runCheck(0xfffae589, const Color(0xffccb95f)); // 0xffcbb85e
        runCheck(0xffa6c7e5, const Color(0xff9cbcda)); // 0xff9cbddb
        runCheck(0xffe79ab5, const Color(0xffe79ab5));
        runCheck(0xffbfd56f, const Color(0xffacc25d));
        runCheck(0xfff4ae55, const Color(0xfff0ab52)); // 0xffefa951
        runCheck(0xffb0a5fd, const Color(0xffb0a5fd));
        runCheck(0xffaddfe5, const Color(0xff90c1c7)); // 0xff90c2c8
        runCheck(0xfff5ce6e, const Color(0xffd9b456)); // 0xffd8b355
        runCheck(0xffc2726a, const Color(0xffc2726a));
        runCheck(0xff94c849, const Color(0xff94c849));
        runCheck(0xffbd86e5, const Color(0xffbd86e5));
        runCheck(0xffee7e4a, const Color(0xffee7e4a));
        runCheck(0xffa6dcbf, const Color(0xff8fc4a8));
        runCheck(0xff95a5fd, const Color(0xff95a5fd));
        runCheck(0xff53a063, const Color(0xff53a063));
        runCheck(0xff9987e1, const Color(0xff9987e1));
        runCheck(0xffe4523d, const Color(0xffe4523d));
        runCheck(0xffc2c2c2, const Color(0xffb9b9b9));
        runCheck(0xff4f8de4, const Color(0xff4f8de4));
        runCheck(0xffc6a8ad, const Color(0xffc6a8ad));
        runCheck(0xffe7cc4d, const Color(0xffd1b839)); // 0xffd0b737
        runCheck(0xffc8bebf, const Color(0xffc0b6b7));
        runCheck(0xffa47462, const Color(0xffa47462));
        runCheck(0xffacc25d, const Color(0xffacc25d));
      });

      test('iconOnBarBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.light(base))
            .iconOnBarBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/381#discussion_r1399319296

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        runCheck(0xff76ce90, const Color(0xff46ba69));
        runCheck(0xfffae589, const Color(0xffb49f39)); // 0xffb29d3a
        runCheck(0xffa6c7e5, const Color(0xff6f9ec9)); // 0xff6f9fcb
        runCheck(0xffe79ab5, const Color(0xffdb6991));
        runCheck(0xffbfd56f, const Color(0xff8ea43e));
        runCheck(0xfff4ae55, const Color(0xffeb901a)); // 0xffea8d19
        runCheck(0xffb0a5fd, const Color(0xff7b69fc));
        runCheck(0xffaddfe5, const Color(0xff67aab2)); // 0xff67acb4
        runCheck(0xfff5ce6e, const Color(0xffc59a2c)); // 0xffc3992d
        runCheck(0xffc2726a, const Color(0xffa94e45));
        runCheck(0xff94c849, const Color(0xff74a331));
        runCheck(0xffbd86e5, const Color(0xffa254da));
        runCheck(0xffee7e4a, const Color(0xffe55716));
        runCheck(0xffa6dcbf, const Color(0xff67af89));
        runCheck(0xff95a5fd, const Color(0xff5972fc));
        runCheck(0xff53a063, const Color(0xff3e784a));
        runCheck(0xff9987e1, const Color(0xff6f56d5));
        runCheck(0xffe4523d, const Color(0xffc8311c));
        runCheck(0xffc2c2c2, const Color(0xff9a9a9a));
        runCheck(0xff4f8de4, const Color(0xff216cd5));
        runCheck(0xffc6a8ad, const Color(0xffae838a));
        runCheck(0xffe7cc4d, const Color(0xffa69127)); // 0xffa38f26
        runCheck(0xffc8bebf, const Color(0xffa49597));
        runCheck(0xffa47462, const Color(0xff7f584a));
        runCheck(0xffacc25d, const Color(0xff8ea43e));
      });

      test('barBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.light(base))
            .barBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/381#discussion_r1399319296

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        runCheck(0xff76ce90, const Color(0xffddefe1));
        runCheck(0xfffae589, const Color(0xfff1ead7)); // 0xfff0ead6
        runCheck(0xffa6c7e5, const Color(0xffe5ebf2)); // 0xffe5ecf2
        runCheck(0xffe79ab5, const Color(0xfff6e4ea));
        runCheck(0xffbfd56f, const Color(0xffe9edd6));
        runCheck(0xfff4ae55, const Color(0xfffbe7d4)); // 0xfffae7d4
        runCheck(0xffb0a5fd, const Color(0xffeae6fa));
        runCheck(0xffaddfe5, const Color(0xffe2edee));
        runCheck(0xfff5ce6e, const Color(0xfff5e9d5)); // 0xfff4e9d5
        runCheck(0xffc2726a, const Color(0xfff0dbd8)); // 0xffefdbd8
        runCheck(0xff94c849, const Color(0xffe5eed3)); // 0xffe4eed3
        runCheck(0xffbd86e5, const Color(0xffeddff5));
        runCheck(0xffee7e4a, const Color(0xfffdded1)); // 0xfffcded1
        runCheck(0xffa6dcbf, const Color(0xffe2ede7));
        runCheck(0xff95a5fd, const Color(0xffe5e6fa)); // 0xffe4e6fa
        runCheck(0xff53a063, const Color(0xffd5e5d6));
        runCheck(0xff9987e1, const Color(0xffe5dff4));
        runCheck(0xffe4523d, const Color(0xfffcd6cd)); // 0xfffbd6cd
        runCheck(0xffc2c2c2, const Color(0xffebebeb));
        runCheck(0xff4f8de4, const Color(0xffd9e0f5)); // 0xffd8e0f5
        runCheck(0xffc6a8ad, const Color(0xffeee7e8));
        runCheck(0xffe7cc4d, const Color(0xfff4ead0)); // 0xfff3eacf
        runCheck(0xffc8bebf, const Color(0xffeceaea));
        runCheck(0xffa47462, const Color(0xffe7dad6));
        runCheck(0xffacc25d, const Color(0xffe9edd6));
      });
    });

    group('dark', () {
      test('base', () {
        check(ChannelColorSwatch.dark(0xffffffff))
          .base.isSameColorAs(const Color(0xffffffff));
      });

      test('unreadCountBadgeBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.dark(base))
            .unreadCountBadgeBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS and EXTREME_COLORS
        // in <https://replit.com/@VladKorobov/zulip-sidebar#script.js>.
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/643#issuecomment-2093940972

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        // ZULIP_ASSIGNMENT_COLORS
        runCheck(0xff76ce90, const Color(0x4d65bd80));
        runCheck(0xfffae589, const Color(0x4dbdab53)); // 0x4dbdaa52
        runCheck(0xffa6c7e5, const Color(0x4d8eafcc)); // 0x4d8fb0cd
        runCheck(0xffe79ab5, const Color(0x4de295b0)); // 0x4de194af
        runCheck(0xffbfd56f, const Color(0x4d9eb551)); // 0x4d9eb450
        runCheck(0xfff4ae55, const Color(0x4de19d45)); // 0x4de09c44
        runCheck(0xffb0a5fd, const Color(0x4daba0f8)); // 0x4daca2f9
        runCheck(0xffaddfe5, const Color(0x4d83b4b9)); // 0x4d83b4ba
        runCheck(0xfff5ce6e, const Color(0x4dcba749)); // 0x4dcaa648
        runCheck(0xffc2726a, const Color(0x4dc2726a));
        runCheck(0xff94c849, const Color(0x4d86ba3c)); // 0x4d86ba3b
        runCheck(0xffbd86e5, const Color(0x4dbd86e5));
        runCheck(0xffee7e4a, const Color(0x4dee7e4a));
        runCheck(0xffa6dcbf, const Color(0x4d82b69b)); // 0x4d82b79b
        runCheck(0xff95a5fd, const Color(0x4d95a5fd));
        runCheck(0xff53a063, const Color(0x4d53a063));
        runCheck(0xff9987e1, const Color(0x4d9987e1));
        runCheck(0xffe4523d, const Color(0x4de4523d));
        runCheck(0xffc2c2c2, const Color(0x4dababab));
        runCheck(0xff4f8de4, const Color(0x4d4f8de4));
        runCheck(0xffc6a8ad, const Color(0x4dc2a4a9)); // 0x4dc1a4a9
        runCheck(0xffe7cc4d, const Color(0x4dc3ab2a)); // 0x4dc2aa28
        runCheck(0xffc8bebf, const Color(0x4db3a9aa));
        runCheck(0xffa47462, const Color(0x4da47462));

        // EXTREME_COLORS
        runCheck(0xFFFFFFFF, const Color(0x4dababab));
        runCheck(0xFF000000, const Color(0x4d474747));
        runCheck(0xFFD3D3D3, const Color(0x4dababab));
        runCheck(0xFFA9A9A9, const Color(0x4da9a9a9));
        runCheck(0xFF808080, const Color(0x4d808080));
        runCheck(0xFFFFFF00, const Color(0x4dacb300)); // 0x4dacb200
        runCheck(0xFFFF0000, const Color(0x4dff0000));
        runCheck(0xFF008000, const Color(0x4d008000));
        runCheck(0xFF0000FF, const Color(0x4d0000ff)); // 0x4d0902ff
        runCheck(0xFFEE82EE, const Color(0x4dee82ee));
        runCheck(0xFFFFA500, const Color(0x4def9800)); // 0x4ded9600
        runCheck(0xFF800080, const Color(0x4d810181)); // 0x4d810281
        runCheck(0xFF00FFFF, const Color(0x4d00c2c3)); // 0x4d00c3c5
        runCheck(0xFFFF00FF, const Color(0x4dff00ff));
        runCheck(0xFF00FF00, const Color(0x4d00cb00));
        runCheck(0xFF800000, const Color(0x4d8d140c)); // 0x4d8b130b
        runCheck(0xFF008080, const Color(0x4d008080));
        runCheck(0xFF000080, const Color(0x4d492bae)); // 0x4d4b2eb3
        runCheck(0xFFFFFFE0, const Color(0x4dadad90)); // 0x4dacad90
        runCheck(0xFFFF69B4, const Color(0x4dff69b4));
      });

      test('iconOnPlainBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.dark(base))
            .iconOnPlainBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/643#issuecomment-2093940972

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        runCheck(0xff76ce90, const Color(0xff73cb8d));
        runCheck(0xfffae589, const Color(0xffccb95f)); // 0xffcbb85e
        runCheck(0xffa6c7e5, const Color(0xff9cbcda)); // 0xff9cbddb
        runCheck(0xffe79ab5, const Color(0xffe79ab5));
        runCheck(0xffbfd56f, const Color(0xffacc25d));
        runCheck(0xfff4ae55, const Color(0xfff0ab52)); // 0xffefa951
        runCheck(0xffb0a5fd, const Color(0xffb0a5fd));
        runCheck(0xffaddfe5, const Color(0xff90c1c7)); // 0xff90c2c8
        runCheck(0xfff5ce6e, const Color(0xffd9b456)); // 0xffd8b355
        runCheck(0xffc2726a, const Color(0xffc2726a));
        runCheck(0xff94c849, const Color(0xff94c849));
        runCheck(0xffbd86e5, const Color(0xffbd86e5));
        runCheck(0xffee7e4a, const Color(0xffee7e4a));
        runCheck(0xffa6dcbf, const Color(0xff8fc4a8));
        runCheck(0xff95a5fd, const Color(0xff95a5fd));
        runCheck(0xff53a063, const Color(0xff53a063));
        runCheck(0xff9987e1, const Color(0xff9987e1));
        runCheck(0xffe4523d, const Color(0xffe4523d));
        runCheck(0xffc2c2c2, const Color(0xffb9b9b9));
        runCheck(0xff4f8de4, const Color(0xff4f8de4));
        runCheck(0xffc6a8ad, const Color(0xffc6a8ad));
        runCheck(0xffe7cc4d, const Color(0xffd1b839)); // 0xffd0b737
        runCheck(0xffc8bebf, const Color(0xffc0b6b7));
        runCheck(0xffa47462, const Color(0xffa47462));
        runCheck(0xffacc25d, const Color(0xffacc25d));
      });

      test('iconOnBarBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.dark(base))
            .iconOnBarBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to generate expected results, see:
        //   https://github.com/zulip/zulip-flutter/pull/643#issuecomment-2093940972

        // TODO Fix bug causing our implementation's results to differ from the
        //   web app's. Where they differ, see comment with what web uses.

        runCheck(0xff76ce90, const Color(0xff73cb8d));
        runCheck(0xfffae589, const Color(0xffccb95f)); // 0xffcbb85e
        runCheck(0xffa6c7e5, const Color(0xff9cbcda)); // 0xff9cbddb
        runCheck(0xffe79ab5, const Color(0xffe79ab5));
        runCheck(0xffbfd56f, const Color(0xffacc25d));
        runCheck(0xfff4ae55, const Color(0xfff0ab52)); // 0xffefa951
        runCheck(0xffb0a5fd, const Color(0xffb0a5fd));
        runCheck(0xffaddfe5, const Color(0xff90c1c7)); // 0xff90c2c8
        runCheck(0xfff5ce6e, const Color(0xffd9b456)); // 0xffd8b355
        runCheck(0xffc2726a, const Color(0xffc2726a));
        runCheck(0xff94c849, const Color(0xff94c849));
        runCheck(0xffbd86e5, const Color(0xffbd86e5));
        runCheck(0xffee7e4a, const Color(0xffee7e4a));
        runCheck(0xffa6dcbf, const Color(0xff8fc4a8));
        runCheck(0xff95a5fd, const Color(0xff95a5fd));
        runCheck(0xff53a063, const Color(0xff53a063));
        runCheck(0xff9987e1, const Color(0xff9987e1));
        runCheck(0xffe4523d, const Color(0xffe4523d));
        runCheck(0xffc2c2c2, const Color(0xffb9b9b9));
        runCheck(0xff4f8de4, const Color(0xff4f8de4));
        runCheck(0xffc6a8ad, const Color(0xffc6a8ad));
        runCheck(0xffe7cc4d, const Color(0xffd1b839)); // 0xffd0b737
        runCheck(0xffc8bebf, const Color(0xffc0b6b7));
        runCheck(0xffa47462, const Color(0xffa47462));
        runCheck(0xffacc25d, const Color(0xffacc25d));
      });

      test('barBackground', () {
        void runCheck(int base, Color expected) {
          check(ChannelColorSwatch.dark(base))
            .barBackground.isSameColorAs(expected);
        }

        // Check against everything in ZULIP_ASSIGNMENT_COLORS
        // in <https://replit.com/@VladKorobov/zulip-topic-feed-colors#script.js>.
        // (Skipping `streamColors` because there are 100+ of them.)
        // On how to extract expected results from the replit, see:
        //   https://github.com/zulip/zulip-flutter/pull/643#issuecomment-2093940972

        // TODO Fix bug causing our implementation's results to differ from the
        //   replit's. Where they differ, see comment with what the replit gives.

        runCheck(0xff76ce90, const Color(0xff2e4935));
        runCheck(0xfffae589, const Color(0xff4a4327));
        runCheck(0xffa6c7e5, const Color(0xff3a444e)); // 0xff3a454e
        runCheck(0xffe79ab5, const Color(0xff523a42));
        runCheck(0xffbfd56f, const Color(0xff404627));
        runCheck(0xfff4ae55, const Color(0xff563f23)); // 0xff553e23
        runCheck(0xffb0a5fd, const Color(0xff413d59));
        runCheck(0xffaddfe5, const Color(0xff374648));
        runCheck(0xfff5ce6e, const Color(0xff4e4224)); // 0xff4e4124
        runCheck(0xffc2726a, const Color(0xff472d2a));
        runCheck(0xff94c849, const Color(0xff394821)); // 0xff384821
        runCheck(0xffbd86e5, const Color(0xff453351));
        runCheck(0xffee7e4a, const Color(0xff563120));
        runCheck(0xffa6dcbf, const Color(0xff36473e));
        runCheck(0xff95a5fd, const Color(0xff393d59));
        runCheck(0xff53a063, const Color(0xff243c28));
        runCheck(0xff9987e1, const Color(0xff3a3350));
        runCheck(0xffe4523d, const Color(0xff53241c)); // 0xff53241b
        runCheck(0xffc2c2c2, const Color(0xff434343));
        runCheck(0xff4f8de4, const Color(0xff263551)); // 0xff253551
        runCheck(0xffc6a8ad, const Color(0xff483e40));
        runCheck(0xffe7cc4d, const Color(0xff4c431d)); // 0xff4c431c
        runCheck(0xffc8bebf, const Color(0xff464243));
        runCheck(0xffa47462, const Color(0xff3d2d27));
        runCheck(0xffacc25d, const Color(0xff404627));
      });
    });

    test('lerp (different a, b)', () {
      final swatchA = ChannelColorSwatch.light(0xff76ce90);
      final swatchB = ChannelColorSwatch.dark(0xff76ce90);
      for (final t in [0.0, 0.5, 1.0, -0.1, 1.1]) {
        final result = ChannelColorSwatch.lerp(swatchA, swatchB, t)!;
        for (final variant in ChannelColorVariant.values) {
          final (subject, expected) = switch (variant) {
            ChannelColorVariant.base => (check(result).base,
              Color.lerp(swatchA.base, swatchB.base, t)!),
            ChannelColorVariant.unreadCountBadgeBackground => (check(result).unreadCountBadgeBackground,
              Color.lerp(swatchA.unreadCountBadgeBackground, swatchB.unreadCountBadgeBackground, t)!),
            ChannelColorVariant.iconOnPlainBackground => (check(result).iconOnPlainBackground,
              Color.lerp(swatchA.iconOnPlainBackground, swatchB.iconOnPlainBackground, t)!),
            ChannelColorVariant.iconOnBarBackground => (check(result).iconOnBarBackground,
              Color.lerp(swatchA.iconOnBarBackground, swatchB.iconOnBarBackground, t)!),
            ChannelColorVariant.barBackground => (check(result).barBackground,
              Color.lerp(swatchA.barBackground, swatchB.barBackground, t)!),
          };
          subject.isSameColorAs(expected);
        }
      }
    });

    test('lerp (identical a, b)', () {
      check(ChannelColorSwatch.lerp(null, null, 0.0)).isNull();

      final swatch = ChannelColorSwatch.light(0xff76ce90);
      check(ChannelColorSwatch.lerp(swatch, swatch, 0.5)).isNotNull()
        ..identicalTo(swatch)
        ..base.isSameColorAs(const Color(0xff76ce90));
    });
  });
}
