import 'package:checks/checks.dart';
import 'package:zulip/api/route/messages.dart';

extension SendMessageResultChecks on Subject<SendMessageResult> {
  Subject<int> get id => has((e) => e.id, 'id');
}

// TODO add similar extensions for other classes in api/route/*.dart
