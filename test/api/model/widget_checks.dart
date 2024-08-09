import 'package:checks/checks.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/model/widget.dart';

extension PollChecks on Subject<Poll> {
  Subject<List<Submessage>> get submessages => has((e) => e.submessages, 'submessages');
  Subject<String> get question => has((e) => e.question, 'question');
  Subject<Iterable<Option>> get options => has((e) => e.options, 'options');
}
