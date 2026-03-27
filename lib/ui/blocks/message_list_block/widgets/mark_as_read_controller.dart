import 'package:get/get.dart';

import '../../../../get/services/domains/unreads/unreads_service.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../../../../model/unreads.dart';

class MarkAsReadController extends GetxController {
  final Narrow narrow;
  final RxBool loading = false.obs;
  final RxInt unreadCount = 0.obs;

  Unreads? _unreadsModel;
  late final Worker _storeWorker;

  MarkAsReadController({required this.narrow});

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _storeWorker = ever(StoreService.to.currentStore, (_) => _setupListeners());
  }

  void _setupListeners() {
    _unreadsModel?.removeListener(_onModelChanged);
    final unreads = UnreadsService.to.unreads;
    if (unreads != null) {
      _unreadsModel = unreads..addListener(_onModelChanged);
      _updateUnreadCount();
    }
  }

  void _onModelChanged() {
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    final model = _unreadsModel;
    if (model != null) {
      unreadCount.value = model.countInNarrow(narrow);
    }
  }

  bool get shouldHide => unreadCount.value == 0;

  Future<void> handlePress() async {
    loading.value = true;
    // Note: The actual mark as read action should be handled by the caller
    // since it needs BuildContext for navigation/dialogs
    loading.value = false;
  }

  @override
  void onClose() {
    _storeWorker.dispose();
    _unreadsModel?.removeListener(_onModelChanged);
    super.onClose();
  }
}
