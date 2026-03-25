import 'package:get/get.dart';

import '../../../get/app_pages.dart';

class SettingsController extends GetxController {
  final RxBool isLoading = false.obs;

  void loadSettings() {
    // Placeholder
  }

  void navigateToExperimentalFeatures() {
    Get.toNamed<dynamic>(AppRoutes.experimentalFeatures);
  }
}
