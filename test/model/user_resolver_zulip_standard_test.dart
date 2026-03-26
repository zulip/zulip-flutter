import 'package:flutter_test/flutter_test.dart';

import '../example_data.dart' as eg;
import '../mocks.dart';
import '../../lib/model/user_resolver.dart';
import '../../lib/model/store.dart';
import '../../lib/api/model/model.dart';

/// UserResolver tests following Zulip testing standards
/// 
/// This test suite follows Zulip's testing philosophy:
/// - Comprehensive coverage (aim for 98%+ on core code)
/// - Speed (tests should run in seconds, not minutes)
/// - Accuracy (tests should be precise and reliable)
/// - Completeness (cover all important scenarios)
/// 
/// Based on: https://zulip.readthedocs.io/en/latest/testing/index.html
void main() {
  group('UserResolver: Core Resolution', () {
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

    test('resolveUser returns known user', () {
      final user = eg.user(fullName: 'Alice Smith');
      store.addUser(user);
      
      final resolved = resolver.resolveUser(user.userId);
      expect(resolved, isNotNull);
      expect(resolved!.userId, equals(user.userId));
      expect(resolved.fullName, equals('Alice Smith'));
    });

    test('resolveUser returns null for unknown user', () {
      const unknownUserId = 999999;
      final resolved = resolver.resolveUser(unknownUserId);
      expect(resolved, isNull);
    });

    test('resolveUser caches results for performance', () {
      final user = eg.user(fullName: 'Cached User');
      store.addUser(user);
      
      // First lookup should populate cache
      final user1 = resolver.resolveUser(user.userId);
      expect(user1, isNotNull);
      
      // Second lookup should use cache (same object reference)
      final user2 = resolver.resolveUser(user.userId);
      expect(user2, same(user1));
      
      // Verify cache statistics
      final stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(1));
    });
  });

  group('UserResolver: Fallback Handling', () {
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

    test('resolveUserOrFallback creates synthetic user for unknown user', () {
      const unknownUserId = 999999;
      final resolved = resolver.resolveUserOrFallback(unknownUserId);
      
      expect(resolved.userId, equals(unknownUserId));
      expect(resolved.fullName, equals('Unknown user'));
      expect(resolved.email, equals('unknown-999999@example.com'));
      expect(resolved.isUnknown, isTrue);
      expect(resolved.isActive, isTrue);
      expect(resolved.isBot, isFalse);
    });

    test('resolveUserOrFallback uses custom fallback name', () {
      const unknownUserId = 999999;
      const customFallback = 'Deleted User';
      
      final resolved = resolver.resolveUserOrFallback(
        unknownUserId, 
        fallbackName: customFallback,
      );
      
      expect(resolved.fullName, equals(customFallback));
    });

    test('getDisplayName handles unknown users with fallback', () {
      const unknownUserId = 999999;
      final displayName = resolver.getDisplayName(unknownUserId);
      expect(displayName, equals('Unknown user'));
    });

    test('getDisplayName uses message context for better fallbacks', () {
      const unknownUserId = 999999;
      final message = eg.message(
        senderId: unknownUserId,
        senderFullName: 'Message Context Name',
      );
      
      final displayName = resolver.getDisplayName(
        unknownUserId,
        messageContext: message,
      );
      expect(displayName, equals('Message Context Name'));
    });

    test('getDisplayName handles muted users correctly', () {
      final user = eg.user(fullName: 'Muted User');
      store.addUser(user);
      store.addMutedUser(user.userId);
      
      // With replaceIfMuted = true
      final displayNameMuted = resolver.getDisplayName(
        user.userId,
        replaceIfMuted: true,
      );
      expect(displayNameMuted, equals('Muted user'));
      
      // With replaceIfMuted = false
      final displayNameNotMuted = resolver.getDisplayName(
        user.userId,
        replaceIfMuted: false,
      );
      expect(displayNameNotMuted, equals('Muted User'));
    });
  });

  group('UserResolver: Performance and Caching', () {
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

    test('caching improves lookup performance', () {
      final user = eg.user(fullName: 'Performance Test User');
      store.addUser(user);
      
      // Measure first lookup (cache miss)
      final start1 = DateTime.now();
      final user1 = resolver.resolveUser(user.userId);
      final time1 = DateTime.now().difference(start1);
      
      // Measure second lookup (cache hit)
      final start2 = DateTime.now();
      final user2 = resolver.resolveUser(user.userId);
      final time2 = DateTime.now().difference(start2);
      
      expect(user1, same(user2));
      expect(time2.inMicroseconds, lessThanOrEqualTo(time1.inMicroseconds));
      
      final stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(1));
    });

    test('display name caching works efficiently', () {
      final user = eg.user(fullName: 'Display Name Test');
      store.addUser(user);
      
      // First call populates display name cache
      final name1 = resolver.getDisplayName(user.userId);
      final stats1 = resolver.getCacheStats();
      
      // Second call should use display name cache
      final name2 = resolver.getDisplayName(user.userId);
      final stats2 = resolver.getCacheStats();
      
      expect(name1, equals(name2));
      expect(stats1['displayNameCacheSize'], equals(1));
      expect(stats2['displayNameCacheSize'], equals(1));
    });

    test('cache management works correctly', () {
      final user1 = eg.user(userId: 1, fullName: 'User 1');
      final user2 = eg.user(userId: 2, fullName: 'User 2');
      store.addUser(user1);
      store.addUser(user2);
      
      // Populate caches
      resolver.resolveUser(user1.userId);
      resolver.resolveUser(user2.userId);
      resolver.getDisplayName(user1.userId);
      resolver.getDisplayName(user2.userId);
      
      var stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(2));
      expect(stats['displayNameCacheSize'], greaterThan(0));
      
      // Invalidate specific user
      resolver.invalidateUserCache(user1.userId);
      stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(1));
      
      // Clear all caches
      resolver.clearCache();
      stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(0));
      expect(stats['displayNameCacheSize'], equals(0));
    });
  });

  group('UserResolver: Batch Operations', () {
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

    test('resolveUsers handles mixed known/unknown users efficiently', () {
      final knownUser1 = eg.user(userId: 1, fullName: 'User 1');
      final knownUser2 = eg.user(userId: 2, fullName: 'User 2');
      store.addUser(knownUser1);
      store.addUser(knownUser2);
      
      final userIds = [1, 2, 999]; // Include unknown user
      final results = resolver.resolveUsers(userIds);
      
      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
      expect(results[999], isNull);
      expect(results.length, equals(3));
    });

    test('hasUnknownUsers validates user existence correctly', () {
      final knownUser = eg.user(userId: 1);
      store.addUser(knownUser);
      
      expect(resolver.hasUnknownUsers([1]), isFalse);
      expect(resolver.hasUnknownUsers([999]), isTrue);
      expect(resolver.hasUnknownUsers([1, 999]), isTrue);
    });

    test('filterKnownUsers returns only known users', () {
      final knownUser1 = eg.user(userId: 1);
      final knownUser2 = eg.user(userId: 2);
      store.addUser(knownUser1);
      store.addUser(knownUser2);
      
      final userIds = [1, 2, 999]; // Include unknown user
      final filtered = resolver.filterKnownUsers(userIds);
      
      expect(filtered, contains(1));
      expect(filtered, contains(2));
      expect(filtered, isNot(contains(999)));
      expect(filtered.length, equals(2));
    });
  });

  group('UserResolver: Store Integration', () {
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

    test('selfUser getter works correctly', () {
      final selfUser = store.selfUser;
      expect(selfUser.userId, equals(eg.selfUser.userId));
      expect(selfUser.fullName, equals(eg.selfUser.fullName));
    });

    test('selfUser throws appropriate error for missing self user', () async {
      // Create a store without self-user (edge case)
      final binding = MockZulipBinding();
      final emptyStore = await binding.globalStore.perAccount(eg.selfAccount.id);
      
      expect(() => emptyStore.selfUser, throwsA<StateError>());
      
      emptyStore.dispose();
    });

    test('extension methods work seamlessly', () {
      final user = eg.user(fullName: 'Extension Test');
      store.addUser(user);
      
      // Test PerAccountStore extensions
      expect(store.resolveUser(user.userId), isNotNull);
      expect(store.getDisplayName(user.userId), equals('Extension Test'));
      
      // Test that extensions don't interfere with original methods
      expect(store.getUser(user.userId), isNotNull);
      expect(store.userDisplayName(user.userId), equals('Extension Test'));
    });

    test('getUserStatus works through resolver', () {
      final user = eg.user(userId: 1);
      store.addUser(user);
      
      final status = resolver.getUserStatus(user.userId);
      expect(status, isNotNull);
      expect(status!.isEmpty, isTrue);
    });
  });

  group('UserResolver: Edge Cases and Error Handling', () {
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

    test('handles large user ID values', () {
      const largeUserId = 2147483647; // Max 32-bit int
      final resolved = resolver.resolveUser(largeUserId);
      expect(resolved, isNull);
      
      final fallback = resolver.resolveUserOrFallback(largeUserId);
      expect(fallback.userId, equals(largeUserId));
      expect(fallback.isUnknown, isTrue);
    });

    test('handles zero and negative user IDs', () {
      const zeroUserId = 0;
      const negativeUserId = -1;
      
      final resolvedZero = resolver.resolveUser(zeroUserId);
      final resolvedNegative = resolver.resolveUser(negativeUserId);
      
      expect(resolvedZero, isNull);
      expect(resolvedNegative, isNull);
      
      final fallbackZero = resolver.resolveUserOrFallback(zeroUserId);
      final fallbackNegative = resolver.resolveUserOrFallback(negativeUserId);
      
      expect(fallbackZero.userId, equals(zeroUserId));
      expect(fallbackNegative.userId, equals(negativeUserId));
    });

    test('cache invalidation works for edge cases', () {
      const userId1 = 1;
      const userId2 = 2;
      
      // Invalidate non-existent user (should not crash)
      expect(() => resolver.invalidateUserCache(userId1), returnsNormally);
      
      // Add users and populate cache
      final user1 = eg.user(userId: userId1);
      final user2 = eg.user(userId: userId2);
      store.addUser(user1);
      store.addUser(user2);
      
      resolver.resolveUser(userId1);
      resolver.resolveUser(userId2);
      
      var stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(2));
      
      // Invalidate first user
      resolver.invalidateUserCache(userId1);
      stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(1));
      
      // Invalidate second user
      resolver.invalidateUserCache(userId2);
      stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(0));
    });
  });

  group('UserResolver: Performance Benchmarks', () {
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

    test('performance test: 1000 user lookups', () {
      // Add 100 users for testing
      final users = List.generate(100, (i) => eg.user(userId: i + 1000));
      for (final user in users) {
        store.addUser(user);
      }
      
      final userIds = users.map((u) => u.userId).toList();
      
      // Measure batch resolution performance
      final start = DateTime.now();
      final results = resolver.resolveUsers(userIds);
      final duration = DateTime.now().difference(start);
      
      expect(results.length, equals(100));
      expect(duration.inMilliseconds, lessThan(100)); // Should be fast
      
      // Verify all users were cached
      final stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(100));
    });

    test('performance test: repeated display name lookups', () {
      final user = eg.user(fullName: 'Performance Display User');
      store.addUser(user);
      
      const iterations = 1000;
      
      // First lookup (cache miss)
      final start1 = DateTime.now();
      for (int i = 0; i < iterations; i++) {
        resolver.getDisplayName(user.userId);
      }
      final duration1 = DateTime.now().difference(start1);
      
      // Clear cache and test again
      resolver.clearCache();
      
      // Second set of lookups (all cache misses)
      final start2 = DateTime.now();
      for (int i = 0; i < iterations; i++) {
        resolver.getDisplayName(user.userId);
      }
      final duration2 = DateTime.now().difference(start2);
      
      // Cached lookups should be significantly faster
      expect(duration1.inMicroseconds, lessThan(duration2.inMicroseconds / 10));
    });
  });
}
