import 'dart:math';

/// A machine that can sleep for increasing durations, for network backoff.
///
/// Call the constructor before a loop starts, and call [wait] in each iteration
/// of the loop.  Do not re-use the instance after exiting the loop.
class BackoffMachine {
  BackoffMachine();

  static const double _firstDurationMs = 100;
  static const double _durationCeilingMs = 10 * 1000;
  static const double _base = 2;

  /// How many waits have completed so far.
  ///
  /// Use this to implement "give up" logic by breaking out of the loop after
  /// a threshold number of waits.
  int get waitsCompleted => _waitsCompleted;
  int _waitsCompleted = 0;

  /// A future that resolves after the appropriate duration.
  ///
  /// The popular exponential backoff strategy is to increase the duration
  /// exponentially with the number of sleeps completed, with a base of 2,
  /// until a ceiling is reached.  E.g., if the first duration is 100ms and
  /// the ceiling is 10s = 10000ms, the sequence is, in ms:
  ///
  ///   100, 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, ...
  ///
  /// Instead of using this strategy directly, we also apply "jitter".
  /// We use capped exponential backoff for the *upper bound* on a random
  /// duration, where the lower bound is always zero.  Mitigating "bursts" is
  /// the goal of any "jitter" strategy, and the larger the range of randomness,
  /// the smoother the bursts.  Keeping the lower bound at zero
  /// maximizes the range while preserving a capped exponential shape on
  /// the expected value.  Greg discusses this in more detail at:
  ///   https://github.com/zulip/zulip-mobile/pull/3841
  ///
  /// The duration is always positive; [Duration] works in microseconds, so
  /// we deviate from the idealized uniform distribution just by rounding
  /// the smallest durations up to one microsecond instead of down to zero.
  /// Because in the real world any delay takes nonzero time, this mainly
  /// affects tests that use fake time, and keeps their behavior more realistic.
  Future<void> wait() async {
    final durationMs =
      Random().nextDouble() // "Jitter"
      * min(_durationCeilingMs,
            _firstDurationMs * pow(_base, _waitsCompleted));

    await Future<void>.delayed(Duration(
      microseconds: max(1, (1000 * durationMs).round())));

    _waitsCompleted++;
  }
}
