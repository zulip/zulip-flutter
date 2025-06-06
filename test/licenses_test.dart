import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/licenses.dart';

import 'fake_async.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smoke: ensure all additional licenses load', () => awaitFakeAsync((async) async {
    await check(additionalLicenses().toList())
      .completes((it) => it.isNotEmpty());
  }));
}
