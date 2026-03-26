import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/compose_keyboard_padding_fix.dart';

void main() {
  group('Keyboard Padding Fix Tests', () {
    testWidgets('adds bottom padding when keyboard is visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardPaddingFix(
              additionalPadding: 20.0,
              child: Container(
                key: const Key('test_content'),
                height: 100,
                color: Colors.blue,
                child: const Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Verify no padding initially
      expect(MediaQuery.of(tester.context).viewInsets.bottom, equals(0.0));

      // Simulate keyboard appearing
      final originalMetrics = tester.binding.window.devicePixelRatioTestMetrics;
      final keyboardMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = keyboardMetrics;
      await tester.pump();

      // Verify keyboard metrics are detected
      expect(MediaQuery.of(tester.context).viewInsets.bottom, equals(300.0));

      // Verify padding is applied (keyboard height + additional padding)
      final renderBox = tester.renderObject(find.byKey(const Key('test_content')));
      final padding = renderBox.parent as RenderPadding;
      final bottomPadding = padding.padding.bottom;
      
      expect(bottomPadding, equals(320.0)); // 300 + 20
    });

    testWidgets('no padding when keyboard is hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardPaddingFix(
              additionalPadding: 16.0,
              child: Container(
                key: const Key('test_content'),
                height: 100,
                color: Colors.green,
                child: const Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Verify no padding when keyboard is hidden
      final renderBox = tester.renderObject(find.byKey(const Key('test_content')));
      final padding = renderBox.parent as RenderPadding;
      final bottomPadding = padding.padding.bottom;
      
      expect(bottomPadding, equals(16.0)); // Only additional padding
    });

    testWidgets('extension method works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: const Key('test_content'),
              height: 100,
              color: Colors.red,
              child: const Text('Test Content'),
            ).withKeyboardPadding(additionalPadding: 24.0),
          ),
        ),
      );

      // Verify the widget is wrapped with padding
      expect(find.byType(KeyboardPaddingFix), findsOneWidget);
      expect(find.byKey(const Key('test_content')), findsOneWidget);
    });

    testWidgets('send button stays above keyboard with padding fix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Container(
                    height: 500,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Content Area'),
                    ),
                  ),
                ),
                // Send button with keyboard padding fix
                ElevatedButton(
                  key: const Key('send_button'),
                  onPressed: () {},
                  child: const Text('Send'),
                ).withKeyboardPadding(additionalPadding: 16.0),
              ],
            ),
          ),
        ),
      );

      // Simulate keyboard appearing
      final originalMetrics = tester.binding.window.devicePixelRatioTestMetrics;
      final keyboardMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = keyboardMetrics;
      await tester.pump();

      // Verify send button is still visible
      expect(find.byKey(const Key('send_button')), findsOneWidget);

      // Get send button position
      final sendButton = find.byKey(const Key('send_button'));
      final renderBox = tester.renderObject(sendButton) as RenderBox;
      final buttonPosition = renderBox.localToGlobal(Offset.zero);

      // Get screen height
      final screenHeight = tester.binding.window.physicalSize.height / 
                          tester.binding.window.devicePixelRatio;

      // Verify button is above keyboard (screenHeight - keyboardHeight - padding)
      final keyboardTop = screenHeight - 300.0 - 16.0; // keyboard height + padding
      final buttonBottom = buttonPosition.dy + renderBox.size.height;

      expect(buttonBottom, lessThan(keyboardTop));
    });
  });
}

class FakeViewPadding extends ViewPadding {
  const FakeViewPadding({required double bottom}) : super(bottom: bottom);
  
  factory FakeViewPadding.fromWindowPadding(WindowPadding padding) {
    return FakeViewPadding(bottom: padding.bottom);
  }
}
