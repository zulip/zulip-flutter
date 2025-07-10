import 'dart:math';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/algorithms.dart';

void main() {
  group('binarySearchByKey', () {
    late List<({int data})> list;

    int search(int key) => binarySearchByKey(list, key, (element, key) =>
      element.data.compareTo(key));

    test('empty', () {
      list = [];
      check(search(1)).equals(-1);
    });

    test('2 elements', () {
      list = [(data: 2), (data: 4)];
      check(search(1)).equals(-1);
      check(search(2)).equals(0);
      check(search(3)).equals(-1);
      check(search(4)).equals(1);
      check(search(5)).equals(-1);
    });

    test('3 elements', () {
      list = [(data: 2), (data: 4), (data: 6)];
      // Exercise the binary search before, at, and after each element of the list.
      check(search(1)).equals(-1);
      check(search(2)).equals(0);
      check(search(3)).equals(-1);
      check(search(4)).equals(1);
      check(search(5)).equals(-1);
      check(search(6)).equals(2);
      check(search(7)).equals(-1);
    });
  });

  group('setUnion', () {
    for (final (String desc, Iterable<int> xs, Iterable<int> ys) in [
      ('empty', [], []),
      ('nonempty, empty', [1, 2], []),
      ('empty, nonempty', [], [1, 2]),
      ('in order', [1, 2], [3, 4]),
      ('reversed', [3, 4], [1, 2]),
      ('interleaved', [1, 3], [2, 4]),
      ('all dupes', [1, 2], [1, 2]),
      ('some dupes', [1, 2], [2, 3]),
      ('comparison is numeric, not lexicographic', [11], [2]),
    ]) {
      test(desc, () {
        final expected = Set.of(xs.followedBy(ys)).toList()..sort();
        check(setUnion(xs, ys)).deepEquals(expected);
      });
    }
  });

  group('bucketSort', () {
    /// Same spec as [bucketSort], except slow: N * B time instead of N + B.
    List<T> simpleBucketSort<T>(Iterable<T> xs, int Function(T) bucketOf, {
      required int numBuckets,
    }) {
      return Iterable.generate(numBuckets,
        (k) => xs.where((s) => bucketOf(s) == k)).flattenedToList;
    }

    void checkBucketSort<T>(Iterable<T> xs, {
      required int Function(T) bucketOf, required int numBuckets,
    }) {
      check(bucketSort(xs, bucketOf, numBuckets: numBuckets)).deepEquals(
        simpleBucketSort<T>(xs, bucketOf, numBuckets: numBuckets));
    }

    int stringBucket(String s) => s.codeUnits.last - '0'.codeUnits.single;

    test('explicit result, interleaved: 4 elements, 2 buckets', () {
      check(bucketSort(['a1', 'd0', 'c1', 'b0'], stringBucket, numBuckets: 2))
        .deepEquals(['d0', 'b0', 'a1', 'c1']);
    });

    List<_SortablePair> generatePairs(Iterable<int> keys) {
      var token = 0;
      return keys.map((k) => _SortablePair(k, "${token++}")).toList();
    }

    void checkSortPairs(int numBuckets, Iterable<int> keys) {
      checkBucketSort(numBuckets: numBuckets, bucketOf: (p) => p.key,
        generatePairs(keys));
    }

    test('empty list, zero buckets', () {
      checkSortPairs(0, []);
    });

    test('empty, some buckets', () {
      checkSortPairs(3, []);
    });

    test('interleaved: 4 elements, 2 buckets', () {
      checkSortPairs(2, [1, 0, 1, 0]);
    });

    test('some buckets empty: 10 elements in 3 of 10 buckets', () {
      checkSortPairs(10, [9, 9, 9, 5, 5, 5, 1, 1, 1, 1]);
    });

    test('one big bucket', () {
      checkSortPairs(1, Iterable.generate(100, (_) => 0));
    });

    const seed = 4321;

    Iterable<int> randomKeys({required int numBuckets, required int length}) {
      final rand = Random(seed);
      return Iterable.generate(length, (_) => rand.nextInt(numBuckets));
    }

    test('long random list, 1000 in 2 buckets', () {
      checkSortPairs(2, randomKeys(numBuckets: 2, length: 1000));
    });

    test('long random list, 1000 in 1000 buckets', () {
      checkSortPairs(1000, randomKeys(numBuckets: 1000, length: 1000));
    });

    test('sparse random list, 100 in 1000 buckets', () {
      checkSortPairs(1000, randomKeys(numBuckets: 1000, length: 100));
    });
  });
}

class _SortablePair {
  _SortablePair(this.key, this.tag);

  final int key;
  final String tag;

  @override
  bool operator ==(Object other) {
    return other is _SortablePair && key == other.key && tag == other.tag;
  }

  @override
  int get hashCode => Object.hash(key, tag);

  @override
  String toString() => "$tag:$key";
}
