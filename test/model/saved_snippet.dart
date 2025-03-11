import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'store_checks.dart';

void main() {
  test('handleSavedSnippetEvent', () {
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      savedSnippets: [eg.savedSnippet(id: 101)]));

    store.handleEvent(SavedSnippetsAddEvent(
      id: 1, savedSnippet: eg.savedSnippet(id: 102)));
    check(store).savedSnippets.deepEquals(<Condition<Object?>>[
      (it) => it.isA<SavedSnippet>().id.equals(101),
      (it) => it.isA<SavedSnippet>().id.equals(102),
    ]);

    store.handleEvent(SavedSnippetsRemoveEvent(
      id: 2, savedSnippetId: 101));
    check(store).savedSnippets.single.id.equals(102);
  });
}
