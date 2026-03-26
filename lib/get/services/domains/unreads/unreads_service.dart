import 'package:get/get.dart';

import '../../../../model/unreads.dart';
import '../../store_service.dart';

class UnreadsService extends GetxService {
  static UnreadsService get to => Get.find<UnreadsService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
  }

  Unreads? get unreads {
    return StoreService.to.store?.unreads;
  }

  void clear() {
    // No local state to clear
  }
}
