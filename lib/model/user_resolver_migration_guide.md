# UserResolver Migration Guide

This guide shows how to migrate existing code to use the new `UserResolver` system to address issue #716 efficiently.

## Problem Solved

The original issue #716 requires handling unknown users everywhere in the codebase. The current approach has several problems:
- Repetitive null-checking code
- Inconsistent fallback handling
- Performance issues with repeated lookups
- No centralized caching

## Solution Overview

The `UserResolver` class provides:
- **Null-safe user lookups** with intelligent fallbacks
- **Caching mechanisms** for better performance
- **Convenience methods** for common operations
- **Multipurpose utilities** beyond just unknown user handling

## Migration Patterns

### 1. Basic User Lookup

**Before:**
```dart
final user = store.getUser(userId);
if (user == null) {
  return; // or handle error
}
// use user...
```

**After:**
```dart
final user = store.userResolver.resolveUser(userId);
if (user == null) {
  return; // or handle error
}
// use user...
```

### 2. Guaranteed Non-Null User

**Before:**
```dart
final user = store.getUser(userId)!; // Unsafe!
```

**After:**
```dart
final user = store.userResolver.resolveUserOrFallback(userId);
// Always returns a valid User object
```

### 3. Display Name with Fallbacks

**Before:**
```dart
String getSenderName(Message message) {
  final user = store.getUser(message.senderId);
  if (user != null) {
    return user.fullName;
  } else {
    return message.senderFullName;
  }
}
```

**After:**
```dart
String getSenderName(Message message) {
  return store.userResolver.getSenderDisplayName(message);
}
```

### 4. Self-User Access

**Before:**
```dart
final selfUser = store.getUser(selfUserId)!; // Unsafe
```

**After:**
```dart
final selfUser = store.selfUser; // Safe and efficient
```

### 5. Batch User Operations

**Before:**
```dart
final users = userIds.map((id) => store.getUser(id)).toList();
// Handle nulls individually...
```

**After:**
```dart
final users = store.userResolver.resolveUsers(userIds);
// Already null-safe
```

### 6. Unknown User Validation

**Before:**
```dart
bool hasUnknownUsers(List<int> userIds) {
  return userIds.any((id) => store.getUser(id) == null);
}
```

**After:**
```dart
bool hasUnknownUsers(List<int> userIds) {
  return store.userResolver.hasUnknownUsers(userIds);
}
```

## Performance Benefits

1. **Caching**: Frequently accessed users are cached
2. **Batch Operations**: Reduced individual lookups
3. **Intelligent Fallbacks**: Avoid repeated string operations
4. **Memory Management**: Cache invalidation and cleanup

## Additional Features

### Cache Management
```dart
// Clear all caches (useful for testing or memory management)
store.userResolver.clearCache();

// Invalidate specific user cache
store.userResolver.invalidateUserCache(userId);

// Get cache statistics for debugging
final stats = store.userResolver.getCacheStats();
```

### Advanced Fallbacks
```dart
// Custom fallback name for unknown users
final user = store.userResolver.resolveUserOrFallback(
  userId, 
  fallbackName: 'Deleted User'
);

// Display name with custom fallback
final displayName = store.userResolver.getDisplayName(
  userId,
  fallbackName: 'Unknown Person'
);
```

## Files to Update

Based on the codebase analysis, prioritize these files:

### High Priority (Direct User Lookups)
- `lib/widgets/user.dart` - Line 66: `store.getUser(userId)`
- `lib/widgets/profile.dart` - Line 53: `store.getUser(userId)`
- `lib/widgets/message_list.dart` - Line 1337, 1357, 2091: `store.getUser(...)`
- `lib/widgets/compose_box.dart` - Line 902, 2269, 2276: `store.getUser(...)`
- `lib/widgets/recent_dm_conversations.dart` - Line 141: `store.getUser(id)`

### Medium Priority (Display Names)
- `lib/model/user.dart` - Line 70, 91: `getUser(...)?.fullName ?? fallback`
- Any file using `userDisplayName` or `senderDisplayName`

### Low Priority (Test Files)
- Test files can use the new system for better test coverage

## Migration Strategy

1. **Phase 1**: Add UserResolver imports and replace direct `getUser` calls
2. **Phase 2**: Replace display name logic with `getDisplayName`/`getSenderDisplayName`
3. **Phase 3**: Replace `selfUser` access with the new getter
4. **Phase 4**: Add batch operations where applicable
5. **Phase 5**: Add cache management for long-running operations

## Testing Considerations

The new system is designed to be backward compatible, but tests should be updated to:

1. Test unknown user scenarios explicitly
2. Verify cache behavior
3. Test performance with large user sets
4. Validate fallback name logic

## Benefits Beyond Issue #716

While primarily solving the unknown user issue, this system provides:

- **Better Performance**: Caching and batch operations
- **Cleaner Code**: Centralized user logic
- **Future Extensibility**: Easy to add new user-related features
- **Better Testing**: Isolated user resolution logic
- **Memory Efficiency**: Controlled cache management

## Example Complete Migration

**Before:**
```dart
Widget buildUserRow(int userId) {
  final user = store.getUser(userId);
  if (user == null) {
    return Text('Unknown User');
  }
  
  final displayName = store.isUserMuted(userId) 
    ? 'Muted User' 
    : user.fullName;
    
  return Row([
    Avatar(userId: userId),
    Text(displayName),
  ]);
}
```

**After:**
```dart
Widget buildUserRow(int userId) {
  final displayName = store.userResolver.getDisplayName(userId);
  
  return Row([
    Avatar(userId: userId),
    Text(displayName),
  ]);
}
```

The new code is:
- **Shorter** (8 lines vs 14 lines)
- **Safer** (no null risks)
- **More efficient** (cached lookups)
- **More consistent** (standardized fallbacks)
