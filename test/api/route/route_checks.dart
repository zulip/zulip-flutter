// ignore_for_file: non_constant_identifier_names

import 'package:checks/checks.dart';
import 'package:zulip/api/route/messages.dart';

extension SendMessageResultChecks on Subject<SendMessageResult> {
  Subject<int> get id => has((e) => e.id, 'id');
  Subject<String?> get deliver_at => has((e) => e.deliver_at, 'deliver_at');
}

// TODO add similar extensions for other classes in api/route/*.dart
