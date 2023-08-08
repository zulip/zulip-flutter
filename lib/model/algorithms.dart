
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
