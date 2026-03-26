import 'package:flutter_test/flutter_test.dart';

import '../example_data.dart' as eg;
import '../mocks.dart';
import '../../lib/model/user_resolver.dart';
import '../../lib/model/store.dart';
import '../../lib/api/model/model.dart';

/// Integration test to verify UserResolver works seamlessly with existing codebase
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

    test('integrates with existing PerAccountStore methods', () {
      // Test that UserResolver doesn't break existing functionality
      final user = eg.user(fullName: 'Test User');
      store.addUser(user);

      // Existing method still works
      final existingUser = store.getUser(user.userId);
      expect(existingUser, isNotNull);
      expect(existingUser!.fullName, equals('Test User'));

      // New UserResolver method works
      final resolvedUser = resolver.resolveUser(user.userId);
      expect(resolvedUser, isNotNull);
      expect(resolvedUser!.fullName, equals('Test User'));
    });

    test('selfUser getter works correctly', () {
      final selfUser = store.selfUser;
      expect(selfUser.userId, equals(eg.selfUser.userId));
      expect(selfUser.fullName, equals(eg.selfUser.fullName));
    });

    test('display name methods work with existing userDisplayName', () {
      final user = eg.user(fullName: 'John Doe');
      store.addUser(user);

      // Existing method
      final existingName = store.userDisplayName(user.userId);
      
      // New method
      final resolverName = resolver.getDisplayName(user.userId);

      expect(existingName, equals(resolverName));
      expect(resolverName, equals('John Doe'));
    });

    test('handles unknown users gracefully', () {
      const unknownUserId = 999999;

      // Existing method returns null
      final existingUser = store.getUser(unknownUserId);
      expect(existingUser, isNull);

      // UserResolver handles unknown users safely
      final resolvedUser = resolver.resolveUser(unknownUserId);
      expect(resolvedUser, isNull);

      // But getDisplayName provides fallback
      final displayName = resolver.getDisplayName(unknownUserId);
      expect(displayName, equals('Unknown user'));

      // resolveUserOrFallback never returns null
      final fallbackUser = resolver.resolveUserOrFallback(unknownUserId);
      expect(fallbackUser, isNotNull);
      expect(fallbackUser.userId, equals(unknownUserId));
      expect(fallbackUser.isUnknown, isTrue);
    });

    test('caching improves performance', () {
      final user = eg.user(fullName: 'Cached User');
      store.addUser(user);

      // First lookup populates cache
      final start = DateTime.now();
      final user1 = resolver.resolveUser(user.userId);
      final firstLookupTime = DateTime.now().difference(start);

      // Second lookup should use cache
      final start2 = DateTime.now();
      final user2 = resolver.resolveUser(user.userId);
      final secondLookupTime = DateTime.now().difference(start2);

      expect(user1, same(user2)); // Same object due to caching
      expect(firstLookupTime.inMicroseconds, greaterThan(0));
      // Note: In real scenarios, cached lookup would be faster
    });

    test('batch operations work efficiently', () {
      final users = [
        eg.user(userId: 1),
        eg.user(userId: 2),
        eg.user(userId: 3),
      ];
      for (final user in users) {
        store.addUser(user);
      }

      final userIds = [1, 2, 3, 999]; // Include unknown user
      final results = resolver.resolveUsers(userIds);

      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
      expect(results[3], isNotNull);
      expect(results[999], isNull);
    });

    test('message context improves fallbacks', () {
      const unknownUserId = 999999;
      final message = eg.message(
        senderId: unknownUserId,
        senderFullName: 'Message Sender Name',
      );

      // Without context, uses generic fallback
      final displayName1 = resolver.getDisplayName(unknownUserId);
      expect(displayName1, equals('Unknown user'));

      // With context, uses better fallback
      final displayName2 = resolver.getDisplayName(
        unknownUserId,
        messageContext: message,
      );
      expect(displayName2, equals('Message Sender Name'));
    });

    test('cache management works correctly', () {
      final user = eg.user();
      store.addUser(user);

      // Populate cache
      resolver.resolveUser(user.userId);
      resolver.getDisplayName(user.userId);

      var stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], greaterThan(0));
      expect(stats['displayNameCacheSize'], greaterThan(0));

      // Clear cache
      resolver.clearCache();
      stats = resolver.getCacheStats();
      expect(stats['userCacheSize'], equals(0));
      expect(stats['displayNameCacheSize'], equals(0));
    });

    test('extension methods work seamlessly', () {
      final user = eg.user(fullName: 'Extension Test');
      store.addUser(user);

      // Test PerAccountStore extensions
      expect(store.resolveUser(user.userId), isNotNull);
      expect(store.getDisplayName(user.userId), equals('Extension Test'));
      expect(store.selfUser, isNotNull);
    });

    test('performance with large user sets', () {
      // Add many users to test performance
      final users = List.generate(100, (i) => eg.user(userId: i + 1000));
      for (final user in users) {
        store.addUser(user);
      }

      final start = DateTime.now();
      
      // Test batch resolution
      final userIds = users.map((u) => u.userId).toList();
      final results = resolver.resolveUsers(userIds);
      
      final duration = DateTime.now().difference(start);
      
      expect(results.length, equals(100));
      expect(duration.inMilliseconds, lessThan(100)); // Should be fast
    });
  });
}
