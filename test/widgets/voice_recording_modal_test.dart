import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/voice_recording_modal.dart';

import '../example_data.dart' as eg;
import '../test_navigation.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('VoiceRecordingModal', () {
    late PerAccountStore store;

    Future<void> setupWidget(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: const VoiceRecordingModal(),
      ));
      await tester.pump();
    }

    testWidgets('renders recording interface', (tester) async {
      await setupWidget(tester);

      check(find.byType(VoiceRecordingModal)).findsOne();
      check(find.text('Record Voice Message')).findsWidgets();
    });

    testWidgets('displays record button', (tester) async {
      await setupWidget(tester);

      check(find.byIcon(Icons.mic)).findsWidgets();
    });

    testWidgets('displays cancel button', (tester) async {
      await setupWidget(tester);

      check(find.byIcon(Icons.close)).findsWidgets();
    });

    testWidgets('displays send button', (tester) async {
      await setupWidget(tester);

      check(find.byIcon(Icons.send)).findsWidgets();
    });

    testWidgets('initial state shows idle UI', (tester) async {
      await setupWidget(tester);

      // Should show record button enabled initially
      check(find.byIcon(Icons.mic)).findsWidgets();
    });

    testWidgets('cancel button closes modal', (tester) async {
      await setupWidget(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Modal should be closed (check for pop behavior)
      check(find.byType(VoiceRecordingModal)).findsNothing();
    });
  });
}
