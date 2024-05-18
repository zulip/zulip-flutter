import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/recent_dm_conversations.dart';

extension RecentDmConversationsViewChecks on Subject<RecentDmConversationsView> {
  Subject<Map<DmNarrow, int>> get map => has((v) => v.map, 'map');
  Subject<QueueList<DmNarrow>> get sorted => has((v) => v.sorted, 'sorted');
  Subject<Map<int, int>> get latestMessagesByRecipient => has(
    (v) => v.latestMessagesByRecipient, 'latestMessagesByRecipient');
}
