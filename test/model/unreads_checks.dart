import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/unreads.dart';
import 'package:zulip/model/channel.dart';

extension UnreadsChecks on Subject<Unreads> {
  Subject<Map<int, Map<TopicName, QueueList<int>>>> get streams => has(
    (unreads) {
      return unreads.streams.map(
        (streamId, topicMap) => MapEntry(streamId, topicMap.toMap()),
      );
    },
    'streams',
  );
  Subject<Map<DmNarrow, QueueList<int>>> get dms => has((u) => u.dms, 'dms');
  Subject<Set<int>> get mentions => has((u) => u.mentions, 'mentions');
  Subject<bool> get oldUnreadsMissing => has((u) => u.oldUnreadsMissing, 'oldUnreadsMissing');
}
