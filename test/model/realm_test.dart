import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../example_data.dart' as eg;

void main() {
  test('processTopicLikeServer', () {
    final emptyTopicDisplayName = eg.defaultRealmEmptyTopicDisplayName;

    TopicName process(TopicName topic, int zulipFeatureLevel) {
      final account = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
      final store = eg.store(account: account, initialSnapshot: eg.initialSnapshot(
        zulipFeatureLevel: zulipFeatureLevel,
        realmEmptyTopicDisplayName: emptyTopicDisplayName));
      return store.processTopicLikeServer(topic);
    }

    void doCheck(TopicName topic, TopicName expected, int zulipFeatureLevel) {
      check(process(topic, zulipFeatureLevel)).equals(expected);
    }

    check(() => process(eg.t(''), 333)).throws<void>();
    doCheck(eg.t('(no topic)'),          eg.t('(no topic)'),          333);
    doCheck(eg.t(emptyTopicDisplayName), eg.t(emptyTopicDisplayName), 333);
    doCheck(eg.t('other topic'),         eg.t('other topic'),         333);

    doCheck(eg.t(''),                    eg.t(''),                    334);
    doCheck(eg.t('(no topic)'),          eg.t('(no topic)'),          334);
    doCheck(eg.t(emptyTopicDisplayName), eg.t(''),                    334);
    doCheck(eg.t('other topic'),         eg.t('other topic'),         334);

    doCheck(eg.t('(no topic)'),          eg.t(''),                    370);
  });

  group('customProfileFields', () {
    test('update clobbers old list', () async {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText),
          eg.customProfileField(1, CustomProfileFieldType.shortText),
        ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([0, 1]);

      await store.handleEvent(CustomProfileFieldsEvent(id: 0, fields: [
        eg.customProfileField(0, CustomProfileFieldType.shortText),
        eg.customProfileField(2, CustomProfileFieldType.shortText),
      ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([0, 2]);
    });

    test('sorts by displayInProfile', () async {
      // Sorts both the data from the initial snapshot…
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText,
            displayInProfileSummary: false),
          eg.customProfileField(1, CustomProfileFieldType.shortText,
            displayInProfileSummary: true),
          eg.customProfileField(2, CustomProfileFieldType.shortText,
            displayInProfileSummary: false),
        ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([1, 0, 2]);

      // … and from an event.
      await store.handleEvent(CustomProfileFieldsEvent(id: 0, fields: [
        eg.customProfileField(0, CustomProfileFieldType.shortText,
          displayInProfileSummary: false),
        eg.customProfileField(1, CustomProfileFieldType.shortText,
          displayInProfileSummary: false),
        eg.customProfileField(2, CustomProfileFieldType.shortText,
          displayInProfileSummary: true),
      ]));
      check(store.customProfileFields.map((f) => f.id)).deepEquals([2, 0, 1]);
    });
  });
}
