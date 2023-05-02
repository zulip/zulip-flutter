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
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmitted(BuildContext context, String value) async {
    final Uri? url = Uri.tryParse(value);
    switch (url) {
      case Uri(scheme: 'https' || 'http'):
        // TODO(#35): validate realm URL further?
        break;
      default:
        // TODO(#35): give feedback to user on bad realm URL
        return;
    }

    // TODO(#35): show feedback that we're working, while fetching server settings
    final serverSettings = await getServerSettings(realmUrl: url);
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
                onSubmitted: (value) => _onSubmitted(context, value),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Your Zulip server URL')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _onSubmitted(context, _controller.text),
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

      await Navigator.of(context).pushAndRemoveUntil(
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
