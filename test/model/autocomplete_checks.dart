import 'package:checks/checks.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<AutocompleteIntent<ComposeAutocompleteQuery>?> get autocompleteIntent => has((c) => c.autocompleteIntent(), 'autocompleteIntent');
}

extension ComposeTopicControllerChecks on Subject<ComposeTopicController> {
  Subject<AutocompleteIntent<TopicAutocompleteQuery>?> get autocompleteIntent => has((c) => c.autocompleteIntent(), 'autocompleteIntent');
  Subject<String> get textNormalized => has((c) => c.textNormalized, 'textNormalized');
}

extension AutocompleteIntentChecks on Subject<AutocompleteIntent<AutocompleteQuery>> {
  Subject<int> get syntaxStart => has((i) => i.syntaxStart, 'syntaxStart');
  Subject<AutocompleteQuery> get query => has((i) => i.query, 'query');
}

extension UserMentionAutocompleteResultChecks on Subject<UserMentionAutocompleteResult> {
  Subject<int> get userId => has((r) => r.userId, 'userId');
}

extension WildcardMentionAutocompleteResultChecks on Subject<WildcardMentionAutocompleteResult> {
  Subject<WildcardMentionOption> get wildcardOption => has((x) => x.wildcardOption, 'wildcardOption');
}

extension UserGroupMentionAutocompleteResultChecks on Subject<UserGroupMentionAutocompleteResult> {
  Subject<int> get groupId => has((r) => r.groupId, 'groupId');
}

extension TopicAutocompleteResultChecks on Subject<TopicAutocompleteResult> {
  Subject<TopicName> get topic => has((r) => r.topic, 'topic');
}

extension ChannelLinkAutocompleteResultChecks on Subject<ChannelLinkAutocompleteResult> {
  Subject<int> get channelId => has((r) => r.channelId, 'channelId');
}
