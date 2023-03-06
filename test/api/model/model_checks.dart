import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';

extension MessageChecks on Subject<Message> {
  Subject<Map<String, dynamic>> get toJson => has((e) => e.toJson(), 'toJson');

  void jsonEquals(Message expected) {
    toJson.deepEquals(expected.toJson());
  }

  Subject<List<String>> get flags => has((e) => e.flags, 'flags');

  // TODO accessors for other fields
}

// TODO similar extensions for other types in model
