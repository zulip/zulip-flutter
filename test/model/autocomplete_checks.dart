import 'package:checks/checks.dart';
import 'package:zulip/model/autocomplete.dart';

extension UserMentionAutocompleteResultChecks on Subject<UserMentionAutocompleteResult> {
  Subject<int> get userId => has((r) => r.userId, 'userId');
}
