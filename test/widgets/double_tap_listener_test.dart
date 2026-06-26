import 'package:checks/checks.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/double_tap_listener.dart';

// Most of these tests are taken from the upstream repo and then tweaked
// for simplicity. See: https://github.com/flutter/flutter/blob/2731746a84d/packages/flutter/test/gestures/double_tap_test.dart

void main() {
  late int doubleTapCount;
  late int parentTapCount;
  late int childTapCount;

  final childKey = UniqueKey();

  void checkDoubleTapped({int count = 1}) {
    check(doubleTapCount).equals(count);
    doubleTapCount = 0;
  }
  void checkNotDoubleTapped() => checkDoubleTapped(count: 0);

  Future<void> pumpDoubleTapListener(
    WidgetTester tester, {
    Set<PointerDeviceKind>? supportedDevices,
    AllowedButtonsFilter? allowedButtonsFilter,
    bool nullCallback = false,
    bool includeParentTapHandler = false,
    bool includeChildTapHandler = false,
  }) async {
    Widget child = Container(key: childKey, width: 300, height: 300, color: Colors.teal);
    if (includeChildTapHandler) {
      child = GestureDetector(onTap: () => childTapCount++, child: child);
    }

    final onDoubleTap = nullCallback ? null : () => doubleTapCount++;
    Widget listener = allowedButtonsFilter == null
      ? DoubleTapListener(
          onDoubleTap: onDoubleTap,
          supportedDevices: supportedDevices,
          child: child)
      : DoubleTapListener(
          onDoubleTap: onDoubleTap,
          supportedDevices: supportedDevices,
          allowedButtonsFilter: allowedButtonsFilter,
          child: child);
    if (includeParentTapHandler) {
      listener = GestureDetector(
        onTap: () => parentTapCount++, behavior: .translucent, child: listener);
    }

    await tester.pumpWidget(Directionality(textDirection: .ltr, child: listener));
  }

  Offset center(WidgetTester tester) => tester.getCenter(find.byKey(childKey));

  setUp(() {
    doubleTapCount = 0;
    parentTapCount = 0;
    childTapCount = 0;
  });

  testWidgets('Recognizes double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 100));
    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Inter-tap distance cancels double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 100));
    await tester.tapAt(center(tester).translate(100 + 1, 0));

    checkNotDoubleTapped();
  });

  testWidgets('Intra-tap distance cancels double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    final gesture = await tester.startGesture(center(tester));
    await gesture.moveBy(Offset(18 + 1, 0));
    await gesture.up();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkNotDoubleTapped();
  });

  testWidgets('Inter-tap delay cancels double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 300));
    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkNotDoubleTapped();
  });

  testWidgets('Inter-tap delay resets state allowing third tap to complete double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 300));
    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 100));
    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Intra-tap delay does not cancel double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    final gesture = await tester.startGesture(center(tester));
    await tester.pump(Duration(milliseconds: 1000));
    await gesture.up();

    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Does not recognize overlapping taps', (tester) async {
    await pumpDoubleTapListener(tester);

    final gesture1 = await tester.startGesture(center(tester));
    final gesture2 = await tester.startGesture(center(tester));

    await gesture1.up();
    await gesture2.up();
    await tester.pump(kDoubleTapMinTime);

    checkNotDoubleTapped();
  });

  testWidgets('Recognizes one overlapping tap followed by a second tap', (tester) async {
    await pumpDoubleTapListener(tester);

    final gesture1 = await tester.startGesture(center(tester));
    final gesture2 = await tester.startGesture(center(tester));

    await gesture1.up();
    await gesture2.up();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Does not recognize two over-rapid taps', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkNotDoubleTapped();
  });

  testWidgets('Over-rapid taps reset state allowing third tap to complete double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tapAt(center(tester));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Pointer-cancel rejects double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    final gesture = await tester.startGesture(center(tester));
    await gesture.cancel();

    await tester.pump(const Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    await tester.pump(kDoubleTapMinTime);

    checkNotDoubleTapped();
  });

  testWidgets('Does not recognize double tap from unsupported devices', (tester) async {
    await pumpDoubleTapListener(tester, supportedDevices: {.touch});

    await tester.tapAt(center(tester), kind: .stylus);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center(tester), kind: .stylus);

    checkNotDoubleTapped();
  });

  testWidgets('Does not recognize double tap on null callback', (tester) async {
    await pumpDoubleTapListener(tester, nullCallback: true);

    await tester.tapAt(center(tester));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center(tester));

    checkNotDoubleTapped();
  });

  group('Buttons filtering:', () {
    testWidgets('By default, does not recognize a secondary double tap', (tester) async {
      await pumpDoubleTapListener(tester);

      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);
      await tester.pump(Duration(milliseconds: 100));
      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);

      checkNotDoubleTapped();
    });

    testWidgets('Does not recognize invalid buttons double tap', (tester) async {
      await pumpDoubleTapListener(tester,
        allowedButtonsFilter: (buttons) => buttons == kSecondaryButton);

      await tester.tapAt(center(tester), buttons: kMiddleMouseButton);
      await tester.pump(Duration(milliseconds: 100));
      await tester.tapAt(center(tester), buttons: kMiddleMouseButton);

      checkNotDoubleTapped();
    });

    testWidgets('Button change interrupts existing sequence', (tester) async {
      await pumpDoubleTapListener(tester);

      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      // Tap1 -> Tap2 (different button from 1) -> Tap3 (same button as 1)
      // Tap1 and Tap3 could've been a double tap, but is interrupted by Tap2.
      // Tap2 gets ignored because it's not the default primary button.
      // Regardless, the state is reset.

      await tester.tapAt(center(tester));
      await tester.pump(interval);
      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);

      checkNotDoubleTapped();

      await tester.pump(interval);
      await tester.tapAt(center(tester));
      await tester.pump(kDoubleTapMinTime);

      checkNotDoubleTapped();
    });

    testWidgets('Button change with allowedButtonsFilter interrupts existing sequence', (tester) async {
      await pumpDoubleTapListener(tester,
        allowedButtonsFilter: (buttons) => buttons == kSecondaryButton);

      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      // Tap1 -> Tap2 (different button from 1) -> Tap3 (same button as 1)
      // Tap1 and Tap3 could've been a double tap, but is interrupted by Tap2.
      // Tap2 gets ignored because it's not a secondary button.
      // Regardless, the state is reset.

      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);
      await tester.pump(interval);
      await tester.tapAt(center(tester), buttons: kMiddleMouseButton);

      checkNotDoubleTapped();

      await tester.pump(interval);
      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);
      await tester.pump(kDoubleTapMinTime);

      checkNotDoubleTapped();
    });

    testWidgets('Button change starts a valid sequence', (tester) async {
      await pumpDoubleTapListener(tester);

      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      // Tap1 -> Tap2 (different button from 1) -> Tap3 (same button as 2)
      // Tap2 and Tap3 completes a double tap.

      await tester.tapAt(center(tester), buttons: kSecondaryMouseButton);
      await tester.pump(interval);
      await tester.tapAt(center(tester));

      checkNotDoubleTapped();

      await tester.pump(interval);
      await tester.tapAt(center(tester));
      await tester.pump(kDoubleTapMinTime);

      checkDoubleTapped();
    });
  });

  testWidgets('Double tap does not suppress parent tap handler', (tester) async {
    await pumpDoubleTapListener(tester, includeParentTapHandler: true);

    await tester.tapAt(center(tester));
    check(parentTapCount).equals(1);
    checkNotDoubleTapped();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    check(parentTapCount).equals(2);

    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });

  testWidgets('Double tap does not suppress child tap handler', (tester) async {
    await pumpDoubleTapListener(tester, includeChildTapHandler: true);

    await tester.tapAt(center(tester));
    check(childTapCount).equals(1);
    checkNotDoubleTapped();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    check(childTapCount).equals(2);

    await tester.pump(kDoubleTapMinTime);

    checkDoubleTapped();
  });
}
