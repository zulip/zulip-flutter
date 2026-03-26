import 'package:get/get.dart';

import '../../../../model/presence.dart';
import '../../store_service.dart';

class PresenceService extends GetxService {
  static PresenceService get to => Get.find<PresenceService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
  }

  Presence? get presence {
    return StoreService.to.store?.presence;
  }

  void clear() {
    // No local state to clear
  }
}
