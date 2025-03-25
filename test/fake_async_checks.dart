import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';

extension FakeTimerChecks on Subject<FakeTimer> {
  Subject<Duration> get duration => has((t) => t.duration, 'duration');
}
