import 'package:flutter/material.dart';

import '../api/core.dart';
import '../api/route/account.dart';
import '../api/route/realm.dart';
import '../api/route/users.dart';
import '../model/store.dart';
import 'app.dart';
import 'dialog.dart';
import 'input.dart';
import 'store.dart';

class _LoginSequenceRoute extends MaterialPageRoute<void> {
  _LoginSequenceRoute({
    required super.builder,
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

  String message() { // TODO(i18n)
    switch (this) {
      case empty:
        return 'Please enter a URL.';
      case invalidUrl:
        return 'Please enter a valid URL.';
      case noUseEmail:
        return 'Please enter the server URL, not your email.';
      case unsupportedSchemeZulip:
      case unsupportedSchemeOther:
        return 'The server URL must start with http:// or https://.';
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
    return _LoginSequenceRoute(builder: (context) =>
      const AddAccountPage());
  }

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
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
    final url = _parseResult.url;
    final error = _parseResult.error;
    if (error != null) {
      showErrorDialog(context: context,
        title: 'Invalid input', message: error.message());
      return;
    }
    assert(url != null);

    // TODO(#35): show feedback that we're working, while fetching server settings
    final serverSettings = await getServerSettings(realmUrl: url!);
    // https://github.com/dart-lang/linter/issues/4007
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    // TODO(#36): support login methods beyond email/password
    Navigator.push(context,
      EmailPasswordLoginPage.buildRoute(serverSettings: serverSettings));
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final error = _parseResult.error;
    final errorText = error == null || error.shouldDeferFeedback()
      ? null
      : error.message();

    // TODO(#35): more help to user on entering realm URL
    return Scaffold(
      appBar: AppBar(title: const Text('Add an account')),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextField(
                controller: _controller,
                onSubmitted: (value) => _onSubmitted(context),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Your Zulip server URL',
                  errorText: errorText,
                  helperText: kLayoutPinningHelperText)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: errorText == null
                  ? () => _onSubmitted(context)
                  : null,
                child: const Text('Continue')),
            ])))));
  }
}

class EmailPasswordLoginPage extends StatefulWidget {
  const EmailPasswordLoginPage({super.key, required this.serverSettings});

  final GetServerSettingsResult serverSettings;

  static Route<void> buildRoute({required GetServerSettingsResult serverSettings}) {
    return _LoginSequenceRoute(builder: (context) =>
      EmailPasswordLoginPage(serverSettings: serverSettings));
  }

  @override
  State<EmailPasswordLoginPage> createState() => _EmailPasswordLoginPageState();
}

class _EmailPasswordLoginPageState extends State<EmailPasswordLoginPage> {
  final GlobalKey<FormFieldState<String>> _emailKey = GlobalKey();
  final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey();

  bool _obscurePassword = true;
  void _handlePasswordVisibilityPress() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  bool _inProgress = false;

  Future<int> _getUserId(FetchApiKeyResult fetchApiKeyResult) async {
    final FetchApiKeyResult(:email, :apiKey) = fetchApiKeyResult;
    final auth = Auth(
      realmUrl: widget.serverSettings.realmUri, email: email, apiKey: apiKey);
    final connection = LiveApiConnection(auth: auth); // TODO make this widget testable
    return (await getOwnUser(connection)).userId;
  }

  void _submit() async {
    final context = _emailKey.currentContext!;
    final realmUrl = widget.serverSettings.realmUri;
    final emailFieldState = _emailKey.currentState!;
    final passwordFieldState = _passwordKey.currentState!;
    final emailValid = emailFieldState.validate(); // Side effect: on-field error text
    final passwordValid = passwordFieldState.validate(); // Side effect: on-field error text
    if (!emailValid || !passwordValid) {
      return;
    }
    final String email = emailFieldState.value!;
    final String password = passwordFieldState.value!;

    setState(() {
      _inProgress = true;
    });
    try {
      final FetchApiKeyResult result;
      try {
        result = await fetchApiKey(
          realmUrl: realmUrl, username: email, password: password);
      } on Exception { // TODO(#37): distinguish API exceptions
        if (!context.mounted) return;
        // TODO(#35) give more helpful feedback. Needs #37. The RN app is
        //   unhelpful here; we should at least recognize invalid auth errors, and
        //   errors for deactivated user or realm (see zulip-mobile#4571).
        showErrorDialog(context: context, title: 'Login failed');
        return;
      }

      // TODO(server-7): Rely on user_id from fetchApiKey.
      final int userId = result.userId ?? await _getUserId(result);
      // https://github.com/dart-lang/linter/issues/4007
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      final globalStore = GlobalStoreWidget.of(context);
      // TODO(#35): give feedback to user on SQL exception, like dupe realm+user
      final accountId = await globalStore.insertAccount(AccountsCompanion.insert(
        realmUrl: realmUrl,
        email: result.email,
        apiKey: result.apiKey,
        userId: userId,
        zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
        zulipVersion: widget.serverSettings.zulipVersion,
        zulipMergeBase: Value(widget.serverSettings.zulipMergeBase),
      ));
      // https://github.com/dart-lang/linter/issues/4007
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        HomePage.buildRoute(accountId: accountId),
        (route) => (route is! _LoginSequenceRoute),
      );
    } finally {
      setState(() {
        _inProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));

    final emailField = TextFormField(
      key: _emailKey,
      autofillHints: const [AutofillHints.email],
      keyboardType: TextInputType.emailAddress,
      // TODO(upstream?): Apparently pressing "next" doesn't count
      //   as user interaction, and validation isn't done.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email.';
        }
        // TODO(#35): validate is in the shape of an email
        return null;
      },
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email address',
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
          return 'Please enter your password.';
        }
        return null;
      },
      textInputAction: TextInputAction.go,
      onFieldSubmitted: (value) => _submit(),
      decoration: InputDecoration(
        labelText: 'Password',
        helperText: kLayoutPinningHelperText,
        suffixIcon: Semantics(label: 'Hide password', toggled: _obscurePassword,
          child: IconButton(
            onPressed: _handlePasswordVisibilityPress,
            icon: _obscurePassword
              ? const Icon(Icons.visibility_off)
              : const Icon(Icons.visibility)))));

    return Scaffold(
      appBar: AppBar(title: const Text('Log in'),
        bottom: _inProgress
          ? const PreferredSize(preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(minHeight: 4)) // 4 restates default
          : null),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              child: AutofillGroup(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  emailField,
                  const SizedBox(height: 8),
                  passwordField,
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _inProgress ? null : _submit,
                    child: const Text('Log in')),
                ])))))));
  }
}
