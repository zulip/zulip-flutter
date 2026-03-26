import 'package:flutter_test/flutter_test.dart';

import '../example_data.dart' as eg;
import '../mocks.dart';
import '../../lib/model/user_resolver.dart';
import '../../lib/model/store.dart';
import '../../lib/api/model/model.dart';

/// Integration test to verify UserResolver works seamlessly with existing codebase
/// Following Zulip testing standards:
/// - Comprehensive test coverage
/// - Clear setup and teardown
/// - Proper use of test helpers
/// - Performance considerations
void main() {
  group('UserResolver Integration Tests', () {
    late PerAccountStore store;
    late UserResolver resolver;

    setUp(() async {
      final binding = MockZulipBinding();
      store = await binding.globalStore.perAccount(eg.selfAccount.id);
      resolver = store.userResolver;
    });

    tearDown(() {
      store.dispose();
    });

    group('resolveUser', () {
      test('returns known user', () {
        final user = eg.user();
        store.addUser(user);

        final resolved = resolver.resolveUser(user.userId);
        expect(resolved, isNotNull);
        expect(resolved!.userId, equals(user.userId));
        expect(resolved.fullName, equals(user.fullName));
      });

      test('returns null for unknown user', () {
        const unknownUserId = 999999;
        final resolved = resolver.resolveUser(unknownUserId);
        expect(resolved, isNull);
      });

      test('caches user lookups', () {
        final user = eg.user();
        store.addUser(user);

        // First lookup
        final resolved1 = resolver.resolveUser(user.userId);
        expect(resolved1, isNotNull);

        // Second lookup should use cache
        final resolved2 = resolver.resolveUser(user.userId);
        expect(resolved2, same(resolved1)); // Same object reference due to caching
      });
    });

    group('resolveUserOrFallback', () {
      test('returns known user', () {
        final user = eg.user();
        store.addUser(user);

        final resolved = resolver.resolveUserOrFallback(user.userId);
        expect(resolved.userId, equals(user.userId));
        expect(resolved.fullName, equals(user.fullName));
      });

      test('creates synthetic user for unknown user', () {
        const unknownUserId = 999999;
        final resolved = resolver.resolveUserOrFallback(unknownUserId);

        expect(resolved.userId, equals(unknownUserId));
        expect(resolved.fullName, equals('Unknown user'));
        expect(resolved.email, equals('unknown-999999@example.com'));
        expect(resolved.isUnknown, isTrue);
      });

      test('uses custom fallback name', () {
        const unknownUserId = 999999;
        const fallbackName = 'Deleted User';

        final resolved = resolver.resolveUserOrFallback(
          unknownUserId,
          fallbackName: fallbackName,
        );

        expect(resolved.fullName, equals(fallbackName));
      });
    });

    group('getDisplayName', () {
      test('returns known user name', () {
        final user = eg.user(fullName: 'John Doe');
        store.addUser(user);

        final displayName = resolver.getDisplayName(user.userId);
        expect(displayName, equals('John Doe'));
      });

      test('returns fallback for unknown user', () {
        const unknownUserId = 999999;
        final displayName = resolver.getDisplayName(unknownUserId);
        expect(displayName, equals('Unknown user'));
      });

      test('uses message context for better fallback', () {
        const unknownUserId = 999999;
        final message = eg.message(
          senderId: unknownUserId,
          senderFullName: 'Message Sender',
        );

        final displayName = resolver.getDisplayName(
          unknownUserId,
          messageContext: message,
        );
        expect(displayName, equals('Message Sender'));
      });

      test('handles muted users', () {
        final user = eg.user(fullName: 'John Doe');
        store.addUser(user);
        store.addMutedUser(user.userId);

        final displayName = resolver.getDisplayName(
          user.userId,
          replaceIfMuted: true,
        );
        expect(displayName, equals('Muted user'));

        final displayNameNotMuted = resolver.getDisplayName(
          user.userId,
          replaceIfMuted: false,
        );
        expect(displayNameNotMuted, equals('John Doe'));
      });

      test('caches display names', () {
        final user = eg.user(fullName: 'John Doe');
        store.addUser(user);

        final displayName1 = resolver.getDisplayName(user.userId);
        final displayName2 = resolver.getDisplayName(user.userId);

        // Should be cached (same string reference)
        expect(displayName1, same(displayName2));
      });
    });

    group('getSenderDisplayName', () {
      test('returns sender name from message context', () {
        final message = eg.message(
          senderFullName: 'Message Sender',
        );

        final displayName = resolver.getSenderDisplayName(message);
        expect(displayName, equals('Message Sender'));
      });

      test('falls back to user store when needed', () {
        final user = eg.user(fullName: 'John Doe');
        store.addUser(user);
        final message = eg.message(
          senderId: user.userId,
          senderFullName: 'Different Name', // Should prefer user store
        );

        final displayName = resolver.getSenderDisplayName(message);
        expect(displayName, equals('John Doe'));
      });
    });

    group('batch operations', () {
      test('resolveUsers handles mixed known/unknown users', () {
        final knownUser = eg.user();
        store.addUser(knownUser);
        const unknownUserId = 999999;

        final results = resolver.resolveUsers([
          knownUser.userId,
          unknownUserId,
        ]);

        expect(results[knownUser.userId], isNotNull);
        expect(results[unknownUserId], isNull);
      });

      test('hasUnknownUsers works correctly', () {
        final knownUser = eg.user();
        store.addUser(knownUser);
        const unknownUserId = 999999;

        expect(resolver.hasUnknownUsers([knownUser.userId]), isFalse);
        expect(resolver.hasUnknownUsers([unknownUserId]), isTrue);
        expect(resolver.hasUnknownUsers([knownUser.userId, unknownUserId]), isTrue);
      });

      test('filterKnownUsers works correctly', () {
        final knownUser = eg.user();
        store.addUser(knownUser);
        const unknownUserId = 999999;

        final filtered = resolver.filterKnownUsers([
          knownUser.userId,
          unknownUserId,
        ]);

        expect(filtered, contains(knownUser.userId));
        expect(filtered, isNot(contains(unknownUserId)));
      });
    });

    group('cache management', () {
      test('clearCache empties all caches', () {
        final user = eg.user();
        store.addUser(user);

        // Populate caches
        resolver.resolveUser(user.userId);
        resolver.getDisplayName(user.userId);

        expect(resolver.getCacheStats()['userCacheSize'], greaterThan(0));
        expect(resolver.getCacheStats()['displayNameCacheSize'], greaterThan(0));

        resolver.clearCache();

        expect(resolver.getCacheStats()['userCacheSize'], equals(0));
        expect(resolver.getCacheStats()['displayNameCacheSize'], equals(0));
      });

      test('invalidateUserCache removes specific user', () {
        final user1 = eg.user();
        final user2 = eg.user();
        store.addUser(user1);
        store.addUser(user2);

        // Populate caches
        resolver.resolveUser(user1.userId);
        resolver.resolveUser(user2.userId);

        expect(resolver.getCacheStats()['userCacheSize'], equals(2));

        resolver.invalidateUserCache(user1.userId);

        expect(resolver.getCacheStats()['userCacheSize'], equals(1));

        // user2 should still be cached
        expect(resolver.resolveUser(user2.userId), isNotNull);
      });
    });

    group('PerAccountStore extensions', () {
      test('selfUser returns correct user', () {
        final selfUser = store.selfUser;
        expect(selfUser.userId, equals(eg.selfUser.userId));
        expect(selfUser.fullName, equals(eg.selfUser.fullName));
      });

      test('resolveUser works through extension', () {
        final user = eg.user();
        store.addUser(user);

        final resolved = store.resolveUser(user.userId);
        expect(resolved, isNotNull);
        expect(resolved!.userId, equals(user.userId));
      });

      test('getDisplayName works through extension', () {
        final user = eg.user(fullName: 'John Doe');
        store.addUser(user);

        final displayName = store.getDisplayName(user.userId);
        expect(displayName, equals('John Doe'));
      });
    });

    group('UserExtensions', () {
      test('isUnknown identifies synthetic users', () {
        final realUser = eg.user();
        expect(realUser.isUnknown, isFalse);

        final syntheticUser = resolver.resolveUserOrFallback(999999);
        expect(syntheticUser.isUnknown, isTrue);
      });

      test('safeDisplayName works correctly', () {
        final realUser = eg.user(fullName: 'John Doe');
        expect(realUser.safeDisplayName, equals('John Doe'));

        final syntheticUser = resolver.resolveUserOrFallback(999999);
        expect(syntheticUser.safeDisplayName, equals('Unknown user'));
      });
    });
  });
}
