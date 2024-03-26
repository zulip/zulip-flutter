import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/route/account.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/widgets/login.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../stdlib_checks.dart';
import 'dialog_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

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

  // TODO test AddAccountPage

  group('LoginPage', () {
    late FakeApiConnection connection;

    Future<void> prepare(WidgetTester tester,
        GetServerSettingsResult serverSettings) async {
      addTearDown(testBinding.reset);

      connection = testBinding.globalStore.apiConnection(
        realmUrl: serverSettings.realmUrl,
        zulipFeatureLevel: serverSettings.zulipFeatureLevel);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: ZulipLocalizations.localizationsDelegates,
          supportedLocales: ZulipLocalizations.supportedLocales,
          home: GlobalStoreWidget(
            child: LoginPage(serverSettings: serverSettings))));
      await tester.pump(); // load global store
    }

    final findUsernameInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.email));
    final findPasswordInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.password));
    final findSubmitButton = find.widgetWithText(ElevatedButton, 'Log in');

    group('username/password login', () {
      void checkFetchApiKey({required String username, required String password}) {
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/fetch_api_key')
          ..bodyFields.deepEquals({
            'username': username,
            'password': password,
          });
      }

      testWidgets('basic happy case', (tester) async {
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        check(testBinding.globalStore.accounts).isEmpty();

        await tester.enterText(findUsernameInput, eg.selfAccount.email);
        await tester.enterText(findPasswordInput, 'p455w0rd');
        connection.prepare(json: FetchApiKeyResult(
          apiKey: eg.selfAccount.apiKey,
          email: eg.selfAccount.email,
          userId: eg.selfAccount.userId,
        ).toJson());
        await tester.tap(findSubmitButton);
        checkFetchApiKey(username: eg.selfAccount.email, password: 'p455w0rd');
        await tester.idle();
        check(testBinding.globalStore.accounts).single
          .equals(eg.selfAccount.copyWith(
            id: testBinding.globalStore.accounts.single.id));
      });

      testWidgets('account already exists', (tester) async {
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        check(testBinding.globalStore.accounts).isEmpty();
        testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

        await tester.enterText(findUsernameInput, eg.selfAccount.email);
        await tester.enterText(findPasswordInput, 'p455w0rd');
        connection.prepare(json: FetchApiKeyResult(
          apiKey: eg.selfAccount.apiKey,
          email: eg.selfAccount.email,
          userId: eg.selfAccount.userId,
        ).toJson());
        await tester.tap(findSubmitButton);
        await tester.pumpAndSettle();

        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorAccountLoggedInTitle)));
      });

      // TODO test validators on the TextFormField widgets
      // TODO test navigation, i.e. the call to pushAndRemoveUntil
      // TODO test _getUserId case
      // TODO test handling failure in fetchApiKey request
      // TODO test _inProgress logic
    });
  });
}
