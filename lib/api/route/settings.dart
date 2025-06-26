import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';

part 'settings.g.dart';

/// https://zulip.com/api/update-settings
Future<UpdateSettingsResult> updateSettings(ApiConnection connection, {
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

  return connection.patch('updateSettings', UpdateSettingsResult.fromJson, 'settings',
    params);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateSettingsResult {
  UpdateSettingsResult();

  factory UpdateSettingsResult.fromJson(Map<String, dynamic> json) =>
    _$UpdateSettingsResultFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSettingsResultToJson(this);
}
