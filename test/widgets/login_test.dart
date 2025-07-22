import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/web_auth.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/login.dart';
import 'package:zulip/widgets/page.dart';

import '../api/fake_api.dart';
import '../api/route/route_checks.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'checks.dart';

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

  group('AddAccountPage', () {
    late FakeApiConnection connection;
    List<Route<dynamic>> pushedRoutes = [];
    List<Route<dynamic>> poppedRoutes = [];

    List<Route<dynamic>> takePushedRoutes() {
      final routes = pushedRoutes.toList();
      pushedRoutes.clear();
      return routes;
    }

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);

      pushedRoutes = [];
      poppedRoutes = [];
      final testNavObserver = TestNavigatorObserver();
      testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
      testNavObserver.onPopped = (route, prevRoute) => poppedRoutes.add(route);
      testNavObserver.onReplaced = (route, prevRoute) {
        poppedRoutes.add(prevRoute!);
        pushedRoutes.add(route!);
      };

      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      check(takePushedRoutes()).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
      await tester.tap(find.text('Add an account'));
      check(takePushedRoutes()).single.isA<WidgetRoute>().page.isA<AddAccountPage>();
      await testNavObserver.pumpPastTransition(tester);
    }

    Future<void> attempt(WidgetTester tester,
        Uri realmUrl, Map<String, Object?> responseJson) async {
      await tester.enterText(find.byType(TextField), realmUrl.toString());
      testBinding.globalStore.useCachedApiConnections = true;
      connection = testBinding.globalStore.apiConnection(
        realmUrl: realmUrl,
        zulipFeatureLevel: null);
      connection.prepare(json: responseJson);
      await tester.tap(find.text('Continue'));
      await tester.pump(Duration.zero);
    }

    testWidgets('happy path', (tester) async {
      await prepare(tester);

      final serverSettings = eg.serverSettings();

      await attempt(tester, serverSettings.realmUrl, serverSettings.toJson());
      checkNoDialog(tester);
      check(takePushedRoutes()).single.isA<WidgetRoute>().page.isA<LoginPage>()
        .serverSettings.realmUrl.equals(serverSettings.realmUrl);
    });

    testWidgets('Server too old, well-formed response', (tester) async {
      await prepare(tester);

      final serverSettings = eg.serverSettings(
        zulipFeatureLevel: 1, zulipVersion: '3.0');

      await attempt(tester, serverSettings.realmUrl, serverSettings.toJson());
      checkErrorDialog(tester,
        expectedTitle: 'Could not connect',
        expectedMessage: '${serverSettings.realmUrl} is running Zulip Server 3.0, which is unsupported. The minimum supported version is Zulip Server $kMinSupportedZulipVersion.');
      // i.e., not the login route
      check(takePushedRoutes()).single.isA<DialogRoute<void>>();
    });

    testWidgets('Server too old, malformed response', (tester) async {
      await prepare(tester);

      final serverSettings = eg.serverSettings(
        zulipFeatureLevel: 1, zulipVersion: '3.0');
      final serverSettingsMalformedJson =
        serverSettings.toJson()..['push_notifications_enabled'] = 'abcd';
      check(() => GetServerSettingsResult.fromJson(serverSettingsMalformedJson))
        .throws<void>();

      await attempt(tester, serverSettings.realmUrl, serverSettingsMalformedJson);
      checkErrorDialog(tester,
        expectedTitle: 'Could not connect',
        expectedMessage: '${serverSettings.realmUrl} is running Zulip Server 3.0, which is unsupported. The minimum supported version is Zulip Server $kMinSupportedZulipVersion.');
      // i.e., not the login route
      check(takePushedRoutes()).single.isA<DialogRoute<void>>();
    });

    testWidgets('Malformed response, server not too old', (tester) async {
      await prepare(tester);

      final serverSettings = eg.serverSettings(
        zulipVersion: eg.recentZulipVersion,
        zulipFeatureLevel: eg.recentZulipFeatureLevel);
      final serverSettingsMalformedJson =
        serverSettings.toJson()..['push_notifications_enabled'] = 'abcd';
      check(() => GetServerSettingsResult.fromJson(serverSettingsMalformedJson))
        .throws<void>();

      await attempt(tester, serverSettings.realmUrl, serverSettingsMalformedJson);
      checkErrorDialog(tester,
        expectedTitle: 'Could not connect',
        expectedMessage: 'Failed to connect to server:\n${serverSettings.realmUrl}');
      // i.e., not the login route
      check(takePushedRoutes()).single.isA<DialogRoute<void>>();
    });

    // TODO other errors
  });

  group('LoginPage', () {
    late FakeApiConnection connection;
    late List<Route<void>> pushedRoutes;
    late List<Route<void>> poppedRoutes;

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
      poppedRoutes = [];
      final testNavObserver = TestNavigatorObserver();
      testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
      testNavObserver.onPopped = (route, prevRoute) => poppedRoutes.add(route);
      testNavObserver.onReplaced = (route, prevRoute) {
        poppedRoutes.add(prevRoute!);
        pushedRoutes.add(route!);
      };
      await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(LoginPage.buildRoute(serverSettings: serverSettings)));
      await tester.pumpAndSettle();
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

      Future<void> login(WidgetTester tester, Account account) async {
        await tester.enterText(findUsernameInput, account.email);
        await tester.enterText(findPasswordInput, 'p455w0rd');
        testBinding.globalStore.useCachedApiConnections = true;
        connection.prepare(json: FetchApiKeyResult(
          apiKey: account.apiKey,
          email: account.email,
          userId: account.userId,
        ).toJson());
        await tester.tap(findSubmitButton);
        checkFetchApiKey(username: account.email, password: 'p455w0rd');
        await tester.idle();
      }

      testWidgets('basic happy case', (tester) async {
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        takeStartingRoutes();
        check(pushedRoutes).isEmpty();
        check(testBinding.globalStore.accounts).isEmpty();

        await login(tester, eg.selfAccount);
        check(testBinding.globalStore.accounts).single
          .equals(eg.selfAccount.copyWith(
            id: testBinding.globalStore.accounts.single.id));
      });

      testWidgets('logging into a second account', (tester) async {
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        check(poppedRoutes).isEmpty();
        check(pushedRoutes).deepEquals(<Condition<Object?>>[
          (it) => it.isA<WidgetRoute>().page.isA<HomePage>(),
          (it) => it.isA<WidgetRoute>().page.isA<LoginPage>(),
        ]);
        pushedRoutes.clear();

        await login(tester, eg.otherAccount);
        final newAccount = testBinding.globalStore.accounts.singleWhere(
          (account) => account != eg.selfAccount);
        check(newAccount).equals(eg.otherAccount.copyWith(id: newAccount.id));
        check(poppedRoutes).length.equals(2);
        check(pushedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
      });

      testWidgets('trims whitespace on username', (tester) async {
        final serverSettings = eg.serverSettings();
        await prepare(tester, serverSettings);
        takeStartingRoutes();
        check(pushedRoutes).isEmpty();
        check(testBinding.globalStore.accounts).isEmpty();

        await tester.enterText(findUsernameInput, '  ${eg.selfAccount.email}  ');
        await tester.enterText(findPasswordInput, 'p455w0rd');
        testBinding.globalStore.useCachedApiConnections = true;
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
        takeStartingRoutes();
        check(pushedRoutes).isEmpty();
        check(testBinding.globalStore.accounts).isEmpty();
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

        await tester.enterText(findUsernameInput, eg.selfAccount.email);
        await tester.enterText(findPasswordInput, 'p455w0rd');
        testBinding.globalStore.useCachedApiConnections = true;
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
        takeStartingRoutes();
        check(pushedRoutes).isEmpty();
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
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation', message, null);

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
