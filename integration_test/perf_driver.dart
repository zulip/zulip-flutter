// This integration driver configures output of timeline data
// and a summary thereof from integration tests. See
// docs/integration_tests.md for background.

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  // See cookbook recipe for this sort of driver:
  //   https://docs.flutter.dev/cookbook/testing/integration/profiling#3-save-the-results-to-disk
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final timeline = driver.Timeline.fromJson(data['timeline'] as Map<String, dynamic>);
      final summary = driver.TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'trace_output',
        pretty: true,
        includeSummary: true);
    });
}
