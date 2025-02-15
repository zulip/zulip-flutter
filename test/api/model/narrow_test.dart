import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'events_checks.dart';
import 'model_checks.dart';

void main() {
  group('resolveApiNarrowForServer', () {
    void doTest(
      String description,
      ApiNarrow input,
      ApiNarrow expected, {
      int zulipFeatureLevel = eg.recentZulipFeatureLevel
    }) {
      test('$description, FL $zulipFeatureLevel', () {
        final actual = resolveApiNarrowForServer(input, zulipFeatureLevel);
        check(actual).jsonEquals(expected);
      });
    }

    final stream = ApiNarrowStream(eg.stream().streamId);
    final topic = ApiNarrowTopic(eg.t('topic'));
    final dm = ApiNarrowDm([eg.user().userId]);
    final with_ = ApiNarrowWith(eg.streamMessage().id);

    group('recent FL', () {
      doTest('dm (modern)', [dm], [dm.resolve(legacy: false)]);
      doTest('topic, not permalink', [stream, topic], [stream, topic]);
      doTest('topic permalink (modern)', [stream, topic, with_], [stream, topic, with_]);

      // Unlikely to occur in the wild but should still be handled correctly
      doTest('dm + with', [dm, with_], [dm.resolve(legacy: false), with_]);
    });

    // TODO(server-7)
    group('FL 176', () {
      final zulipFeatureLevel = 176;
      doTest('dm (legacy)', zulipFeatureLevel: zulipFeatureLevel,
        [dm], [dm.resolve(legacy: true)]);
      doTest('topic, not permalink', [stream, topic], [stream, topic]);
      doTest('topic permalink (legacy)', zulipFeatureLevel: zulipFeatureLevel,
        [stream, topic, with_], [stream, topic]);

      // Unlikely to occur in the wild but should still be handled correctly
      doTest('dm + with', zulipFeatureLevel: zulipFeatureLevel,
        [dm, with_], [dm.resolve(legacy: true)]);
    });

    // TODO(server-9)
    group('FL 270', () {
      final zulipFeatureLevel = 270;
      doTest('topic permalink (legacy)', zulipFeatureLevel: zulipFeatureLevel,
        [stream, topic, with_], [stream, topic]);
      doTest('topic, not permalink', [stream, topic], [stream, topic]);
      doTest('dm (modern)', zulipFeatureLevel: zulipFeatureLevel,
        [dm], [dm.resolve(legacy: false)]);

      // Unlikely to occur in the wild but should still be handled correctly
      doTest('dm + with', zulipFeatureLevel: zulipFeatureLevel,
        [dm, with_], [dm.resolve(legacy: false)]);
    });
  });
}
