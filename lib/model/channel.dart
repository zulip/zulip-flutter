import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import 'realm.dart';
import 'store.dart';
import 'user.dart';

final _apiGetChannelTopics = getStreamTopics;  // similar to _apiSendMessage in lib/model/message.dart

/// The portion of [PerAccountStore] for channels, topics, and stuff about them.
///
/// This type is useful for expressing the needs of other parts of the
/// implementation of [PerAccountStore], to avoid circularity.
///
/// The data structures described here are implemented at [ChannelStoreImpl].
mixin ChannelStore on UserStore {
  @protected
  UserStore get userStore;

  /// All known channels/streams, indexed by [ZulipStream.streamId].
  ///
  /// The same [ZulipStream] objects also appear in [streamsByName].
  ///
  /// For channels the self-user is subscribed to, the value is in fact
  /// a [Subscription] object and also appears in [subscriptions].
  Map<int, ZulipStream> get streams;

  /// All known channels/streams, indexed by [ZulipStream.name].
  ///
  /// The same [ZulipStream] objects also appear in [streams].
  ///
  /// For channels the self-user is subscribed to, the value is in fact
  /// a [Subscription] object and also appears in [subscriptions].
  Map<String, ZulipStream> get streamsByName;

  /// All the channels the self-user is subscribed to, indexed by
  /// [Subscription.streamId], with subscription details.
  ///
  /// The same [Subscription] objects are among the values in [streams]
  /// and [streamsByName].
  Map<int, Subscription> get subscriptions;

  /// All the channel folders, including archived ones, indexed by ID.
  Map<int, ChannelFolder> get channelFolders;

  static int compareChannelsByName(ZulipStream a, ZulipStream b) {
    // A user gave feedback wanting zulip-flutter to match web in putting
    // emoji-prefixed channels first; see #1202.
    // TODO(#1165) for matching web's ordering completely, which
    //   (for the all-channels view) I think just means locale-aware sorting.
    final aStartsWithEmoji = _startsWithEmojiRegex.hasMatch(a.name);
    final bStartsWithEmoji = _startsWithEmojiRegex.hasMatch(b.name);
    if (aStartsWithEmoji && !bStartsWithEmoji) return -1;
    if (!aStartsWithEmoji && bStartsWithEmoji) return 1;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  // TODO(linter): The linter incorrectly flags the following regexp string
  //    as invalid. See: https://github.com/dart-lang/sdk/issues/61246
  // ignore: valid_regexps
  static final _startsWithEmojiRegex = RegExp(r'^\p{Emoji}', unicode: true);

  /// A compare function for [ChannelFolder]s, using [ChannelFolder.order].
  ///
  /// Channels without [ChannelFolder.order] will come first,
  /// sorted alphabetically.
  // TODO(server-11) Once [ChannelFolder.order] is required,
  //   remove alphabetical sorting.
  static int compareChannelFolders(ChannelFolder a, ChannelFolder b) {
    return switch ((a.order, b.order)) {
      (null,   null) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      (null,  int()) => -1,
      (int(),  null) => 1,
      (int a, int b) => a.compareTo(b),
    };
  }

  /// Fetch topics in a channel from the server, only if they're not fetched yet.
  ///
  /// The results from the last successful fetch
  /// can be retrieved with [getChannelTopics].
  Future<void> fetchTopics(int channelId);

  /// Pairs of the known topics and its latest message ID, in the given channel.
  ///
  /// Returns null if the data has never been fetched yet.
  /// To fetch it from the server, use [fetchTopics].
  ///
  /// The result is guaranteed to be sorted by [GetStreamTopicsEntry.maxId]
  /// descending, and the topics are guaranteed to be distinct.
  ///
  /// In some cases, the same maxId affected by message moves can be present in
  /// multiple [GetStreamTopicsEntry] entries. For this reason, the caller
  /// should not rely on [getChannelTopics] to determine which topic the message
  /// is in. Instead, refer to [PerAccountStore.messages].
  /// See [handleUpdateMessageEvent] on how this could happen.
  List<GetStreamTopicsEntry>? getChannelTopics(int channelId);

  /// The visibility policy that the self-user has for the given topic.
  ///
  /// This does not incorporate the user's channel-level policy,
  /// and is mainly used in the implementation of other [ChannelStore] methods.
  ///
  /// For policies directly applicable in the UI, see
  /// [isTopicVisibleInStream] and [isTopicVisible].
  ///
  /// Topics are treated case-insensitively; see [TopicName.isSameAs].
  UserTopicVisibilityPolicy topicVisibilityPolicy(int streamId, TopicName topic);

  /// The raw data structure underlying [topicVisibilityPolicy].
  ///
  /// This is sometimes convenient for checks in tests.
  /// It differs from [topicVisibilityPolicy] in on the one hand omitting
  /// all topics where the value would be [UserTopicVisibilityPolicy.none],
  /// and on the other hand being a concrete, finite data structure that
  /// can be compared using `deepEquals`.
  @visibleForTesting
  Map<int, Map<TopicName, UserTopicVisibilityPolicy>> get debugTopicVisibility;

  /// Whether this topic should appear when already focusing on its stream.
  ///
  /// This is determined purely by the user's visibility policy for the topic.
  ///
  /// This function is appropriate for muting calculations in UI contexts that
  /// are already specific to a stream: for example the stream's unread count,
  /// or the message list in the stream's narrow.
  ///
  /// For UI contexts that are not specific to a particular stream, see
  /// [isTopicVisible].
  bool isTopicVisibleInStream(int streamId, TopicName topic) {
    return _isTopicVisibleInStream(topicVisibilityPolicy(streamId, topic));
  }

  /// Whether the given event will change the result of [isTopicVisibleInStream]
  /// for its stream and topic, compared to the current state.
  UserTopicVisibilityEffect willChangeIfTopicVisibleInStream(UserTopicEvent event) {
    final streamId = event.streamId;
    final topic = event.topicName;
    return UserTopicVisibilityEffect._fromBeforeAfter(
      _isTopicVisibleInStream(topicVisibilityPolicy(streamId, topic)),
      _isTopicVisibleInStream(event.visibilityPolicy));
  }

  static bool _isTopicVisibleInStream(UserTopicVisibilityPolicy policy) {
    switch (policy) {
      case UserTopicVisibilityPolicy.none:
        return true;
      case UserTopicVisibilityPolicy.muted:
        return false;
      case UserTopicVisibilityPolicy.unmuted:
      case UserTopicVisibilityPolicy.followed:
        return true;
      case UserTopicVisibilityPolicy.unknown:
        assert(false);
        return true;
    }
  }

  /// Whether this topic should appear when not specifically focusing
  /// on this stream.
  ///
  /// This takes into account the user's visibility policy for the stream
  /// overall, as well as their policy for this topic.
  ///
  /// For UI contexts that are specific to a particular stream, see
  /// [isTopicVisibleInStream].
  bool isTopicVisible(int streamId, TopicName topic) {
    return _isTopicVisible(streamId, topicVisibilityPolicy(streamId, topic));
  }

  /// Whether the given event will change the result of [isTopicVisible]
  /// for its stream and topic, compared to the current state.
  UserTopicVisibilityEffect willChangeIfTopicVisible(UserTopicEvent event) {
    final streamId = event.streamId;
    final topic = event.topicName;
    return UserTopicVisibilityEffect._fromBeforeAfter(
      _isTopicVisible(streamId, topicVisibilityPolicy(streamId, topic)),
      _isTopicVisible(streamId, event.visibilityPolicy));
  }

  bool _isTopicVisible(int streamId, UserTopicVisibilityPolicy policy) {
    switch (policy) {
      case UserTopicVisibilityPolicy.none:
        switch (subscriptions[streamId]?.isMuted) {
          case false: return true;
          case true:  return false;
          case null:  return false; // not subscribed; treat like muted
        }
      case UserTopicVisibilityPolicy.muted:
        return false;
      case UserTopicVisibilityPolicy.unmuted:
      case UserTopicVisibilityPolicy.followed:
        return true;
      case UserTopicVisibilityPolicy.unknown:
        assert(false);
        return true;
    }
  }

  bool selfHasContentAccess(ZulipStream channel) {
    // Compare web's stream_data.has_content_access.
    if (channel.isWebPublic) return true;
    if (channel is Subscription) return true;
    // Here web calls has_metadata_access... but that always returns true,
    // as its comment says.
    if (selfUser.role == UserRole.guest) return false;
    if (!channel.inviteOnly) return true;
    return _selfHasContentAccessViaGroupPermissions(channel);
  }

  bool _selfHasContentAccessViaGroupPermissions(ZulipStream channel) {
    // Compare web's stream_data.has_content_access_via_group_permissions.

    if (selfHasPermissionForGroupSetting(channel.canAddSubscribersGroup,
          GroupSettingType.stream, 'can_add_subscribers_group')) {
      return true;
    }

    if (selfHasPermissionForGroupSetting(channel.canSubscribeGroup,
          GroupSettingType.stream, 'can_subscribe_group')) {
      return true;
    }

    return false;
  }

  bool selfCanSendMessage({
    required ZulipStream inChannel,
    required DateTime byDate,
  }) {
    // (selfHasPermissionForGroupSetting isn't equipped to handle the old-server
    // fallback logic for this specific permission; it's dynamic and depends on
    // channelPostPolicy, so we do our own null check here.)
    if (inChannel.canSendMessageGroup != null) {
      return selfHasPermissionForGroupSetting(inChannel.canSendMessageGroup!,
               GroupSettingType.stream, 'can_send_message_group');
    } else if (inChannel.channelPostPolicy != null) {
      return _selfPassesLegacyChannelPostPolicy(inChannel: inChannel, atDate: byDate);
    } else {
      assert(false); // TODO(log)
      return true;
    }
  }

  bool _selfPassesLegacyChannelPostPolicy({
    required ZulipStream inChannel,
    required DateTime atDate,
  }) {
    assert(inChannel.channelPostPolicy != null);
    final role = selfUser.role;

    // (Could early-return true on [UserRole.unknown],
    // but pre-333 servers shouldn't be giving us an unknown role.)

    switch (inChannel.channelPostPolicy!) {
      case ChannelPostPolicy.any:             return true;
      case ChannelPostPolicy.fullMembers:     {
        if (!role.isAtLeast(UserRole.member)) return false;
        if (role == UserRole.member) {
          return selfHasPassedWaitingPeriod(byDate: atDate);
        }
        return true;
      }
      case ChannelPostPolicy.moderators:      return role.isAtLeast(UserRole.moderator);
      case ChannelPostPolicy.administrators:  return role.isAtLeast(UserRole.administrator);
      case ChannelPostPolicy.unknown:         return true;
    }
  }
}

/// Whether and how a given [UserTopicEvent] will affect the results
/// that [ChannelStore.isTopicVisible] or [ChannelStore.isTopicVisibleInStream]
/// would give for some messages.
enum UserTopicVisibilityEffect {
  /// The event will have no effect on the visibility results.
  none,

  /// The event will change some visibility results from true to false.
  muted,

  /// The event will change some visibility results from false to true.
  unmuted;

  factory UserTopicVisibilityEffect._fromBeforeAfter(bool before, bool after) {
    return switch ((before, after)) {
      (false, true) => UserTopicVisibilityEffect.unmuted,
      (true, false) => UserTopicVisibilityEffect.muted,
      _             => UserTopicVisibilityEffect.none,
    };
  }
}

mixin ProxyChannelStore on ChannelStore {
  @protected
  ChannelStore get channelStore;

  @override
  Map<int, ZulipStream> get streams => channelStore.streams;

  @override
  Map<String, ZulipStream> get streamsByName => channelStore.streamsByName;

  @override
  Map<int, Subscription> get subscriptions => channelStore.subscriptions;

  @override
  Map<int, ChannelFolder> get channelFolders => channelStore.channelFolders;

  @override
  Future<void> fetchTopics(int channelId) => channelStore.fetchTopics(channelId);

  @override
  List<GetStreamTopicsEntry>? getChannelTopics(int channelId) =>
    channelStore.getChannelTopics(channelId);

  @override
  UserTopicVisibilityPolicy topicVisibilityPolicy(int streamId, TopicName topic) =>
    channelStore.topicVisibilityPolicy(streamId, topic);

  @override
  Map<int, Map<TopicName, UserTopicVisibilityPolicy>> get debugTopicVisibility =>
    channelStore.debugTopicVisibility;
}

/// A base class for [PerAccountStore] substores
/// that need access to [ChannelStore] as well as to its prerequisites
/// [CorePerAccountStore], [RealmStore], and [UserStore].
abstract class HasChannelStore extends HasUserStore with ChannelStore, ProxyChannelStore {
  HasChannelStore({required ChannelStore channels})
    : channelStore = channels, super(users: channels.userStore);

  @protected
  @override
  final ChannelStore channelStore;
}

/// The implementation of [ChannelStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [ChannelStore] which describes its interface.
class ChannelStoreImpl extends HasUserStore with ChannelStore {
  factory ChannelStoreImpl({
    required UserStore users,
    required InitialSnapshot initialSnapshot,
  }) {
    final subscriptions = Map.fromEntries(initialSnapshot.subscriptions.map(
      (subscription) => MapEntry(subscription.streamId, subscription)));

    final streams = Map<int, ZulipStream>.of(subscriptions);
    for (final stream in initialSnapshot.streams) {
      streams.putIfAbsent(stream.streamId, () => stream);
    }

    final channelFolders = Map.fromEntries((initialSnapshot.channelFolders ?? [])
      .map((channelFolder) => MapEntry(channelFolder.id, channelFolder)));

    final topicVisibility = <int, TopicKeyedMap<UserTopicVisibilityPolicy>>{};
    for (final item in initialSnapshot.userTopics) {
      if (_warnInvalidVisibilityPolicy(item.visibilityPolicy)) {
        // Not a value we expect. Keep it out of our data structures. // TODO(log)
        continue;
      }
      final forStream = topicVisibility.putIfAbsent(item.streamId, () => makeTopicKeyedMap());
      forStream[item.topicName] = item.visibilityPolicy;
    }

    return ChannelStoreImpl._(
      users: users,
      streams: streams,
      streamsByName: streams.map((_, stream) => MapEntry(stream.name, stream)),
      subscriptions: subscriptions,
      channelFolders: channelFolders,
      topicVisibility: topicVisibility,
    );
  }

  ChannelStoreImpl._({
    required super.users,
    required this.streams,
    required this.streamsByName,
    required this.subscriptions,
    required this.channelFolders,
    required this.topicVisibility,
  });

  @override
  final Map<int, ZulipStream> streams;
  @override
  final Map<String, ZulipStream> streamsByName;
  @override
  final Map<int, Subscription> subscriptions;
  @override
  final Map<int, ChannelFolder> channelFolders;

  /// Maps indexed by channel IDs, of the known latest message IDs in each topic.
  ///
  /// For example: `_latestMessageIdsByChannelTopic[channel.streamId][topic] = maxId`
  ///
  /// In some cases, the same message IDs, when affected by message moves, can
  /// be present for mutliple channel-topic keys.
  /// See [handleUpdateMessageEvent] on how this could happen.
  final Map<int, Map<TopicName, int>> _latestMessageIdsByChannelTopic = {};

  @override
  Future<void> fetchTopics(int channelId) async {
    if (_latestMessageIdsByChannelTopic[channelId] != null) return;

    final result = await _apiGetChannelTopics(connection, streamId: channelId,
      allowEmptyTopicName: true);
    _latestMessageIdsByChannelTopic[channelId] = {
      for (final GetStreamTopicsEntry(:name, :maxId) in result.topics)
        name: maxId,
    };
  }

  @override
  List<GetStreamTopicsEntry>? getChannelTopics(int channelId) {
    final latestMessageIdsByTopic = _latestMessageIdsByChannelTopic[channelId];
    if (latestMessageIdsByTopic == null) return null;
    return [
      for (final MapEntry(:key, :value) in latestMessageIdsByTopic.entries)
        GetStreamTopicsEntry(maxId: value, name: key),
    ].sortedBy((value) => -value.maxId);
  }

  @override
  Map<int, TopicKeyedMap<UserTopicVisibilityPolicy>> get debugTopicVisibility => topicVisibility;

  final Map<int, TopicKeyedMap<UserTopicVisibilityPolicy>> topicVisibility;

  @override
  UserTopicVisibilityPolicy topicVisibilityPolicy(int streamId, TopicName topic) {
    return topicVisibility[streamId]?[topic] ?? UserTopicVisibilityPolicy.none;
  }

  static bool _warnInvalidVisibilityPolicy(UserTopicVisibilityPolicy visibilityPolicy) {
    if (visibilityPolicy == UserTopicVisibilityPolicy.unknown) {
      // Not a value we expect. Keep it out of our data structures. // TODO(log)
      return true;
    }
    return false;
  }

  void handleChannelEvent(ChannelEvent event) {
    switch (event) {
      case ChannelCreateEvent():
        assert(event.streams.every((stream) =>
          !streams.containsKey(stream.streamId)
          && !streamsByName.containsKey(stream.name)));
        streams.addEntries(event.streams.map((stream) => MapEntry(stream.streamId, stream)));
        streamsByName.addEntries(event.streams.map((stream) => MapEntry(stream.name, stream)));
        // (Don't touch `subscriptions`. If the user is subscribed to the stream,
        // details will come in a later `subscription` event.)

      case ChannelDeleteEvent():
        for (final stream in event.streams) {
          assert(identical(streams[stream.streamId], streamsByName[stream.name]));
          assert(subscriptions[stream.streamId] == null
            || identical(subscriptions[stream.streamId], streams[stream.streamId]));
          streams.remove(stream.streamId);
          streamsByName.remove(stream.name);
          subscriptions.remove(stream.streamId);
        }

      case ChannelUpdateEvent():
        final stream = streams[event.streamId];
        if (stream == null) return; // TODO(log)
        assert(stream.streamId == event.streamId);

        if (event.renderedDescription != null) {
          stream.renderedDescription = event.renderedDescription!;
        }
        if (event.historyPublicToSubscribers != null) {
          stream.historyPublicToSubscribers = event.historyPublicToSubscribers!;
        }
        if (event.isWebPublic != null) {
          stream.isWebPublic = event.isWebPublic!;
        }

        if (event.property == null) {
          // unrecognized property; do nothing
          return;
        }
        switch (event.property!) {
          case ChannelPropertyName.name:
            final streamName = stream.name;
            assert(streamName == event.name);
            assert(identical(streams[stream.streamId], streamsByName[streamName]));
            stream.name = event.value as String;
            streamsByName.remove(streamName);
            streamsByName[stream.name] = stream;
          case ChannelPropertyName.isArchived:
            stream.isArchived = event.value as bool;
          case ChannelPropertyName.description:
            stream.description = event.value as String;
          case ChannelPropertyName.firstMessageId:
            stream.firstMessageId = event.value as int?;
          case ChannelPropertyName.inviteOnly:
            stream.inviteOnly = event.value as bool;
          case ChannelPropertyName.messageRetentionDays:
            stream.messageRetentionDays = event.value as int?;
          case ChannelPropertyName.channelPostPolicy:
            stream.channelPostPolicy = event.value as ChannelPostPolicy;
          case ChannelPropertyName.folderId:
            stream.folderId = event.value as int?;
          case ChannelPropertyName.canAddSubscribersGroup:
            stream.canAddSubscribersGroup = event.value as GroupSettingValue;
          case ChannelPropertyName.canDeleteAnyMessageGroup:
            stream.canDeleteAnyMessageGroup = event.value as GroupSettingValue;
          case ChannelPropertyName.canDeleteOwnMessageGroup:
            stream.canDeleteOwnMessageGroup = event.value as GroupSettingValue;
          case ChannelPropertyName.canSendMessageGroup:
            stream.canSendMessageGroup = event.value as GroupSettingValue;
          case ChannelPropertyName.canSubscribeGroup:
            stream.canSubscribeGroup = event.value as GroupSettingValue;
          case ChannelPropertyName.streamWeeklyTraffic:
            stream.streamWeeklyTraffic = event.value as int?;
        }
    }
  }

  void handleSubscriptionEvent(SubscriptionEvent event) {
    switch (event) {
      case SubscriptionAddEvent():
        for (final subscription in event.subscriptions) {
          assert(streams.containsKey(subscription.streamId));
          assert(streams[subscription.streamId] is! Subscription);
          assert(streamsByName.containsKey(subscription.name));
          assert(streamsByName[subscription.name] is! Subscription);
          assert(!subscriptions.containsKey(subscription.streamId));
          streams[subscription.streamId] = subscription;
          streamsByName[subscription.name] = subscription;
          subscriptions[subscription.streamId] = subscription;
        }

      case SubscriptionRemoveEvent():
        for (final streamId in event.streamIds) {
          assert(streams.containsKey(streamId));
          assert(streams[streamId] is Subscription);
          assert(streamsByName.containsKey(streams[streamId]!.name));
          assert(streamsByName[streams[streamId]!.name] is Subscription);
          assert(subscriptions.containsKey(streamId));
          final subscription = subscriptions.remove(streamId);
          if (subscription == null) continue; // TODO(log)
          final stream = ZulipStream.fromSubscription(subscription);
          streams[streamId] = stream;
          streamsByName[subscription.name] = stream;
        }

      case SubscriptionUpdateEvent():
        final subscription = subscriptions[event.streamId];
        if (subscription == null) return; // TODO(log)
        assert(identical(streams[event.streamId], subscription));
        assert(identical(streamsByName[subscription.name], subscription));
        switch (event.property) {
          case SubscriptionProperty.color:
            subscription.color                  = event.value as int;
          case SubscriptionProperty.isMuted:
            // TODO(#1255) update [MessageListView] if affected
            subscription.isMuted                = event.value as bool;
          case SubscriptionProperty.pinToTop:
            subscription.pinToTop               = event.value as bool;
          case SubscriptionProperty.desktopNotifications:
            subscription.desktopNotifications   = event.value as bool;
          case SubscriptionProperty.audibleNotifications:
            subscription.audibleNotifications   = event.value as bool;
          case SubscriptionProperty.pushNotifications:
            subscription.pushNotifications      = event.value as bool;
          case SubscriptionProperty.emailNotifications:
            subscription.emailNotifications     = event.value as bool;
          case SubscriptionProperty.wildcardMentionsNotify:
            subscription.wildcardMentionsNotify = event.value as bool;
          case SubscriptionProperty.unknown:
            // unrecognized property; do nothing
            return;
        }

      case SubscriptionPeerAddEvent():
      case SubscriptionPeerRemoveEvent():
        // We don't currently store the data these would update; that's #374.
    }
  }

  void handleChannelFolderEvent(ChannelFolderEvent event) {
    switch (event) {
      case ChannelFolderAddEvent():
        final newChannelFolder = event.channelFolder;
        channelFolders[newChannelFolder.id] = newChannelFolder;

      case ChannelFolderUpdateEvent():
        final change = event.data;
        final channelFolder = channelFolders[event.channelFolderId];
        if (channelFolder == null) return; // TODO(log)

        if (change.name != null)                channelFolder.name = change.name!;
        if (change.description != null)         channelFolder.description = change.description!;
        if (change.renderedDescription != null) channelFolder.renderedDescription = change.renderedDescription!;
        if (change.isArchived != null)          channelFolder.isArchived = change.isArchived!;

      case ChannelFolderReorderEvent():
        final order = event.order;
        for (int i = 0; i < order.length; i++) {
          final id = order[i];
          final channelFolder = channelFolders[id];
          if (channelFolder == null) continue; // TODO(log)
          channelFolder.order = i;
        }
    }
  }

  void handleUserTopicEvent(UserTopicEvent event) {
    UserTopicVisibilityPolicy visibilityPolicy = event.visibilityPolicy;
    if (_warnInvalidVisibilityPolicy(visibilityPolicy)) {
      visibilityPolicy = UserTopicVisibilityPolicy.none;
    }
    if (visibilityPolicy == UserTopicVisibilityPolicy.none) {
      // This is the "zero value" for this type, which our data structure
      // represents by leaving the topic out entirely.
      final forStream = topicVisibility[event.streamId];
      if (forStream == null) return;
      forStream.remove(event.topicName);
      if (forStream.isEmpty) {
        topicVisibility.remove(event.streamId);
      }
    } else {
      final forStream = topicVisibility.putIfAbsent(event.streamId, () => makeTopicKeyedMap());
      forStream[event.topicName] = visibilityPolicy;
    }
  }

  /// Handle a [MessageEvent], returning whether listeners should be notified.
  bool handleMessageEvent(MessageEvent event) {
    if (event.message is! StreamMessage) return false;
    final StreamMessage(:streamId, :topic) = event.message as StreamMessage;

    final latestMessageIdsByTopic = _latestMessageIdsByChannelTopic[streamId];
    // If we don't already know about the list of topics of the channel this
    // message belongs to, we don't want to proceed and put one entry about the
    // topic of this message, otherwise [fetchTopics] and the callers of
    // [getChannelTopics] would think that the channel only has this one topic
    // and would never fetch the complete list of topics for that matter.
    if (latestMessageIdsByTopic == null) return false;

    // If this message is already the latest message in the topic because it was
    // received through fetch in fetch/event race, or it is a message sent even
    // before the latest message of the fetch, we don't do the update.
    final currentLatestMessageId = latestMessageIdsByTopic[topic];
    if (currentLatestMessageId != null && currentLatestMessageId >= event.message.id) {
      return false;
    }
    latestMessageIdsByTopic[topic] = event.message.id;
    return true;
  }

  /// Handle an [UpdateMessageEvent], returning whether listeners should be
  /// notified.
  bool handleUpdateMessageEvent(UpdateMessageEvent event) {
    if (event.moveData == null) return false;
    final UpdateMessageMoveData(
      :origStreamId, :origTopic, :newStreamId, :newTopic, :propagateMode,
    ) = event.moveData!;
    bool shouldNotify = false;

    final origLatestMessageIdsByTopics = _latestMessageIdsByChannelTopic[origStreamId];
    // We only handle the case where all the messages of [origTopic] are
    // moved to [newTopic]; in that case we can remove [origTopic] safely.
    // But if only one messsage is moved (`PropagateMode.changeOne`) or a few
    // messages are moved (`PropagateMode.changeLater`), we cannot do anything
    // about [origTopic] here as we cannot determine the new `maxId` for it.
    // (This is the case where there could be multiple channel-topic keys with
    //  the same `maxId`)
    if (propagateMode == PropagateMode.changeAll
        && origLatestMessageIdsByTopics != null) {
      shouldNotify = origLatestMessageIdsByTopics.remove(origTopic) != null;
    }

    final newLatestMessageIdsByTopics = _latestMessageIdsByChannelTopic[newStreamId];
    if (newLatestMessageIdsByTopics != null) {
      final movedMaxId = event.messageIds.max;
      if (!newLatestMessageIdsByTopics.containsKey(newTopic)
          || newLatestMessageIdsByTopics[newTopic]! < movedMaxId) {
        newLatestMessageIdsByTopics[newTopic] = movedMaxId;
        shouldNotify = true;
      }
    }

    return shouldNotify;
  }
}

/// A [Map] with [TopicName] keys and [V] values.
///
/// When one of these is created by [makeTopicKeyedMap],
/// key equality is done case-insensitively; see there.
///
/// This type should only be used for maps created by [makeTopicKeyedMap].
/// It would be nice to enforce that.
typedef TopicKeyedMap<V> = Map<TopicName, V>;

/// Make a case-insensitive, case-preserving [TopicName]-keyed [LinkedHashMap].
///
/// The equality function is [TopicName.isSameAs],
/// and the hash code is [String.hashCode] of [TopicName.canonicalize].
TopicKeyedMap<V> makeTopicKeyedMap<V>() => LinkedHashMap<TopicName, V>(
  equals: (a, b) => a.isSameAs(b),
  hashCode: (k) => k.canonicalize().hashCode,
);
