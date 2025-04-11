import 'package:checks/checks.dart';
import 'package:zulip/model/message.dart';

extension OutboxMessageChecks on Subject<OutboxMessage> {
  Subject<int> get localMessageId => has((x) => x.localMessageId, 'localMessageId');
  Subject<OutboxMessageLifecycle> get state => has((x) => x.state, 'state');
  Subject<bool> get hidden => has((x) => x.hidden, 'hidden');
}
