import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/user_resolver_zulip_style.dart';

import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('UserResolver', () {
    late PerAccountStore store;
    late UserResolver resolver;

    setUp(() {
      final globalStore = LoadingTestGlobalStore();
      store = PerAccountStore.fromInitialSnapshot(
        globalStore: globalStore,
        accountId: 1,
        initialSnapshot: eg.initialSnapshot(),
      );
      resolver = UserResolver(store);
    });

    test('resolveUser returns existing user', () {
      final user = resolver.resolveUser(eg.selfUser.userId);
      check(user).isNotNull();
      check(user!.userId).equals(eg.selfUser.userId);
      check(user.email).equals(eg.selfUser.email);
    });

    test('resolveUser returns null for unknown user', () {
      final user = resolver.resolveUser(999999);
      check(user).isNull();
    });

    test('resolveUser caches results', () {
      final user1 = resolver.resolveUser(eg.selfUser.userId);
      final user2 = resolver.resolveUser(eg.selfUser.userId);
      check(user1).equals(user2);
      check(identical(user1, user2)).isTrue();
    });

    test('resolveUserOrFallback returns existing user', () {
      final user = resolver.resolveUserOrFallback(eg.selfUser.userId);
      check(user).isNotNull();
      check(user.userId).equals(eg.selfUser.userId);
      check(user.email).equals(eg.selfUser.email);
    });

    test('resolveUserOrFallback creates synthetic user for unknown user', () {
      final user = resolver.resolveUserOrFallback(999999);
      check(user).isNotNull();
      check(user.userId).equals(999999);
      check(user.email).equals('unknown-999999@example.com');
      check(user.fullName).equals('Unknown user');
      check(user.isUnknown).isTrue();
    });

    test('resolveUserOrFallback uses custom fallback name', () {
      final user = resolver.resolveUserOrFallback(999999, fallbackName: 'Custom name');
      check(user.fullName).equals('Custom name');
    });

    test('getDisplayName returns full name for existing user', () {
      final displayName = resolver.getDisplayName(eg.selfUser.userId);
      check(displayName).equals(eg.selfUser.fullName);
    });

    test('getDisplayName returns fallback for unknown user', () {
      final displayName = resolver.getDisplayName(999999);
      check(displayName).equals('Unknown user');
    });

    test('getDisplayName uses custom fallback name', () {
      final displayName = resolver.getDisplayName(999999, fallbackName: 'Custom name');
      check(displayName).equals('Custom name');
    });

    test('getDisplayName handles muted user', () {
      // Add a muted user to the store
      final mutedUser = eg.user(userId: 123, fullName: 'Muted User');
      store.handleEvent(RealmUserEvent(
        id: 1,
        event: UserEvent(op: UserOp.add, user: mutedUser),
      ));
      store.handleEvent(UpdateMutedUsersEvent(mutedUserIds: [mutedUser.userId]));

      final displayName = resolver.getDisplayName(mutedUser.userId);
      check(displayName).equals('Muted user');
    });

    test('getDisplayName uses message context for unknown user', () {
      final message = eg.message(
        senderId: 999999,
        senderFullName: 'Message Sender',
      );

      final displayName = resolver.getDisplayName(
        999999,
        messageContext: message,
      );
      check(displayName).equals('Message Sender');
    });

    test('getDisplayName prefers user over message context', () {
      final message = eg.message(
        senderId: eg.selfUser.userId,
        senderFullName: 'Different Name',
      );

      final displayName = resolver.getDisplayName(
        eg.selfUser.userId,
        messageContext: message,
      );
      check(displayName).equals(eg.selfUser.fullName);
    });

    test('getSenderDisplayName returns full name for existing user', () {
      final message = eg.message(senderId: eg.selfUser.userId);
      final displayName = resolver.getSenderDisplayName(message);
      check(displayName).equals(eg.selfUser.fullName);
    });

    test('getSenderDisplayName uses message sender name for unknown user', () {
      final message = eg.message(
        senderId: 999999,
        senderFullName: 'Unknown Sender',
      );
      final displayName = resolver.getSenderDisplayName(message);
      check(displayName).equals('Unknown Sender');
    });

    test('getSenderDisplayName handles muted user', () {
      final mutedUser = eg.user(userId: 123, fullName: 'Muted User');
      store.handleEvent(RealmUserEvent(
        id: 1,
        event: UserEvent(op: UserOp.add, user: mutedUser),
      ));
      store.handleEvent(UpdateMutedUsersEvent(mutedUserIds: [mutedUser.userId]));

      final message = eg.message(senderId: mutedUser.userId);
      final displayName = resolver.getSenderDisplayName(message);
      check(displayName).equals('Muted user');
    });

    test('resolveUsers handles mixed known and unknown users', () {
      final userIds = [eg.selfUser.userId, 999999, eg.otherUser.userId];
      final results = resolver.resolveUsers(userIds);

      check(results).hasLength(3);
      check(results[eg.selfUser.userId]).isNotNull();
      check(results[999999]).isNull();
      check(results[eg.otherUser.userId]).isNotNull();
    });

    test('resolveUsers caches results', () {
      final userIds = [eg.selfUser.userId, eg.otherUser.userId];
      final results1 = resolver.resolveUsers(userIds);
      final results2 = resolver.resolveUsers(userIds);

      check(results1[eg.selfUser.userId]).equals(results2[eg.selfUser.userId]);
      check(identical(results1[eg.selfUser.userId], results2[eg.selfUser.userId])).isTrue();
    });

    test('clearCache clears all cached users', () {
      // Cache some users
      resolver.resolveUser(eg.selfUser.userId);
      resolver.resolveUser(eg.otherUser.userId);

      // Clear cache
      resolver.clearCache();

      // Users should be fetched again (not from cache)
      final user1 = resolver.resolveUser(eg.selfUser.userId);
      final user2 = resolver.resolveUser(eg.otherUser.userId);

      check(user1).isNotNull();
      check(user2).isNotNull();
    });

    test('clearUserCache clears specific user', () {
      // Cache a user
      resolver.resolveUser(eg.selfUser.userId);

      // Clear specific user cache
      resolver.clearUserCache(eg.selfUser.userId);

      // User should be fetched again (not from cache)
      final user = resolver.resolveUser(eg.selfUser.userId);
      check(user).isNotNull();
    });
  });

  group('PerAccountStoreUserResolver extension', () {
    late PerAccountStore store;

    setUp(() {
      final globalStore = LoadingTestGlobalStore();
      store = PerAccountStore.fromInitialSnapshot(
        globalStore: globalStore,
        accountId: 1,
        initialSnapshot: eg.initialSnapshot(),
      );
    });

    test('userResolver returns UserResolver instance', () {
      final resolver = store.userResolver;
      check(resolver).isNotNull();
      check(resolver).isA<UserResolver>();
    });

    test('resolveUser convenience method works', () {
      final user = store.resolveUser(eg.selfUser.userId);
      check(user).isNotNull();
      check(user!.userId).equals(eg.selfUser.userId);
    });

    test('getDisplayName convenience method works', () {
      final displayName = store.getDisplayName(eg.selfUser.userId);
      check(displayName).equals(eg.selfUser.fullName);
    });
  });

  group('UserExtensions', () {
    test('isUnknown identifies synthetic users', () {
      final syntheticUser = User(
        userId: 999999,
        deliveryEmail: null,
        email: 'unknown-999999@example.com',
        fullName: 'Unknown user',
        dateJoined: DateTime.now(),
        isActive: true,
        isBot: false,
        botType: BotType.normal,
        botOwnerId: null,
        role: UserRole.member,
        timezone: null,
        avatarUrl: null,
        avatarVersion: 0,
        profileData: null,
        isSystemBot: false,
      );

      check(syntheticUser.isUnknown).isTrue();
    });

    test('isUnknown returns false for real users', () {
      check(eg.selfUser.isUnknown).isFalse();
    });

    test('safeDisplayName returns fullName for synthetic users', () {
      final syntheticUser = User(
        userId: 999999,
        deliveryEmail: null,
        email: 'unknown-999999@example.com',
        fullName: 'Unknown user',
        dateJoined: DateTime.now(),
        isActive: true,
        isBot: false,
        botType: BotType.normal,
        botOwnerId: null,
        role: UserRole.member,
        timezone: null,
        avatarUrl: null,
        avatarVersion: 0,
        profileData: null,
        isSystemBot: false,
      );

      check(syntheticUser.safeDisplayName).equals('Unknown user');
    });

    test('safeDisplayName returns fullName for real users with name', () {
      check(eg.selfUser.safeDisplayName).equals(eg.selfUser.fullName);
    });

    test('safeDisplayName returns email for users with empty name', () {
      final userWithEmptyName = eg.selfUser.copyWith(fullName: '');
      check(userWithEmptyName.safeDisplayName).equals(userWithEmptyName.email);
    });
  });

  group('Edge cases and error handling', () {
    late PerAccountStore store;
    late UserResolver resolver;

    setUp(() {
      final globalStore = LoadingTestGlobalStore();
      store = PerAccountStore.fromInitialSnapshot(
        globalStore: globalStore,
        accountId: 1,
        initialSnapshot: eg.initialSnapshot(),
      );
      resolver = UserResolver(store);
    });

    test('handles empty user list in resolveUsers', () {
      final results = resolver.resolveUsers([]);
      check(results).isEmpty();
    });

    test('handles duplicate user IDs in resolveUsers', () {
      final userIds = [eg.selfUser.userId, eg.selfUser.userId];
      final results = resolver.resolveUsers(userIds);

      check(results).hasLength(1);
      check(results[eg.selfUser.userId]).isNotNull();
    });

    test('handles very large user IDs', () {
      final largeUserId = 2147483647; // Max int
      final user = resolver.resolveUserOrFallback(largeUserId);
      check(user.userId).equals(largeUserId);
      check(user.email).equals('unknown-2147483647@example.com');
    });

    test('handles zero user ID', () {
      final user = resolver.resolveUserOrFallback(0);
      check(user.userId).equals(0);
      check(user.email).equals('unknown-0@example.com');
    });

    test('handles negative user ID', () {
      final user = resolver.resolveUserOrFallback(-1);
      check(user.userId).equals(-1);
      check(user.email).equals('unknown--1@example.com');
    });
  });
}
