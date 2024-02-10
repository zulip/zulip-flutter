import 'dart:math';

/// A machine that can sleep for increasing durations, for network backoff.
///
/// Call the constructor before a loop starts, and call [wait] in each iteration
/// of the loop.  Do not re-use the instance after exiting the loop.
class BackoffMachine {
  BackoffMachine();

  final double _firstDuration = 100;
  final double _durationCeiling = 10 * 1000;
  final double _base = 2;

  DateTime? _startTime;

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
  /// until a ceiling is reached.  E.g., if firstDuration is 100 and
  /// durationCeiling is 10 * 1000 = 10000, the sequence is:
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
  Future<void> wait() async {
    _startTime ??= DateTime.now();

    final duration =
      Random().nextDouble() // "Jitter"
      * min(_durationCeiling,
            _firstDuration * pow(_base, _waitsCompleted));

    await Future.delayed(Duration(milliseconds: duration.round()));

    _waitsCompleted++;
  }
}
