import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/unreads.dart';

extension UnreadsChecks on Subject<Unreads> {
  Subject<int> get count => has((u) => u.totalCount, 'count');
  Subject<Map<int, StreamUnreads>> get streams => has((u) => u.streams, 'streams');
  Subject<Map<DmNarrow, QueueList<int>>> get dms => has((u) => u.dms, 'dms');
  Subject<Set<int>> get mentions => has((u) => u.mentions, 'mentions');
  Subject<bool> get oldUnreadsMissing => has((u) => u.oldUnreadsMissing, 'oldUnreadsMissing');
}
