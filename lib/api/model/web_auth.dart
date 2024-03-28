import 'dart:math';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

/// The authentication information contained in the zulip:// redirect URL.
class WebAuthPayload {
  final String otpEncryptedApiKey;
  final String email;
  final int? userId; // TODO(server-5) new in FL 108
  final Uri realm;

  WebAuthPayload._({
    required this.otpEncryptedApiKey,
    required this.email,
    required this.userId,
    required this.realm,
  });

  factory WebAuthPayload.parse(Uri url) {
    if (
      url case Uri(
        scheme: 'zulip',
        host: 'login',
        queryParameters: {
          'email': String(isEmpty: false) && var email,
          'realm': String(isEmpty: false) && var realmStr,
          'otp_encrypted_api_key': String(isEmpty: false) && var otpEncryptedApiKey,
        },
      )
    ) {
      // TODO(server-5) require in queryParameters (new in FL 108)
      final userIdStr = url.queryParameters['user_id'];
      int? userId;
      if (userIdStr != null) {
        final maybeParsed = int.tryParse(userIdStr, radix: 10);
        if (maybeParsed == null) {
          throw const FormatException();
        }
        userId = maybeParsed;
      }

      final Uri realm;
      final maybeParsedRealm = Uri.tryParse(realmStr);
      if (maybeParsedRealm == null) {
        throw const FormatException();
      }
      realm = maybeParsedRealm;

      return WebAuthPayload._(
        otpEncryptedApiKey: otpEncryptedApiKey,
        email: email,
        userId: userId,
        realm: realm,
      );
    } else {
      throw const FormatException();
    }
  }

  String decodeApiKey(String otp) {
    final otpBytes = hex.decode(otp);
    final otpEncryptedApiKeyBytes = hex.decode(otpEncryptedApiKey);
    if (otpBytes.length != otpEncryptedApiKeyBytes.length) {
      throw const FormatException();
    }
    return String.fromCharCodes(Iterable.generate(otpBytes.length,
      (i) => otpBytes[i] ^ otpEncryptedApiKeyBytes[i]));
  }
}

String generateOtp() {
  final rand = Random.secure();
  final Uint8List bytes = Uint8List.fromList(
    List.generate(32, (_) => rand.nextInt(256)));
  return hex.encode(bytes);
}

/// For tests, create an OTP-encrypted API key.
@visibleForTesting
String debugEncodeApiKey(String apiKey, String otp) {
  final apiKeyBytes = apiKey.codeUnits;
  assert(apiKeyBytes.every((byte) => byte <= 0xff));
  final otpBytes = hex.decode(otp);
  assert(apiKeyBytes.length == otpBytes.length);
  return hex.encode(List.generate(otpBytes.length,
    (i) => apiKeyBytes[i] ^ otpBytes[i]));
}
