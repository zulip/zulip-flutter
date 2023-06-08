
import 'package:checks/checks.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/model/narrow.dart';

extension NarrowChecks on Subject<Narrow> {
  Subject<ApiNarrow> get apiEncode => has((x) => x.apiEncode(), 'apiEncode()');
}

extension DmNarrowChecks on Subject<DmNarrow> {
  Subject<List<int>> get allRecipientIds => has((x) => x.allRecipientIds, 'allRecipientIds');
  Subject<List<int>> get otherRecipientIds => has((x) => x.otherRecipientIds, 'otherRecipientIds');
}
