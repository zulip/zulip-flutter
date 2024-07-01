import 'package:checks/checks.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<AutocompleteIntent<MentionAutocompleteQuery>?> get autocompleteIntent => has((c) => c.autocompleteIntent(), 'autocompleteIntent');
}

extension ComposeTopicControllerChecks on Subject<ComposeTopicController> {
  Subject<AutocompleteIntent<TopicAutocompleteQuery>?> get autocompleteIntent => has((c) => c.autocompleteIntent(), 'autocompleteIntent');
}

extension AutocompleteIntentChecks on Subject<AutocompleteIntent<MentionAutocompleteQuery>> {
  Subject<int> get syntaxStart => has((i) => i.syntaxStart, 'syntaxStart');
  Subject<MentionAutocompleteQuery> get query => has((i) => i.query, 'query');
}

extension TopicAutocompleteIntentChecks on Subject<AutocompleteIntent<TopicAutocompleteQuery>> {
  Subject<int> get syntaxStart => has((i) => i.syntaxStart, 'syntaxStart');
  Subject<TopicAutocompleteQuery> get query => has((i) => i.query, 'query');
}

extension UserMentionAutocompleteResultChecks on Subject<UserMentionAutocompleteResult> {
  Subject<int> get userId => has((r) => r.userId, 'userId');
}

extension TopicAutocompleteResultChecks on Subject<TopicAutocompleteResult> {
  Subject<int> get maxId => has((r) => r.topic.maxId, 'maxId');
  Subject<String> get name => has((r) => r.topic.name, 'name');
}
