import 'package:checks/checks.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<AutocompleteIntent?> get autocompleteIntent => has((c) => c.autocompleteIntent(), 'autocompleteIntent');
}

extension AutocompleteIntentChecks on Subject<AutocompleteIntent> {
  Subject<int> get syntaxStart => has((i) => i.syntaxStart, 'syntaxStart');
  Subject<MentionAutocompleteQuery> get query => has((i) => i.query, 'query');
}

extension UserMentionAutocompleteResultChecks on Subject<UserMentionAutocompleteResult> {
  Subject<int> get userId => has((r) => r.userId, 'userId');
}
