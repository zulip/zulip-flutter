// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the docs/THIRDPARTY file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/double_tap_recognizer.dart';

import 'gesture_tester.dart';

// Copied from the upstream Flutter repo, but adjusted to not participate
// in the gesture arena.
//   https://github.com/flutter/flutter/blob/ab7eb7aff/packages/flutter/test/gestures/double_tap_test.dart

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DoubleTapRecognizer tap;
  var doubleTapRecognized = false;

  setUp(() {
    tap = DoubleTapRecognizer();
    addTearDown(tap.dispose);

    doubleTapRecognized = false;
    tap.onDoubleTap = () {
      expect(doubleTapRecognized, isFalse);
      doubleTapRecognized = true;
    };
  });

  tearDown(() {
    tap.dispose();
  });

  // Down/up pair 1: normal tap sequence
  const down1 = PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));

  const up1 = PointerUpEvent(pointer: 1, position: Offset(11.0, 9.0));

  // Down/up pair 2: normal tap sequence close to pair 1
  const down2 = PointerDownEvent(pointer: 2, position: Offset(12.0, 12.0));

  const up2 = PointerUpEvent(pointer: 2, position: Offset(13.0, 11.0));

  // Down/up pair 3: normal tap sequence far away from pair 1
  const down3 = PointerDownEvent(pointer: 3, position: Offset(130.0, 130.0));

  const up3 = PointerUpEvent(pointer: 3, position: Offset(131.0, 129.0));

  // Down/move/up sequence 4: intervening motion
  const down4 = PointerDownEvent(pointer: 4, position: Offset(10.0, 10.0));

  const move4 = PointerMoveEvent(pointer: 4, position: Offset(25.0, 25.0));

  const up4 = PointerUpEvent(pointer: 4, position: Offset(25.0, 25.0));

  // Down/up pair 5: normal tap sequence identical to pair 1
  const down5 = PointerDownEvent(pointer: 5, position: Offset(10.0, 10.0));

  const up5 = PointerUpEvent(pointer: 5, position: Offset(11.0, 9.0));

  // Down/up pair 6: normal tap sequence close to pair 1 but on secondary button
  const down6 = PointerDownEvent(
    pointer: 6,
    position: Offset(10.0, 10.0),
    buttons: kSecondaryMouseButton,
  );

  const up6 = PointerUpEvent(pointer: 6, position: Offset(11.0, 9.0));

  testGesture('Should recognize double tap', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tester.async.elapse(const Duration(milliseconds: 100));
    tap.addPointer(down2);
    tester.route(down2);
    expect(doubleTapRecognized, isFalse);

    tester.route(up2);
    expect(doubleTapRecognized, isTrue);
  });

  testGesture('Should recognize double tap with secondaryButton', (GestureTester tester) {
    final tapSecondary = DoubleTapRecognizer(
      allowedButtonsFilter: (int buttons) => buttons == kSecondaryButton,
    );
    addTearDown(tapSecondary.dispose);
    tapSecondary.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    // Down/up pair 7: normal tap sequence close to pair 6
    const down7 = PointerDownEvent(
      pointer: 7,
      position: Offset(10.0, 10.0),
      buttons: kSecondaryMouseButton,
    );

    const up7 = PointerUpEvent(pointer: 7, position: Offset(11.0, 9.0));

    tapSecondary.addPointer(down6);
    tester.route(down6);
    tester.route(up6);

    tester.async.elapse(const Duration(milliseconds: 100));
    tapSecondary.addPointer(down7);
    tester.route(down7);
    expect(doubleTapRecognized, isFalse);

    tester.route(up7);
    expect(doubleTapRecognized, isTrue);
  });

  testGesture('Inter-tap distance cancels double tap', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tap.addPointer(down3);
    tester.route(down3);
    tester.route(up3);

    expect(doubleTapRecognized, isFalse);
  });

  testGesture('Intra-tap distance cancels double tap', (GestureTester tester) {
    tap.addPointer(down4);
    tester.route(down4);

    tester.route(move4);
    tester.route(up4);

    tap.addPointer(down1);
    tester.route(down2);
    tester.route(up1);

    expect(doubleTapRecognized, isFalse);
  });

  testGesture('Inter-tap delay cancels double tap', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tester.async.elapse(const Duration(milliseconds: 5000));
    tap.addPointer(down2);
    tester.route(down2);
    tester.route(up2);

    expect(doubleTapRecognized, isFalse);
  });

  testGesture('Inter-tap delay resets double tap, allowing third tap to be a double-tap', (
    GestureTester tester,
  ) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tester.async.elapse(const Duration(milliseconds: 5000));
    tap.addPointer(down2);
    tester.route(down2);
    tester.route(up2);

    tester.async.elapse(const Duration(milliseconds: 100));
    tap.addPointer(down5);
    tester.route(down5);
    expect(doubleTapRecognized, isFalse);

    tester.route(up5);
    expect(doubleTapRecognized, isTrue);
  });

  testGesture('Intra-tap delay does not cancel double tap', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.async.elapse(const Duration(milliseconds: 1000));
    tester.route(up1);

    tap.addPointer(down2);
    tester.route(down2);
    expect(doubleTapRecognized, isFalse);

    tester.route(up2);
    expect(doubleTapRecognized, isTrue);
  });

  testGesture('Should not recognize two overlapping taps', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);

    tap.addPointer(down2);
    tester.route(down1);

    tester.route(up1);

    tester.route(up2);

    expect(doubleTapRecognized, isFalse);
  });

  testGesture('Should recognize one tap of group followed by second tap', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);

    tap.addPointer(down2);
    tester.route(down1);

    tester.route(up1);

    tester.route(up2);

    tester.async.elapse(const Duration(milliseconds: 100));
    tap.addPointer(down1);
    tester.route(down1);
    expect(doubleTapRecognized, isFalse);

    tester.route(up1);
    expect(doubleTapRecognized, isTrue);
  });

  testGesture('Should not recognize two over-rapid taps', (GestureTester tester) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tester.async.elapse(const Duration(milliseconds: 10));
    tap.addPointer(down2);
    tester.route(down2);
    tester.route(up2);

    expect(doubleTapRecognized, isFalse);
  });

  testGesture('Over-rapid taps resets double tap, allowing third tap to be a double-tap', (
    GestureTester tester,
  ) {
    tap.addPointer(down1);
    tester.route(down1);
    tester.route(up1);

    tester.async.elapse(const Duration(milliseconds: 10));
    tap.addPointer(down2);
    tester.route(down2);
    tester.route(up2);

    tester.async.elapse(const Duration(milliseconds: 100));
    tap.addPointer(down5);
    tester.route(down5);
    expect(doubleTapRecognized, isFalse);

    tester.route(up5);
    expect(doubleTapRecognized, isTrue);
  });

  group('Enforce consistent-button restriction:', () {
    testGesture('Button change should interrupt existing sequence', (GestureTester tester) {
      // Down1 -> down6 (different button from 1) -> down2 (same button as 1)
      // Down1 and down2 could've been a double tap, but is interrupted by down 6.

      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      tap.addPointer(down1);
      tester.route(down1);
      tester.route(up1);

      tester.async.elapse(interval);

      tap.addPointer(down6);
      tester.route(down6);
      tester.route(up6);

      tester.async.elapse(interval);
      expect(doubleTapRecognized, isFalse);

      tap.addPointer(down2);
      tester.route(down2);
      tester.route(up2);

      expect(doubleTapRecognized, isFalse);
    });

    testGesture('Button change with allowedButtonsFilter should interrupt existing sequence', (
      GestureTester tester,
    ) {
      final tapPrimary = DoubleTapRecognizer(
        allowedButtonsFilter: (int buttons) => buttons == kPrimaryButton,
      );
      addTearDown(tapPrimary.dispose);
      tapPrimary.onDoubleTap = () {
        doubleTapRecognized = true;
      };

      // Down1 -> down6 (different button from 1) -> down2 (same button as 1)
      // Down1 and down2 could've been a double tap, but is interrupted by down 6.
      // Down6 gets ignored because it's not a primary button. Regardless, the state
      // is reset.
      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      tapPrimary.addPointer(down1);
      tester.route(down1);
      tester.route(up1);

      tester.async.elapse(interval);

      tapPrimary.addPointer(down6);
      tester.route(down6);
      tester.route(up6);

      tester.async.elapse(interval);
      expect(doubleTapRecognized, isFalse);

      tapPrimary.addPointer(down2);
      tester.route(down2);
      tester.route(up2);

      expect(doubleTapRecognized, isFalse);
    });

    testGesture('Button change should start a valid sequence', (GestureTester tester) {
      // Down6 -> down1 (different button from 6) -> down2 (same button as 1)

      const interval = Duration(milliseconds: 100);
      assert(interval * 2 < kDoubleTapTimeout);
      assert(interval > kDoubleTapMinTime);

      tap.addPointer(down6);
      tester.route(down6);
      tester.route(up6);

      tester.async.elapse(interval);

      tap.addPointer(down1);
      tester.route(down1);
      tester.route(up1);

      expect(doubleTapRecognized, isFalse);
      tester.async.elapse(interval);

      tap.addPointer(down2);
      tester.route(down2);
      tester.route(up2);

      expect(doubleTapRecognized, isTrue);
    });
  });

  group('Recognizers do not form competition:', () {
    // This test is assisted by tap recognizers. If a tap gesture has
    // an accompanying double-tap recognizer, a pointer down/up event sequence
    // triggers its onTap immediately; without a timeout.
    // The following tests make sure that double tap recognizers do not form
    // competition with a tap gesture recognizer, either listening on the same
    // or a different button.

    final recognized = <String>[];
    late TapGestureRecognizer tapPrimary;
    late TapGestureRecognizer tapSecondary;
    late DoubleTapRecognizer doubleTap;
    setUp(() {
      tapPrimary = TapGestureRecognizer()
        ..onTap = () {
          recognized.add('tapPrimary');
        };
      addTearDown(tapPrimary.dispose);
      tapSecondary = TapGestureRecognizer()
        ..onSecondaryTap = () {
          recognized.add('tapSecondary');
        };
      addTearDown(tapSecondary.dispose);
      doubleTap = DoubleTapRecognizer()
        ..onDoubleTap = () {
          recognized.add('doubleTap');
        };
      addTearDown(doubleTap.dispose);
    });

    tearDown(() {
      recognized.clear();
      tapPrimary.dispose();
      tapSecondary.dispose();
      doubleTap.dispose();
    });

    testGesture(
      'A primary double tap recognizer does not form competition with a secondary tap recognizer',
      (GestureTester tester) {
        doubleTap.addPointer(down6);
        tapSecondary.addPointer(down6);
        tester.closeArena(down6.pointer);

        tester.route(down6);
        tester.route(up6);
        expect(recognized, <String>['tapSecondary']);
      },
    );

    testGesture('A primary double tap recognizer does not form competition with a primary tap recognizer', (
      GestureTester tester,
    ) {
      doubleTap.addPointer(down1);
      tapPrimary.addPointer(down1);
      tester.closeArena(down1.pointer);

      tester.route(down1);
      tester.route(up1);
      expect(recognized, <String>['tapPrimary']);
    });
  });

  testGesture('A secondary double tap should not trigger primary', (GestureTester tester) {
    final recognized = <String>[];
    final doubleTap = DoubleTapRecognizer()
      ..onDoubleTap = () {
        recognized.add('primary');
      };
    addTearDown(doubleTap.dispose);

    // Down/up pair 7: normal tap sequence close to pair 6
    const down7 = PointerDownEvent(
      pointer: 7,
      position: Offset(10.0, 10.0),
      buttons: kSecondaryMouseButton,
    );

    const up7 = PointerUpEvent(pointer: 7, position: Offset(11.0, 9.0));

    doubleTap.addPointer(down6);
    tester.route(down6);
    tester.route(up6);

    tester.async.elapse(const Duration(milliseconds: 100));
    doubleTap.addPointer(down7);
    tester.route(down7);
    tester.route(up7);
    expect(recognized, <String>[]);

    recognized.clear();
    doubleTap.dispose();
  });

  testGesture('Buttons filter should cancel invalid taps', (GestureTester tester) {
    final recognized = <String>[];
    final doubleTap = DoubleTapRecognizer(allowedButtonsFilter: (int buttons) => false)
      ..onDoubleTap = () {
        recognized.add('primary');
      };
    addTearDown(doubleTap.dispose);

    // Down/up pair 7: normal tap sequence close to pair 6
    const down7 = PointerDownEvent(pointer: 7, position: Offset(10.0, 10.0));

    const up7 = PointerUpEvent(pointer: 7, position: Offset(11.0, 9.0));

    doubleTap.addPointer(down7);
    tester.route(down7);
    tester.route(up7);

    tester.async.elapse(const Duration(milliseconds: 100));
    doubleTap.addPointer(down6);
    tester.route(down6);
    tester.route(up6);

    expect(recognized, <String>[]);

    recognized.clear();
    doubleTap.dispose();
  });
}
