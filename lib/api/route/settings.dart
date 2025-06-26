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
    final value = switch (name) {
      UserSettingName.twentyFourHourTime => valueRaw as bool,
      UserSettingName.displayEmojiReactionUsers => valueRaw as bool,
      UserSettingName.emojiset => RawParameter((valueRaw as Emojiset).toJson()),
      UserSettingName.presenceEnabled => valueRaw as bool,
    };
    params[name.toJson()] = value;
  }

  return connection.patch('updateSettings', (_) {}, 'settings', params);
}
