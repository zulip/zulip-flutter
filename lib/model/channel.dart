import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';

/// The portion of [PerAccountStore] for channels, topics, and stuff about them.
///
/// This type is useful for expressing the needs of other parts of the
/// implementation of [PerAccountStore], to avoid circularity.
///
/// The data structures described here are implemented at [ChannelStoreImpl].
mixin ChannelStore {
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

  /// The visibility policy that the self-user has for the given topic.
  ///
  /// This does not incorporate the user's channel-level policy,
  /// and is mainly used in the implementation of other [ChannelStore] methods.
  ///
  /// For policies directly applicable in the UI, see
  /// [isTopicVisibleInStream] and [isTopicVisible].
  UserTopicVisibilityPolicy topicVisibilityPolicy(int streamId, String topic);

  /// The raw data structure underlying [topicVisibilityPolicy].
  ///
  /// This is sometimes convenient for checks in tests.
  /// It differs from [topicVisibilityPolicy] in on the one hand omitting
  /// all topics where the value would be [UserTopicVisibilityPolicy.none],
  /// and on the other hand being a concrete, finite data structure that
  /// can be compared using `deepEquals`.
  @visibleForTesting
  Map<int, Map<String, UserTopicVisibilityPolicy>> get debugTopicVisibility;

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
  bool isTopicVisibleInStream(int streamId, String topic) {
    return _isTopicVisibleInStream(topicVisibilityPolicy(streamId, topic));
  }

  /// Whether the given event will change the result of [isTopicVisibleInStream]
  /// for its stream and topic, compared to the current state.
  VisibilityEffect willChangeIfTopicVisibleInStream(UserTopicEvent event) {
    final streamId = event.streamId;
    final topic = event.topicName;
    return VisibilityEffect._fromBeforeAfter(
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
  bool isTopicVisible(int streamId, String topic) {
    return _isTopicVisible(streamId, topicVisibilityPolicy(streamId, topic));
  }

  /// Whether the given event will change the result of [isTopicVisible]
  /// for its stream and topic, compared to the current state.
  VisibilityEffect willChangeIfTopicVisible(UserTopicEvent event) {
    final streamId = event.streamId;
    final topic = event.topicName;
    return VisibilityEffect._fromBeforeAfter(
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
}

/// Whether and how a given [UserTopicEvent] will affect the results
/// that [ChannelStore.isTopicVisible] or [ChannelStore.isTopicVisibleInStream]
/// would give for some messages.
enum VisibilityEffect {
  /// The event will have no effect on the visibility results.
  none,

  /// The event will change some visibility results from true to false.
  muted,

  /// The event will change some visibility results from false to true.
  unmuted;

  factory VisibilityEffect._fromBeforeAfter(bool before, bool after) {
    return switch ((before, after)) {
      (false, true) => VisibilityEffect.unmuted,
      (true, false) => VisibilityEffect.muted,
      _             => VisibilityEffect.none,
    };
  }
}

/// The implementation of [ChannelStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [ChannelStore] which describes its interface.
class ChannelStoreImpl with ChannelStore {
  factory ChannelStoreImpl({required InitialSnapshot initialSnapshot}) {
    final subscriptions = Map.fromEntries(initialSnapshot.subscriptions.map(
      (subscription) => MapEntry(subscription.streamId, subscription)));

    final streams = Map<int, ZulipStream>.of(subscriptions);
    for (final stream in initialSnapshot.streams) {
      streams.putIfAbsent(stream.streamId, () => stream);
    }

    final topicVisibility = <int, Map<String, UserTopicVisibilityPolicy>>{};
    for (final item in initialSnapshot.userTopics ?? const <UserTopicItem>[]) {
      if (_warnInvalidVisibilityPolicy(item.visibilityPolicy)) {
        // Not a value we expect. Keep it out of our data structures. // TODO(log)
        continue;
      }
      final forStream = topicVisibility.putIfAbsent(item.streamId, () => {});
      forStream[item.topicName] = item.visibilityPolicy;
    }

    return ChannelStoreImpl._(
      streams: streams,
      streamsByName: streams.map((_, stream) => MapEntry(stream.name, stream)),
      subscriptions: subscriptions,
      topicVisibility: topicVisibility,
    );
  }

  ChannelStoreImpl._({
    required this.streams,
    required this.streamsByName,
    required this.subscriptions,
    required this.topicVisibility,
  });

  @override
  final Map<int, ZulipStream> streams;
  @override
  final Map<String, ZulipStream> streamsByName;
  @override
  final Map<int, Subscription> subscriptions;

  @override
  Map<int, Map<String, UserTopicVisibilityPolicy>> get debugTopicVisibility => topicVisibility;

  final Map<int, Map<String, UserTopicVisibilityPolicy>> topicVisibility;

  @override
  UserTopicVisibilityPolicy topicVisibilityPolicy(int streamId, String topic) {
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
          case ChannelPropertyName.canRemoveSubscribersGroup:
          case ChannelPropertyName.canRemoveSubscribersGroupId:
            stream.canRemoveSubscribersGroup = event.value as int?;
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
          subscriptions.remove(streamId);
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
            // TODO(#421) update [MessageListView] if affected
            subscription.isMuted                = event.value as bool;
          case SubscriptionProperty.inHomeView:
            subscription.isMuted                = !(event.value as bool);
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

  void handleUserTopicEvent(UserTopicEvent event) {
    UserTopicVisibilityPolicy visibilityPolicy = event.visibilityPolicy;
    if (_warnInvalidVisibilityPolicy(visibilityPolicy)) {
      visibilityPolicy = UserTopicVisibilityPolicy.none;
    }
    // TODO(#421) update [MessageListView] if affected
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
      final forStream = topicVisibility.putIfAbsent(event.streamId, () => {});
      forStream[event.topicName] = visibilityPolicy;
    }
  }
}
