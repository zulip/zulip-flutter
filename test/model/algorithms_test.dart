
import 'package:checks/checks.dart';
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
}
