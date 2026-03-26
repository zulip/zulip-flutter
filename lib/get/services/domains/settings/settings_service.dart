import 'package:get/get.dart';

import '../../../../api/model/initial_snapshot.dart';
import '../../../../api/model/model.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find<SettingsService>();

  final Rx<UserSettings> settings = Rx<UserSettings>(_defaultSettings);

  static UserSettings get _defaultSettings => UserSettings(
    twentyFourHourTime: TwentyFourHourTimeMode.twelveHour,
    starredMessageCounts: true,
    displayEmojiReactionUsers: true,
    emojiset: Emojiset.google,
    presenceEnabled: true,
  );

  void syncFromStore() {
    // Will be implemented when full integration is done
  }

  void updateSettings(UserSettings newSettings) {
    settings.value = newSettings;
  }

  void clear() {
    settings.value = _defaultSettings;
  }

  TwentyFourHourTimeMode get twentyFourHourTime =>
      settings.value.twentyFourHourTime;
  bool get starredMessageCounts => settings.value.starredMessageCounts;
  bool get displayEmojiReactionUsers =>
      settings.value.displayEmojiReactionUsers;
  Emojiset get emojiset => settings.value.emojiset;
  bool get presenceEnabled => settings.value.presenceEnabled;
}
