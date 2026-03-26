import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/compose_keyboard_aware.dart';

void main() {
  group('KeyboardAwareComposeMixin Simple Tests', () {
    testWidgets('mixin can be applied to widget state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareWidget(),
          ),
        ),
      );

      // Verify the widget renders without errors
      expect(find.byType(TestKeyboardAwareWidget), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('keyboard metrics change detection works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareWidget(),
          ),
        ),
      );

      // Verify initial state
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

      // Verify send button is still visible
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('send button position remains above keyboard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareWidget(),
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

      // Get send button position
      final sendButton = find.byKey(const Key('send_button'));
      final renderBox = tester.renderObject(sendButton) as RenderBox;
      final buttonPosition = renderBox.localToGlobal(Offset.zero);

      // Get screen height
      final screenHeight = tester.binding.window.physicalSize.height / 
                          tester.binding.window.devicePixelRatio;

      // Verify button is above keyboard (screenHeight - keyboardHeight)
      final keyboardTop = screenHeight - 300.0;
      final buttonBottom = buttonPosition.dy + renderBox.size.height;

      expect(buttonBottom, lessThan(keyboardTop));
    });
  });
}

class TestKeyboardAwareWidget extends StatefulWidget {
  @override
  State<TestKeyboardAwareWidget> createState() => _TestKeyboardAwareWidgetState();
}

class _TestKeyboardAwareWidgetState extends State<TestKeyboardAwareWidget>
    with KeyboardAwareComposeMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    setupKeyboardAwareness(_scrollController);
  }

  @override
  void dispose() {
    disposeKeyboardAwareness();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                ),
                child: Container(
                  height: 1000, // Tall content to enable scrolling
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Test Content'),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            ),
            color: Colors.white,
            child: Center(
              child: ElevatedButton(
                key: const Key('send_button'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text('Send'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FakeViewPadding extends ViewPadding {
  const FakeViewPadding({required double bottom}) : super(bottom: bottom);
  
  factory FakeViewPadding.fromWindowPadding(WindowPadding padding) {
    return FakeViewPadding(bottom: padding.bottom);
  }
}
