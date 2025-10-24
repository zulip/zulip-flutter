import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'store_checks.dart';

void main() {
  test('handleSavedSnippetsEvent', () async {
    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      savedSnippets: [eg.savedSnippet(id: 101)]));
    check(store).savedSnippets.values.single.id.equals(101);

    await store.handleEvent(SavedSnippetsAddEvent(id: 1,
      savedSnippet: eg.savedSnippet(
        id: 102,
        title: 'foo title',
        content: 'foo content',
      )));
    check(store).savedSnippets.values.deepEquals(<Condition<Object?>>[
      (it) => it.isA<SavedSnippet>().id.equals(101),
      (it) => it.isA<SavedSnippet>()..id.equals(102)
                                    ..title.equals('foo title')
                                    ..content.equals('foo content')
    ]);

    await store.handleEvent(SavedSnippetsRemoveEvent(id: 1, savedSnippetId: 101));
    check(store).savedSnippets.values.single.id.equals(102);

    await store.handleEvent(SavedSnippetsUpdateEvent(id: 1,
      savedSnippet: eg.savedSnippet(
        id: 102,
        title: 'bar title',
        content: 'bar content',
        dateCreated: store.savedSnippets.values.single.dateCreated,
      )));
    check(store).savedSnippets.values.single
      ..id.equals(102)
      ..title.equals('bar title')
      ..content.equals('bar content');
  });
}
