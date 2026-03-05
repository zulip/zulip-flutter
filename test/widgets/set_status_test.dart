import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/set_status.dart';
import 'package:zulip/widgets/user.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../example_data.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';

import 'checks.dart';
import 'finders.dart';
import 'test_app.dart';

void main() {
  late PerAccountStore store;

  TestZulipBinding.ensureInitialized();

  final ServerEmojiData suggestedEmojiData = ServerEmojiData(codeToNames: {
    '1f6e0': ['working_on_it'],
    '1f4c5': ['calendar'],
    '1f68c': ['bus'],
    '1f912': ['sick'],
    '1f334': ['palm_tree'],
    '1f3e0': ['house'],
    '1f3e2': ['office'],
  });

  Future<void> setupPage(WidgetTester tester, {
    UserStatusChange? change,
    ServerEmojiData? emojiData,
    NavigatorObserver? navigatorObserver,
  }) async {
    addTearDown(testBinding.reset);

    Route<dynamic>? currentRoute;
    final testNavObserver = TestNavigatorObserver()
      ..onPushed = (route, _) => currentRoute = route;

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUser(eg.selfUser);
    if (change != null) {
      await store.changeUserStatus(eg.selfUser.userId, change);
    }
    if (emojiData != null) {
      store.setServerEmojiData(emojiData);
    }

    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      navigatorObservers: [testNavObserver, ?navigatorObserver],
      child: ProfilePage(userId: eg.selfUser.userId)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ZulipMenuItemButton,
      switch (change) {
        null || UserStatusChange(text: OptionNone(), emoji: OptionNone())
          => 'Set status',
        _ => 'Status',
      }));
    await tester.pump();
    await testNavObserver.pumpPastTransition(tester);
    check(currentRoute).isA<MaterialAccountWidgetRoute>().page.isA<SetStatusPage>();
  }

  final clearButtonFinder = find.widgetWithText(TextButton, 'Clear');
  final saveButtonFinder = find.widgetWithText(TextButton, 'Save');

  void checkButtonsEnabled(WidgetTester tester,
      {required bool expectClear, required bool expectSave}) {
    final clearButton = tester.widget<TextButton>(clearButtonFinder);
    final saveButton = tester.widget<TextButton>(saveButtonFinder);

    expectClear
      ? check(clearButton.onPressed).isNotNull()
      : check(clearButton.onPressed).isNull();
    expectSave
      ? check(saveButton.onPressed).isNotNull()
      : check(saveButton.onPressed).isNull();
  }

  Finder findEmojiButton({bool emojiSelected = false}) {
    return find.ancestor(of: emojiSelected
        ? find.byType(UserStatusEmoji) : find.byIcon(ZulipIcons.smile),
      matching: find.ancestor(of: find.byIcon(ZulipIcons.chevron_down),
        matching: find.byType(IconButton)));
  }

  Finder findStatusTextField() {
    return find.byWidgetPredicate((widget) => switch(widget) {
      TextField(decoration: InputDecoration(hintText: 'Your status')) => true,
      _                                                               => false
    });
  }

  Finder findSuggestion({required String code, required String text}) {
    final emojiFinder = find.ancestor(
      of: find.text(tryParseEmojiCodeToUnicode(code)!),
      matching: find.byType(UserStatusEmoji));
    return find.ancestor(of: emojiFinder,
      matching: find.ancestor(of: find.text(text),
        matching: find.byType(StatusSuggestionsListEntry)));
  }

  testWidgets('set status page renders', (tester) async {
    await setupPage(tester, emojiData: suggestedEmojiData);

    check(find.text('Set status')).findsOne();
    check(clearButtonFinder).findsOne();
    check(saveButtonFinder).findsOne();
    check(findEmojiButton()).findsOne();
    check(findStatusTextField()).findsOne();

    check(findSuggestion(code: '1f6e0', text: 'Busy')).findsOne();
    check(findSuggestion(code: '1f4c5', text: 'In a meeting')).findsOne();
    check(findSuggestion(code: '1f68c', text: 'Commuting')).findsOne();
    check(findSuggestion(code: '1f3e0', text: 'Working remotely')).findsOne();
  });

  group('"Clear" & "Save" buttons', () {
    group('initial state', () {
      testWidgets('no status set -> buttons are disabled', (tester) async {
        await setupPage(tester);
        checkButtonsEnabled(tester, expectClear: false, expectSave: false);
      });

      testWidgets('text & emoji are set -> "Clear" is enabled, "Save" is not', (tester) async {
        await setupPage(tester, change: UserStatusChange(
          text: OptionSome('Happy'),
          emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
            emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
        checkButtonsEnabled(tester, expectClear: true, expectSave: false);
      });

      testWidgets('only text is set -> "Clear" is enabled, "Save" is not', (tester) async {
        await setupPage(tester, change: UserStatusChange(
          text: OptionSome('Happy'), emoji: OptionNone()));
        checkButtonsEnabled(tester, expectClear: true, expectSave: false);
      });

      testWidgets('only emoji is set -> "Clear" is enabled, "Save" is not', (tester) async {
        await setupPage(tester, change: UserStatusChange(
          text: OptionNone(),
          emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
            emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
        checkButtonsEnabled(tester, expectClear: true, expectSave: false);
      });
    });

    group('edit status', () {
      Future<void> chooseUnicodeEmojiFromPicker(WidgetTester tester, String code, {
        bool emojiSelected = false,
        required TestNavigatorObserver navObserver,
        required ValueGetter<Route<dynamic>> currentRoute,
      }) async {
        await tester.tap(findEmojiButton(emojiSelected: emojiSelected));
        check(currentRoute()).isA<ModalBottomSheetRoute<EmojiCandidate>>();
        await navObserver.pumpPastTransition(tester);
        // We use `find.descendant` to not match for an emoji in status
        // suggestions in the underlying page.
        await tester.tap(find.descendant(of: find.byType(EmojiPicker),
          matching: find.text(tryParseEmojiCodeToUnicode(code)!)));
        await tester.pump();
        await navObserver.pumpPastTransition(tester);
        check(currentRoute()).isA<MaterialAccountWidgetRoute>()
          .page.isA<SetStatusPage>();
      }

      group('no status set, buttons are disabled', () {
        testWidgets('emoji is added -> buttons are enabled', (tester) async {
          prepareBoringImageHttpClient();

          Route<dynamic>? currentRoute;
          final testNavObserver = TestNavigatorObserver();
          testNavObserver.onPushed = (route, _) => currentRoute = route;
          testNavObserver.onPopped = (_, previous) => currentRoute = previous;

          await setupPage(tester,
            emojiData: serverEmojiDataPopular,
            navigatorObserver: testNavObserver);
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);

          // Choose 'slight_smile' from popular emojis.
          await chooseUnicodeEmojiFromPicker(tester, '1f642',
            navObserver: testNavObserver, currentRoute: () => currentRoute!);
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);

          debugNetworkImageHttpClientProvider = null;
        });

        testWidgets('text is added -> buttons are enabled', (tester) async {
          await setupPage(tester);
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);

          await tester.enterText(findStatusTextField(), 'Happy');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);
        });

        testWidgets('empty spaces are added as text -> buttons stays disabled', (tester) async {
          await setupPage(tester);
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);

          await tester.enterText(findStatusTextField(), '   ');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);
        });

        testWidgets('a suggestion is selected -> buttons are enabled', (tester) async {
          await setupPage(tester, emojiData: suggestedEmojiData);
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);

          await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);
        });

        testWidgets('a suggestion is selected, then removed -> buttons are enabled, then disabled', (tester) async {
          await setupPage(tester, emojiData: suggestedEmojiData);
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);

          await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);

          await tester.tap(clearButtonFinder);
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: false, expectSave: false);
        });
      });

      group('status set, "Clear" is enabled, "Save" is not', () {
        testWidgets('emoji is changed -> buttons are enabled', (tester) async {
          prepareBoringImageHttpClient();

          Route<dynamic>? currentRoute;
          final testNavObserver = TestNavigatorObserver();
          testNavObserver.onPushed = (route, _) => currentRoute = route;
          testNavObserver.onPopped = (_, previous) => currentRoute = previous;

          await setupPage(tester,
            emojiData: ServerEmojiData(codeToNames: {
              ...serverEmojiDataPopular.codeToNames,
              ...suggestedEmojiData.codeToNames,
            }),
            navigatorObserver: testNavObserver,
            change: UserStatusChange(
              text: OptionSome('Happy'),
              emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
                emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          // Choose 'calender' included in suggested emojis.
          await chooseUnicodeEmojiFromPicker(tester, '1f4c5',
            emojiSelected: true,
            navObserver: testNavObserver, currentRoute: () => currentRoute!);
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);

          debugNetworkImageHttpClientProvider = null;
        });

        testWidgets('text is changed -> buttons are enabled', (tester) async {
          await setupPage(tester, change: UserStatusChange(
            text: OptionSome('Happy'),
            emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
              emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          await tester.enterText(findStatusTextField(), 'Happy as a calm');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);
        });

        testWidgets('empty spaces are added around the text -> buttons stays the same', (tester) async {
          await setupPage(tester, change: UserStatusChange(
            text: OptionSome('Happy'),
            emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
              emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          await tester.enterText(findStatusTextField(), ' Happy  ');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);
        });

        testWidgets('a suggestion is selected -> buttons are enabled', (tester) async {
          await setupPage(tester,
            emojiData: suggestedEmojiData,
            change: UserStatusChange(
              text: OptionSome('Happy'),
              emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
                emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);
        });

        testWidgets('emoji & text are changed, then reset -> buttons are enabled, then "Clear" is enabled, "Save" is not', (tester) async {
          prepareBoringImageHttpClient();

          Route<dynamic>? currentRoute;
          final testNavObserver = TestNavigatorObserver();
          testNavObserver.onPushed = (route, _) => currentRoute = route;
          testNavObserver.onPopped = (_, previous) => currentRoute = previous;

          await setupPage(tester,
            emojiData: ServerEmojiData(codeToNames: {
              ...serverEmojiDataPopular.codeToNames,
              ...suggestedEmojiData.codeToNames,
            }),
            navigatorObserver: testNavObserver,
            change: UserStatusChange(
              text: OptionSome('Happy'),
              emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
                emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          // Choose 'calender' included in suggested emojis.
          await chooseUnicodeEmojiFromPicker(tester, '1f4c5',
            emojiSelected: true,
            navObserver: testNavObserver, currentRoute: () => currentRoute!);
          await tester.enterText(findStatusTextField(), 'Happy as a calm');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);

          // Reset to the initial emoji.
          await chooseUnicodeEmojiFromPicker(tester, '1f642',
            emojiSelected: true,
            navObserver: testNavObserver, currentRoute: () => currentRoute!);
          // Reset to the initial text.
          await tester.enterText(findStatusTextField(), 'Happy');
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          debugNetworkImageHttpClientProvider = null;
        });

        testWidgets('a new suggestion is selected, then reset -> buttons are enabled, then "Clear" is enabled, "Save" is not', (tester) async {
          await setupPage(tester,
            emojiData: suggestedEmojiData,
            // One of the emoji suggestions.
            change: UserStatusChange(
              text: OptionSome('Working remotely'),
              emoji: OptionSome(StatusEmoji(emojiName: 'house',
                emojiCode: '1f3e0', reactionType: ReactionType.unicodeEmoji))));
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);

          await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: true);

          // Reset the suggestion.
          await tester.tap(findSuggestion(code: '1f3e0', text: 'Working remotely'));
          await tester.pump();
          checkButtonsEnabled(tester, expectClear: true, expectSave: false);
        });
      });
    });

    testWidgets('"Clear" button removes both emoji and text', (tester) async {
      await setupPage(tester, change: UserStatusChange(
        text: OptionSome('Happy'),
        emoji: OptionSome(StatusEmoji(emojiName: 'slight_smile',
          emojiCode: '1f642', reactionType: ReactionType.unicodeEmoji))));

      check(findEmojiButton(emojiSelected: true)).findsOne();
      check(tester.widget<TextField>(findStatusTextField()).controller!.text)
        .equals('Happy');

      await tester.tap(clearButtonFinder);
      await tester.pump();

      check(findEmojiButton(emojiSelected: false)).findsOne();
      check(tester.widget<TextField>(findStatusTextField()).controller!.text)
        .equals('');
    });

    group('"Save" button returns to Profile page, saves the status', () {
      testWidgets('successful -> status info appears', (tester) async {
        final testNavObserver = TestNavigatorObserver();

        await setupPage(tester,
          emojiData: suggestedEmojiData, navigatorObserver: testNavObserver);

        await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
        await tester.pump();

        final connection = store.connection as FakeApiConnection;
        connection.prepare(json: {}, delay: Duration(milliseconds: 100));

        await tester.tap(saveButtonFinder);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/status')
          ..bodyFields['status_text'].equals('Busy')
          ..bodyFields['emoji_name'].equals('working_on_it')
          ..bodyFields['emoji_code'].equals('1f6e0')
          ..bodyFields['reaction_type'].equals('unicode_emoji')
          ..bodyFields.containsKey('scheduled_end_time');
        await testNavObserver.pumpPastTransition(tester);
        check(find.byType(ProfilePage)).findsOne();
      });

      testWidgets("error -> status info doesn't appears", (tester) async {
        final testNavObserver = TestNavigatorObserver();

        await setupPage(tester,
          emojiData: suggestedEmojiData, navigatorObserver: testNavObserver);

        await tester.tap(findSuggestion(code: '1f6e0', text: 'Busy'));
        await tester.pump();

        final connection = store.connection as FakeApiConnection;
        connection.prepare(httpException: SocketException('failed'));

        await tester.tap(saveButtonFinder);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/status')
          ..bodyFields['status_text'].equals('Busy')
          ..bodyFields['emoji_name'].equals('working_on_it')
          ..bodyFields['emoji_code'].equals('1f6e0')
          ..bodyFields['reaction_type'].equals('unicode_emoji')
          ..bodyFields.containsKey('scheduled_end_time');
        await testNavObserver.pumpPastTransition(tester);
        check(find.byType(ProfilePage)).findsOne();

        check(find.text('\u{1f6e0}')).findsNothing();
        check(findText('Busy', includePlaceholders: false)).findsNothing();
      });
    });
  });

  testWidgets('Status text field has a 60-char limit', (tester) async {
    await setupPage(tester);
    check(tester.widget<TextField>(findStatusTextField()).maxLength).equals(60);
  });
}
