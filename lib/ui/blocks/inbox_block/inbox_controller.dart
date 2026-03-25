import 'package:get/get.dart';

class InboxController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<dynamic> items = <dynamic>[].obs;

  void loadItems() {
    // Placeholder - actual implementation depends on inbox_block
  }
}
