import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Only one ZulipBinding can be constructed per isolate,
  // and each test file gets its own isolate.
  // So this file has room for just one test.
  test('LiveZulipBinding.connectivityChanges: keep repeated reports', () async {
    // The plugin's Connectivity.onConnectivityChanged drops a report
    // equal to the last one it delivered.  After a consumer learns of
    // a change some other way (as ConnectivityMonitor does, by rechecking
    // when the app resumes), the plugin's filter can then swallow
    // a real change.
    // So this binding keeps repeats,
    // and a consumer that wants only changes should compare each report
    // with the last.
    const channel = EventChannel('dev.fluttercommunity.plus/connectivity_status');
    MockStreamHandlerEventSink? sink;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(channel,
        MockStreamHandler.inline(onListen: (_, events) => sink = events));

    final binding = LiveZulipBinding();
    final reports = <List<ConnectivityResult>>[];
    final subscription = binding.connectivityChanges.listen(reports.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    sink!.success(['wifi']);
    sink!.success(['wifi']);
    await pumpEventQueue();
    check(reports).length.equals(2);
  });
}
