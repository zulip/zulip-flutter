
import '../model/initial_snapshot.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue() async {
  await Future.delayed(const Duration(seconds: 1));
  throw Exception("registerQueue: unimplemented");
}
