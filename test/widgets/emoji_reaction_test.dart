import 'dart:io' as io;
import 'dart:io';
import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:legacy_checks/legacy_checks.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/emoji_test.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import 'checks.dart';
import 'content_test.dart';
import 'dialog_checks.dart';
import 'test_app.dart';
import 'text_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  MessageListPage.debugEnableMarkReadOnScroll = false;

  late PerAccountStore store;
  late FakeApiConnection connection;
  late TransitionDurationObserver transitionDurationObserver;

  Future<void> prepare() async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    await store.addUser(eg.selfUser);

    // TODO do this more centrally, or put in reusable helper
    final Future<ByteData> font = rootBundle.load('assets/Source_Sans_3/SourceSans3VF-Upright.otf');
    final fontLoader = FontLoader('Source Sans 3')..addFont(font);
    await fontLoader.load();
  }

  // Base JSON for various unicode emoji reactions. Just missing user_id.
  final u1 = {'emoji_name': '+1', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji'};
  final u2 = {'emoji_name': 'family_man_man_girl_boy', 'emoji_code': '1f468-200d-1f468-200d-1f467-200d-1f466', 'reaction_type': 'unicode_emoji'};
  final u3 = {'emoji_name': 'slight_smile', 'emoji_code': '1f642', 'reaction_type': 'unicode_emoji'};
  final u4 = {'emoji_name': 'tada', 'emoji_code': '1f389', 'reaction_type': 'unicode_emoji'};
  final u5 = {'emoji_name': 'exploding_head', 'emoji_code': '1f92f', 'reaction_type': 'unicode_emoji'};

  // Base JSON for various realm-emoji reactions. Just missing user_id.
  final i1 = {'emoji_name': 'twocents', 'emoji_code': '181', 'reaction_type': 'realm_emoji'};
  final i2 = {'emoji_name': 'threecents', 'emoji_code': '182', 'reaction_type': 'realm_emoji'};

  // Base JSON for the one "Zulip extra emoji" reaction. Just missing user_id.
  final z1 = {'emoji_name': 'zulip', 'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji'};

  String nameOf(Map<String, String> jsonEmoji) => jsonEmoji['emoji_name']!;

  Future<void> setupChipsInBox(WidgetTester tester, {
    required List<Reaction> reactions,
    double width = 245.0, // (seen in context on an iPhone 13 Pro)
  }) async {
    final message = eg.streamMessage(reactions: reactions);
    await store.addMessage(message);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    transitionDurationObserver = TransitionDurationObserver();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      navigatorObservers: [transitionDurationObserver],
      child: Center(
        child: ColoredBox(
          color: Colors.white,
          child: SizedBox(
            width: width,
            child: ReactionChipsList(
              messageId: message.id,
              reactions: message.reactions!,
            ))))));
    await tester.pumpAndSettle(); // global store, per-account store

    final reactionChipsList = tester.element(find.byType(ReactionChipsList));
    check(reactionChipsList).size.isNotNull().width.equals(width);
  }

  final findViewReactionsTabBar = find.semantics.byPredicate((node) =>
    node.role == SemanticsRole.tabBar
    && node.label.contains('Emoji reactions'));

  FinderBase<SemanticsNode> findViewReactionsEmojiItem(String emojiName) =>
    find.semantics.descendant(
      of: findViewReactionsTabBar,
      matching: find.semantics.byPredicate(
        (node) => node.role == SemanticsRole.tab && node.label.contains(emojiName)));

  /// Checks that a given emoji item is present or absent in [ViewReactions].
  ///
  /// If the `expectFoo` fields are null, checks that the item is absent,
  /// otherwise checks that it is present with the given details.
  void checkViewReactionsEmojiItem(WidgetTester tester, {
    required String emojiName,
    required int? expectCount,
    required bool? expectSelected,
  }) {
    assert((expectCount == null) == (expectSelected == null));
    check(findViewReactionsTabBar).findsOne();

    final nodes = findViewReactionsEmojiItem(emojiName).evaluate();
    check(nodes).length.isLessThan(2);

    if (expectCount == null) {
      check(nodes).isEmpty();
    } else {
      final expectedLabel = switch (expectCount) {
        1 => '$emojiName: 1 vote',
        _ => '$emojiName: $expectCount votes',
      };
      check(nodes).single.containsSemantics(
        label: expectedLabel,
        isSelected: expectSelected!);
    }
  }

  group('ReactionChipsList', () {
    // Smoke tests under various conditions.
    for (final displayEmojiReactionUsers in [true, false]) {
      for (final emojiset in [Emojiset.text, Emojiset.google]) {
        for (final textDirection in TextDirection.values) {
          for (final textScaleFactor in kTextScaleFactors) {
            Future<void> runSmokeTest(
              String description,
              List<Reaction> reactions, {
              required List<User> users,
              required Map<String, RealmEmojiItem> realmEmoji,
            }) async {
              final descriptionDetails = [
                displayEmojiReactionUsers ? 'show names when few' : 'no names',
                emojiset.name,
                textDirection.name,
                'text scale: $textScaleFactor',
              ].join(' / ');
              testWidgets('smoke ($description): $descriptionDetails', (tester) async {
                // Skip iOS. We're not covering the iOS code, for now, because it
                // contains a workaround for layout issues that we think will only
                // reproduce on actual iOS, and not in this test environment:
                //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20reactions.20ui.20testing/near/1691415>
                // If those layout issues get fixed and we want to cover
                // TargetPlatform.iOS, remember that we suspect the Apple Color
                // Emoji font only works on Apple platforms, so for any tests
                // aimed at iOS, we should only run them on macOS.
                // TODO Could do an on-device integration test, which would let us
                //   cover iOS before a layout fix lands upstream:
                //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20reactions.20ui.20testing/near/1691418>
                debugDefaultTargetPlatformOverride = TargetPlatform.android;

                tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
                addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

                final locale = switch (textDirection) {
                  TextDirection.ltr => const Locale('en'),
                  TextDirection.rtl => const Locale('ar'),
                };
                tester.platformDispatcher.localeTestValue = locale;
                tester.platformDispatcher.localesTestValue = [locale];
                addTearDown(tester.platformDispatcher.clearLocaleTestValue);
                addTearDown(tester.platformDispatcher.clearLocalesTestValue);

                await prepare();

                await store.addUsers(users);
                await store.handleEvent(RealmEmojiUpdateEvent(id: 1,
                  realmEmoji: realmEmoji));
                await store.handleEvent(UserSettingsUpdateEvent(id: 1,
                  property: UserSettingName.displayEmojiReactionUsers,
                  value: displayEmojiReactionUsers));
                await store.handleEvent(UserSettingsUpdateEvent(id: 1,
                  property: UserSettingName.emojiset,
                  value: emojiset));

                // This does mean that all image emoji will look the same…
                // shrug, at least for now.
                final httpClient = FakeImageHttpClient();
                debugNetworkImageHttpClientProvider = () => httpClient;
                httpClient.request.response
                  ..statusCode = HttpStatus.ok
                  ..content = kSolidBlueAvatar;

                await setupChipsInBox(tester, reactions: reactions);

                final reactionChipsList = tester.element(find.byType(ReactionChipsList));
                check(MediaQuery.of(reactionChipsList).textScaler).legacyMatcher(
                  isSystemTextScaler(withScaleFactor: textScaleFactor));
                check(Directionality.of(reactionChipsList)).equals(textDirection);

                // TODO(upstream) Do these in an addTearDown, once we can:
                //   https://github.com/flutter/flutter/issues/123189
                debugDefaultTargetPlatformOverride = null;
                debugNetworkImageHttpClientProvider = null;
              },
              // The Android code for Unicode emojis can't be exercised faithfully
              // on a Mac, because Noto Color Emoji can't work there:
              //   <https://github.com/flutter/flutter/issues/134897#issuecomment-1821632095>
              // So, skip on macOS.
              skip: io.Platform.isMacOS);
            }

            final user1 = eg.user(fullName: 'abc');
            final user2 = eg.user(fullName: 'Long Name With Many Words In It');
            final user3 = eg.user(fullName: 'longnamelongnamelongnamelongname');
            final user4 = eg.user();
            final user5 = eg.user();

            final users = [user1, user2, user3, user4, user5];

            final realmEmoji = <String, RealmEmojiItem>{
              '181': eg.realmEmojiItem(emojiCode: '181', emojiName: 'twocents'),
              '182': eg.realmEmojiItem(emojiCode: '182', emojiName: 'threecents'),
            };

            runSmokeTest('same reaction, different users, with one unknown user', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              // unknown user; shouldn't crash (name should show as "(unknown user)")
              Reaction.fromJson({ ...u1, 'user_id': eg.user().userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('same user on different reactions', [
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u2, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u3, 'user_id': user2.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('self user', [
              Reaction.fromJson({ ...i1, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...i2, 'user_id': user1.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('different [ReactionType]s', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...i1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...z1, 'user_id': user3.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('many, varied', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u2, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u3, 'user_id': user3.userId}),
              Reaction.fromJson({ ...u4, 'user_id': user4.userId}),
              Reaction.fromJson({ ...u5, 'user_id': user4.userId}),
              Reaction.fromJson({ ...u5, 'user_id': user5.userId}),
              Reaction.fromJson({ ...i1, 'user_id': user5.userId}),
              Reaction.fromJson({ ...z1, 'user_id': user5.userId}),
              Reaction.fromJson({ ...u5, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...i1, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...z1, 'user_id': eg.selfUser.userId}),
            ], users: users, realmEmoji: realmEmoji);
          }
        }
      }
    }

    testWidgets('show "Muted user" label for muted reactors', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');

      await prepare();
      await store.addUsers([user1, user2]);
      await store.setMutedUsers([user1.userId]);
      await setupChipsInBox(tester,
        reactions: [
          Reaction.fromJson({'emoji_name': '+1', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji', 'user_id': user1.userId}),
          Reaction.fromJson({'emoji_name': '+1', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji', 'user_id': user2.userId}),
        ]);

      final reactionChipFinder = find.byType(ReactionChip);
      check(reactionChipFinder).findsOne();
      check(find.descendant(
        of: reactionChipFinder,
        matching: find.text('Muted user, User 2')
      )).findsOne();
    });

    testWidgets('show view-reactions sheet on long-press', (tester) async {
      await prepare();
      await store.addUser(eg.otherUser);

      await setupChipsInBox(tester,
        reactions: [
          Reaction.fromJson({'user_id': eg.selfUser.userId, ...u1}),
          Reaction.fromJson({'user_id': eg.otherUser.userId, ...u2}),
        ]);

      await tester.longPress(find.byType(ReactionChip).last);
      await tester.pump();
      await transitionDurationObserver.pumpPastTransition(tester);

      checkViewReactionsEmojiItem(tester,
        emojiName: nameOf(u2), expectCount: 1, expectSelected: true);
    });
  });

  testWidgets('Smoke test for light/dark/lerped', (tester) async {
    await prepare();
    await store.addUsers([eg.selfUser, eg.otherUser]);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await setupChipsInBox(tester, reactions: [
      Reaction.fromJson({
        'user_id': eg.selfUser.userId,
        'emoji_name': 'slight_smile', 'emoji_code': '1f642', 'reaction_type': 'unicode_emoji'}),
      Reaction.fromJson({
        'user_id': eg.otherUser.userId,
        'emoji_name': 'tada', 'emoji_code': '1f389', 'reaction_type': 'unicode_emoji'}),
    ]);

    Color? backgroundColor(String emojiName) {
      final material = tester.widget<Material>(find.descendant(
        of: find.bySemanticsLabel(RegExp(r'^' + RegExp.escape(emojiName) + r':\ ')),
        matching: find.byType(Material)));
      return material.color;
    }

    check(backgroundColor('slight_smile')).isNotNull()
      .isSameColorAs(EmojiReactionTheme.light.bgSelected);
    check(backgroundColor('tada')).isNotNull()
      .isSameColorAs(EmojiReactionTheme.light.bgUnselected);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    await tester.pump(kThemeAnimationDuration * 0.4);
    final expectedLerped = EmojiReactionTheme.light.lerp(EmojiReactionTheme.dark, 0.4);
    check(backgroundColor('slight_smile')).isNotNull()
      .isSameColorAs(expectedLerped.bgSelected);
    check(backgroundColor('tada')).isNotNull()
      .isSameColorAs(expectedLerped.bgUnselected);

    await tester.pump(kThemeAnimationDuration * 0.6);
    check(backgroundColor('slight_smile')).isNotNull()
      .isSameColorAs(EmojiReactionTheme.dark.bgSelected);
    check(backgroundColor('tada')).isNotNull()
      .isSameColorAs(EmojiReactionTheme.dark.bgUnselected);
  });

  testWidgets('use emoji font', (tester) async {
    await prepare();
    await store.addUser(eg.selfUser);
    await setupChipsInBox(tester, reactions: [
      Reaction.fromJson({
        'user_id': eg.selfUser.userId,
        'emoji_name': 'heart', 'emoji_code': '2764', 'reaction_type': 'unicode_emoji'}),
    ]);

    check(mergedStyleOf(tester, '\u{2764}')).isNotNull()
      .fontFamily.equals(switch (defaultTargetPlatform) {
        TargetPlatform.android => 'Noto Color Emoji',
        TargetPlatform.iOS => 'Apple Color Emoji',
        _ => throw StateError('unexpected platform in test'),
      });
  }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

  // TODO more tests:
  // - Tapping a chip does the right thing
  // - When an image emoji fails to load, falls back to :text_emoji:
  // - Label text correctly chooses names or number
  // - When a user isn't found, says "(unknown user)"
  // - More about layout? (not just that it's error-free)
  // - Non-animated image emoji is selected when intended

  group('EmojiPicker', () {
    final popularCandidates =
      (eg.store()..setServerEmojiData(eg.serverEmojiDataPopular))
        .popularEmojiCandidates();

    Future<void> setupEmojiPicker(WidgetTester tester, {
      required StreamMessage message,
      required Narrow narrow,
    }) async {
      addTearDown(testBinding.reset);
      // TODO(#1667) will be null in a search narrow; remove `!`.
      assert(narrow.containsMessage(message)!);

      final httpClient = FakeImageHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.ok
        ..content = kSolidBlueAvatar;

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUsers([
        eg.selfUser,
        eg.user(userId: message.senderId),
      ]);
      final stream = eg.stream(streamId: message.streamId);
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));

      transitionDurationObserver = TransitionDurationObserver();

      connection = store.connection as FakeApiConnection;
      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [message]).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        navigatorObservers: [transitionDurationObserver],
        child: MessageListPage(initNarrow: narrow)));

      store.setServerEmojiData(eg.serverEmojiDataPopularPlus(
        ServerEmojiData(codeToNames: {
          '1f4a4': ['zzz', 'sleepy'], // (just 'zzz' in real data)
        })));

      // global store, per-account store, and message list get loaded
      await tester.pumpAndSettle();
      // request the message action sheet
      await tester.longPress(find.byType(MessageContent));
      // sheet appears onscreen
      await transitionDurationObserver.pumpPastTransition(tester);

      await store.handleEvent(RealmEmojiUpdateEvent(id: 1, realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'buzzing'),
      }));

      // request the emoji picker sheet
      await tester.tap(find.byIcon(ZulipIcons.chevron_right));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(EmojiPicker));
    }

    final searchFieldFinder = find.widgetWithText(TextField, 'Search emoji');

    Finder findInPicker(Finder finder) =>
      find.descendant(of: find.byType(EmojiPicker), matching: finder);

    Condition<Object?> conditionEmojiListEntry({
      required ReactionType emojiType,
      required String emojiCode,
      required String emojiName,
    }) {
      return (Subject<Object?> it) => it.isA<EmojiPickerListEntry>()
        ..emoji.which((it) => it
          ..emojiType.equals(emojiType)
          ..emojiCode.equals(emojiCode)
          ..emojiName.equals(emojiName));
    }

    List<Condition<Object?>> arePopularEntries = popularCandidates.map((c) =>
      conditionEmojiListEntry(
        emojiType: c.emojiType,
        emojiCode: c.emojiCode,
        emojiName: c.emojiName)).toList();

    testWidgets('show, search', (tester) async {
      final message = eg.streamMessage();
      await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

      check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
        ...arePopularEntries,
        conditionEmojiListEntry(
          emojiType: ReactionType.realmEmoji,
          emojiCode: '1',
          emojiName: 'buzzing'),
        conditionEmojiListEntry(
          emojiType: ReactionType.zulipExtraEmoji,
          emojiCode: 'zulip',
          emojiName: 'zulip'),
        conditionEmojiListEntry(
          emojiType: ReactionType.unicodeEmoji,
          emojiCode: '1f4a4',
          emojiName: 'zzz'),
      ]);

      await tester.enterText(searchFieldFinder, 'z');
      await tester.pump();

      check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
        conditionEmojiListEntry(
          emojiType: ReactionType.zulipExtraEmoji,
          emojiCode: 'zulip',
          emojiName: 'zulip'),
        conditionEmojiListEntry(
          emojiType: ReactionType.unicodeEmoji,
          emojiCode: '1f4a4',
          emojiName: 'zzz'),
        conditionEmojiListEntry(
          emojiType: ReactionType.realmEmoji,
          emojiCode: '1',
          emojiName: 'buzzing'),
      ]);

      await tester.enterText(searchFieldFinder, 'zz');
      await tester.pump();

      check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
        conditionEmojiListEntry(
          emojiType: ReactionType.unicodeEmoji,
          emojiCode: '1f4a4',
          emojiName: 'zzz'),
        conditionEmojiListEntry(
          emojiType: ReactionType.realmEmoji,
          emojiCode: '1',
          emojiName: 'buzzing'),
      ]);

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('adding success', (tester) async {
      final message = eg.streamMessage();
      await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

      connection.prepare(json: {});
      await tester.tap(findInPicker(find.text('\u{1f4a4}'))); // 'zzz' emoji
      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/${message.id}/reactions')
        ..bodyFields.deepEquals({
            'reaction_type': 'unicode_emoji',
            'emoji_code': '1f4a4',
            'emoji_name': 'zzz',
          });

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('request has an error', (tester) async {
      final message = eg.streamMessage();
      await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

      connection.prepare(
        delay: const Duration(seconds: 2),
        apiException: eg.apiBadRequest(message: 'Invalid message(s)'));

      await tester.tap(findInPicker(find.text('\u{1f4a4}'))); // 'zzz' emoji
      await tester.pump(); // register tap
      await tester.pump(const Duration(seconds: 1)); // emoji picker animates away
      await tester.pump(const Duration(seconds: 1)); // error arrives; error dialog shows

      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Adding reaction failed',
        expectedMessage: 'Invalid message(s)')));

      debugNetworkImageHttpClientProvider = null;
    });

    group('handle view paddings', () {
      const screenHeight = 400.0;

      late Rect scrollViewRect;
      final scrollViewFinder = findInPicker(find.bySubtype<ScrollView>());

      Rect getListEntriesRect(WidgetTester tester) =>
        tester.getRect(find.byType(EmojiPickerListEntry).first)
          .expandToInclude(tester.getRect(find.byType(EmojiPickerListEntry).last));

      Future<void> prepare(WidgetTester tester, {
        required FakeViewPadding viewPadding,
      }) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = Size(640, screenHeight);
        // This makes it easier to convert between device pixels used for
        // [FakeViewPadding] and logical pixels used in tests.
        // If needed, there is a clearer way to implement this generally.
        // See comment: https://github.com/zulip/zulip-flutter/pull/1315/files#r1962703436
        tester.view.devicePixelRatio = 1.0;

        tester.view.viewPadding = viewPadding;
        tester.view.padding = viewPadding;

        final message = eg.streamMessage();
        await setupEmojiPicker(tester,
          message: message, narrow: TopicNarrow.ofMessage(message));

        scrollViewRect = tester.getRect(scrollViewFinder);
        // The scroll view should expand all the way to the bottom of the
        // screen, even if there is device bottom padding.
        check(scrollViewRect)
          ..bottom.equals(screenHeight)
          // There should always be enough entries to overflow the scroll view.
          ..height.isLessThan(getListEntriesRect(tester).height);
      }

      testWidgets('no view padding', (tester) async {
        await prepare(tester, viewPadding: FakeViewPadding.zero);

        // The top edge of the list entries is padded by 8px from the top edge
        // of the scroll view; the bottom edge is out of view.
        Rect listEntriesRect = getListEntriesRect(tester);
        check(scrollViewRect)
          ..top.equals(listEntriesRect.top - 8)
          ..bottom.isLessThan(listEntriesRect.bottom);

        // Scroll to the very bottom of the list with a large offset.
        await tester.drag(scrollViewFinder, Offset(0, -500));
        await tester.pumpAndSettle();  // let overscroll finish
        // The top edge of the list entries is out of view;
        // the bottom is padded by 8px, the minimum padding, from the bottom
        // edge of the scroll view.
        listEntriesRect = getListEntriesRect(tester);
        check(scrollViewRect)
          ..top.isGreaterThan(listEntriesRect.top)
          ..bottom.equals(listEntriesRect.bottom + 8);

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('with bottom view padding', (tester) async {
        await prepare(tester, viewPadding: FakeViewPadding(bottom: 10));

        // The top edge of the list entries is padded by 8px from the top edge
        // of the scroll view; the bottom edge is out of view.
        Rect listEntriesRect = getListEntriesRect(tester);
        check(scrollViewRect)
          ..top.equals(listEntriesRect.top - 8)
          ..bottom.isLessThan(listEntriesRect.bottom);

        // Scroll to the very bottom of the list with a large offset.
        await tester.drag(scrollViewFinder, Offset(0, -500));
        await tester.pumpAndSettle();  // let overscroll finish
        // The top edge of the list entries is out of view;
        // the bottom edge is padded by 10px from the bottom edge of the scroll
        // view, because the view bottom padding is larger than the minimum 8px.
        listEntriesRect = getListEntriesRect(tester);
        check(scrollViewRect)
          ..top.isGreaterThan(listEntriesRect.top)
          ..bottom.equals(listEntriesRect.bottom + 10);

        debugNetworkImageHttpClientProvider = null;
      });
    });
  });

  group('showViewReactionsSheet', () {
    Future<void> setupViewReactionsSheet(WidgetTester tester, {
      required StreamMessage message,
      List<User> usersExcludingSelf = const [],
    }) async {
      assert(message.reactions != null && message.reactions!.total > 0);
      addTearDown(testBinding.reset);

      final httpClient = FakeImageHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.ok
        ..content = kSolidBlueAvatar;

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUsers([
        eg.selfUser,
        ...usersExcludingSelf,
      ]);
      final stream = eg.stream(streamId: message.streamId);
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));

      transitionDurationObserver = TransitionDurationObserver();

      connection = store.connection as FakeApiConnection;
      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [message]).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        navigatorObservers: [transitionDurationObserver],
        child: MessageListPage(initNarrow: CombinedFeedNarrow())));

      store.setServerEmojiData(eg.serverEmojiDataPopularPlus(
        ServerEmojiData(codeToNames: {
          '1f4a4': ['zzz', 'sleepy'], // (just 'zzz' in real data)
        })));

      // global store, per-account store, and message list get loaded
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(MessageContent));
      await transitionDurationObserver.pumpPastTransition(tester);

      await store.handleEvent(RealmEmojiUpdateEvent(id: 1, realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'buzzing'),
      }));

      await tester.tap(find.byIcon(ZulipIcons.see_who_reacted));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ViewReactions));
    }

    void checkUserList(WidgetTester tester, String emojiName, List<User> expectUsers) {
      final findPanel = find.semantics.byPredicate((node) =>
        node.role == SemanticsRole.tabPanel
        && node.label.contains('Votes for $emojiName'));

      final panel = findPanel.evaluate().single;
      check(panel).containsSemantics(label: 'Votes for $emojiName (${expectUsers.length})');

      for (final user in expectUsers) {
        check(find.semantics.descendant(
          of: findPanel,
          matching: find.semantics.byLabel(user.fullName)),
        because: 'expect ${user.fullName}').findsOne();
      }
    }

    testWidgets('smoke', (tester) async {
      final reactions = <Reaction>[
        Reaction.fromJson({'user_id': eg.selfUser.userId, ...i1}),
        Reaction.fromJson({'user_id': eg.selfUser.userId, ...z1}),
        Reaction.fromJson({'user_id': eg.selfUser.userId, ...u1}),
        Reaction.fromJson({'user_id': eg.selfUser.userId, ...u2}),

        Reaction.fromJson({'user_id': eg.otherUser.userId, ...i1}),
        Reaction.fromJson({'user_id': eg.otherUser.userId, ...z1}),
        Reaction.fromJson({'user_id': eg.otherUser.userId, ...u2}),
        Reaction.fromJson({'user_id': eg.otherUser.userId, ...u3}),
      ];

      final message = eg.streamMessage(reactions: reactions);
      await setupViewReactionsSheet(tester, message: message, usersExcludingSelf: [eg.otherUser]);

      checkViewReactionsEmojiItem(tester, emojiName: nameOf(i1), expectCount: 2, expectSelected: true);
      checkViewReactionsEmojiItem(tester, emojiName: nameOf(z1), expectCount: 2, expectSelected: false);
      checkViewReactionsEmojiItem(tester, emojiName: nameOf(u1), expectCount: 1, expectSelected: false);
      checkViewReactionsEmojiItem(tester, emojiName: nameOf(u2), expectCount: 2, expectSelected: false);
      checkViewReactionsEmojiItem(tester, emojiName: nameOf(u3), expectCount: 1, expectSelected: false);

      checkUserList(tester, nameOf(i1), [eg.selfUser, eg.otherUser]);
      tester.semantics.tap(findViewReactionsEmojiItem(nameOf(z1)));
      await tester.pump();
      checkUserList(tester, nameOf(z1), [eg.selfUser, eg.otherUser]);
      tester.semantics.tap(findViewReactionsEmojiItem(nameOf(u1)));
      await tester.pump();
      checkUserList(tester, nameOf(u1), [eg.selfUser]);
      tester.semantics.tap(findViewReactionsEmojiItem(nameOf(u3)));
      await tester.pump();
      checkUserList(tester, nameOf(u3), [eg.otherUser]);

      // TODO(upstream) Do this in an addTearDown once we can:
      //   https://github.com/flutter/flutter/issues/123189
      debugNetworkImageHttpClientProvider = null;
    });

    // TODO test last-vote-removed on selected emoji
    // TODO test message deleted
    // TODO test that tapping a user opens their profile
    // TODO test emoji list's scroll-into-view logic
    // TODO test expired event queue/refresh
  });
}
