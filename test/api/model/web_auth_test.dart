import 'package:checks/checks.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/web_auth.dart';

import '../../example_data.dart' as eg;

void main() {
  group('WebAuthPayload', () {
    const otp = '186f6d085a5621ebaf1ccfc05033e8acba57dae03f061705ac1e58c402c30a31';
    final encryptedApiKey = debugEncodeApiKey(eg.selfAccount.apiKey, otp);
    final wellFormed = Uri.parse(
      'zulip://login?otp_encrypted_api_key=$encryptedApiKey'
        '&email=self%40example&user_id=1&realm=https%3A%2F%2Fchat.example%2F');

    test('basic happy case', () {
      final payload = WebAuthPayload.parse(wellFormed);
      check(payload)
        ..otpEncryptedApiKey.equals(encryptedApiKey)
        ..email.equals('self@example')
        ..userId.equals(1)
        ..realm.equals(Uri.parse('https://chat.example/'));
      check(payload.decodeApiKey(otp)).equals(eg.selfAccount.apiKey);
    });

    test('parse fails when an expected field is missing', () {
      final queryParams = {...wellFormed.queryParameters}..remove('email');
      final input = wellFormed.replace(queryParameters: queryParams);
      check(() => WebAuthPayload.parse(input)).throws<FormatException>();
    });

    test('parse fails when otp_encrypted_api_key is wrong length', () {
      final queryParams = {...wellFormed.queryParameters}
        ..['otp_encrypted_api_key'] = 'asdf';
      final input = wellFormed.replace(queryParameters: queryParams);
      check(() => WebAuthPayload.parse(input)).throws<FormatException>();
    });

    test('parse fails when host is not "login"', () {
      final input = wellFormed.replace(host: 'foo');
      check(() => WebAuthPayload.parse(input)).throws<FormatException>();
    });

    test('parse fails when scheme is not "zulip"', () {
      final input = wellFormed.replace(scheme: 'https');
      check(() => WebAuthPayload.parse(input)).throws<FormatException>();
    });

    test('decodeApiKey fails when otp is wrong length', () {
      final payload = WebAuthPayload.parse(wellFormed);
      check(() => payload.decodeApiKey('asdf')).throws<FormatException>();
    });
  });

  group('generateOtp', () {
    test('smoke, and check all 256 byte values are used', () {
      // This is a probabilistic test.  We've chosen `n` so that when the test
      // should pass, the probability it fails is < 1e-9.  See analysis below.
      const n = 216;
      final manyOtps = List.generate(n, (_) => generateOtp());

      final bytesThatAppear = <int>{};
      for (final otp in manyOtps) {
        final bytes = hex.decode(otp);
        check(bytes).length.equals(32);
        bytesThatAppear.addAll(bytes);
      }

      // Each possible value gets n * 32 opportunities to show up,
      // each with probability 1/256; so the probability of missing all of those
      // is exp(- n * 32 / 256) < 2e-12, and there are 256 such possible
      // byte values so the probability that any of them gets missed is < 1e-9.
      for (final byteValue in Iterable<int>.generate(256)) {
        check(bytesThatAppear).contains(byteValue);
      }
    });
  });
}

extension WebAuthPayloadChecks on Subject<WebAuthPayload> {
  Subject<String> get otpEncryptedApiKey => has((x) => x.otpEncryptedApiKey, 'otpEncryptedApiKey');
  Subject<String> get email => has((x) => x.email, 'email');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<Uri> get realm => has((x) => x.realm, 'realm');
}
