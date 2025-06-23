import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import 'localizations.dart';
import 'store.dart';

/// The portion of [PerAccountStore] describing the users in the realm.
mixin UserStore on PerAccountStoreBase {
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

  /// All known users in the realm.
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
  /// This is the user's [User.fullName] if the user is known,
  /// and otherwise a translation of "(unknown user)".
  ///
  /// When a [Message] is available which the user sent,
  /// use [senderDisplayName] instead for a better-informed fallback.
  String userDisplayName(int userId) {
    return getUser(userId)?.fullName
      ?? GlobalLocalizations.zulipLocalizations.unknownUserName;
  }

  /// The name to show for the given message's sender in the UI.
  ///
  /// If the user is known (see [getUser]), this is their current [User.fullName].
  /// If unknown, this uses the fallback value conveniently provided on the
  /// [Message] object itself, namely [Message.senderFullName].
  ///
  /// For a user who isn't the sender of some known message,
  /// see [userDisplayName].
  String senderDisplayName(Message message) {
    return getUser(message.senderId)?.fullName
      ?? message.senderFullName;
  }

  /// Whether the user with [userId] is muted by the self-user.
  ///
  /// Looks for [userId] in a private [Set],
  /// or in [event.mutedUsers] instead if event is non-null.
  bool isUserMuted(int userId, {MutedUsersEvent? event});

  /// The status of the user with the given ID, or `null` if no status is set.
  UserStatus? getUserStatus(int userId);
}

/// The implementation of [UserStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [UserStore] which describes its interface.
class UserStoreImpl extends PerAccountStoreBase with UserStore {
  UserStoreImpl({
    required super.core,
    required InitialSnapshot initialSnapshot,
  }) : _users = Map.fromEntries(
         initialSnapshot.realmUsers
         .followedBy(initialSnapshot.realmNonActiveUsers)
         .followedBy(initialSnapshot.crossRealmBots)
         .map((user) => MapEntry(user.userId, user))),
       _mutedUsers = Set.from(initialSnapshot.mutedUsers.map((item) => item.id)),
       _userStatuses = initialSnapshot.userStatuses;

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

  final Map<int, UserStatus> _userStatuses;

  @override
  UserStatus? getUserStatus(int userId) => _userStatuses[userId];

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
    final UserStatusEvent(
      :userId, :statusText, :emojiName, :emojiCode, :reactionType) = event;

    final oldStatus = _userStatuses[userId];
    // Here's what the different values of a property in the event mean and how
    // they affect the corresponding values in the resulting new status:
    //  - Value is `null` -> property is not changed -> value in the new status
    //    is the same as in the old status, or `null` if status wasn't set before.
    //  - Value is empty -> property is cleared -> value in the new status is `null`.
    //  - Value is not empty -> property is set - value in the new status is the
    //    same as the value from the event.
    final newStatus = UserStatus(
      statusText: statusText == null
        ? oldStatus?.statusText
        : statusText.isEmpty
            ? null
            : statusText,
      emojiName: emojiName == null
        ? oldStatus?.emojiName
        : emojiName.isEmpty
            ? null
            : emojiName,
      emojiCode: emojiCode == null
        ? oldStatus?.emojiCode
        : emojiCode.isEmpty
            ? null
            : emojiCode,
      reactionType: reactionType == null
        ? oldStatus?.reactionType
        : reactionType == UserStatusEventReactionType.empty
          // Currently, if a status emoji is not selected, the server sends
          // "reaction_type: unicode_emoji", so to keep things clean,
          // we treat it as `null`.
          // See discussion:
          //   https://chat.zulip.org/#narrow/channel/378-api-design/topic/user.20status/near/2203928
          || (emojiName!.isEmpty)
            ? null
            : ReactionType.fromApiValue(reactionType.toJson()),
      );

    _userStatuses[event.userId] = newStatus;
  }

  void handleMutedUsersEvent(MutedUsersEvent event) {
    _mutedUsers.clear();
    _mutedUsers.addAll(event.mutedUsers.map((item) => item.id));
  }
}
