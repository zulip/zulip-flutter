import 'dart:async';
import 'dart:math';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/backoff.dart';

import '../fake_async.dart';

Future<Duration> measureWait(Future<void> future) async {
  final start = clock.now();
  await future;
  return clock.now().difference(start);
}

void main() {
  List<Duration> expectedBounds({
    required int length,
    required Duration firstBound,
    required Duration maxBound,
  }) {
    return List.generate(length, growable: false, (completed) {
      return Duration(microseconds:
        min(maxBound.inMicroseconds,
            (firstBound.inMicroseconds
             * pow(BackoffMachine.base, completed)).round()));
    });
  }

  void checkEmpirically({
      required Duration firstBound, required Duration maxBound}) {
    // This is a randomized test.  [numTrials] is chosen so that the failure
    // probability < 1e-9.  There are 2 * 11 assertions, and each one has a
    // failure probability < 1e-12; see below.
    const numTrials = 100;
    final expectedMaxDurations = expectedBounds(length: 11,
      firstBound: firstBound, maxBound: maxBound);

    // Check an assumption used in our failure-probability estimates.
    assert(2 * expectedMaxDurations.length < 1000);

    final trialResults = List.generate(numTrials, (_) {
      return awaitFakeAsync((async) async {
        final backoffMachine = BackoffMachine(firstBound: firstBound,
                                              maxBound: maxBound);
        final results = <Duration>[];
        for (int i = 0; i < expectedMaxDurations.length; i++) {
          final duration = await measureWait(backoffMachine.wait());
          results.add(duration);
        }
        check(async.pendingTimers).isEmpty();
        return results;
      });
    });

    for (int i = 0; i < expectedMaxDurations.length; i++) {
      Duration maxFromAllTrials = trialResults[0][i];
      Duration minFromAllTrials = trialResults[0][i];
      for (final singleTrial in trialResults.skip(1)) {
        final t = singleTrial[i];
        maxFromAllTrials = t > maxFromAllTrials ? t : maxFromAllTrials;
        minFromAllTrials = t < minFromAllTrials ? t : minFromAllTrials;
      }

      final expectedMax = expectedMaxDurations[i];
      // Each of these two assertions has a failure probability of:
      //     pow(0.75, numTrials) = pow(0.75, 100) < 1e-12
      check(minFromAllTrials).isLessThan(   expectedMax * 0.25);
      check(maxFromAllTrials).isGreaterThan(expectedMax * 0.75);

      check(maxFromAllTrials).isLessOrEqual(expectedMax);
    }
  }

  test('BackoffMachine timeouts are random from zero to the intended bounds', () {
    checkEmpirically(firstBound: const Duration(milliseconds: 100),
                     maxBound:   const Duration(seconds: 10));
  });

  test('BackoffMachine timeouts, varying firstBound and maxBound', () {
    checkEmpirically(firstBound: const Duration(seconds: 5),
                     maxBound:   const Duration(seconds: 300));
  });

  test('BackoffMachine timeouts, maxBound equal to firstBound', () {
    checkEmpirically(firstBound: const Duration(seconds: 1),
                     maxBound:   const Duration(seconds: 1));
  });

  test('BackoffMachine default firstBound and maxBound', () {
    final backoffMachine = BackoffMachine();
    check(backoffMachine.firstBound).equals(const Duration(milliseconds: 100));
    check(backoffMachine.maxBound).equals(const Duration(seconds: 10));

    // This check on expectedBounds acts as a cross-check on the
    // other test cases above, confirming what it is they're checking for.
    final bounds = expectedBounds(length: 11,
      firstBound: backoffMachine.firstBound, maxBound: backoffMachine.maxBound);
    check(bounds.map((d) => d.inMilliseconds)).deepEquals([
      100, 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, 10000,
    ]);
  });

  test('BackoffMachine timeouts are always positive', () {
    // Regression test for: https://github.com/zulip/zulip-flutter/issues/602
    // This is a randomized test with a false-failure rate of zero.

    // In the pre-#602 implementation, the first timeout was zero
    // when a random number from [0, 100] was below 0.5.
    // [numTrials] is chosen so that an implementation with that behavior
    // will fail the test with probability 99%.
    const hypotheticalFailureRate = 0.5 / 100;
    const numTrials = 2 * ln10 / hypotheticalFailureRate;

    awaitFakeAsync((async) async {
      for (int i = 0; i < numTrials; i++) {
        final duration = await measureWait(BackoffMachine().wait());
        check(duration).isGreaterThan(Duration.zero);
      }
      check(async.pendingTimers).isEmpty();
    });
  });

  test('BackoffMachine handles long backoff safely', () => awaitFakeAsync(
    flushTimeout: Duration(hours: 12),
    (async) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1339.
      // The regression was caused by exponential backoff multiplying powers of
      // two by the `firstBound` duration, collectively causing a double
      // overflow to Infinity at high retry counts.

      final backoffMachine = BackoffMachine();

      // Smallest exponent `n` where `2^n` overflows to Infinity as a double.
      const minOverflowExponent = 1024;
      assert(pow(2.0, minOverflowExponent - 1) != double.infinity);
      assert(pow(2.0, minOverflowExponent    ) == double.infinity);

      // Number of waits that would surely cause double overflow error.
      final minTrials = minOverflowExponent + 1;

      final start = clock.now();
      // Advance the backoff to the point where overflow would occur.
      for (var i = 0; i < minTrials; i++) {
        await check(backoffMachine.wait()).completes();
      }

      // Time limit to avoid exceeding fake_async timeout due to the last
      // backoff wait.
      final endTime = Duration(hours: 12) - backoffMachine.maxBound;

      // Continue waiting to ensure backoff stays stable over long runs.
      while(clock.now().difference(start) < endTime) {
        await check(backoffMachine.wait()).completes();
      }
    },
  ));
}
