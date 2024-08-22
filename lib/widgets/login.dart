import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/core.dart';
import '../api/exception.dart';
import '../api/model/web_auth.dart';
import '../api/route/account.dart';
import '../api/route/realm.dart';
import '../api/route/users.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/server_support.dart';
import '../model/store.dart';
import 'dialog.dart';
import 'home.dart';
import 'input.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

class _LoginSequenceRoute extends MaterialWidgetRoute<void> {
  _LoginSequenceRoute({
    required super.page,
  });
}

enum ServerUrlValidationError {
  empty,
  invalidUrl,
  noUseEmail,
  unsupportedSchemeZulip,
  unsupportedSchemeOther;

  /// Whether to wait until the user presses "submit" to give error feedback.
  ///
  /// True for errors that will often happen when the user just hasn't finished
  /// typing a good URL. False for errors that strongly signal a wrong path was
  /// taken, like when we recognize the form of an email address.
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
        // Someone might get the idea to try one of the "zulip://" URLs that
        // are discussed sometimes.
        // TODO(log): Log to Sentry? How much does this happen, if at all? Maybe
        //   log once when the input enters this error state, but don't spam
        //   on every keystroke/render while it's in it.
        return ServerUrlParseResult.error(ServerUrlValidationError.unsupportedSchemeZulip);
      } else if (url != null && url.hasScheme && url.scheme != 'http' && url.scheme != 'https') {
        return ServerUrlParseResult.error(ServerUrlValidationError.unsupportedSchemeOther);
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

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  static Route<void> buildRoute() {
    return _LoginSequenceRoute(page: const AddAccountPage());
  }

  /// The hint text to show in the "Zulip server URL" input.
  ///
  /// If this contains an example value, it must be one that has been reserved
  /// so that it cannot point to a real Zulip realm (nor any unknown other site).
  /// The realm name `your-org` under zulipchat.com is reserved for this reason.
  /// See discussion:
  ///   https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/flutter.3A.20login.20URL/near/1570347
  // TODO(i18n): In principle this should be translated, because it's trying to
  //   convey to the user the English phrase "your org".  But doing that is
  //   tricky because of the need to have the example name reserved.
  //   Realistically that probably means we'll only ever translate this for
  //   at most a handful of languages, most likely none.
  static const _serverUrlHint = 'your-org.zulipchat.com';

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  bool _inProgress = false;

  final ServerUrlTextEditingController _controller = ServerUrlTextEditingController();
  late ServerUrlParseResult _parseResult;

  void _serverUrlChanged() {
    setState(() {
      _parseResult = _controller.tryParse();
    });
  }

  @override
  void initState() {
    super.initState();
    _parseResult = _controller.tryParse();
    _controller.addListener(_serverUrlChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(BuildContext context) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final url = _parseResult.url;
    final error = _parseResult.error;
    if (error != null) {
      showErrorDialog(context: context,
        title: zulipLocalizations.errorLoginInvalidInputTitle,
        message: error.message(zulipLocalizations));
      return;
    }
    assert(url != null);

    setState(() {
      _inProgress = true;
    });
    try {
      final GetServerSettingsResult serverSettings;
      try {
        final globalStore = GlobalStoreWidget.of(context);
        final connection = globalStore.apiConnection(realmUrl: url!, zulipFeatureLevel: null);
        try {
          serverSettings = await getServerSettings(connection);
          final zulipVersionData = ZulipVersionData.fromServerSettings(serverSettings);
          if (zulipVersionData.isUnsupported) {
            throw ServerVersionUnsupportedException(zulipVersionData);
          }
        } on MalformedServerResponseException catch (e) {
          final zulipVersionData = ZulipVersionData.fromMalformedServerResponseException(e);
          if (zulipVersionData != null && zulipVersionData.isUnsupported) {
            throw ServerVersionUnsupportedException(zulipVersionData);
          }
          rethrow;
        } finally {
          connection.close();
        }
      } catch (e) {
        if (!context.mounted) return;

        String? message;
        Uri? learnMoreButtonUrl;
        switch (e) {
          case ServerVersionUnsupportedException(:final data):
            message = zulipLocalizations.errorServerVersionUnsupportedMessage(
              url.toString(),
              data.zulipVersion,
              kMinSupportedZulipVersion);
            learnMoreButtonUrl = kServerSupportDocUrl;
          default:
            // TODO(#105) give more helpful feedback; see `fetchServerSettings`
            //   in zulip-mobile's src/message/fetchActions.js.
            message = zulipLocalizations.errorLoginCouldNotConnect(url.toString());
        }
        showErrorDialog(context: context,
          title: zulipLocalizations.errorCouldNotConnectTitle,
          message: message,
          learnMoreButtonUrl: learnMoreButtonUrl);
        return;
      }
      if (!context.mounted) return;

      unawaited(Navigator.push(context,
        LoginPage.buildRoute(serverSettings: serverSettings)));
    } finally {
      setState(() {
        _inProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final zulipLocalizations = ZulipLocalizations.of(context);
    final error = _parseResult.error;
    final errorText = error == null || error.shouldDeferFeedback()
      ? null
      : error.message(zulipLocalizations);

    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.loginAddAnAccountPageTitle),
        bottom: _inProgress
          ? const PreferredSize(preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(minHeight: 4)) // 4 restates default
          : null),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // TODO(#109) Link to doc about what a "server URL" is and how to find it
              // TODO(#111) Perhaps give tappable realm URL suggestions based on text typed so far
              TextField(
                controller: _controller,
                onSubmitted: (value) => _onSubmitted(context),
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onEditingComplete: () {
                  // Repeat default implementation by clearing IME compose session…
                  _controller.clearComposing();
                  // …but leave out unfocusing the input in case more editing is needed.
                },
                decoration: InputDecoration(
                  labelText: zulipLocalizations.loginServerUrlLabel,
                  errorText: errorText,
                  helperText: kLayoutPinningHelperText,
                  hintText: AddAccountPage._serverUrlHint)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: !_inProgress && errorText == null
                  ? () => _onSubmitted(context)
                  : null,
                child: Text(zulipLocalizations.dialogContinue)),
            ])))));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.serverSettings});

  static Route<void> buildRoute({required GetServerSettingsResult serverSettings}) {
    return _LoginSequenceRoute(
      page: LoginPage(serverSettings: serverSettings, key: _lastBuiltKey));
  }

  final GetServerSettingsResult serverSettings;

  /// Log in using the payload of a web-auth URL like zulip://login?…
  static Future<void> handleWebAuthUrl(Uri url) async {
    return _lastBuiltKey.currentState?.handleWebAuthUrl(url);
  }

  /// A key for the page from the last [buildRoute] call.
  static final _lastBuiltKey = GlobalKey<_LoginPageState>();

  /// The OTP to use, instead of an app-generated one, for testing.
  @visibleForTesting
  static String? debugOtpOverride;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _inProgress = false;

  String? get _otp {
    String? result;
    assert(() {
      result = LoginPage.debugOtpOverride;
      return true;
    }());
    return result ?? __otp;
  }
  String? __otp;

  Future<void> handleWebAuthUrl(Uri url) async {
    setState(() {
      _inProgress = true;
    });
    try {
      await ZulipBinding.instance.closeInAppWebView();

      if (_otp == null) throw Error();
      final payload = WebAuthPayload.parse(url);
      if (payload.realm.origin != widget.serverSettings.realmUrl.origin) throw Error();
      final apiKey = payload.decodeApiKey(_otp!);
      await _tryInsertAccountAndNavigate(
        userId: payload.userId,
        email: payload.email,
        apiKey: apiKey,
      );
    } catch (e) {
      assert(debugLog(e.toString()));
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);

      String message = zulipLocalizations.errorWebAuthOperationalError;
      if (e is PlatformException && e.message != null) {
        message = e.message!;
      }
      showErrorDialog(context: context,
        title: zulipLocalizations.errorWebAuthOperationalErrorTitle,
        message: message);
    } finally {
      setState(() {
        _inProgress = false;
        __otp = null;
      });
    }
  }

  Future<void> _beginWebAuth(ExternalAuthenticationMethod method) async {
    __otp = generateOtp();
    try {
      final url = widget.serverSettings.realmUrl.resolve(method.loginUrl)
        .replace(queryParameters: {'mobile_flow_otp': _otp!});

      // Could set [_inProgress]… but we'd need to unset it if the web-auth
      // attempt is aborted (by the user closing the browser, for example),
      // and I don't think we can reliably know when that happens.

      // Not using [PlatformActions.launchUrl] because web auth needs special
      // error handling.
      await ZulipBinding.instance.launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      assert(debugLog(e.toString()));

      if (e is PlatformException
        && defaultTargetPlatform == TargetPlatform.iOS
        && e.message != null && e.message!.startsWith('Error while launching')) {
        // Ignore; I've seen this on my iPhone even when auth succeeds.
        // Specifically, Apple web auth…which on iOS should be replaced by
        // Apple native auth; that's #462.
        // Possibly related:
        //   https://github.com/flutter/flutter/issues/91660
        // but in that issue, people report authentication not succeeding.
        // TODO(#462) remove this?
        return;
      }

      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);

      String message = zulipLocalizations.errorWebAuthOperationalError;
      if (e is PlatformException && e.message != null) {
        message = e.message!;
      }
      showErrorDialog(context: context,
        title: zulipLocalizations.errorWebAuthOperationalErrorTitle,
        message: message);
    }
  }

  Future<void> _tryInsertAccountAndNavigate({
    required String email,
    required String apiKey,
    required int userId,
  }) async {
    final globalStore = GlobalStoreWidget.of(context);
    final realmUrl = widget.serverSettings.realmUrl;
    final int accountId;
    try {
      accountId = await globalStore.insertAccount(AccountsCompanion.insert(
        realmUrl: realmUrl,
        email: email,
        apiKey: apiKey,
        userId: userId,
        zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
        zulipVersion: widget.serverSettings.zulipVersion,
        zulipMergeBase: Value(widget.serverSettings.zulipMergeBase),
      ));
      // TODO give feedback to user on other SQL exceptions
    } on AccountAlreadyExistsException {
      if (!mounted) {
        return;
      }
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorAccountLoggedInTitle,
        message: zulipLocalizations.errorAccountLoggedIn(
          email, realmUrl.toString()));
      return;
    }

    if (!mounted) {
      return;
    }

    HomePage.navigate(context, accountId: accountId);
  }

  Future<int> _getUserId(String email, String apiKey) async {
    final globalStore = GlobalStoreWidget.of(context);
    final connection = globalStore.apiConnection(
      realmUrl: widget.serverSettings.realmUrl,
      zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
      email: email, apiKey: apiKey);
    try {
      return (await getOwnUser(connection)).userId;
    } finally {
      connection.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final colorScheme = Theme.of(context).colorScheme;
    final zulipLocalizations = ZulipLocalizations.of(context);

    final externalAuthenticationMethods = widget.serverSettings.externalAuthenticationMethods;

    final loginForm = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _UsernamePasswordForm(loginPageState: this),
      if (externalAuthenticationMethods.isNotEmpty) ...[
        const OrDivider(),
        ...externalAuthenticationMethods.map((method) {
          final icon = method.displayIcon;
          return OutlinedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colorScheme.secondaryContainer),
              foregroundColor: WidgetStatePropertyAll(colorScheme.onSecondaryContainer)),
            icon: icon != null
              ? Image.network(icon, width: 24, height: 24)
              : null,
            onPressed: !_inProgress
              ? () => _beginWebAuth(method)
              : null,
            label: Text(
              zulipLocalizations.signInWithFoo(method.displayName)));
        }),
      ],
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.loginPageTitle),
        bottom: _inProgress
          ? const PreferredSize(preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(minHeight: 4)) // 4 restates default
          : null),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 8),
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              // TODO also detect vertical scroll gestures that start on the
              //   left or the right of this box
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: loginForm))))));
  }
}

class _UsernamePasswordForm extends StatefulWidget {
  const _UsernamePasswordForm({required this.loginPageState});

  final _LoginPageState loginPageState;

  @override
  State<_UsernamePasswordForm> createState() => _UsernamePasswordFormState();
}

class _UsernamePasswordFormState extends State<_UsernamePasswordForm> {
  final GlobalKey<FormFieldState<String>> _usernameKey = GlobalKey();
  final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey();

  bool _obscurePassword = true;
  void _handlePasswordVisibilityPress() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _submit() async {
    final serverSettings = widget.loginPageState.widget.serverSettings;

    final context = _usernameKey.currentContext!;
    final realmUrl = serverSettings.realmUrl;
    final usernameFieldState = _usernameKey.currentState!;
    final passwordFieldState = _passwordKey.currentState!;
    final usernameValid = usernameFieldState.validate(); // Side effect: on-field error text
    final passwordValid = passwordFieldState.validate(); // Side effect: on-field error text
    if (!usernameValid || !passwordValid) {
      return;
    }
    final String username = usernameFieldState.value!.trim();
    final String password = passwordFieldState.value!;

    widget.loginPageState.setState(() {
      widget.loginPageState._inProgress = true;
    });
    try {
      final FetchApiKeyResult result;
      try {
        final globalStore = GlobalStoreWidget.of(context);
        final connection = globalStore.apiConnection(realmUrl: realmUrl,
          zulipFeatureLevel: serverSettings.zulipFeatureLevel);
        try {
          result = await fetchApiKey(connection,
            username: username, password: password);
        } finally {
          connection.close();
        }
      } on ApiRequestException catch (e) {
        if (!context.mounted) return;
        // TODO(#105) give more helpful feedback. The RN app is
        //   unhelpful here; we should at least recognize invalid auth errors, and
        //   errors for deactivated user or realm (see zulip-mobile#4571).
        final zulipLocalizations = ZulipLocalizations.of(context);
        final message = (e is ZulipApiException)
          ? zulipLocalizations.errorServerMessage(e.message)
          : e.message;
        showErrorDialog(context: context,
          title: zulipLocalizations.errorLoginFailedTitle,
          message: message);
        return;
      }

      // TODO(server-7): Rely on user_id from fetchApiKey.
      final int userId = result.userId
        ?? await widget.loginPageState._getUserId(result.email, result.apiKey);
      // https://github.com/dart-lang/linter/issues/4007
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      await widget.loginPageState._tryInsertAccountAndNavigate(
        email: result.email,
        apiKey: result.apiKey,
        userId: userId,
      );
    } finally {
      widget.loginPageState.setState(() {
        widget.loginPageState._inProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final serverSettings = widget.loginPageState.widget.serverSettings;
    final zulipLocalizations = ZulipLocalizations.of(context);
    final requireEmailFormatUsernames = serverSettings.requireEmailFormatUsernames;

    final usernameField = TextFormField(
      key: _usernameKey,
      autofillHints: [
        if (!requireEmailFormatUsernames) AutofillHints.username,
        AutofillHints.email,
      ],
      keyboardType: TextInputType.emailAddress,
      // TODO(upstream?): Apparently pressing "next" doesn't count
      //   as user interaction, and validation isn't done.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return requireEmailFormatUsernames
            ? zulipLocalizations.loginErrorMissingEmail
            : zulipLocalizations.loginErrorMissingUsername;
        }
        if (requireEmailFormatUsernames) {
          // TODO(#106): validate is in the shape of an email
        }
        return null;
      },
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: requireEmailFormatUsernames
          ? zulipLocalizations.loginEmailLabel
          : zulipLocalizations.loginUsernameLabel,
        helperText: kLayoutPinningHelperText,
      ));

    final passwordField = TextFormField(
      key: _passwordKey,
      autofillHints: const [AutofillHints.password],
      obscureText: _obscurePassword,
      keyboardType: _obscurePassword ? null : TextInputType.visiblePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return zulipLocalizations.loginErrorMissingPassword;
        }
        return null;
      },
      textInputAction: TextInputAction.go,
      onFieldSubmitted: (value) => _submit(),
      decoration: InputDecoration(
        labelText: zulipLocalizations.loginPasswordLabel,
        helperText: kLayoutPinningHelperText,
        suffixIcon: IconButton(
          tooltip: zulipLocalizations.loginHidePassword,
          onPressed: _handlePasswordVisibilityPress,
          icon: const Icon(Icons.visibility),
          isSelected: _obscurePassword,
          selectedIcon: const Icon(Icons.visibility_off),
        )));

    return Form(
      // TODO(#110) Try to highlight CZO / Zulip Cloud realms in autofill
      child: AutofillGroup(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          usernameField,
          const SizedBox(height: 8),
          passwordField,
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.loginPageState._inProgress ? null : _submit,
            child: Text(zulipLocalizations.loginFormSubmitLabel)),
        ])));
  }
}

// Loosely based on the corresponding element in the web app.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    final divider = Expanded(
      child: Divider(color: designVariables.loginOrDivider, thickness: 2));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(zulipLocalizations.loginMethodDivider,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: designVariables.loginOrDividerText,
              height: 1.5,
            ).merge(weightVariableTextStyle(context, wght: 600)))),
        divider,
      ]));
  }
}
