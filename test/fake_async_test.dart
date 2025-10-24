import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:test/scaffolding.dart';

import 'fake_async.dart';

void main() {
  group('awaitFakeAsync', () {
    test('basic success', () {
      const duration = Duration(milliseconds: 100);
      check(awaitFakeAsync((async) async {
        final start = clock.now();
        await Future<void>.delayed(duration);
        return clock.now().difference(start);
      })).equals(duration);
    });

    int someFunction() => throw _TestException();

    test('propagates error from future returned by callback', () {
      try {
        awaitFakeAsync((async) async => someFunction());
        assert(false);
      } catch (e, s) {
        check(e).isA<_TestException>();
        check(s.toString()).contains('someFunction');
      }
    });

    test('propagates error from callback itself', () {
      try {
        awaitFakeAsync((async) => Future.value(someFunction()));
        assert(false);
      } catch (e, s) {
        check(e).isA<_TestException>();
        check(s.toString()).contains('someFunction');
      }
    });

    test('TimeoutException on deadlocked callback', () {
      check(() => awaitFakeAsync((async) async {
        await Completer<void>().future;
      })).throws<TimeoutException>();
    });
  });
}

class _TestException {}
