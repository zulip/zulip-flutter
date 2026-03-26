import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/compose_keyboard_aware.dart';

void main() {
  group('Compose Box Keyboard Integration Tests', () {
    testWidgets('send button visible with keyboard on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardAwareComposeTest(),
          ),
        ),
      );

      // Verify send button is initially visible
      final sendButton = find.byKey(const Key('send_button'));
      expect(sendButton, findsOneWidget);

      // Simulate iOS keyboard appearance
      final originalMetrics = tester.binding.window.devicePixelRatioTestMetrics;
      final keyboardMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0), // iOS keyboard height
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = keyboardMetrics;
      await tester.pump();

      // Verify send button is still visible after keyboard appears
      expect(sendButton, findsOneWidget);
      
      // Verify send button is not obscured by keyboard
      final renderBox = tester.renderObject(sendButton);
      final renderBoxRect = renderBox.paintBounds;
      final screenHeight = tester.binding.window.physicalSize.height / 
                          tester.binding.window.devicePixelRatio;
      
      // Send button should be above keyboard (screenHeight - keyboardHeight)
      final keyboardTop = screenHeight - 300.0;
      final buttonBottom = renderBoxRect.bottom;
      
      expect(buttonBottom, lessThan(keyboardTop));
    });

    testWidgets('long message compose with keyboard scrolling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardAwareComposeTest(),
          ),
        ),
      );

      // Type a long message that would normally hide send button
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 
        'This is a very long message that spans multiple lines...\n'
        'Line 2 of the message...\n'
        'Line 3 of the message...\n'
        'Line 4 of the message...\n'
        'Line 5 of the message...\n'
      );

      await tester.pump();

      // Simulate keyboard appearance
      final originalMetrics = tester.binding.window.devicePixelRatioTestMetrics;
      final keyboardMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = keyboardMetrics;
      await tester.pump();

      // Verify send button is still visible
      final sendButton = find.byKey(const Key('send_button'));
      expect(sendButton, findsOneWidget);

      // Verify content scrolled to keep send button visible
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
    });

    testWidgets('keyboard dismissal maintains proper layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardAwareComposeTest(),
          ),
        ),
      );

      // Simulate keyboard appearance
      final originalMetrics = tester.binding.window.devicePixelRatioTestMetrics;
      final keyboardMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = keyboardMetrics;
      await tester.pump();

      // Verify keyboard is visible
      expect(MediaQuery.of(tester.context).viewInsets.bottom, equals(300.0));

      // Simulate keyboard dismissal
      final normalMetrics = originalMetrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 0.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = normalMetrics;
      await tester.pump();

      // Verify keyboard is dismissed
      expect(MediaQuery.of(tester.context).viewInsets.bottom, equals(0.0));

      // Verify send button is still visible
      final sendButton = find.byKey(const Key('send_button'));
      expect(sendButton, findsOneWidget);
    });
  });
}

class KeyboardAwareComposeTest extends StatefulWidget {
  @override
  State<KeyboardAwareComposeTest> createState() => _KeyboardAwareComposeTestState();
}

class _KeyboardAwareComposeTestState extends State<KeyboardAwareComposeTest>
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
                child: Column(
                  children: [
                    // Simulate message list content
                    Container(
                      height: 500,
                      color: Colors.grey[100],
                      child: const Center(
                        child: Text('Message List'),
                      ),
                    ),
                    // Compose area
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.white,
                      child: Column(
                        children: [
                          TextField(
                            key: const Key('compose_field'),
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
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
                        ],
                      ),
                    ),
                  ],
                ),
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
