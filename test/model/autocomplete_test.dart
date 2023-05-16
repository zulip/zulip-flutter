import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';

import '../example_data.dart' as eg;

void main() {
  test('MentionAutocompleteQuery.testUser', () {
    doCheck(String rawQuery, User user, bool expected) {
      final result = MentionAutocompleteQuery(rawQuery)
        .testUser(user, AutocompleteDataCache());
      expected ? check(result).isTrue() : check(result).isFalse();
    }

    doCheck('', eg.user(fullName: 'Full Name'), true);
    doCheck('', eg.user(fullName: ''), true); // Unlikely case, but should not crash
    doCheck('Full Name', eg.user(fullName: 'Full Name'), true);
    doCheck('full name', eg.user(fullName: 'Full Name'), true);
    doCheck('Full Name', eg.user(fullName: 'full name'), true);
    doCheck('Full', eg.user(fullName: 'Full Name'), true);
    doCheck('Name', eg.user(fullName: 'Full Name'), true);
    doCheck('Full Name', eg.user(fullName: 'Fully Named'), true);
    doCheck('Full Four', eg.user(fullName: 'Full Name Four Words'), true);
    doCheck('Name Words', eg.user(fullName: 'Full Name Four Words'), true);
    doCheck('Full F', eg.user(fullName: 'Full Name Four Words'), true);
    doCheck('F Four', eg.user(fullName: 'Full Name Four Words'), true);
    doCheck('full full', eg.user(fullName: 'Full Full Name'), true);
    doCheck('full full', eg.user(fullName: 'Full Name Full'), true);

    doCheck('F', eg.user(fullName: ''), false); // Unlikely case, but should not crash
    doCheck('Fully Named', eg.user(fullName: 'Full Name'), false);
    doCheck('Full Name', eg.user(fullName: 'Full'), false);
    doCheck('Full Name', eg.user(fullName: 'Name'), false);
    doCheck('ull ame', eg.user(fullName: 'Full Name'), false);
    doCheck('ull Name', eg.user(fullName: 'Full Name'), false);
    doCheck('Full ame', eg.user(fullName: 'Full Name'), false);
    doCheck('Full Full', eg.user(fullName: 'Full Name'), false);
    doCheck('Name Name', eg.user(fullName: 'Full Name'), false);
    doCheck('Name Full', eg.user(fullName: 'Full Name'), false);
    doCheck('Name Four Full Words', eg.user(fullName: 'Full Name Four Words'), false);
    doCheck('F Full', eg.user(fullName: 'Full Name Four Words'), false);
    doCheck('Four F', eg.user(fullName: 'Full Name Four Words'), false);
  });
}
