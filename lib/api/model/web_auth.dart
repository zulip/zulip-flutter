import 'dart:math';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

/// The authentication information contained in the zulip:// redirect URL.
class WebAuthPayload {
  final Uri realm;
  final String email;
  final int userId;
  final String otpEncryptedApiKey;

  WebAuthPayload._({
    required this.realm,
    required this.email,
    required this.userId,
    required this.otpEncryptedApiKey,
  });

  factory WebAuthPayload.parse(Uri url) {
    if (
      url case Uri(
        scheme: 'zulip',
        host: 'login',
        queryParameters: {
          'realm': String realmStr,
          'email': String email,
          'user_id': String userIdStr,
          'otp_encrypted_api_key': String otpEncryptedApiKey,
        },
      )
    ) {
      final Uri? realm = Uri.tryParse(realmStr);
      if (realm == null) throw const FormatException();

      final int? userId = int.tryParse(userIdStr, radix: 10);
      if (userId == null) throw const FormatException();

      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(otpEncryptedApiKey)) {
        throw const FormatException();
      }

      return WebAuthPayload._(
        otpEncryptedApiKey: otpEncryptedApiKey,
        email: email,
        userId: userId,
        realm: realm,
      );
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
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
