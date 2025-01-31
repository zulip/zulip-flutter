import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/reaction_users_sheet.dart';
import 'package:zulip/widgets/profile.dart';

import '../example_data.dart' as eg;
import '../model/test_store.dart';
import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;

  Future<void> prepare() async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    await store.addUser(eg.selfUser);
  }

  Future<void> pumpReactionUsersSheet(WidgetTester tester, {
    required List<Reaction> reactions,
    required ReactionWithVotes initialSelectedReaction,
    Size? screenSize,
  }) async {
    await tester.binding.setSurfaceSize(screenSize ?? const Size(400, 600));
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: Material(
        child: ReactionUsersSheet(
          reactions: Reactions(reactions),
          initialSelectedReaction: initialSelectedReaction,
          store: store,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('ReactionUsersSheet', () {
    testWidgets('displays emoji buttons correctly', (tester) async {
      await prepare();
      final user1 = eg.user(fullName: 'User One', isActive: true);
      final user2 = eg.user(fullName: 'User Two', isActive: false);
      await store.addUsers([user1, user2]);

      final reaction1 = Reaction(
        userId: user1.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );
      final reaction2 = Reaction(
        userId: user2.userId,
        emojiName: 'heart',
        emojiCode: '2764',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [reaction1, reaction2];

      final selectedReaction = ReactionWithVotes.empty(reaction1)
        ..userIds.add(user1.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Verify emoji buttons are displayed
      expect(find.text('1'), findsNWidgets(2)); // Count for both emojis
    });

    testWidgets('displays user list correctly', (tester) async {
      await prepare();
      final user1 = eg.user(fullName: 'User One', isActive: true);
      final user2 = eg.user(fullName: 'User Two', isActive: false);
      await store.addUsers([user1, user2]);

      final reaction = Reaction(
        userId: user1.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [
        reaction,
        Reaction(
          userId: user2.userId,
          emojiName: 'smile',
          emojiCode: '1f642',
          reactionType: ReactionType.unicodeEmoji,
        ),
      ];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.addAll([user1.userId, user2.userId]);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Verify user names are displayed
      expect(find.text('User One'), findsOneWidget);
      expect(find.text('User Two'), findsOneWidget);
    });

    testWidgets('handles unknown users gracefully', (tester) async {
      await prepare();
      const unknownUserId = 999;

      final reaction = Reaction(
        userId: unknownUserId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [reaction];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.add(unknownUserId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Verify unknown user is displayed with fallback text
      expect(find.text('(unknown user)'), findsOneWidget);
    });

    testWidgets('navigates to user profile on tap', (tester) async {
      await prepare();
      final user = eg.user(fullName: 'Test User', isActive: true);
      await store.addUsers([user]);

      final reaction = Reaction(
        userId: user.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [reaction];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.add(user.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Tap on user name
      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();

      // Verify navigation to profile page
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('switches between reactions', (tester) async {
      await prepare();
      final user1 = eg.user(fullName: 'User One', isActive: true);
      final user2 = eg.user(fullName: 'User Two', isActive: false);
      await store.addUsers([user1, user2]);

      final reaction1 = Reaction(
        userId: user1.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );
      final reaction2 = Reaction(
        userId: user2.userId,
        emojiName: 'heart',
        emojiCode: '2764',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [reaction1, reaction2];

      final selectedReaction = ReactionWithVotes.empty(reaction1)
        ..userIds.add(user1.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Initially should show User One
      expect(find.text('User One'), findsOneWidget);
      expect(find.text('User Two'), findsNothing);

      // Tap second reaction
      await tester.tap(find.text('1').last);
      await tester.pumpAndSettle();

      // Should now show User Two
      expect(find.text('User One'), findsNothing);
      expect(find.text('User Two'), findsOneWidget);
    });

    testWidgets('displays online status indicator correctly', (tester) async {
      await prepare();
      final onlineUser = eg.user(fullName: 'Online User', isActive: true);
      final offlineUser = eg.user(fullName: 'Offline User', isActive: false);
      await store.addUsers([onlineUser, offlineUser]);

      final reaction = Reaction(
        userId: onlineUser.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [
        reaction,
        Reaction(
          userId: offlineUser.userId,
          emojiName: 'smile',
          emojiCode: '1f642',
          reactionType: ReactionType.unicodeEmoji,
        ),
      ];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.addAll([onlineUser.userId, offlineUser.userId]);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Find the green dot indicators
      final greenDots = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == Colors.green);

      // Should find exactly one green dot (for the online user)
      expect(greenDots, findsOneWidget);

      // Verify the green dot is associated with the online user
      final onlineUserListItem = find.ancestor(
        of: find.text('Online User'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: onlineUserListItem,
          matching: greenDots,
        ),
        findsOneWidget,
      );

      // Verify the offline user doesn't have a green dot
      final offlineUserListItem = find.ancestor(
        of: find.text('Offline User'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: offlineUserListItem,
          matching: greenDots,
        ),
        findsNothing,
      );

      // Test status update
      await store.handleEvent(RealmUserUpdateEvent(
        id: 1,
        userId: offlineUser.userId,
        isActive: true,
      ));
      await tester.pump();

      // Should now find two green dots
      expect(greenDots, findsNWidgets(2));

      // Make the online user offline
      await store.handleEvent(RealmUserUpdateEvent(
        id: 2,
        userId: onlineUser.userId,
        isActive: false,
      ));
      await tester.pump();

      // Should now find one green dot again
      expect(greenDots, findsOneWidget);
    });

    testWidgets('handles horizontal overflow with many reactions', (tester) async {
      await prepare();
      final users = List.generate(20, (i) => eg.user(
        fullName: 'User $i',
        isActive: i % 2 == 0, // Alternate between online and offline
      ));
      await store.addUsers(users);

      // Create 20 different reactions
      final reactions = List.generate(20, (i) => Reaction(
        userId: users[i].userId,
        emojiName: 'emoji_$i',
        emojiCode: '1f${600 + i}',
        reactionType: ReactionType.unicodeEmoji,
      ));

      final selectedReaction = ReactionWithVotes.empty(reactions[0])
        ..userIds.add(users[0].userId);

      // Use a narrow screen size to force horizontal scrolling
      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
        screenSize: const Size(300, 600),
      );

      // Verify that horizontal scrolling works
      final firstReactionFinder = find.text('1').first;
      final lastReactionFinder = find.text('1').last;

      // Get the initial position of the first reaction
      final firstReactionInitialRect = tester.getRect(firstReactionFinder);

      // Scroll to the right
      await tester.dragFrom(
        tester.getCenter(find.byType(SingleChildScrollView)),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      // Verify that the first reaction has moved off screen
      final firstReactionFinalRect = tester.getRect(firstReactionFinder);
      expect(firstReactionFinalRect.left, lessThan(firstReactionInitialRect.left));

      // Verify that we can see the last reaction
      expect(tester.getRect(lastReactionFinder).right, isPositive);
    });

    testWidgets('handles vertical overflow with many users', (tester) async {
      await prepare();
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      // Create 50 users to ensure vertical scrolling
      final users = List.generate(50, (i) => eg.user(fullName: 'User $i'));
      await store.addUsers(users);

      final reaction = Reaction(
        userId: users[0].userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      // Add all users to the same reaction
      final selectedReaction = ReactionWithVotes.empty(reaction);
      for (final user in users) {
        selectedReaction.userIds.add(user.userId);
      }

      // Build the widget with a constrained height
      await tester.pumpWidget(
        TestZulipApp(
          accountId: eg.selfAccount.id,
          child: Material(
            child: SizedBox(
              height: 300, // Constrain height to force scrolling
              child: ReactionUsersSheet(
                reactions: Reactions([reaction]),
                initialSelectedReaction: selectedReaction,
                store: store,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('User 0'), findsOneWidget);
      expect(find.text('User 49'), findsNothing);

      // Find the ListView
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // Scroll down using fling
      await tester.fling(listViewFinder, const Offset(0, -500), 10000);
      await tester.pumpAndSettle();

      // After scrolling down, verify that we can see users at the bottom
      expect(find.text('User 0'), findsNothing);

      // Look for any users from 40-49 to verify we scrolled far enough
      bool foundLaterUser = false;
      for (int i = 40; i < 50; i++) {
        if (find.text('User $i').evaluate().isNotEmpty) {
          foundLaterUser = true;
          break;
        }
      }
      expect(foundLaterUser, isTrue, reason: 'Should find at least one user from 40-49 after scrolling down');

      // Scroll back to top using fling
      await tester.fling(listViewFinder, const Offset(0, 500), 10000);
      await tester.pumpAndSettle();

      // Verify we're back at the top
      expect(find.text('User 0'), findsOneWidget);

      // Verify no users from the bottom are visible
      bool foundBottomUser = false;
      for (int i = 40; i < 50; i++) {
        if (find.text('User $i').evaluate().isNotEmpty) {
          foundBottomUser = true;
          break;
        }
      }
      expect(foundBottomUser, isFalse, reason: 'Should not find any users from 40-49 after scrolling back up');
    });

    testWidgets('handles long user names without overflow', (tester) async {
      await prepare();
      final user = eg.user(fullName: 'User with a very very very very very long name that might cause overflow issues');
      await store.addUsers([user]);

      final reaction = Reaction(
        userId: user.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.add(user.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: [reaction],
        initialSelectedReaction: selectedReaction,
        screenSize: const Size(300, 600), // Narrow screen to test overflow handling
      );

      // Verify the long name is displayed
      expect(find.text('User with a very very very very very long name that might cause overflow issues'), findsOneWidget);

      // Verify no overflow errors in the console
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays different types of emojis correctly', (tester) async {
      await prepare();
      final user = eg.user(fullName: 'Test User');
      await store.addUsers([user]);

      // Unicode emoji reaction
      final unicodeReaction = Reaction(
        userId: user.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      // Image/custom emoji reaction
      final imageReaction = Reaction(
        userId: user.userId,
        emojiName: 'zulip',
        emojiCode: 'zulip',
        reactionType: ReactionType.realmEmoji,
      );

      // Text emoji reaction (using zulip text emoji format)
      final textReaction = Reaction(
        userId: user.userId,
        emojiName: 'octopus',
        emojiCode: 'octopus',
        reactionType: ReactionType.zulipExtraEmoji,
      );

      final reactions = [unicodeReaction, imageReaction, textReaction];
      final selectedReaction = ReactionWithVotes.empty(unicodeReaction)
        ..userIds.add(user.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Verify emoji buttons are displayed
      expect(find.text('1'), findsNWidgets(3)); // Each reaction has 1 user

      // Test switching between reactions and verify user display
      // Initially unicode emoji is selected
      expect(find.text('Test User'), findsOneWidget);

      // Switch to image emoji
      await tester.tap(find.text('1').at(1));
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);

      // Switch to text emoji
      await tester.tap(find.text('1').at(2));
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);

      // Switch back to unicode emoji
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);

      // Verify no errors in the console
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays online status indicator correctly', (tester) async {
      await prepare();
      final onlineUser = eg.user(fullName: 'Online User', isActive: true);
      final offlineUser = eg.user(fullName: 'Offline User', isActive: false);
      await store.addUsers([onlineUser, offlineUser]);

      final reaction = Reaction(
        userId: onlineUser.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [
        reaction,
        Reaction(
          userId: offlineUser.userId,
          emojiName: 'smile',
          emojiCode: '1f642',
          reactionType: ReactionType.unicodeEmoji,
        ),
      ];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.addAll([onlineUser.userId, offlineUser.userId]);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Find the green dot indicators
      final greenDots = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == Colors.green);

      // Should find exactly one green dot (for the online user)
      expect(greenDots, findsOneWidget);

      // Verify the green dot is associated with the online user
      final onlineUserListItem = find.ancestor(
        of: find.text('Online User'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: onlineUserListItem,
          matching: greenDots,
        ),
        findsOneWidget,
      );

      // Verify the offline user doesn't have a green dot
      final offlineUserListItem = find.ancestor(
        of: find.text('Offline User'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: offlineUserListItem,
          matching: greenDots,
        ),
        findsNothing,
      );

      // Test status update
      await store.handleEvent(RealmUserUpdateEvent(
        id: 1,
        userId: offlineUser.userId,
        isActive: true,
      ));
      await tester.pump();

      // Should now find two green dots
      expect(greenDots, findsNWidgets(2));

      // Make the online user offline
      await store.handleEvent(RealmUserUpdateEvent(
        id: 2,
        userId: onlineUser.userId,
        isActive: false,
      ));
      await tester.pump();

      // Should now find one green dot again
      expect(greenDots, findsOneWidget);
    });

    testWidgets('updates online status when user status changes', (tester) async {
      await prepare();
      final user = eg.user(fullName: 'Test User', isActive: false);
      await store.addUsers([user]);

      final reaction = Reaction(
        userId: user.userId,
        emojiName: 'smile',
        emojiCode: '1f642',
        reactionType: ReactionType.unicodeEmoji,
      );

      final reactions = [reaction];

      final selectedReaction = ReactionWithVotes.empty(reaction)
        ..userIds.add(user.userId);

      await pumpReactionUsersSheet(
        tester,
        reactions: reactions,
        initialSelectedReaction: selectedReaction,
      );

      // Initially no green dot
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == Colors.green),
        findsNothing,
      );

      // Change user status to online
      await store.handleEvent(RealmUserUpdateEvent(
        id: 1,
        userId: user.userId,
        isActive: true,
      ));
      await tester.pump();

      // Should now show green dot
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == Colors.green),
        findsOneWidget,
      );

      // Change user status back to offline
      await store.handleEvent(RealmUserUpdateEvent(
        id: 2,
        userId: user.userId,
        isActive: false,
      ));
      await tester.pump();

      // Green dot should be gone
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == Colors.green),
        findsNothing,
      );
    });
  });
}