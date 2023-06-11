import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/content.dart';

void main() {
  testWidgets('Throws if no `PerAccountStoreWidget` ancestor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RealmContentNetworkImage('https://zulip.invalid/path/to/image.png', filterQuality: FilterQuality.medium));
    check(tester.takeException()).isA<AssertionError>();
  });

  // TODO(#30): Simulate a `PerAccountStoreWidget` ancestor, to use in more tests:
  // TODO: 'Includes auth header if `src` is on-realm'
  // TODO: 'Excludes auth header if `src` is off-realm'
}
