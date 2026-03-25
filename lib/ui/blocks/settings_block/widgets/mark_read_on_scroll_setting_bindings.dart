import 'package:get/get.dart';
import 'mark_read_on_scroll_setting.dart';

class MarkReadOnScrollSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MarkReadOnScrollSettingController>(
      () => MarkReadOnScrollSettingController(),
    );
  }
}
