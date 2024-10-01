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
  test('BackoffMachine timeouts are random from zero to 100ms, 200ms, 400ms, ...', () {
    // This is a randomized test.  [numTrials] is chosen so that the failure
    // probability < 1e-9.  There are 2 * 11 assertions, and each one has a
    // failure probability < 1e-12; see below.
    const numTrials = 100;
    final expectedMaxDurations = [
      100, 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, 10000,
    ].map((ms) => Duration(milliseconds: ms)).toList();

    final trialResults = List.generate(numTrials, (_) {
      return awaitFakeAsync((async) async {
        final backoffMachine = BackoffMachine();
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
      // Each of these assertions has a failure probability of:
      //     pow(0.75, numTrials) = pow(0.75, 100) < 1e-12
      check(minFromAllTrials).isLessThan(   expectedMax * 0.25);
      check(maxFromAllTrials).isGreaterThan(expectedMax * 0.75);
    }
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
}
