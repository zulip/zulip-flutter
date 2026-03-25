import 'package:get/get.dart';
import 'recent_dm_conversations_controller.dart';

class RecentDmConversationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecentDmConversationsController>(
      () => RecentDmConversationsController(),
    );
  }
}
