
import 'package:checks/checks.dart';
import 'package:zulip/api/model/submessage.dart';

extension SubmessageChecks on Subject<Submessage> {
  Subject<SubmessageType> get msgType => has((e) => e.msgType, 'msgType');
  Subject<Object?> get content => has((e) => e.content, 'content');
  Subject<int> get messageId => has((e) => e.messageId, 'messageId');
  Subject<int> get senderId => has((e) => e.senderId, 'senderId');
  Subject<int> get id => has((e) => e.id, 'id');
}

extension WidgetDataChecks on Subject<WidgetData> {
  Subject<WidgetType> get widgetType => has((e) => e.widgetType, 'widgetType');
}

extension PollWidgetDataChecks on Subject<PollWidgetData> {
  Subject<PollWidgetExtraData> get extraData => has((e) => e.extraData, 'extraData');
}

extension PollWidgetExtraDataChecks on Subject<PollWidgetExtraData> {
  Subject<String> get question => has((e) => e.question, 'question');
  Subject<List<String>> get options => has((e) => e.options, 'options');
}

extension PollEventChecks on Subject<PollEvent> {
  Subject<PollEventType> get type => has((e) => e.type, 'type');
}

extension PollOptionEventChecks on Subject<PollOptionEvent> {
  Subject<String> get option => has((e) => e.option, 'option');
}

extension PollQuestionEventChecks on Subject<PollQuestionEvent> {
  Subject<String> get question => has((e) => e.question, 'question');
}

extension PollVoteEventChecks on Subject<PollVoteEvent> {
  Subject<String> get key => has((e) => e.key, 'key');
  Subject<VoteOp> get op => has((e) => e.op, 'op');
}
