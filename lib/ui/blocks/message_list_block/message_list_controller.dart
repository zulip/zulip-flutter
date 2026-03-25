import 'package:get/get.dart';

class MessageListController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<dynamic> messages = <dynamic>[].obs;

  void loadMessages() {
    // Placeholder - actual implementation depends on message_list_block
  }

  void sendMessage(String content) {
    // Placeholder
  }
}
