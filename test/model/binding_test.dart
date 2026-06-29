import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/binding.dart';

import 'binding.dart';
import 'binding_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('IosDeviceInfo.majorVersion', () {
    test('typical', () {
      check(const IosDeviceInfo(systemVersion: '17.5.1')).majorVersion.equals(17);
    });

    test('two-part', () {
      check(const IosDeviceInfo(systemVersion: '18')).majorVersion.equals(18);
    });

    test('unparseable', () {
      check(const IosDeviceInfo(systemVersion: 'garbage')).majorVersion.isNull();
    });

    test('unparseable (empty string)', () {
      check(const IosDeviceInfo(systemVersion: '')).majorVersion.isNull();
    });
  });
}
