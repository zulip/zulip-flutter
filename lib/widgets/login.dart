import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/core.dart';
import '../api/exception.dart';
import '../api/route/account.dart';
import '../api/route/realm.dart';
import '../api/route/users.dart';
import '../model/store.dart';
import 'app.dart';
import 'dialog.dart';
import 'input.dart';
import 'page.dart';
import 'store.dart';

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

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  bool _inProgress = false;

  final ServerUrlTextEditingController _controller = ServerUrlTextEditingController();
  late ServerUrlParseResult _parseResult;

  _serverUrlChanged() {
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

  Future<void> _onSubmitted(BuildContext context) async {
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
        // TODO make this function testable by controlling ApiConnection
        final connection = ApiConnection.live(realmUrl: url!, zulipFeatureLevel: null);
        try {
          serverSettings = await getServerSettings(connection);
        } finally {
          connection.close();
        }
      } catch (e) {
        if (!context.mounted) {
          return;
        }
        // TODO(#105) give more helpful feedback; see `fetchServerSettings`
        //   in zulip-mobile's src/message/fetchActions.js.
        showErrorDialog(context: context,
          title: zulipLocalizations.errorLoginCouldNotConnectTitle,
          message: zulipLocalizations.errorLoginCouldNotConnect(url.toString()));
        return;
      }
      // https://github.com/dart-lang/linter/issues/4007
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      // TODO(#36): support login methods beyond username/password
      Navigator.push(context,
        PasswordLoginPage.buildRoute(serverSettings: serverSettings));
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
                  labelText: zulipLocalizations.loginServerUrlInputLabel,
                  errorText: errorText,
                  helperText: kLayoutPinningHelperText,
                  hintText: 'your-org.zulipchat.com')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: !_inProgress && errorText == null
                  ? () => _onSubmitted(context)
                  : null,
                child: Text(zulipLocalizations.dialogContinue)),
            ])))));
  }
}

class PasswordLoginPage extends StatefulWidget {
  const PasswordLoginPage({super.key, required this.serverSettings});

  final GetServerSettingsResult serverSettings;

  static Route<void> buildRoute({required GetServerSettingsResult serverSettings}) {
    return _LoginSequenceRoute(
      page: PasswordLoginPage(serverSettings: serverSettings));
  }

  @override
  State<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends State<PasswordLoginPage> {
  bool _inProgress = false;

  Future<void> _tryInsertAccountAndNavigate({
    required String email,
    required String apiKey,
    required int userId,
  }) async {
    final globalStore = GlobalStoreWidget.of(context);
    // TODO(#108): give feedback to user on SQL exception, like dupe realm+user
    final accountId = await globalStore.insertAccount(AccountsCompanion.insert(
      realmUrl: widget.serverSettings.realmUrl,
      email: email,
      apiKey: apiKey,
      userId: userId,
      zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
      zulipVersion: widget.serverSettings.zulipVersion,
      zulipMergeBase: Value(widget.serverSettings.zulipMergeBase),
    ));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      HomePage.buildRoute(accountId: accountId),
      (route) => (route is! _LoginSequenceRoute),
    );
  }

  Future<int> _getUserId(String email, apiKey) async {
    final connection = ApiConnection.live( // TODO make this widget testable
      realmUrl: widget.serverSettings.realmUrl,
      zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
      email: email, apiKey: apiKey);
    return (await getOwnUser(connection)).userId;
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.loginPageTitle),
        bottom: _inProgress
          ? const PreferredSize(preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(minHeight: 4)) // 4 restates default
          : null),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _UsernamePasswordForm(loginPageState: this)))));
  }
}

class _UsernamePasswordForm extends StatefulWidget {
  const _UsernamePasswordForm({required this.loginPageState});

  final _PasswordLoginPageState loginPageState;

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
    final String username = usernameFieldState.value!;
    final String password = passwordFieldState.value!;

    widget.loginPageState.setState(() {
      widget.loginPageState._inProgress = true;
    });
    try {
      final FetchApiKeyResult result;
      try {
        // TODO make this function testable by controlling ApiConnection
        final connection = ApiConnection.live(realmUrl: realmUrl,
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
      keyboardType: TextInputType.visiblePassword,
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
