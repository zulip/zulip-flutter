import 'package:flutter/foundation.dart';

import '../api/model/model.dart';
import 'store.dart';

/// A utility class for efficient and safe user resolution.
///
/// This class centralizes user lookup logic and provides null-safe
/// lookups with intelligent fallbacks to address issue #716.
class UserResolver {
  UserResolver(this._store);

  final PerAccountStore _store;

  final Map<int, User?> _userCache = <int, User?>{};

  User? resolveUser(int userId) {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final user = _store.getUser(userId);
    _userCache[userId] = user;
    return user;
  }

  User resolveUserOrFallback(int userId, {String? fallbackName}) {
    final user = resolveUser(userId);
    if (user != null) return user;

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
    } else if (messageContext != null && messageContext.senderId == userId) {
      return messageContext.senderFullName;
    } else {
      return fallbackName ?? 'Unknown user';
    }
  }

  String getSenderDisplayName(Message message) {
    if (_store.isUserMuted(message.senderId)) {
      return 'Muted user';
    }

    final user = resolveUser(message.senderId);
    if (user != null) {
      return user.fullName;
    } else {
      return message.senderFullName;
    }
  }

  Map<int, User?> resolveUsers(List<int> userIds) {
    final result = <int, User?>{};
    for (final userId in userIds) {
      result[userId] = resolveUser(userId);
    }
    return result;
  }

  void clearCache() {
    _userCache.clear();
  }

  void clearUserCache(int userId) {
    _userCache.remove(userId);
  }
}

extension PerAccountStoreUserResolver on PerAccountStore {
  UserResolver get userResolver => UserResolver(this);

  User? resolveUser(int userId) => userResolver.resolveUser(userId);

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

extension UserExtensions on User {
  bool get isUnknown => email.startsWith('unknown-') && email.endsWith('@example.com');

  String get safeDisplayName => isUnknown ? fullName : (fullName.isNotEmpty ? fullName : email);
}
