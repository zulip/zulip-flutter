import 'package:get/get.dart';

import '../../../../api/model/model.dart';
import '../../store_service.dart';

class ChannelsService extends GetxService {
  static ChannelsService get to => Get.find<ChannelsService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
  }

  ZulipStream? getStream(int streamId) {
    final store = StoreService.to.store;
    if (store == null) return null;
    return store.channelStore.streams[streamId];
  }

  Subscription? getSubscription(int streamId) {
    final store = StoreService.to.store;
    if (store == null) return null;
    return store.channelStore.subscriptions[streamId];
  }

  Map<int, ZulipStream> get streams {
    final store = StoreService.to.store;
    if (store == null) return {};
    return store.channelStore.streams;
  }

  Map<int, Subscription> get subscriptions {
    final store = StoreService.to.store;
    if (store == null) return {};
    return store.channelStore.subscriptions;
  }

  List<ZulipStream> get sortedStreams {
    final streamList = streams.values.toList();
    streamList.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return streamList;
  }

  List<Subscription> get sortedSubscriptions {
    final subList = subscriptions.values.toList();
    subList.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return subList;
  }

  List<Subscription> get subscribedStreams => subscriptions.values.toList();

  bool isSubscribed(int streamId) {
    return subscriptions.containsKey(streamId);
  }

  int get subscribedCount => subscriptions.length;

  String streamName(int streamId) {
    return streams[streamId]?.name ?? 'Unknown';
  }

  int? streamColor(int streamId) {
    return subscriptions[streamId]?.color;
  }

  bool streamMuted(int streamId) {
    return subscriptions[streamId]?.isMuted ?? false;
  }

  bool streamPinned(int streamId) {
    return subscriptions[streamId]?.pinToTop ?? false;
  }

  void clear() {
    // No local state to clear
  }
}
