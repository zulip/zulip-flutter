import 'package:get/get.dart';
import 'experimental_features_page.dart';

class ExperimentalFeaturesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExperimentalFeaturesController>(
      () => ExperimentalFeaturesController(),
    );
  }
}
