import 'package:get/get.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/typing_status.dart';

class TypingService extends GetxService {
  static TypingService get to => Get.find<TypingService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
  }

  TypingStatus? get typingStatus {
    return StoreService.to.store?.typingStatus;
  }

  void clear() {
    // No local state to clear
  }
}
