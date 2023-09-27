
import 'package:collection/collection.dart';

/// Returns the index in [sortedList] of an element matching the given [key],
/// if there is one.
///
/// Returns -1 if there is no matching element.
///
/// The return values of [compare] are interpreted in the same way as for
/// [Comparable.compareTo]: a negative value of `compare(element, key)` means
/// the element goes before the key, zero means the element matches the key,
/// and positive means the element goes after the key.
///
/// The list [sortedList] must be sorted in the sense that any elements that
/// compare before [key] come before any elements that match [key] or
/// compare after it, and any elements that match [key] come before any
/// elements that compare after [key].
/// If the list is not sorted, the return value may be arbitrary.
///
/// Only the portion of the list from [start] to [end] (defaulting to 0
/// and `sortedList.length` respectively, so to the entire list) is searched,
/// and only that portion need be sorted.
// Based on binarySearchBy in package:collection/src/algorithms.dart .
int binarySearchByKey<E, K>(
  List<E> sortedList,
  K key,
  int Function(E element, K key) compare,
  [int start = 0, int? end]
) {
  end = RangeError.checkValidRange(start, end, sortedList.length);
  int min = start;
  int max = end;
  while (min < max) {
    final mid = min + ((max - min) >> 1);
    final element = sortedList[mid];
    final comp = compare(element, key);
    if (comp == 0) return mid;
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

bool isSortedWithoutDuplicates(List<int> items) {
  final length = items.length;
  if (length == 0) {
    return true;
  }
  int lastItem = items[0];
  for (int i = 1; i < length; i++) {
    final item = items[i];
    if (item <= lastItem) {
      return false;
    }
    lastItem = item;
  }
  return true;
}

/// The union of sets, represented as sorted lists.
///
/// The inputs must be sorted (by `<`) and without duplicates (by `==`).
///
/// The output will contain all the elements found in either input, again
/// sorted and without duplicates.
// When implementing this, it was convenient to have it return a [QueueList].
// We can make it more general if needed:
//   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20unreads.20model/near/1647754
QueueList<int> setUnion(Iterable<int> xs, Iterable<int> ys) {
  // This will overshoot by the number of elements that occur in both lists.
  // That may make this optimization less effective, but it will not cause
  // incorrectness.
  final capacity = xs is List && ys is List // [List]s should have efficient `.length`
    ? xs.length + ys.length
    : null;
  final result = QueueList<int>(capacity);

  final iterX = xs.iterator;
  final iterY = ys.iterator;
  late bool xHasElement;
  void moveX() => xHasElement = iterX.moveNext();
  late bool yHasElement;
  void moveY() => yHasElement = iterY.moveNext();

  moveX();
  moveY();
  while (true) {
    if (!xHasElement || !yHasElement) {
      break;
    }

    int x = iterX.current;
    int y = iterY.current;
    if (x < y) {
      result.add(x);
      moveX();
    } else if (x != y) {
      result.add(y);
      moveY();
    } else { // x == y
      result.add(x);
      moveX();
      moveY();
    }
  }
  while (xHasElement) {
    result.add(iterX.current);
    moveX();
  }
  while (yHasElement) {
    result.add(iterY.current);
    moveY();
  }
  return result;
}
