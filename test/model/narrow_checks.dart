
import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/model/narrow.dart';

extension NarrowChecks on Subject<Narrow> {
  Subject<ApiNarrow> get apiEncode => has((x) => x.apiEncode(), 'apiEncode()');
}

extension DmNarrowChecks on Subject<DmNarrow> {
  Subject<List<int>> get allRecipientIds => has((x) => x.allRecipientIds, 'allRecipientIds');
  Subject<List<int>> get otherRecipientIds => has((x) => x.otherRecipientIds, 'otherRecipientIds');
}

extension TopicNarrowChecks on Subject<TopicNarrow> {
  Subject<int> get streamId => has((x) => x.streamId, 'streamId');
  Subject<TopicName> get topic => has((x) => x.topic, 'topic');
  Subject<int?> get with_ => has((x) => x.with_, 'with_');
}
