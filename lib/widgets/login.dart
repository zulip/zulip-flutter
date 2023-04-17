import 'package:flutter/material.dart';

import '../api/core.dart';
import '../api/route/account.dart';
import '../api/route/realm.dart';
import '../api/route/users.dart';
import '../model/store.dart';
import 'app.dart';
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
    if (context.mounted) {} // https://github.com/dart-lang/linter/issues/4007
    else {
      return;
    }

    // TODO(#36): support login methods beyond email/password
    Navigator.push(context,
      EmailPasswordLoginPage.buildRoute(realmUrl: url, serverSettings: serverSettings));
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
            child: TextField(
              controller: _controller,
              onSubmitted: (value) => _onSubmitted(context, value),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Your Zulip server URL',
                suffixIcon: InkWell(
                  onTap: () => _onSubmitted(context, _controller.text),
                  child: const Icon(Icons.arrow_forward))))))));
  }
}

class EmailPasswordLoginPage extends StatefulWidget {
  const EmailPasswordLoginPage({
    super.key, required this.realmUrl, required this.serverSettings});

  final Uri realmUrl;
  final GetServerSettingsResult serverSettings;

  static Route<void> buildRoute({
      required Uri realmUrl, required GetServerSettingsResult serverSettings}) {
    return _LoginSequenceRoute(builder: (context) =>
      EmailPasswordLoginPage(realmUrl: realmUrl, serverSettings: serverSettings));
  }

  @override
  State<EmailPasswordLoginPage> createState() => _EmailPasswordLoginPageState();
}

class _EmailPasswordLoginPageState extends State<EmailPasswordLoginPage> {
  final GlobalKey<FormFieldState<String>> _emailKey = GlobalKey();
  final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey();

  Future<int> _getUserId(FetchApiKeyResult fetchApiKeyResult) async {
    final FetchApiKeyResult(:email, :apiKey) = fetchApiKeyResult;
    final auth = Auth(
      realmUrl: widget.realmUrl, email: email, apiKey: apiKey);
    final connection = LiveApiConnection(auth: auth); // TODO make this widget testable
    return (await getOwnUser(connection)).userId;
  }

  void _submit() async {
    final context = _emailKey.currentContext!;
    final realmUrl = widget.realmUrl;
    final String? email = _emailKey.currentState!.value;
    final String? password = _passwordKey.currentState!.value;
    if (email == null || password == null) {
      // TODO can these FormField values actually be null? when?
      return;
    }
    // TODO(#35): validate email is in the shape of an email

    final FetchApiKeyResult result;
    try {
      result = await fetchApiKey(
        realmUrl: realmUrl, username: email, password: password);
    } on Exception catch (e) { // TODO(#37): distinguish API exceptions
      // TODO(#35): give feedback to user on failed login
      debugPrint(e.toString());
      return;
    }

    // TODO(server-7): Rely on user_id from fetchApiKey.
    final int userId = result.userId ?? await _getUserId(result);
    if (context.mounted) {} // https://github.com/dart-lang/linter/issues/4007
    else {
      return;
    }

    final account = Account(
      realmUrl: realmUrl,
      email: result.email,
      apiKey: result.apiKey,
      userId: userId,
      zulipFeatureLevel: widget.serverSettings.zulipFeatureLevel,
      zulipVersion: widget.serverSettings.zulipVersion,
      zulipMergeBase: widget.serverSettings.zulipMergeBase,
    );
    final globalStore = GlobalStoreWidget.of(context);
    final accountId = await globalStore.insertAccount(account);
    if (context.mounted) {} // https://github.com/dart-lang/linter/issues/4007
    else {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      HomePage.buildRoute(accountId: accountId),
      (route) => (route is! _LoginSequenceRoute),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextFormField(
                  key: _emailKey,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address')),
                const SizedBox(height: 8),
                TextFormField(
                  key: _passwordKey,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    labelText: 'Password')),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Log in')),
              ]))))));
  }
}
