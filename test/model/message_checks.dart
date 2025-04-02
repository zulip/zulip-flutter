import 'package:checks/checks.dart';
import 'package:zulip/model/message.dart';

extension OutboxMessageChecks on Subject<OutboxMessage> {
  Subject<OutboxMessageLifecycle> get state => has((x) => x.state, 'state');
  Subject<bool> get hidden => has((x) => x.hidden, 'hidden');
}
