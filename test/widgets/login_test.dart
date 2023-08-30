import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/widgets/login.dart';

import '../model/binding.dart';
import '../stdlib_checks.dart';
import '../example_data.dart' as eg;

void main() {
  TestZulipBinding.ensureInitialized();

  group('AuthMethodsPage', () {
    Future<void> setupPage(WidgetTester tester, {
      required GetServerSettingsResult serverSettings,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthMethodsPage(serverSettings: serverSettings)));
    }

    testWidgets('shows all the external methods', (tester) async {
      final methods = <ExternalAuthenticationMethod>[
        eg.externalAuthenticationMethod(
          name: 'some_new_method',
          displayName: 'Some new method',
        ),
        eg.externalAuthenticationMethod(
          name: 'github',
          displayName: 'Github',
        ),
      ];
      await setupPage(
        tester,
        serverSettings: eg.serverSettings(
          emailAuthEnabled: false, // don't show password method
          externalAuthenticationMethods: methods));

      final widgets = tester.widgetList<OutlinedButton>(
        find.ancestor(
          of: find.textContaining('Sign in with'),
          matching: find.byType(OutlinedButton))
      );
      check(widgets.length).equals(methods.length);
    });

    testWidgets('shows all the methods', (tester) async {
      final methods = <ExternalAuthenticationMethod>[
        eg.externalAuthenticationMethod(
          name: 'some_new_method',
          displayName: 'Some new method',
        ),
        eg.externalAuthenticationMethod(
          name: 'github',
          displayName: 'Github',
        ),
      ];
      await setupPage(
        tester,
        serverSettings: eg.serverSettings(
          emailAuthEnabled: true, // show password method
          externalAuthenticationMethods: methods));

      final widgets = tester.widgetList<OutlinedButton>(
        find.ancestor(
          of: find.textContaining('Sign in with'),
          matching: find.byType(OutlinedButton))
      );
      check(widgets.length).equals(methods.length + 1);
    });

    testWidgets('untested methods disabled', (tester) async {
      final untestedMethod = eg.externalAuthenticationMethod(
        name: 'some_new_method',
        displayName: 'Some new method',
      );
      await setupPage(
        tester,
        serverSettings: eg.serverSettings(externalAuthenticationMethods: [untestedMethod]));

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sign in with ${untestedMethod.displayName}'),
          matching: find.byType(OutlinedButton)));
      check(button.enabled).isFalse();
    });

    testWidgets('tested methods enabled', (tester) async {
      final testedMethod = eg.externalAuthenticationMethod(
        name: 'github',
        displayName: 'Github',
      );
      await setupPage(
        tester,
        serverSettings: eg.serverSettings(externalAuthenticationMethods: [testedMethod]));

      final button = tester.firstWidget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sign in with ${testedMethod.displayName}'),
          matching: find.byType(OutlinedButton)));
      check(button.enabled).isTrue();
    });
  });

  group('ServerUrlTextEditingController.tryParse', () {
    final controller = ServerUrlTextEditingController();

    expectUrlFromText(String text, String expectedUrl) {
      test('text "$text" gives URL "$expectedUrl"', () {
        controller.text = text;
        final result = controller.tryParse();
        check(result.error).isNull();
        check(result.url).isNotNull().asString.equals(expectedUrl);
      });
    }

    expectErrorFromText(String text, ServerUrlValidationError expectedError) {
      test('text "$text" gives error "$expectedError"', () {
        controller.text = text;
        final result = controller.tryParse();
        check(result.url).isNull();
        check(result.error).equals(expectedError);
      });
    }

    expectUrlFromText('https://chat.zulip.org',   'https://chat.zulip.org');
    expectUrlFromText('https://chat.zulip.org/',  'https://chat.zulip.org/');
    expectUrlFromText(' https://chat.zulip.org ', 'https://chat.zulip.org');
    expectUrlFromText('http://chat.zulip.org',    'http://chat.zulip.org');
    expectUrlFromText('chat.zulip.org',           'https://chat.zulip.org');
    expectUrlFromText('192.168.1.21:9991',        'https://192.168.1.21:9991');
    expectUrlFromText('http://192.168.1.21:9991', 'http://192.168.1.21:9991');

    expectErrorFromText('',                  ServerUrlValidationError.empty);
    expectErrorFromText(' ',                 ServerUrlValidationError.empty);
    expectErrorFromText('zulip://foo',       ServerUrlValidationError.unsupportedSchemeZulip);
    expectErrorFromText('ftp://foo',         ServerUrlValidationError.unsupportedSchemeOther);
    expectErrorFromText('!@#*asd;l4fkj',     ServerUrlValidationError.invalidUrl);
    expectErrorFromText('email@example.com', ServerUrlValidationError.noUseEmail);
  });
}
