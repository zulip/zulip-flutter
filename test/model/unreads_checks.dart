import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/unreads.dart';

extension UnreadsChecks on Subject<Unreads> {
  Subject<Map<int, SendableNarrow>> get locatorMap => has((u) => u.locatorMap, 'locatorMap');
  Subject<Map<int, Map<TopicName, QueueList<int>>>> get streams => has((u) => u.streams, 'streams');
  Subject<Map<DmNarrow, QueueList<int>>> get dms => has((u) => u.dms, 'dms');
  Subject<Set<int>> get mentions => has((u) => u.mentions, 'mentions');
  Subject<bool> get oldUnreadsMissing => has((u) => u.oldUnreadsMissing, 'oldUnreadsMissing');
}
