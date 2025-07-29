import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import 'algorithms.dart';
import 'localizations.dart';
import 'narrow.dart';
import 'realm.dart';
import 'store.dart';

/// The portion of [PerAccountStore] describing the users in the realm.
mixin UserStore on PerAccountStoreBase, RealmStore {
  @protected
  RealmStore get realmStore;

  /// The user with the given ID, if that user is known.
  ///
  /// There may be other users that are perfectly real but are
  /// not known to the app, for multiple reasons:
  ///
  ///  * The self-user may not have permission to see all the users in the
  ///    realm, for example because the self-user is a guest.
  ///
  ///  * Because of the fetch/event race, any data that the client fetched
  ///    outside of the event system may reflect an earlier or later time
  ///    than this data, which is maintained by the event system.
  ///    This includes messages fetched for a message list, and notifications.
  ///    Those may therefore refer to users for which we have yet to see the
  ///    [RealmUserAddEvent], or have already handled a [RealmUserRemoveEvent].
  ///
  /// Code that looks up a user here should therefore always handle
  /// the possibility that the user is not found (except
  /// where there is a specific reason to know the user should be found).
  /// Consider using [userDisplayName].
  User? getUser(int userId);

  /// All known users in the realm, including deactivated users.
  ///
  /// Before presenting these users in the UI, consider whether to exclude
  /// users who are deactivated (see [User.isActive]) or muted ([isUserMuted]).
  ///
  /// This may have a large number of elements, like tens of thousands.
  /// Consider [getUser] or other alternatives to iterating through this.
  ///
  /// There may be perfectly real users which are not known
  /// and so are not found here.  For details, see [getUser].
  Iterable<User> get allUsers;

  /// The [User] object for the "self-user",
  /// i.e. the account the person using this app is logged into.
  ///
  /// When only the user ID is needed, see [selfUserId].
  User get selfUser => getUser(selfUserId)!;

  /// The name to show the given user as in the UI, even for unknown users.
  ///
  /// If the user is muted and [replaceIfMuted] is true (the default),
  /// this is [ZulipLocalizations.mutedUser].
  ///
  /// Otherwise this is the user's [User.fullName] if the user is known,
  /// or (if unknown) [ZulipLocalizations.unknownUserName].
  ///
  /// When a [Message] is available which the user sent,
  /// use [senderDisplayName] instead for a better-informed fallback.
  String userDisplayName(int userId, {bool replaceIfMuted = true}) {
    if (replaceIfMuted && isUserMuted(userId)) {
      return GlobalLocalizations.zulipLocalizations.mutedUser;
    }
    return getUser(userId)?.fullName
      ?? GlobalLocalizations.zulipLocalizations.unknownUserName;
  }

  /// The name to show for the given message's sender in the UI.
  ///
  /// If the sender is muted and [replaceIfMuted] is true (the default),
  /// this is [ZulipLocalizations.mutedUser].
  ///
  /// Otherwise, if the user is known (see [getUser]),
  /// this is their current [User.fullName].
  /// If unknown, this uses the fallback value conveniently provided on the
  /// [Message] object itself, namely [Message.senderFullName].
  ///
  /// For a user who isn't the sender of some known message,
  /// see [userDisplayName].
  String senderDisplayName(Message message, {bool replaceIfMuted = true}) {
    final senderId = message.senderId;
    if (replaceIfMuted && isUserMuted(senderId)) {
      return GlobalLocalizations.zulipLocalizations.mutedUser;
    }
    return getUser(senderId)?.fullName ?? message.senderFullName;
  }

  /// The user's real email address, if known, for displaying in the UI.
  ///
  /// Returns null if self-user isn't able to see the user's real email address,
  /// or if the user isn't actually a user we know about.
  String? userDisplayEmail(int userId) => getUser(userId)?.deliveryEmail;

  /// Whether [user] has passed the realm's waiting period to be a full member.
  ///
  /// See:
  ///   https://zulip.com/api/roles-and-permissions#determining-if-a-user-is-a-full-member
  ///
  /// To determine if a user is a full member, callers must also check that the
  /// user's role is at least [UserRole.member].
  bool hasPassedWaitingPeriod(User user, {required DateTime byDate}) {
    // [User.dateJoined] is in UTC. For logged-in users, the format is:
    // YYYY-MM-DDTHH:mm+00:00, which includes the timezone offset for UTC.
    // For logged-out spectators, the format is: YYYY-MM-DD, which doesn't
    // include the timezone offset. In the later case, [DateTime.parse] will
    // interpret it as the client's local timezone, which could lead to
    // incorrect results; but that's acceptable for now because the app
    // doesn't support viewing as a spectator.
    //
    // See the related discussion:
    //   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/provide.20an.20explicit.20format.20for.20.60realm_user.2Edate_joined.60/near/1980194
    final dateJoined = DateTime.parse(user.dateJoined);
    return byDate.difference(dateJoined).inDays >= realmWaitingPeriodThreshold;
  }

  /// Whether the user with [userId] is muted by the self-user.
  ///
  /// Looks for [userId] in a private [Set],
  /// or in [event.mutedUsers] instead if event is non-null.
  bool isUserMuted(int userId, {MutedUsersEvent? event});

  /// Whether the self-user has muted everyone in [narrow].
  ///
  /// Returns false for the self-DM.
  ///
  /// Calls [isUserMuted] for each participant, passing along [event].
  bool shouldMuteDmConversation(DmNarrow narrow, {MutedUsersEvent? event}) {
    if (narrow.otherRecipientIds.isEmpty) return false;
    return narrow.otherRecipientIds.every(
      (userId) => isUserMuted(userId, event: event));
  }

  /// Whether the given event might change the result of [shouldMuteDmConversation]
  /// for its list of muted users, compared to the current state.
  MutedUsersVisibilityEffect mightChangeShouldMuteDmConversation(MutedUsersEvent event);

  /// The status of the user with the given ID.
  ///
  /// If no status is set for the user, returns [UserStatus.zero].
  UserStatus getUserStatus(int userId);
}

/// Whether and how a given [MutedUsersEvent] may affect the results
/// that [UserStore.shouldMuteDmConversation] would give for some messages.
enum MutedUsersVisibilityEffect {
  /// The event will have no effect on the visibility results.
  none,

  /// The event may change some visibility results from true to false.
  muted,

  /// The event may change some visibility results from false to true.
  unmuted,

  /// The event may change some visibility results from false to true,
  /// and some from true to false.
  mixed;
}

mixin ProxyUserStore on UserStore {
  @protected
  UserStore get userStore;

  @override
  User? getUser(int userId) => userStore.getUser(userId);

  @override
  Iterable<User> get allUsers => userStore.allUsers;

  @override
  bool isUserMuted(int userId, {MutedUsersEvent? event}) =>
    userStore.isUserMuted(userId, event: event);

  @override
  MutedUsersVisibilityEffect mightChangeShouldMuteDmConversation(MutedUsersEvent event) =>
    userStore.mightChangeShouldMuteDmConversation(event);

  @override
  UserStatus getUserStatus(int userId) => userStore.getUserStatus(userId);
}

/// A base class for [PerAccountStore] substores that need access to [UserStore]
/// as well as to its prerequisites [CorePerAccountStore] and [RealmStore].
abstract class HasUserStore extends HasRealmStore with UserStore, ProxyUserStore {
  HasUserStore({required UserStore users})
    : userStore = users, super(realm: users.realmStore);

  @protected
  @override
  final UserStore userStore;
}

/// The implementation of [UserStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [UserStore] which describes its interface.
class UserStoreImpl extends HasRealmStore with UserStore {
  UserStoreImpl({
    required super.realm,
    required InitialSnapshot initialSnapshot,
  }) : _users = Map.fromEntries(
         initialSnapshot.realmUsers
         .followedBy(initialSnapshot.realmNonActiveUsers)
         .followedBy(initialSnapshot.crossRealmBots)
         .map((user) => MapEntry(user.userId, user))),
       _mutedUsers = Set.from(initialSnapshot.mutedUsers.map((item) => item.id)),
       _userStatuses = initialSnapshot.userStatuses.map((userId, change) =>
         MapEntry(userId, change.apply(UserStatus.zero)));

  final Map<int, User> _users;

  @override
  User? getUser(int userId) => _users[userId];

  @override
  Iterable<User> get allUsers => _users.values;

  final Set<int> _mutedUsers;

  @override
  bool isUserMuted(int userId, {MutedUsersEvent? event}) {
    return (event?.mutedUsers.map((item) => item.id) ?? _mutedUsers).contains(userId);
  }

  @override
  MutedUsersVisibilityEffect mightChangeShouldMuteDmConversation(MutedUsersEvent event) {
    final sortedOld = _mutedUsers.toList()..sort();
    final sortedNew = event.mutedUsers.map((u) => u.id).toList()..sort();
    assert(isSortedWithoutDuplicates(sortedOld));
    assert(isSortedWithoutDuplicates(sortedNew));
    final union = setUnion(sortedOld, sortedNew);

    final willMuteSome = sortedOld.length < union.length;
    final willUnmuteSome = sortedNew.length < union.length;

    switch ((willUnmuteSome, willMuteSome)) {
      case (true, false):
        return MutedUsersVisibilityEffect.unmuted;
      case (false, true):
        return MutedUsersVisibilityEffect.muted;
      case (true, true):
        return MutedUsersVisibilityEffect.mixed;
      case (false, false): // TODO(log)?
        return MutedUsersVisibilityEffect.none;
    }
  }

  final Map<int, UserStatus> _userStatuses;

  @override
  UserStatus getUserStatus(int userId) => _userStatuses[userId] ?? UserStatus.zero;

  void handleRealmUserEvent(RealmUserEvent event) {
    switch (event) {
      case RealmUserAddEvent():
        _users[event.person.userId] = event.person;

      case RealmUserRemoveEvent():
        _users.remove(event.userId);

      case RealmUserUpdateEvent():
        final user = _users[event.userId];
        if (user == null) {
          return; // TODO log
        }
        if (event.fullName != null)       user.fullName       = event.fullName!;
        if (event.avatarUrl != null)      user.avatarUrl      = event.avatarUrl!;
        if (event.avatarVersion != null)  user.avatarVersion  = event.avatarVersion!;
        if (event.timezone != null)       user.timezone       = event.timezone!;
        if (event.botOwnerId != null)     user.botOwnerId     = event.botOwnerId!;
        if (event.role != null)           user.role           = event.role!;
        if (event.isBillingAdmin != null) user.isBillingAdmin = event.isBillingAdmin!;
        if (event.deliveryEmail != null)  user.deliveryEmail  = event.deliveryEmail!.value;
        if (event.newEmail != null)       user.email          = event.newEmail!;
        if (event.isActive != null)       user.isActive       = event.isActive!;
        if (event.customProfileField != null) {
          final profileData = (user.profileData ??= {});
          final update = event.customProfileField!;
          if (update.value != null) {
            profileData[update.id] = ProfileFieldUserData(value: update.value!, renderedValue: update.renderedValue);
          } else {
            profileData.remove(update.id);
          }
          if (profileData.isEmpty) {
            // null is equivalent to `{}` for efficiency; see [User._readProfileData].
            user.profileData = null;
          }
        }
    }
  }

  void handleUserStatusEvent(UserStatusEvent event) {
    _userStatuses[event.userId] =
      event.change.apply(getUserStatus(event.userId));
  }

  void handleMutedUsersEvent(MutedUsersEvent event) {
    _mutedUsers.clear();
    _mutedUsers.addAll(event.mutedUsers.map((item) => item.id));
  }
}
