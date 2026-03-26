import 'dart:async';

import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

/// A utility class for efficient and safe user resolution.
///
/// This class centralizes user lookup logic and provides null-safe
/// lookups with intelligent fallbacks to address issue #716.
/// Follows Zulip's coding conventions and patterns.
class UserResolver {
  UserResolver(this._store);

  final PerAccountStore _store;

  final Map<int, User?> _userCache = <int, User?>{};

  /// Get a user with null safety.
  ///
  /// Returns the user if found, null otherwise.
  /// Uses caching to avoid repeated lookups.
  User? resolveUser(int userId) {
    final cachedUser = _userCache[userId];
    if (cachedUser != null) {
      return cachedUser;
    }

    final user = _store.getUser(userId);
    _userCache[userId] = user;
    return user;
  }

  /// Get a user with guaranteed non-null result.
  ///
  /// Creates a synthetic user if the user is not found.
  /// This ensures callers never get null results.
  User resolveUserOrFallback(int userId, {String? fallbackName}) {
    final user = resolveUser(userId);
    if (user != null) {
      return user;
    }

    // Create a synthetic user for unknown users
    return User(
      userId: userId,
      deliveryEmail: null,
      email: 'unknown-$userId@example.com',
      fullName: fallbackName ?? 'Unknown user',
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
  }

  /// Get display name with intelligent fallbacks.
  ///
  /// Handles muted users, unknown users, and message context.
  /// Provides consistent display names across the application.
  String getDisplayName(
    int userId, {
    bool replaceIfMuted = true,
    Message? messageContext,
    String? fallbackName,
  }) {
    if (replaceIfMuted && _store.isUserMuted(userId)) {
      return 'Muted user';
    }

    final user = resolveUser(userId);
    if (user != null) {
      return user.fullName;
    }

    if (messageContext != null && messageContext.senderId == userId) {
      return messageContext.senderFullName;
    }

    return fallbackName ?? 'Unknown user';
  }

  /// Get display name for a message sender.
  ///
  /// Optimized for message display with context awareness.
  String getSenderDisplayName(Message message) {
    if (_store.isUserMuted(message.senderId)) {
      return 'Muted user';
    }

    final user = resolveUser(message.senderId);
    if (user != null) {
      return user.fullName;
    }

    return message.senderFullName;
  }

  /// Resolve multiple users efficiently.
  ///
  /// Returns a map of user IDs to users (null if not found).
  /// Uses caching for optimal performance.
  Map<int, User?> resolveUsers(List<int> userIds) {
    final result = <int, User?>{};
    for (final userId in userIds) {
      result[userId] = resolveUser(userId);
    }
    return result;
  }

  /// Clear all cached users.
  ///
  /// Useful for testing or when user data changes.
  void clearCache() {
    _userCache.clear();
  }

  /// Clear cache for a specific user.
  ///
  /// Useful when a single user's data changes.
  void clearUserCache(int userId) {
    _userCache.remove(userId);
  }
}

/// Extension methods for PerAccountStore to provide UserResolver access.
extension PerAccountStoreUserResolver on PerAccountStore {
  /// Get a UserResolver for this store.
  UserResolver get userResolver => UserResolver(this);

  /// Safe user lookup with intelligent fallbacks.
  ///
  /// Convenience method that uses UserResolver internally.
  User? resolveUser(int userId) => userResolver.resolveUser(userId);

  /// Get display name with intelligent fallbacks.
  ///
  /// Convenience method that uses UserResolver internally.
  String getDisplayName(
    int userId, {
    bool replaceIfMuted = true,
    Message? messageContext,
  }) => userResolver.getDisplayName(
    userId,
    replaceIfMuted: replaceIfMuted,
    messageContext: messageContext,
  );
}

/// Extension methods for User to provide additional utilities.
extension UserExtensions on User {
  /// Check if this user is effectively unknown/synthetic.
  bool get isUnknown => email.startsWith('unknown-') && email.endsWith('@example.com');

  /// Get a safe display name that works even for synthetic users.
  String get safeDisplayName => isUnknown ? fullName : (fullName.isNotEmpty ? fullName : email);
}
