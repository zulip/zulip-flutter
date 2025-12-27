import '../core.dart';
import '../model/model.dart';

/// https://zulip.com/api/update-settings
Future<void> updateSettings(ApiConnection connection, {
  required Map<UserSettingName, Object?> newSettings,
}) {
  final params = <String, Object?>{};
  for (final entry in newSettings.entries) {
    final name = entry.key;
    final valueRaw = entry.value;
    final Object? value;
    switch (name) {
      case UserSettingName.twentyFourHourTime:
        final mode = (valueRaw as TwentyFourHourTimeMode);
        // TODO(server-future) allow localeDefault for servers that support it
        assert(mode != TwentyFourHourTimeMode.localeDefault);
        value = mode.toJson();
      case UserSettingName.displayEmojiReactionUsers:
        value = valueRaw as bool;
      case UserSettingName.emojiset:
        value = RawParameter((valueRaw as Emojiset).toJson());
      case UserSettingName.presenceEnabled:
        value = valueRaw as bool;
    }
    params[name.toJson()] = value;
  }

  return connection.patch('updateSettings', (_) {}, 'settings', params);
}
