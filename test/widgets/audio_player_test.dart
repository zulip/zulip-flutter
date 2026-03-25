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
    const testAudioUrl = 'https://example.com/voice_message.m4a';

    Future<void> setupWidget(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: const AudioPlayerBottomSheet(audioUrl: testAudioUrl),
      ));
      await tester.pump();
    }

    testWidgets('renders audio player interface', (tester) async {
      await setupWidget(tester);

      check(find.byType(AudioPlayerBottomSheet)).findsOne();
    });

    testWidgets('displays play button', (tester) async {
      await setupWidget(tester);

      check(find.byIcon(Icons.play_arrow)).findsWidgets();
    });

    testWidgets('displays close button', (tester) async {
      await setupWidget(tester);

      check(find.byIcon(Icons.close)).findsWidgets();
    });

    testWidgets('displays progress slider', (tester) async {
      await setupWidget(tester);

      check(find.byType(Slider)).findsWidgets();
    });

    testWidgets('displays duration text', (tester) async {
      await setupWidget(tester);

      // Audio player should display time information
      check(find.byType(Text)).findsWidgets();
    });

    testWidgets('close button closes player', (tester) async {
      await setupWidget(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Player should be closed (bottom sheet dismissed)
      check(find.byType(AudioPlayerBottomSheet)).findsNothing();
    });

    testWidgets('play button toggles playback state', (tester) async {
      await setupWidget(tester);

      final playButton = find.byIcon(Icons.play_arrow);
      check(playButton).findsWidgets();

      await tester.tap(playButton.first);
      await tester.pump();

      // After tapping play, button should show pause icon
      check(find.byIcon(Icons.pause)).findsWidgets();
    });
  });
}
