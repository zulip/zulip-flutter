import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/connectivity.dart';

import '../fake_async.dart';
import 'binding.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ConnectivityMonitor', () {
    late ConnectivityMonitor monitor;
    late int signalCount;

    void prepare(FakeAsync async, {
      List<ConnectivityResult> connectivity = const [.wifi],
    }) {
      addTearDown(testBinding.reset);
      testBinding.connectivityResult = connectivity;
      monitor = ConnectivityMonitor();
      signalCount = 0;
      monitor.retrySignals.listen((_) => signalCount++);
      // Let the baseline get established.
      async.flushMicrotasks();
    }

    test('signal on a change; updateCount advances', () => awaitFakeAsync((async) async {
      prepare(async);
      final countBefore = monitor.updateCount;

      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
      check(monitor.updateCount).isGreaterThan(countBefore);
    }));

    test('no signal on a report of unchanged connectivity', () => awaitFakeAsync((async) async {
      prepare(async, connectivity: [.wifi, .vpn]);
      final countBefore = monitor.updateCount;

      // The same set in a different order is not a change.
      testBinding.notifyConnectivityChanged([.vpn, .wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(0);
      check(monitor.updateCount).equals(countBefore);
    }));

    test('no signal on losing connectivity; signal when it returns', () => awaitFakeAsync((async) async {
      prepare(async);

      // Losing connectivity entirely prompts no signal:
      // a retry could not succeed anyway.
      testBinding.notifyConnectivityChanged([.none]);
      async.flushMicrotasks();
      check(signalCount).equals(0);

      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
    }));

    test('pace signals: signal a change during cooldown at cooldown end', () => awaitFakeAsync((async) async {
      prepare(async);

      // The first change signals immediately…
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(1);

      // …but another soon after is recorded without a signal…
      async.elapse(const Duration(seconds: 5));
      final countBefore = monitor.updateCount;
      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
      check(monitor.updateCount).isGreaterThan(countBefore);

      // …until the cooldown ends.
      async.elapse(const Duration(seconds: 5));
      check(signalCount).equals(2);

      // With no further changes, no further signals.
      async.elapse(const Duration(minutes: 1));
      check(signalCount).equals(2);
    }));

    test('no deferred signal when connectivity is gone at cooldown end', () => awaitFakeAsync((async) async {
      prepare(async);

      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(1);

      // A change lands during the cooldown… but then connectivity is lost,
      // so the cooldown ends without the deferred signal…
      async.elapse(const Duration(seconds: 3));
      testBinding.notifyConnectivityChanged([.wifi]);
      async.elapse(const Duration(seconds: 3));
      testBinding.notifyConnectivityChanged([.none]);
      async.elapse(const Duration(seconds: 10));
      check(signalCount).equals(1);

      // …and the signal comes when connectivity returns.
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(2);
    }));

    test('signal on resume when connectivity changed', () => awaitFakeAsync((async) async {
      prepare(async);

      // The network changed while the app was in the background, with the
      // connectivity update dropped rather than delivered, as happens on
      // both Android and iOS (see [ZulipBinding.connectivityChanges]).
      // On resume, the change is discovered by checking.
      testBinding.connectivityResult = [.mobile];
      testBinding.notifyAppLifecycleStateChanged(.resumed);
      async.flushMicrotasks();
      check(signalCount).equals(1);
    }));

    test('no signal on resume when connectivity unchanged', () => awaitFakeAsync((async) async {
      prepare(async);

      // A brief trip to the app switcher and back, with no network change.
      testBinding.notifyAppLifecycleStateChanged(.resumed);
      async.flushMicrotasks();
      check(signalCount).equals(0);
    }));

    test('stale checkConnectivity result discarded', () => awaitFakeAsync((async) async {
      // Uncommon: a recheck takes one platform-channel round trip,
      // so this needs a network change during that brief window.

      prepare(async);

      // A recheck on resume is slow to resolve…
      testBinding.connectivityCheckDelay = const Duration(seconds: 2);
      testBinding.notifyAppLifecycleStateChanged(.resumed);
      async.flushMicrotasks();

      // …and meanwhile the network actually changes.
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(1);

      // The recheck's result is from before that change, so it's
      // discarded: it doesn't count as a change back to wifi…
      final countBefore = monitor.updateCount;
      async.elapse(const Duration(seconds: 2));
      check(monitor.updateCount).equals(countBefore);

      // …so a later real change back to wifi is recognized as a change.
      async.elapse(const Duration(seconds: 10));
      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(2);
    }));

    test('overlapping rechecks: the older result is discarded', () => awaitFakeAsync((async) async {
      // Rare: this needs the app to resume, and the network to change,
      // while the monitor's first recheck is still in flight.

      // Each recheck samples the state as of when it starts
      // (see [TestZulipBinding.checkConnectivity]),
      // and the platform's replies resolve in FIFO order.
      addTearDown(testBinding.reset);
      testBinding.connectivityResult = const [.wifi];
      testBinding.connectivityCheckDelay = const Duration(seconds: 2);
      monitor = ConnectivityMonitor(); // baseline recheck samples [wifi]
      signalCount = 0;
      monitor.retrySignals.listen((_) => signalCount++);

      // The network changes before the baseline recheck resolves,
      // and a resume prompts a second recheck, sampling the new state.
      async.elapse(const Duration(seconds: 1));
      testBinding.connectivityResult = const [.mobile];
      testBinding.notifyAppLifecycleStateChanged(.resumed);

      // The stale first result is discarded
      // and the second becomes the baseline…
      async.elapse(const Duration(seconds: 2));
      check(signalCount).equals(0);
      // …so a change back to wifi is recognized as a change.
      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
    }));

    test('stale recheck result discarded after a report of no change', () => awaitFakeAsync((async) async {
      // Rare: this needs the network to change back, and the stream
      // to report it, while a recheck is in flight.

      prepare(async);

      // A resume prompts a recheck, which samples cellular…
      testBinding.connectivityCheckDelay = const Duration(seconds: 2);
      testBinding.connectivityResult = [.mobile];
      testBinding.notifyAppLifecycleStateChanged(.resumed);
      async.flushMicrotasks();

      // …but before it resolves, the stream reports wifi,
      // which is no change from what was recorded.
      async.elapse(const Duration(seconds: 1));
      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();

      // That report is fresher than the recheck's sample,
      // so the recheck's result is discarded.
      final countBefore = monitor.updateCount;
      async.elapse(const Duration(seconds: 2));
      check(monitor.updateCount).equals(countBefore);
      check(signalCount).equals(0);
    }));

    test('survive a failed checkConnectivity', () => awaitFakeAsync((async) async {
      addTearDown(testBinding.reset);
      testBinding.connectivityCheckError = Exception('platform error');
      monitor = ConnectivityMonitor(); // baseline recheck fails
      signalCount = 0;
      monitor.retrySignals.listen((_) => signalCount++);
      async.flushMicrotasks();

      // With the baseline recheck failed, the first stream update
      // has to serve as the baseline, even if it is in fact a change…
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(0);

      // …and from there, changes are recognized as usual.
      testBinding.notifyConnectivityChanged([.wifi]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
    }));

    test('survive an error on the connectivity stream', () => awaitFakeAsync((async) async {
      prepare(async);

      // An error from the platform doesn't crash anything…
      testBinding.notifyConnectivityError(Exception('platform error'));
      async.flushMicrotasks();

      // …and later updates are still delivered and handled.
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(1);
    }));

    test('no effect after dispose', () => awaitFakeAsync((async) async {
      // Only tests dispose the monitor, in [TestZulipBinding.reset];
      // nothing in the app does.

      prepare(async);

      monitor.dispose();
      testBinding.notifyConnectivityChanged([.mobile]);
      async.flushMicrotasks();
      check(signalCount).equals(0);
    }));

    test('no effect from a recheck that resolves after dispose', () => awaitFakeAsync((async) async {
      // Nothing in the app disposes the monitor; the GlobalStore
      // that owns it lasts as long as the app.  But tests dispose it,
      // in [TestZulipBinding.reset], possibly with a recheck pending.

      prepare(async);

      // A resume prompts a recheck, slow to resolve…
      testBinding.connectivityCheckDelay = const Duration(seconds: 2);
      testBinding.connectivityResult = [.mobile];
      testBinding.notifyAppLifecycleStateChanged(.resumed);
      async.flushMicrotasks();

      // …and the monitor is disposed before it does.
      monitor.dispose();
      async.elapse(const Duration(seconds: 2));
      check(signalCount).equals(0);
    }));
  });
}
