# Integration Tests

Integration tests in Flutter allow self-driving end-to-end
testing of app code running with the full GUI.

This document is about using integration tests to capture
performance metrics on physical devices. For more
information on that topic see
[Flutter cookbook on integration profiling][profiling-cookbook].

For more background on integration testing in general
see [Flutter docs on integration testing][flutter-docs].

[profiling-cookbook]: https://docs.flutter.dev/cookbook/testing/integration/profiling
[flutter-docs]: https://docs.flutter.dev/testing/integration-tests


## Capturing performance metrics

Capturing performance metrics involves two parts: an
integration test that runs on a device and driver code that
runs on the host.

Integration test code is written in a similar style as
widget test code, using a `testWidgets` function as well as
a `WidgetTester` instance to arrange widgets and run
interactions. A difference is the usage of
`IntegrationTestWidgetsFlutterBinding` which provides a
`traceAction` method used to record Dart VM timelines.

Driver code runs on the host and is useful to configure
output of captured timeline data. There is a baseline driver
at `integration_test/perf_driver.dart` that additionally
configures output of a timeline summary containing widget
build times and frame rendering performance.


## Obtaining performance metrics

First, obtain a device ID using `flutter devices`.

The command to run an integration test on a device:

```
$ flutter drive \
    --driver=integration_test/perf_driver.dart \
    --target=integration_test/unreadmarker_test.dart \
    --profile \
    --no-dds \
    -d <device_id>
```

A data file with raw event timings will be produced in
`build/trace_output.timeline.json`.

A more readily consumable file will also be produced in
`build/trace_output.timeline_summary.json`. This file
contains widget build and render timing data in a JSON
structure. See the fields `frame_build_times` and
`frame_rasterizer_times` as well as the provided percentile
scores of those. These values are useful for objective
comparison between different runs.
