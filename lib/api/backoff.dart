import 'dart:math';

/// A machine that can sleep for increasing durations, for network backoff.
///
/// Call the constructor before a loop starts, and call [wait] in each iteration
/// of the loop.  Do not re-use the instance after exiting the loop.
class BackoffMachine {
  BackoffMachine({
    this.firstBound = const Duration(milliseconds: 100),
    this.maxBound = const Duration(seconds: 10),
  }) : assert(firstBound <= maxBound);

  /// How many waits have completed so far.
  ///
  /// Use this to implement "give up" logic by breaking out of the loop after
  /// a threshold number of waits.
  int get waitsCompleted => _waitsCompleted;
  int _waitsCompleted = 0;

  /// The upper bound on the duration of the first wait.
  ///
  /// The actual duration will vary randomly up to this value; see [wait].
  final Duration firstBound;

  /// The maximum upper bound on the duration of each wait,
  /// even after many waits.
  ///
  /// The actual durations will vary randomly up to this value; see [wait].
  final Duration maxBound;

  /// The factor the bound is multiplied by at each wait,
  /// until it reaches [maxBound].
  ///
  /// This factor determines the bound on a given wait
  /// as a multiple of the *bound* that applied to the previous wait,
  /// not the (random) previous wait duration itself.
  static const double base = 2;

  /// In debug mode, overrides the duration of the backoff wait.
  ///
  /// Outside of debug mode, this is always `null` and the setter has no effect.
  static Duration? get debugDuration {
    Duration? result;
    assert(() {
      result = _debugDuration;
      return true;
    }());
    return result;
  }
  static Duration? _debugDuration;
  static set debugDuration(Duration? newValue) {
    assert(() {
      _debugDuration = newValue;
      return true;
    }());
  }

  /// A future that resolves after an appropriate backoff time,
  /// with jitter applied to capped exponential growth.
  ///
  /// Each [wait] computes an upper bound on its wait duration,
  /// in a sequence growing exponentially from [firstBound]
  /// to a cap of [maxBound] by factors of [base].
  /// With their default values, this sequence is, in seconds:
  ///
  ///   0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 6.4, 10, 10, 10, ...
  ///
  /// To provide jitter, the actual wait duration is chosen randomly
  /// on the whole interval from zero up to the computed upper bound.
  ///
  /// This jitter strategy with a lower bound of zero is reported to be more
  /// effective than some widespread strategies that use narrower intervals.
  /// The purpose of jitter is to mitigate "bursts" where many clients make
  /// requests in a short period; the larger the range of randomness,
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
    final bound = _minDuration(maxBound,
                               firstBound * pow(base, _waitsCompleted));
    final duration = debugDuration ?? _maxDuration(const Duration(microseconds: 1),
                                                   bound * Random().nextDouble());
    await Future<void>.delayed(duration);
    _waitsCompleted++;
  }
}

Duration _minDuration(Duration a, Duration b) {
  return a <= b ? a : b;
}

Duration _maxDuration(Duration a, Duration b) {
  return a >= b ? a : b;
}
