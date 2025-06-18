import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:zulip/model/recent_senders.dart';

extension MessageIdTrackerChecks on Subject<MessageIdTracker> {
  Subject<QueueList<int>> get ids => has((x) => x.ids, 'ids');
}
