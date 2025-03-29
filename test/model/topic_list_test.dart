import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/topic_list.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late TopicListView topicListView;

  setUp(() async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;
    topicListView = TopicListView(store: store, streamId: eg.stream().streamId);
  });

  test('initial state', () {
    check(topicListView.isLoading).isTrue();
    check(topicListView.hasError).isFalse();
    check(topicListView.errorMessage).isEmpty();
    check(topicListView.topics).isNull();
  });

  test('fetchTopics success', () async {
    final topics = [
      eg.getStreamTopicsEntry(name: 'topic 1', maxId: 1),
      eg.getStreamTopicsEntry(name: 'topic 2', maxId: 2),
    ];
    connection.prepare(json: GetStreamTopicsResult(topics: topics).toJson());

    await topicListView.fetchTopics();

    check(topicListView.isLoading).isFalse();
    check(topicListView.hasError).isFalse();
    check(topicListView.errorMessage).isEmpty();

    check(topicListView.topics).isNotNull().length.equals(2);

    final resultTopics = topicListView.topics!;
    check(resultTopics[0].name.apiName).equals('topic 1');
    check(resultTopics[0].maxId).equals(1);
    check(resultTopics[1].name.apiName).equals('topic 2');
    check(resultTopics[1].maxId).equals(2);
  });

  test('fetchTopics error', () async {
    connection.prepare(apiException: eg.apiBadRequest(message: 'Failed to fetch topics'));

    await topicListView.fetchTopics();

    check(topicListView.isLoading).isFalse();
    check(topicListView.hasError).isTrue();
    check(topicListView.errorMessage).contains('Failed to fetch topics');
    check(topicListView.topics).isNull();
  });
}