import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api/route/realm.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../values/constants.dart';
import '../../utils/page.dart';
import '../../values/text.dart';
import '../../values/theme.dart';
import 'login_controller.dart';

class _LoginSequenceRoute extends MaterialWidgetRoute<void> {
  _LoginSequenceRoute({required super.page});
}

class AddAccountPage extends GetView<LoginController> {
  const AddAccountPage({super.key});

  static Route<void> buildRoute() {
    return _LoginSequenceRoute(page: const AddAccountPage());
  }

  static const _serverUrlHint = 'your-org.zulipchat.com';

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final error = controller.parseResult.value?.error;
    final errorText = error == null || error.shouldDeferFeedback()
        ? null
        : error.message(zulipLocalizations);

    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.loginAddAnAccountPageTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Obx(
            () => controller.inProgress.value
                ? const LinearProgressIndicator(minHeight: 4)
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: controller.serverUrlController,
                  onSubmitted: (_) => controller.onServerUrlSubmitted(context),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onEditingComplete: () {
                    controller.serverUrlController.clearComposing();
                  },
                  decoration: InputDecoration(
                    labelText: zulipLocalizations.loginServerUrlLabel,
                    errorText: errorText,
                    helperText: kLayoutPinningHelperText,
                    hintText: AddAccountPage._serverUrlHint,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => ElevatedButton(
                    onPressed: !controller.inProgress.value && errorText == null
                        ? () => controller.onServerUrlSubmitted(context)
                        : null,
                    child: Text(zulipLocalizations.dialogContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  static Route<void> buildRoute({
    required GetServerSettingsResult serverSettings,
  }) {
    return _LoginSequenceRoute(page: LoginPage());
  }

  static Future<void> handleWebAuthUrl(Uri url) async {
    return Get.find<LoginController>().handleWebAuthUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final zulipLocalizations = ZulipLocalizations.of(context);
    final serverSettings = Get.arguments as GetServerSettingsResult?;

    final externalAuthenticationMethods =
        serverSettings!.externalAuthenticationMethods;

    final loginContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _UsernamePasswordForm(
          serverSettings: serverSettings,
          controller: controller,
        ),
        if (externalAuthenticationMethods.isNotEmpty) ...[
          _AlternativeAuthDivider(),
          ...externalAuthenticationMethods.map((method) {
            final icon = method.displayIcon;
            return Obx(
              () => OutlinedButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.secondaryContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onSecondaryContainer,
                  ),
                ),
                icon: icon != null
                    ? Image.network(icon, width: 24, height: 24)
                    : null,
                onPressed: !controller.inProgress.value
                    ? () => controller.beginWebAuth(method)
                    : null,
                label: Text(
                  zulipLocalizations.signInWithFoo(method.displayName),
                ),
              ),
            );
          }),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.loginPageTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Obx(
            () => controller.inProgress.value
                ? const LinearProgressIndicator(minHeight: 4)
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 8),
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: loginContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsernamePasswordForm extends StatefulWidget {
  const _UsernamePasswordForm({
    required this.serverSettings,
    required this.controller,
  });

  final GetServerSettingsResult serverSettings;
  final LoginController controller;

  @override
  State<_UsernamePasswordForm> createState() => _UsernamePasswordFormState();
}

class _UsernamePasswordFormState extends State<_UsernamePasswordForm> {
  final GlobalKey<FormFieldState<String>> _usernameKey = GlobalKey();
  final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey();

  void _submit() async {
    final usernameFieldState = _usernameKey.currentState!;
    final passwordFieldState = _passwordKey.currentState!;
    final usernameValid = usernameFieldState.validate();
    final passwordValid = passwordFieldState.validate();
    if (!usernameValid || !passwordValid) {
      return;
    }
    final String username = usernameFieldState.value!.trim();
    final String password = passwordFieldState.value!;

    await widget.controller.submitCredentials(
      username: username,
      password: password,
      context: context,
      requireEmailFormatUsernames:
          widget.serverSettings.requireEmailFormatUsernames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final requireEmailFormatUsernames =
        widget.serverSettings.requireEmailFormatUsernames;

    final usernameField = TextFormField(
      key: _usernameKey,
      autofillHints: [
        if (!requireEmailFormatUsernames) AutofillHints.username,
        AutofillHints.email,
      ],
      keyboardType: TextInputType.emailAddress,
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
      ),
    );

    final passwordField = Obx(
      () => TextFormField(
        key: _passwordKey,
        autofillHints: const [AutofillHints.password],
        obscureText: widget.controller.obscurePassword.value,
        keyboardType: widget.controller.obscurePassword.value
            ? null
            : TextInputType.visiblePassword,
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
          suffixIcon: Obx(
            () => IconButton(
              tooltip: zulipLocalizations.loginHidePassword,
              onPressed: widget.controller.togglePasswordVisibility,
              icon: const Icon(Icons.visibility),
              isSelected: widget.controller.obscurePassword.value,
              selectedIcon: const Icon(Icons.visibility_off),
            ),
          ),
        ),
      ),
    );

    return Form(
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            usernameField,
            const SizedBox(height: 8),
            passwordField,
            const SizedBox(height: 8),
            Obx(
              () => ElevatedButton(
                onPressed: widget.controller.inProgress.value ? null : _submit,
                child: Text(zulipLocalizations.loginFormSubmitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativeAuthDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    final divider = Expanded(
      child: Divider(color: designVariables.loginOrDivider, thickness: 2),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Semantics(
        excludeSemantics: true,
        label: zulipLocalizations.loginMethodDividerSemanticLabel,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            divider,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                zulipLocalizations.loginMethodDivider,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: designVariables.loginOrDividerText,
                  height: 1.5,
                ).merge(weightVariableTextStyle(context, wght: 600)),
              ),
            ),
            divider,
          ],
        ),
      ),
    );
  }
}
