import 'package:get/get.dart';
import 'all_channels_controller.dart';

class AllChannelsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllChannelsController>(() => AllChannelsController());
  }
}
