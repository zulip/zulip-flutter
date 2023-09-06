import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'events_checks.dart';
import 'model_checks.dart';

void main() {
  test('message: move flags into message object', () {
    final message = eg.streamMessage();
    MessageEvent mkEvent(List<MessageFlag> flags) => Event.fromJson({
      'type': 'message',
      'id': 1,
      'message': message.toJson()..remove('flags'),
      'flags': flags.map((f) => f.toJson()).toList(),
    }) as MessageEvent;
    check(mkEvent(message.flags)).message.jsonEquals(message);
    check(mkEvent([])).message.flags.deepEquals([]);
    check(mkEvent([MessageFlag.read])).message.flags.deepEquals([MessageFlag.read]);
  });

  test('user_settings: all known settings have event handling', () {
    final dataClassFieldNames = UserSettings.debugKnownNames;
    final enumNames = UserSettingName.values.map((n) => n.name);
    final missingEnumNames = dataClassFieldNames.where((key) => !enumNames.contains(key)).toList();
    check(
      missingEnumNames,
      because:
        'You have added these fields to [UserSettings]\n'
        'without handling the corresponding forms of the\n'
        'user_settings/update event in [PerAccountStore]:\n'
        '  $missingEnumNames\n'
        'To do that, please follow these steps:\n'
        '  (1) Add corresponding members to the [UserSettingName] enum.\n'
        '  (2) Then, re-run the command to refresh the .g.dart files.\n'
        '  (3) Resolve the Dart analysis errors about not exhaustively\n'
        '      matching on that enum, by adding new `switch` cases\n'
        '      on the pattern of the existing cases.'
    ).isEmpty();
  });
}
