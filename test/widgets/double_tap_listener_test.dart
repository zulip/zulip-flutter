import 'package:checks/checks.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/double_tap_listener.dart';

void main() {
  late bool doubleTapped;
  late bool parentTapped;
  late bool childTapped;

  setUp(() {
    doubleTapped = parentTapped = childTapped = false;
  });

  void checkDoubleTapped() {
    check(doubleTapped).isTrue();
    doubleTapped = false;
  }
  void checkNotDoubleTapped() => check(doubleTapped).isFalse();

  void checkParentTapped() {
    check(parentTapped).isTrue();
    parentTapped = false;
  }

  void checkChildTapped() {
    check(childTapped).isTrue();
    childTapped = false;
  }

  final childKey = UniqueKey();

  Future<void> pumpDoubleTapListener(
    WidgetTester tester, {
    Set<PointerDeviceKind>? supportedDevices,
    bool includeParentTapHandler = false,
    bool includeChildTapHandler = false,
  }) async {
    Widget child = Container(key: childKey, width: 300, height: 300, color: Colors.teal);
    if (includeChildTapHandler) {
      child = GestureDetector(onTap: () => childTapped = true, child: child);
    }

    child = DoubleTapListener(
      supportedDevices: supportedDevices,
      onDoubleTap: () => doubleTapped = true,
      child: child);
    if (includeParentTapHandler) {
      child = GestureDetector(
        onTap: () => parentTapped = true, behavior: .translucent, child: child);
    }

    await tester.pumpWidget(Directionality(textDirection: .ltr, child: child));
  }

  Offset center(WidgetTester tester) => tester.getCenter(find.byKey(childKey));

  testWidgets('Recognizes double tap', (tester) async {
    await pumpDoubleTapListener(tester);

    await tester.tapAt(center(tester));
    await tester.pump(Duration(milliseconds: 100));
    await tester.tapAt(center(tester));

    checkDoubleTapped();
  });

  testWidgets('Does not recognize double tap from unsupported devices', (tester) async {
    await pumpDoubleTapListener(tester, supportedDevices: {.touch});

    await tester.tapAt(center(tester), kind: .stylus);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center(tester), kind: .stylus);

    checkNotDoubleTapped();
  });

  testWidgets('Double tap does not suppress parent tap handler', (tester) async {
    await pumpDoubleTapListener(tester, includeParentTapHandler: true);

    await tester.tapAt(center(tester));
    checkParentTapped();
    checkNotDoubleTapped();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    checkParentTapped();
    checkDoubleTapped();
  });

  testWidgets('Double tap does not suppress child tap handler', (tester) async {
    await pumpDoubleTapListener(tester, includeChildTapHandler: true);

    await tester.tapAt(center(tester));
    checkChildTapped();
    checkNotDoubleTapped();

    await tester.pump(Duration(milliseconds: 100));

    await tester.tapAt(center(tester));
    checkChildTapped();
    checkDoubleTapped();
  });
}
