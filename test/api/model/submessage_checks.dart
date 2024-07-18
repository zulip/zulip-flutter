
import 'package:checks/checks.dart';
import 'package:zulip/api/model/submessage.dart';

extension SubmessageChecks on Subject<Submessage> {
  Subject<SubmessageType> get msgType => has((e) => e.msgType, 'msgType');
  Subject<Object?> get content => has((e) => e.content, 'content');
  Subject<int> get senderId => has((e) => e.senderId, 'senderId');
}
