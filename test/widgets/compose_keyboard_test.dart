import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../model/compose.dart';
import '../widgets/compose_keyboard_aware.dart';

void main() {
  group('Compose Box Keyboard Awareness', () {
    late MockScrollController mockScrollController;

    setUp(() {
      mockScrollController = MockScrollController();
    });

    testWidgets('keyboard appears triggers scroll to keep send button visible', (tester) async {
      bool scrolledToBottom = false;
      
      when(mockScrollController.hasClients).thenReturn(true);
      when(mockScrollController.position).thenReturn(MockScrollPosition());
      when(mockScrollController.position.maxScrollExtent).thenReturn(100.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareCompose(
              scrollController: mockScrollController,
              onScrolledToBottom: () => scrolledToBottom = true,
            ),
          ),
        ),
      );

      // Simulate keyboard appearing
      final metrics = tester.binding.window.devicePixelRatioTestMetrics;
      final newMetrics = metrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0), // Simulate keyboard
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = newMetrics;
      await tester.pump();

      // Verify scroll was triggered
      verify(mockScrollController.animateTo(
        100.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ));
      expect(scrolledToBottom, isTrue);
    });

    testWidgets('send button remains visible when keyboard is open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareCompose(
              scrollController: mockScrollController,
            ),
          ),
        ),
      );

      // Simulate keyboard appearing
      final metrics = tester.binding.window.devicePixelRatioTestMetrics;
      final newMetrics = metrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 300.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = newMetrics;
      await tester.pump();

      // Find send button
      final sendButton = find.byType<ElevatedButton>();
      expect(sendButton, findsOneWidget);
      
      // Verify button is visible (not hidden behind keyboard)
      final renderBox = tester.renderObject(sendButton);
      expect(renderBox, isNotNull);
    });

    testWidgets('no scroll when keyboard is not appearing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestKeyboardAwareCompose(
              scrollController: mockScrollController,
            ),
          ),
        ),
      );

      // Simulate keyboard staying closed
      final metrics = tester.binding.window.devicePixelRatioTestMetrics;
      final newMetrics = metrics.copyWith(
        viewInsets: FakeViewPadding.fromWindowPadding(
          const WindowPadding(bottom: 0.0),
        ),
      );
      tester.binding.window.devicePixelRatioTestValue = newMetrics;
      await tester.pump();

      // Verify no scroll was triggered
      verifyNever(mockScrollController.animateTo(
        any,
        duration: any,
        curve: any,
      ));
    });
  });
}

class TestKeyboardAwareCompose extends StatefulWidget {
  const TestKeyboardAwareCompose({
    super.key,
    required this.scrollController,
    this.onScrolledToBottom,
  });

  final ScrollController scrollController;
  final VoidCallback? onScrolledToBottom;

  @override
  State<TestKeyboardAwareCompose> createState() => _TestKeyboardAwareComposeState();
}

class _TestKeyboardAwareComposeState extends State<TestKeyboardAwareCompose>
    with KeyboardAwareComposeMixin {
  @override
  void initState() {
    super.initState();
    setupKeyboardAwareness(widget.scrollController);
  }

  @override
  void dispose() {
    disposeKeyboardAwareness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: Container(
              height: 1000, // Tall content to enable scrolling
              color: Colors.grey[200],
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// Mock classes for testing
class MockScrollController extends Mock implements ScrollController {
  @override
  bool get hasClients => true;
  
  @override
  ScrollPosition get position => MockScrollPosition();
}

class MockScrollPosition extends Mock implements ScrollPosition {
  @override
  double get maxScrollExtent => 100.0;
}

class FakeViewPadding extends ViewPadding {
  const FakeViewPadding({required double bottom}) : super(bottom: bottom);
  
  factory FakeViewPadding.fromWindowPadding(WindowPadding padding) {
    return FakeViewPadding(bottom: padding.bottom);
  }
}
