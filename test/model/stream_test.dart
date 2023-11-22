
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';

import '../example_data.dart' as eg;

void main() {
  group('SubscriptionEvent', () {
    final stream = eg.stream();

    test('SubscriptionProperty.color updates with an int value', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, color: 0xFFFF0000)],
      ));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF0000);

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.color,
        value: 0xFFFF00FF));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF00FF);
    });

    test('SubscriptionProperty.isMuted updates with a boolean value', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.isMuted,
        value: true));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });

    test('SubscriptionProperty.inHomeView updates isMuted instead', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.inHomeView,
        value: false));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });
  });
}
