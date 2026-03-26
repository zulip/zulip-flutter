import 'package:get/get.dart';

import '../../../../api/model/model.dart';
import '../../store_service.dart';

class MessagesService extends GetxService {
  static MessagesService get to => Get.find<MessagesService>();

  void syncFromStore() {
    // Data is accessed directly from store via StoreService
  }

  Message<dynamic>? getMessage(int messageId) {
    return StoreService.to.store?.messages[messageId];
  }

  Map<int, Message<dynamic>> get messages {
    return StoreService.to.store?.messages ?? {};
  }

  bool hasMessage(int messageId) {
    return messages.containsKey(messageId);
  }

  void clear() {
    // No local state to clear
  }
}
