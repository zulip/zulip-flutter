import 'package:checks/checks.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/message_list.dart';

extension MessageListPageChecks on Subject<MessageListPage> {
  Subject<Narrow> get initNarrow => has((x) => x.initNarrow, 'initNarrow');
  Subject<int?> get initAnchorMessageId => has((x) => x.initAnchorMessageId, 'initAnchorMessageId');
}
