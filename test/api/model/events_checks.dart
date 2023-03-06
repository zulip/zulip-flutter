// ignore_for_file: non_constant_identifier_names

import 'package:checks/checks.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

extension EventChecks on Subject<Event> {
  Subject<int> get id => has((e) => e.id, 'id');
  Subject<String> get type => has((e) => e.type, 'type');
}

extension UnexpectedEventChecks on Subject<UnexpectedEvent> {
  Subject<Map<String, dynamic>> get json => has((e) => e.json, 'json');
}

extension AlertWordsEventChecks on Subject<AlertWordsEvent> {
  Subject<List<String>> get alert_words => has((e) => e.alert_words, 'alert_words');
}

extension MessageEventChecks on Subject<MessageEvent> {
  Subject<Message> get message => has((e) => e.message, 'message');
}

extension HeartbeatEventChecks on Subject<HeartbeatEvent> {
  // No properties not covered by Event.
}

// Add more extensions here for more event types as needed.
// Keep them in the same order as the event types' own definitions.
