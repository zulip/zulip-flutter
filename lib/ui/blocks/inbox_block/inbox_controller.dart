import 'package:get/get.dart';

import '../../../get/services/domains/unreads/unreads_service.dart';
import '../../../get/services/store_service.dart';
import '../../../model/recent_dm_conversations.dart';
import '../../../model/unreads.dart';

abstract class InboxPageStateTemplate {
  bool get allDmsCollapsed;
  set allDmsCollapsed(bool value);

  void collapseStream(int streamId);
  void uncollapseStream(int streamId);

  Unreads? get unreadsModel;
  RecentDmConversationsView? get recentDmConversationsModel;
}

class InboxController extends GetxController implements InboxPageStateTemplate {
  final RxBool _allDmsCollapsedRx = false.obs;
  final RxSet<int> collapsedStreamIds = RxSet<int>();
  final RxBool isLoading = true.obs;

  Unreads? _unreadsModel;
  RecentDmConversationsView? _recentDmConversationsModel;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    ever(StoreService.to.currentStore, (_) => _setupListeners());
  }

  void _setupListeners() {
    _unreadsModel?.removeListener(_onModelChanged);
    final unreads = UnreadsService.to.unreads;
    if (unreads != null) {
      _unreadsModel = unreads..addListener(_onModelChanged);
    }

    _recentDmConversationsModel?.removeListener(_onModelChanged);
    _recentDmConversationsModel =
        StoreService.to.store?.recentDmConversationsView
          ?..addListener(_onModelChanged);

    isLoading.value = false;
  }

  void _onModelChanged() {
    final unreads = _unreadsModel;
    if (unreads != null) {
      final streamsToRemove = <int>{};
      for (final streamId in collapsedStreamIds) {
        final topics = unreads.streams[streamId];
        final hasUnreads = topics != null && topics.isNotEmpty;
        if (!hasUnreads) {
          streamsToRemove.add(streamId);
        }
      }
      collapsedStreamIds.removeAll(streamsToRemove);
      if (unreads.dms.isEmpty) {
        _allDmsCollapsedRx.value = false;
      }
    }
    update();
  }

  @override
  bool get allDmsCollapsed => _allDmsCollapsedRx.value;
  @override
  set allDmsCollapsed(bool value) {
    _allDmsCollapsedRx.value = value;
    update();
  }

  @override
  void collapseStream(int streamId) {
    collapsedStreamIds.add(streamId);
    update();
  }

  @override
  void uncollapseStream(int streamId) {
    collapsedStreamIds.remove(streamId);
    update();
  }

  bool isStreamCollapsed(int streamId) {
    return collapsedStreamIds.contains(streamId);
  }

  @override
  Unreads? get unreadsModel => _unreadsModel;
  @override
  RecentDmConversationsView? get recentDmConversationsModel =>
      _recentDmConversationsModel;

  @override
  void onClose() {
    _unreadsModel?.removeListener(_onModelChanged);
    _recentDmConversationsModel?.removeListener(_onModelChanged);
    super.onClose();
  }
}
