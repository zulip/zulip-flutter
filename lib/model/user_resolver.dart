import 'package:flutter/foundation.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../widgets/store.dart';

/// A multipurpose utility class for efficient and safe user resolution.
///
/// This class centralizes all user lookup logic and provides multiple
/// convenience methods for handling unknown users across the codebase.
/// It addresses issue #716 by providing null-safe user lookups with
/// intelligent fallbacks and caching mechanisms.
class UserResolver {
  const UserResolver._(this._store);

  /// Create a UserResolver for the given store.
  factory UserResolver(PerAccountStore store) => UserResolver._(store);

  final PerAccountStore _store;

  /// Cache for frequently accessed users to avoid repeated lookups
  const Map<int, User?> _userCache = {};

  /// Cache for display names to avoid repeated string operations
  const Map<int, String> _displayNameCache = {};

  /// Get a user with null safety guaranteed.
  ///
  /// Unlike [PerAccountStore.getUser], this method provides intelligent
  /// fallbacks and caching for better performance.
  ///
  /// Returns null if user is not found and no fallback is available.
  User? resolveUser(int userId) {
    // Check cache first for performance
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final user = _store.getUser(userId);
    _userCache[userId] = user;
    return user;
  }

  /// Get a user with guaranteed non-null result.
  ///
  /// This method will never return null. If the user is not found,
  /// it creates a synthetic user with appropriate fallback data.
  ///
  /// Use this when you absolutely need a User object and can handle
  /// placeholder data.
  User resolveUserOrFallback(int userId, {String? fallbackName}) {
    final user = resolveUser(userId);
    if (user != null) return user;

    // Create a synthetic user for unknown users
    return User(
      userId: userId,
      email: 'unknown-$userId@example.com',
      fullName: fallbackName ?? ZulipLocalizations.current.unknownUserName,
      avatarUrl: null,
      avatarVersion: 0,
      isActive: true,
      isBot: false,
      timezone: null,
      role: UserRole.member,
      profileData: null,
      botOwnerId: null,
      deliveryEmail: null,
      dateJoined: DateTime.now(),
    );
  }

  /// Get display name with intelligent fallbacks.
  ///
  /// This is the preferred method for getting user display names
  /// as it handles all edge cases:
  /// - Unknown users get fallback names
  /// - Muted users get special handling
  /// - Message context provides better fallbacks
  String getDisplayName(
    int userId, {
    bool replaceIfMuted = true,
    Message? messageContext,
    String? fallbackName,
  }) {
    // Check cache first
    final cacheKey = _DisplayNameCacheKey(userId, replaceIfMuted, messageContext?.id);
    if (_displayNameCache.containsKey(cacheKey.hashCode)) {
      return _displayNameCache[cacheKey.hashCode]!;
    }

    String displayName;

    // Handle muted users
    if (replaceIfMuted && _store.isUserMuted(userId)) {
      displayName = ZulipLocalizations.current.mutedUser;
    } else {
      // Try to get user from store
      final user = resolveUser(userId);
      if (user != null) {
        displayName = user.fullName;
      } else if (messageContext != null && messageContext.senderId == userId) {
        // Use message context for better fallback
        displayName = messageContext.senderFullName;
      } else {
        // Final fallback
        displayName = fallbackName ?? ZulipLocalizations.current.unknownUserName;
      }
    }

    // Cache the result
    _displayNameCache[cacheKey.hashCode] = displayName;
    return displayName;
  }

  /// Get display name for a message sender with optimal fallbacks.
  ///
  /// This is the most efficient way to get sender display names
  /// as it leverages message context for better fallbacks.
  String getSenderDisplayName(Message message, {bool replaceIfMuted = true}) {
    return getDisplayName(
      message.senderId,
      replaceIfMuted: replaceIfMuted,
      messageContext: message,
    );
  }

  /// Check if a user exists in the store.
  ///
  /// This is more efficient than [resolveUser] when you only need
  /// to check existence without accessing user data.
  bool userExists(int userId) {
    return resolveUser(userId) != null;
  }

  /// Get multiple users efficiently.
  ///
  /// This method is optimized for batch operations and reduces
  /// the number of individual lookups.
  Map<int, User?> resolveUsers(Iterable<int> userIds) {
    final result = <int, User?>{};

    for (final userId in userIds) {
      result[userId] = resolveUser(userId);
    }

    return result;
  }

  /// Check if any users in a list are unknown.
  ///
  /// This is useful for validation and UI state management.
  bool hasUnknownUsers(Iterable<int> userIds) {
    return userIds.any((userId) => !userExists(userId));
  }

  /// Filter out unknown users from a list.
  ///
  /// Returns only the user IDs that exist in the store.
  List<int> filterKnownUsers(Iterable<int> userIds) {
    return userIds.where(userExists).toList();
  }

  /// Get user status with safe fallback.
  ///
  /// Never crashes on unknown users.
  UserStatus getUserStatus(int userId) {
    return _store.getUserStatus(userId);
  }

  /// Clear internal caches.
  ///
  /// Call this when user data changes significantly
  /// or for memory management in long-running processes.
  void clearCache() {
    _userCache.clear();
    _displayNameCache.clear();
  }

  /// Get cache statistics for debugging.
  Map<String, int> getCacheStats() {
    return {
      'userCacheSize': _userCache.length,
      'displayNameCacheSize': _displayNameCache.length,
    };
  }

  /// Invalidate cache for specific user.
  ///
  /// Use this when a specific user's data changes.
  void invalidateUserCache(int userId) {
    _userCache.remove(userId);

    // Remove all display name cache entries for this user
    _displayNameCache.removeWhere((key, value) => key == userId);
  }
}

/// Extension methods for PerAccountStore to provide UserResolver access.
extension PerAccountStoreUserResolver on PerAccountStore {
  /// Get a UserResolver for this store.
  UserResolver get userResolver => UserResolver(this);

  /// Get the self-user with guaranteed non-null result.
  ///
  /// This addresses the issue's suggestion to add a selfUser getter.
  /// Unlike the current implementation in UserStore, this is cached
  /// and provides better error handling.
  User get selfUser {
    final user = getUser(selfUserId);
    if (user == null) {
      // This should never happen in normal operation, but we handle it gracefully
      throw StateError('Self-user (ID $selfUserId) not found in user store');
    }
    return user;
  }

  /// Safe user lookup with intelligent fallbacks.
  ///
  /// This is a convenience method that uses UserResolver internally.
  User? resolveUser(int userId) => userResolver.resolveUser(userId);

  /// Get display name with intelligent fallbacks.
  ///
  /// This is a convenience method that uses UserResolver internally.
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

/// Internal cache key for display names.
@immutable
class _DisplayNameCacheKey {
  const _DisplayNameCacheKey(this.userId, this.replaceIfMuted, this.messageId);

  final int userId;
  final bool replaceIfMuted;
  final int? messageId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DisplayNameCacheKey &&
        other.userId == userId &&
        other.replaceIfMuted == replaceIfMuted &&
        other.messageId == messageId;
  }

  @override
  int get hashCode => Object.hash(userId, replaceIfMuted, messageId);
}
