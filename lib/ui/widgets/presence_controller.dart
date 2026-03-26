import 'package:get/get.dart';

import '../../api/model/model.dart';
import '../../get/services/store_service.dart';
import '../../model/binding.dart';

class PresenceController extends GetxController {
  final int userId;
  final Rx<PresenceStatus?> status = Rx<PresenceStatus?>(null);
  late final Worker _worker;

  PresenceController({required this.userId});

  @override
  void onInit() {
    super.onInit();
    _updateStatus();
    _worker = ever(StoreService.to.currentStore, (_) => _updateStatus());
  }

  void _updateStatus() {
    final presence = StoreService.to.store?.presence;
    status.value = presence?.presenceStatusForUser(
      userId,
      utcNow: ZulipBinding.instance.utcNow(),
    );
  }

  @override
  void onClose() {
    _worker.dispose();
    super.onClose();
  }
}
