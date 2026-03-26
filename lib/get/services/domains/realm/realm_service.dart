import 'package:get/get.dart';

import '../../../../api/model/model.dart';

class RealmService extends GetxService {
  static RealmService get to => Get.find<RealmService>();

  final Rx<String> realmUrl = ''.obs;
  final Rx<String> realmName = ''.obs;
  final Rx<Uri?> realmIconUrl = Rx<Uri?>(null);
  final RxMap<String, RealmEmojiItem> emoji = RxMap<String, RealmEmojiItem>();
  final Rx<String> zulipVersion = ''.obs;
  final Rx<int> zulipFeatureLevel = 0.obs;
  final Rx<String> realmEmptyTopicDisplayName = ''.obs;

  void syncFromStore() {
    // Will be implemented when full integration is done
  }

  void updateRealm(
    String url,
    String name,
    Uri? icon,
    String version,
    int featureLevel,
  ) {
    realmUrl.value = url;
    realmName.value = name;
    realmIconUrl.value = icon;
    zulipVersion.value = version;
    zulipFeatureLevel.value = featureLevel;
  }

  void updateEmoji(Map<String, RealmEmojiItem> newEmoji) {
    emoji.value = newEmoji;
  }

  void clear() {
    realmUrl.value = '';
    realmName.value = '';
    realmIconUrl.value = null;
    emoji.clear();
    zulipVersion.value = '';
    zulipFeatureLevel.value = 0;
    realmEmptyTopicDisplayName.value = '';
  }

  RealmEmojiItem? getEmoji(String name) {
    return emoji[name];
  }
}
