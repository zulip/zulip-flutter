import 'package:get/get.dart';
import 'visit_first_unread_setting.dart';

class VisitFirstUnreadSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitFirstUnreadSettingController>(
      () => VisitFirstUnreadSettingController(),
    );
  }
}
