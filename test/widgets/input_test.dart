import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/input.dart';
import 'package:zulip/widgets/theme.dart';

import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ZulipCodePointLengthLimit', () {
    Future<void> prepare(WidgetTester tester, {
      required TextEditingController controller,
      int maxLengthCodePoints = 10,
    }) async {
      addTearDown(testBinding.reset);
      addTearDown(controller.dispose);
      await tester.pumpWidget(TestZulipApp(
        child: Scaffold(
          body: ZulipCodePointLengthLimit(
            controller: controller,
            maxLengthCodePoints: maxLengthCodePoints,
            builder: (context, counter) => TextFormField(
              controller: controller,
              decoration: InputDecoration(counter: counter))))));
      await tester.pump();
    }

    Color counterTextColor(WidgetTester tester, String counterText) {
      return tester.widget<Text>(find.text(counterText)).style!.color!;
    }

    Color? cursorColor(WidgetTester tester) {
      return tester.widget<EditableText>(find.byType(EditableText)).cursorColor;
    }

    testWidgets('smoke: empty controller shows 0/max', (tester) async {
      await prepare(tester, controller: TextEditingController());
      check(find.text('0/10')).findsOne();
    });

    testWidgets('reflects initial text from the controller', (tester) async {
      await prepare(tester, controller: TextEditingController(text: 'abcd'));
      check(find.text('4/10')).findsOne();
    });

    testWidgets('updates on controller text changes', (tester) async {
      final controller = TextEditingController();
      await prepare(tester, controller: controller);
      check(find.text('0/10')).findsOne();

      controller.text = 'hi';
      await tester.pump();
      check(find.text('2/10')).findsOne();

      controller.text = 'hello';
      await tester.pump();
      check(find.text('5/10')).findsOne();
    });

    testWidgets('counts code points, not grapheme clusters', (tester) async {
      // '👍🏽' (thumbs-up with skin-tone modifier) is one grapheme cluster
      // but two Unicode code points.
      await prepare(tester, controller: TextEditingController(text: '👍🏽'));
      check(find.text('2/10')).findsOne();
    });

    testWidgets('counter text color switches when over limit', (tester) async {
      final controller = TextEditingController(text: 'abc');
      await prepare(tester, controller: controller, maxLengthCodePoints: 3);

      final element = tester.element(find.byType(TextFormField));
      final designVariables = DesignVariables.of(element);
      check(counterTextColor(tester, '3/3')).equals(designVariables.textInput);

      controller.text = 'abcd';
      await tester.pump();
      check(counterTextColor(tester, '4/3'))
        .equals(designVariables.contextMenuItemTextDanger);
    });

    testWidgets('cursor color switches when over limit', (tester) async {
      final controller = TextEditingController(text: 'abc');
      await prepare(tester, controller: controller, maxLengthCodePoints: 3);

      final element = tester.element(find.byType(TextFormField));
      final designVariables = DesignVariables.of(element);
      // Not over: cursor should not be danger color.
      check(cursorColor(tester))
        .not((it) => it.equals(designVariables.contextMenuItemTextDanger));

      controller.text = 'abcd';
      await tester.pump();
      check(cursorColor(tester))
        .equals(designVariables.contextMenuItemTextDanger);
    });

    testWidgets('preserves focus across the threshold', (tester) async {
      final controller = TextEditingController(text: 'abc');
      await prepare(tester, controller: controller, maxLengthCodePoints: 3);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      final focusNode = tester.state<EditableTextState>(
        find.byType(EditableText)).widget.focusNode;
      check(focusNode.hasFocus).isTrue();

      controller.text = 'abcd'; // cross to over
      await tester.pump();
      check(focusNode.hasFocus).isTrue();

      controller.text = 'ab'; // cross back to under
      await tester.pump();
      check(focusNode.hasFocus).isTrue();
    });

    testWidgets('exposes currentValueLength and maxValueLength semantics',
    (tester) async {
      final controller = TextEditingController(text: 'abc');
      await prepare(tester, controller: controller, maxLengthCodePoints: 10);

      SemanticsData data() => tester.getSemantics(find.byType(EditableText))
        .getSemanticsData();
      check(data())
        ..currentValueLength.equals(3)
        ..maxValueLength.equals(10);

      controller.text = 'abcdef';
      await tester.pump();
      check(data()).currentValueLength.equals(6);
    });
  });
}

extension on Subject<SemanticsData> {
  Subject<int?> get currentValueLength => has((d) => d.currentValueLength, 'currentValueLength');
  Subject<int?> get maxValueLength => has((d) => d.maxValueLength, 'maxValueLength');
}
