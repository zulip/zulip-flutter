import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/audio_player.dart';

import '../example_data.dart' as eg;
import '../test_navigation.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('AudioPlayerBottomSheet', () {
    late PerAccountStore store;
    final testAudioParams = (src: Uri.parse('https://example.com/voice_message.m4a'), title: 'Test Audio');

    Future<void> setupWidget(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: AudioPlayerBottomSheet(
          src: testAudioParams.src,
          title: testAudioParams.title,
        ),
      ));
      await tester.pump();
    }

    testWidgets('renders audio player interface', (tester) async {
      await setupWidget(tester);
      expect(find.byType(AudioPlayerBottomSheet), findsOneWidget);
    });

    testWidgets('displays play button', (tester) async {
      await setupWidget(tester);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('displays close button', (tester) async {
      await setupWidget(tester);
      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('displays progress slider', (tester) async {
      await setupWidget(tester);
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('displays duration text', (tester) async {
      await setupWidget(tester);
      // Audio player should display time information
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('close button closes player', (tester) async {
      await setupWidget(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Player should be closed (bottom sheet dismissed)
      expect(find.byType(AudioPlayerBottomSheet), findsNothing);
    });

    testWidgets('play button toggles playback state', (tester) async {
      await setupWidget(tester);

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsWidgets);

      await tester.tap(playButton.first);
      await tester.pump();

      // After tapping play, button should show pause icon
      expect(find.byIcon(Icons.pause), findsWidgets);
    });
  });
}
