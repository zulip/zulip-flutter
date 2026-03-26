// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:get/get.dart' hide Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';

import '../../../get/app_pages.dart';
import '../../../api/core.dart';
import '../../../api/exception.dart';
import '../../../api/model/web_auth.dart';
import '../../../api/route/account.dart';
import '../../../api/route/realm.dart';
import '../../../api/route/users.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/global_service.dart';
import '../../../log.dart';
import '../../../model/binding.dart';
import '../../../model/server_support.dart';
import '../../../model/store.dart' hide Value;
import '../../../model/store.dart' as store_model;
import '../../widgets/dialog.dart';

enum ServerUrlValidationError {
  empty,
  invalidUrl,
  noUseEmail,
  unsupportedSchemeZulip,
  unsupportedSchemeOther;

  bool shouldDeferFeedback() {
    switch (this) {
      case empty:
      case invalidUrl:
        return true;
      case noUseEmail:
      case unsupportedSchemeZulip:
      case unsupportedSchemeOther:
        return false;
    }
  }

  String message(ZulipLocalizations zulipLocalizations) {
    switch (this) {
      case empty:
        return zulipLocalizations.serverUrlValidationErrorEmpty;
      case invalidUrl:
        return zulipLocalizations.serverUrlValidationErrorInvalidUrl;
      case noUseEmail:
        return zulipLocalizations.serverUrlValidationErrorNoUseEmail;
      case unsupportedSchemeZulip:
      case unsupportedSchemeOther:
        return zulipLocalizations.serverUrlValidationErrorUnsupportedScheme;
    }
  }
}

class ServerUrlParseResult {
  ServerUrlParseResult.ok(this.url) : error = null;
  ServerUrlParseResult.error(this.error) : url = null;

  final Uri? url;
  final ServerUrlValidationError? error;
}

class ServerUrlTextEditingController extends TextEditingController {
  ServerUrlParseResult tryParse() {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return ServerUrlParseResult.error(ServerUrlValidationError.empty);
    }

    Uri? url = Uri.tryParse(trimmedText);
    if (!RegExp(r'^https?://').hasMatch(trimmedText)) {
      if (url != null && url.scheme == 'zulip') {
        return ServerUrlParseResult.error(
          ServerUrlValidationError.unsupportedSchemeZulip,
        );
      } else if (url != null &&
          url.hasScheme &&
          url.scheme != 'http' &&
          url.scheme != 'https') {
        return ServerUrlParseResult.error(
          ServerUrlValidationError.unsupportedSchemeOther,
        );
      }
      url = Uri.tryParse('https://$trimmedText');
    }

    if (url == null || !url.isAbsolute) {
      return ServerUrlParseResult.error(ServerUrlValidationError.invalidUrl);
    }
    if (url.userInfo.isNotEmpty) {
      return ServerUrlParseResult.error(ServerUrlValidationError.noUseEmail);
    }
    return ServerUrlParseResult.ok(url);
  }
}

class LoginController extends GetxController {
  final ServerUrlTextEditingController serverUrlController =
      ServerUrlTextEditingController();
  final Rx<ServerUrlParseResult?> parseResult = Rx<ServerUrlParseResult?>(null);
  final RxBool inProgress = false.obs;
  final RxBool obscurePassword = true.obs;

  GetServerSettingsResult? serverSettings;

  @override
  void onInit() {
    super.onInit();
    parseResult.value = serverUrlController.tryParse();
    serverUrlController.addListener(_onServerUrlChanged);
  }

  @override
  void onClose() {
    serverUrlController.dispose();
    super.onClose();
  }

  void _onServerUrlChanged() {
    parseResult.value = serverUrlController.tryParse();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> onServerUrlSubmitted(BuildContext context) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final url = parseResult.value?.url;
    final error = parseResult.value?.error;

    if (error != null) {
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorLoginInvalidInputTitle,
        message: error.message(zulipLocalizations),
      );
      return;
    }
    assert(url != null);

    inProgress.value = true;
    try {
      final globalStore = GlobalService.to.globalStore;
      if (globalStore == null) throw StateError('GlobalStore not initialized');
      final serverSettingsResult = await globalStore.fetchServerSettings(url!);

      final zulipVersionData = ZulipVersionData.fromServerSettings(
        serverSettingsResult,
      );
      if (zulipVersionData.isUnsupported) {
        throw ServerVersionUnsupportedException(zulipVersionData);
      }

      serverSettings = serverSettingsResult;
    } catch (e) {
      if (!context.mounted) return;

      String? message;
      Uri? learnMoreButtonUrl;
      switch (e) {
        case ServerVersionUnsupportedException(:final data):
          message = zulipLocalizations.errorServerVersionUnsupportedMessage(
            url.toString(),
            data.zulipVersion,
            kMinSupportedZulipVersion,
          );
          learnMoreButtonUrl = kServerSupportDocUrl;
        default:
          message = zulipLocalizations.errorLoginCouldNotConnect(
            url.toString(),
          );
      }
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorCouldNotConnectTitle,
        message: message,
        learnMoreButtonUrl: learnMoreButtonUrl,
      );
      return;
    }
    inProgress.value = false;

    unawaited(Get.toNamed(AppRoutes.login, arguments: serverSettings));
  }

  Future<void> handleWebAuthUrl(Uri url) async {
    inProgress.value = true;
    try {
      await ZulipBinding.instance.closeInAppWebView();

      final otp = generateOtp();
      if (serverSettings == null) throw Error();

      final payload = WebAuthPayload.parse(url);
      if (payload.realm.origin != serverSettings!.realmUrl.origin) {
        throw Error();
      }
      final apiKey = payload.decodeApiKey(otp);
      await tryInsertAccountAndNavigate(
        context: Get.context!,
        userId: payload.userId,
        email: payload.email,
        apiKey: apiKey,
      );
    } catch (e) {
      assert(debugLog(e.toString()));
      final context = Get.context;
      if (context == null) return;

      final zulipLocalizations = ZulipLocalizations.of(context);
      String message = zulipLocalizations.errorWebAuthOperationalError;
      if (e is PlatformException && e.message != null) {
        message = e.message!;
      }
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorWebAuthOperationalErrorTitle,
        message: message,
      );
    } finally {
      inProgress.value = false;
    }
  }

  Future<void> beginWebAuth(ExternalAuthenticationMethod method) async {
    if (serverSettings == null) return;

    final otp = generateOtp();
    try {
      final url = serverSettings!.realmUrl
          .resolve(method.loginUrl)
          .replace(queryParameters: {'mobile_flow_otp': otp});

      await ZulipBinding.instance.launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      assert(debugLog(e.toString()));

      if (e is PlatformException &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          e.message != null &&
          e.message!.startsWith('Error while launching')) {
        return;
      }

      final context = Get.context;
      if (context == null) return;

      final zulipLocalizations = ZulipLocalizations.of(context);
      String message = zulipLocalizations.errorWebAuthOperationalError;
      if (e is PlatformException && e.message != null) {
        message = e.message!;
      }
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorWebAuthOperationalErrorTitle,
        message: message,
      );
    }
  }

  Future<void> tryInsertAccountAndNavigate({
    required BuildContext context,
    required String email,
    required String apiKey,
    required int userId,
  }) async {
    final globalStore = GlobalService.to.globalStore;
    if (globalStore == null) throw StateError('GlobalStore not initialized');
    final realmUrl = serverSettings!.realmUrl;
    final int accountId;
    try {
      accountId = await globalStore.insertAccount(
        AccountsCompanion.insert(
          realmUrl: realmUrl,
          realmName: store_model.Value(serverSettings!.realmName),
          realmIcon: store_model.Value(serverSettings!.realmIcon),
          email: email,
          apiKey: apiKey,
          userId: userId,
          zulipFeatureLevel: serverSettings!.zulipFeatureLevel,
          zulipVersion: serverSettings!.zulipVersion,
          zulipMergeBase: store_model.Value(serverSettings!.zulipMergeBase),
          possibleLegacyPushToken: const store_model.Value(false),
        ),
      );
    } on AccountAlreadyExistsException {
      if (!context.mounted) {
        return;
      }
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorAccountLoggedInTitle,
        message: zulipLocalizations.errorAccountLoggedIn(
          email,
          realmUrl.toString(),
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    unawaited(
      Get.offAllNamed<dynamic>(
        AppRoutes.home,
        arguments: {'accountId': accountId},
      ),
    );
  }

  Future<int> getUserId(
    String email,
    String apiKey,
    BuildContext context,
  ) async {
    final connection = GlobalService.to.createConnection(
      realmUrl: serverSettings!.realmUrl,
      zulipFeatureLevel: serverSettings!.zulipFeatureLevel,
      email: email,
      apiKey: apiKey,
    );
    try {
      return (await getOwnUser(connection)).userId;
    } finally {
      connection.close();
    }
  }

  Future<void> submitCredentials({
    required String username,
    required String password,
    required BuildContext context,
    required bool requireEmailFormatUsernames,
  }) async {
    inProgress.value = true;
    try {
      final connection = GlobalService.to.createConnection(
        realmUrl: serverSettings!.realmUrl,
        zulipFeatureLevel: serverSettings!.zulipFeatureLevel,
      );
      try {
        final result = await fetchApiKey(
          connection,
          username: username,
          password: password,
        );
        if (!context.mounted) return;

        final usernameTrimmed = username.trim();

        final int userId = await getUserId(
          usernameTrimmed,
          result.apiKey,
          context,
        );

        if (!context.mounted) {
          return;
        }

        await tryInsertAccountAndNavigate(
          context: context,
          email: result.email,
          apiKey: result.apiKey,
          userId: userId,
        );
      } on ApiRequestException catch (e) {
        if (!context.mounted) return;
        final zulipLocalizations = ZulipLocalizations.of(context);
        final message = (e is ZulipApiException)
            ? zulipLocalizations.errorServerMessage(e.message)
            : e.message;
        showErrorDialog(
          context: context,
          title: zulipLocalizations.errorLoginFailedTitle,
          message: message,
        );
        return;
      } finally {
        connection.close();
      }
    } finally {
      inProgress.value = false;
    }
  }
}
