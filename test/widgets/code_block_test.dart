import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/code_block.dart';

import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('CodeBlockTextStyles', () {
    group('lerp', () {
      Future<BuildContext> contextWithZulipTheme(WidgetTester tester) async {
        addTearDown(testBinding.reset);
        await tester.pumpWidget(const TestZulipApp());
        await tester.pump();
        return tester.element(find.byType(Placeholder));
      }

      testWidgets('light -> light', (tester) async {
        final context = await contextWithZulipTheme(tester);
        final a = CodeBlockTextStyles.light(context);
        final b = CodeBlockTextStyles.light(context);
        check(() => CodeBlockTextStyles.lerp(a, b, 0.5)).returnsNormally();
      });

      testWidgets('light -> dark', (tester) async {
        final context = await contextWithZulipTheme(tester);
        final a = CodeBlockTextStyles.light(context);
        final b = CodeBlockTextStyles.dark(context);
        check(() => CodeBlockTextStyles.lerp(a, b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> light', (tester) async {
        final context = await contextWithZulipTheme(tester);
        final a = CodeBlockTextStyles.dark(context);
        final b = CodeBlockTextStyles.light(context);
        check(() => CodeBlockTextStyles.lerp(a, b, 0.5)).returnsNormally();
      });

      testWidgets('dark -> dark', (tester) async {
        final context = await contextWithZulipTheme(tester);
        final a = CodeBlockTextStyles.dark(context);
        final b = CodeBlockTextStyles.dark(context);
        check(() => CodeBlockTextStyles.lerp(a, b, 0.5)).returnsNormally();
      });
    });
  });
}
