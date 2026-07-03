import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:zulip/api/model/narrow.dart';

void main() {
  // resolveApiNarrowForServer is covered in test/api/route/messages_test.dart,
  // in the ApiNarrow.toJson test.

  test('ApiNarrowSearch: constructor assertions', () {
    check(() => ApiNarrowSearch('search query')).returnsNormally();
    check(() => ApiNarrowSearch(' search')).throws<void>();
    check(() => ApiNarrowSearch('query ')).throws<void>();
    check(() => ApiNarrowSearch('  ')).throws<void>();
  });
}
