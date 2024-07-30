import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/web_auth.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/login.dart';
import 'package:zulip/widgets/page.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'page_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ServerUrlTextEditingController.tryParse', () {
    final controller = ServerUrlTextEditingController();

    void expectUrlFromText(String text, String expectedUrl) {
      test('text "$text" gives URL "$expectedUrl"', () {
        controller.text = text;
        final result = controller.tryParse();
        check(result.error).isNull();
        check(result.url).isNotNull().asString.equals(expectedUrl);
      });
    }

    void expectErrorFromText(String text, ServerUrlValidationError expectedError) {
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
    late List<Route<dynamic>> pushedRoutes;

    void takeStartingRoutes() {
      final expected = <Condition<Object?>>[
        (it) => it.isA<WidgetRoute>().page.isA<ChooseAccountPage>(),
        (it) => it.isA<WidgetRoute>().page.isA<LoginPage>(),
      ];
      check(pushedRoutes.take(expected.length)).deepEquals(expected);
      pushedRoutes.removeRange(0, expected.length);
    }

    Future<void> prepare(WidgetTester tester,
        GetServerSettingsResult serverSettings) async {
      addTearDown(testBinding.reset);

      connection = testBinding.globalStore.apiConnection(
        realmUrl: serverSettings.realmUrl,
        zulipFeatureLevel: serverSettings.zulipFeatureLevel);

      pushedRoutes = [];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      navigator.push(LoginPage.buildRoute(serverSettings: serverSettings));
      await tester.pumpAndSettle();
      takeStartingRoutes();
      check(pushedRoutes).isEmpty();
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

      testWidgets('trims whitespace on username', (tester) async {
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        check(testBinding.globalStore.accounts).isEmpty();

        await tester.enterText(findUsernameInput, '  ${eg.selfAccount.email}  ');
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

    group('web auth', () {
      testWidgets('basic happy case', (tester) async {
        final method = ExternalAuthenticationMethod(
          name: 'google',
          displayName: 'Google',
          displayIcon: eg.realmUrl.resolve('/static/images/authentication_backends/googl_e-icon.png').toString(),
          loginUrl: '/accounts/login/social/google',
          signupUrl: '/accounts/register/social/google',
        );
        final serverSettings = eg.serverSettings(
          externalAuthenticationMethods: [method]);
        prepareBoringImageHttpClient(); // icon on social-auth button
        await prepare(tester, serverSettings);
        check(testBinding.globalStore.accounts).isEmpty();

        const otp = '186f6d085a5621ebaf1ccfc05033e8acba57dae03f061705ac1e58c402c30a31';
        LoginPage.debugOtpOverride = otp;
        await tester.tap(find.textContaining('Google'));

        final expectedUrl = eg.realmUrl.resolve(method.loginUrl)
          .replace(queryParameters: {'mobile_flow_otp': otp});
        check(testBinding.takeLaunchUrlCalls())
          .deepEquals([(url: expectedUrl, mode: UrlLaunchMode.inAppBrowserView)]);

        // TODO test _inProgress logic?

        final encoded = debugEncodeApiKey(eg.selfAccount.apiKey, otp);
        final url = Uri(scheme: 'zulip', host: 'login', queryParameters: {
          'otp_encrypted_api_key': encoded,
          'email': eg.selfAccount.email,
          'user_id': eg.selfAccount.userId.toString(),
          'realm': eg.selfAccount.realmUrl.toString(),
        });

        final ByteData message = const JSONMethodCodec().encodeMethodCall(
          MethodCall('pushRouteInformation', {'location': url.toString()}));
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation', message, null);

        await tester.idle();
        check(testBinding.takeCloseInAppWebViewCallCount()).equals(1);

        final account = testBinding.globalStore.accounts.single;
        check(account).equals(eg.selfAccount.copyWith(id: account.id));
        check(pushedRoutes).single.isA<MaterialAccountWidgetRoute>()
          ..accountId.equals(account.id)
          ..page.isA<HomePage>();

        debugNetworkImageHttpClientProvider = null;
      });

      // TODO failures, such as: invalid loginUrl; URL can't be launched;
      //   WebAuthPayload.realm doesn't match the realm the UI is about
    });
  });
}
