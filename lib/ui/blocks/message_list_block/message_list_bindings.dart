import 'package:get/get.dart';
import 'message_list_controller.dart';

class MessageListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessageListController>(() => MessageListController());
  }
}
