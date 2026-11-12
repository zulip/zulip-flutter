import 'dart:async';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

void main() {
  // Only one ZulipBinding can be constructed per isolate,
  // and each test file gets its own isolate.
  // So this file has room for just one test.
  test('LiveZulipBinding.getGlobalStore: no cache a failed load', () async {
    final binding = LoadingLiveZulipBinding();

    // Two callers wait on one load.
    // The first will retry as soon as it sees an error.
    Future<GlobalStore>? retryFuture;
    final future1 = binding.getGlobalStore().catchError((Object error) {
      retryFuture = binding.getGlobalStore();
      throw error;
    });
    final future2 = binding.getGlobalStore();
    check(binding.completers).length.equals(1);

    // The load fails, and both callers get the error.
    final error = Exception('failed to load');
    binding.completers.single.completeError(error);
    await check(future1).throws<Exception>((it) => it.identicalTo(error));
    await check(future2).throws<Exception>((it) => it.identicalTo(error));
    check(binding.getGlobalStoreSync()).isNull();

    // The retry starts a new load, rather than repeating the error,
    // and a later call waits on that same load.
    check(binding.completers).length.equals(2);
    final future3 = binding.getGlobalStore();
    check(binding.completers).length.equals(2);

    // When that load succeeds, its store is cached, as usual.
    final store = eg.globalStore();
    binding.completers.last.complete(store);
    check(await retryFuture!).identicalTo(store);
    check(await future3).identicalTo(store);
    check(binding.getGlobalStoreSync()).identicalTo(store);
    check(await binding.getGlobalStore()).identicalTo(store);
    check(binding.completers).length.equals(2);
  });
}

class LoadingLiveZulipBinding extends LiveZulipBinding {
  List<Completer<GlobalStore>> completers = [];

  @override
  Future<GlobalStore> doLoadGlobalStore() {
    final completer = Completer<GlobalStore>();
    completers.add(completer);
    return completer.future;
  }
}
