import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/message.dart';

extension OutboxMessageChecks<T extends Conversation> on Subject<OutboxMessage<T>> {
  Subject<int> get localMessageId => has((x) => x.localMessageId, 'localMessageId');
  Subject<OutboxMessageState> get state => has((x) => x.state, 'state');
  Subject<bool> get hidden => has((x) => x.hidden, 'hidden');
}
