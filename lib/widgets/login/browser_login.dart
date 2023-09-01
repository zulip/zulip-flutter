import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/route/realm.dart';
import '../../log.dart';
import '../../model/store.dart';
import '../app.dart';
import '../login.dart';
import '../store.dart';

/// An InheritedWidget to co-ordinate the browser auth flow
///
/// The provided [navigatorKey] by this object should be attached to
/// the main app widget so that when the browser redirects to the app
/// using the universal link this widget can use it to access the current
/// navigator instance.
///
/// This object also stores the temporarily generated OTP required for
/// the completion of the flow.
class BrowserLoginWidget extends InheritedWidget {
  BrowserLoginWidget({super.key, required super.child});

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // TODO: Maybe store these on local DB too, because OS can close the
  //       app while user is using the browser during the auth flow.

  // Temporary mobile_flow_otp, that was generated while initiating a browser auth flow.
  final Map<Uri, String> _tempAuthOtp = {};
  // Temporary server settngs, that was stored while initiating a browser auth flow.
  final Map<Uri, GetServerSettingsResult> _tempServerSettings = {};

  @override
  bool updateShouldNotify(covariant BrowserLoginWidget oldWidget) =>
    !identical(oldWidget.navigatorKey, navigatorKey)
    && !identical(oldWidget._tempAuthOtp, _tempAuthOtp)
    && !identical(oldWidget._tempServerSettings, _tempServerSettings);

  static BrowserLoginWidget of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<BrowserLoginWidget>();
    assert(widget != null, 'No BrowserLogin ancestor');
    return widget!;
  }

  Future<void> openLoginUrl(GetServerSettingsResult serverSettings, String loginUrl) async {
    // Generate a temporary otp and store it for later use - for decoding the
    // api key returned by server which will be XOR-ed with this otp.
    final otp = _generateMobileFlowOtp();
    _tempAuthOtp[serverSettings.realmUri] = otp;
    _tempServerSettings[serverSettings.realmUri] = serverSettings;

    // Open the browser
    await launchUrl(serverSettings.realmUri.replace(
      path: loginUrl,
      queryParameters: {'mobile_flow_otp': otp},
    ));
  }

  Future<void> loginFromExternalRoute(BuildContext context, Uri uri) async {
    final globalStore = GlobalStoreWidget.of(context);

    // Parse the query params from the browser redirect url
    final String otpEncryptedApiKey;
    final String email;
    final int userId;
    final Uri realm;
    try {
      if (uri.queryParameters case {
        'otp_encrypted_api_key': final String otpEncryptedApiKeyStr,
        'email': final String emailStr,
        'user_id': final String userIdStr,
        'realm': final String realmStr,
      }) {
        if (otpEncryptedApiKeyStr.isEmpty || emailStr.isEmpty || userIdStr.isEmpty || realmStr.isEmpty) {
          throw 'Got invalid query params from browser redirect url';
        }
        otpEncryptedApiKey = otpEncryptedApiKeyStr;
        realm = Uri.parse(realmStr);
        userId = int.parse(userIdStr);
        email = emailStr;
      } else {
        throw 'Got invalid query params from browser redirect url';
      }
    } catch (e, st) {
      // TODO: Log error to Sentry
      debugLog('$e\n$st');
      return;
    }

    // Get the previously temporarily stored otp & serverSettings.
    final GetServerSettingsResult serverSettings;
    final String apiKey;
    try {
      final otp = _tempAuthOtp[realm];
      _tempAuthOtp.clear();
      final settings = _tempServerSettings[realm];
      _tempServerSettings.clear();
      if (otp == null) {
        throw 'Failed to find the previously generated mobile_auth_otp';
      }
      if (settings == null) {
        // TODO: Maybe try refetching instead of error-ing out.
        throw 'Failed to find the previously stored serverSettings';
      }

      // Decode the otp XOR-ed api key
      apiKey = _decodeApiKey(otp, otpEncryptedApiKey);
      serverSettings = settings;
    } catch (e, st) {
      // TODO: Log error to Sentry
      debugLog('$e\n$st');
      return;
    }

    // TODO(#108): give feedback to user on SQL exception, like dupe realm+user
    final accountId = await globalStore.insertAccount(AccountsCompanion.insert(
      realmUrl: serverSettings.realmUri,
      email: email,
      apiKey: apiKey,
      userId: userId,
      zulipFeatureLevel: serverSettings.zulipFeatureLevel,
      zulipVersion: serverSettings.zulipVersion,
      zulipMergeBase: Value(serverSettings.zulipMergeBase),
    ));

    if (!context.mounted) {
      return;
    }
    navigatorKey.currentState?.pushAndRemoveUntil(
      HomePage.buildRoute(accountId: accountId),
      (route) => (route is! LoginSequenceRoute),
    );
  }
}

/// Generates a `mobile_flow_otp` to be used by the server for
/// mobile login flow, server XOR's the api key with the otp hex
/// and returns the resulting value. So, the same otp that was passed
/// to the server can be used again to decode the actual api key.
String _generateMobileFlowOtp() {
  final rand = Random.secure();
  return hex.encode(rand.nextBytes(32));
}

String _decodeApiKey(String otp, String otpEncryptedApiKey) {
  final otpHex = hex.decode(otp);
  final otpEncryptedApiKeyHex = hex.decode(otpEncryptedApiKey);
  return String.fromCharCodes(otpHex ^ otpEncryptedApiKeyHex);
}

// TODO: Remove this when upstream issue is fixed
//  https://github.com/dart-lang/sdk/issues/53339
extension _RandomNextBytes on Random {
  static const int _pow2_32 = 0x100000000;
  Uint8List nextBytes(int length) {
    if ((length % 4) != 0) {
      throw ArgumentError('\'length\' must be a multiple of 4');
    }
    final result = Uint32List(length);
    for (int i = 0; i < length; i++) {
      result[i] = nextInt(_pow2_32);
    }
    return result.buffer.asUint8List(0, length);
  }
}

extension _IntListOpXOR on List<int> {
  Iterable<int> operator ^(List<int> other) sync* {
    if (length != other.length) {
      throw ArgumentError('Both lists must have the same length');
    }
    for (var i = 0; i < length; i++) {
      yield this[i] ^ other[i];
    }
  }
}
