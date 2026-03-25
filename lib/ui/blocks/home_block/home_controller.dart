import 'package:get/get.dart';
import 'dart:io' show Platform;

import '../../../model/narrow.dart';
import '../../widgets/new_dm_sheet.dart';
import 'home.dart';
import '../../../get/app_pages.dart';

class HomeController extends GetxController {
  final currentTab = Rx<HomePageTab>(HomePageTab.channels);
  final RxBool isLoading = false.obs;

  void changeTab(HomePageTab tab) {
    currentTab.value = tab;
  }

  void loadData() {
    isLoading.value = true;
    // Business logic from _HomePageState.initState would go here
    // For example: load subscriptions, load unreads, etc.
    isLoading.value = false;
  }

  void navigateToInboxSearch() {
    Get.toNamed<dynamic>(
      AppRoutes.topicList,
      arguments: {'narrow': KeywordSearchNarrow('')},
    );
  }

  void navigateToAllChannels() {
    Get.toNamed<dynamic>(AppRoutes.allChannels);
  }

  void navigateToNewDm() {
    showNewDmSheet(Get.context!, (DmNarrow narrow) {
      Get.offNamed<dynamic>(AppRoutes.topicList, arguments: {'narrow': narrow});
    });
  }

  void navigateToSettings() {
    Get.toNamed<dynamic>(AppRoutes.settings);
  }

  bool get isMobile => Platform.isAndroid || Platform.isIOS;
}
