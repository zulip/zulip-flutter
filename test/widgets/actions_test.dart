import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/internal_link.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/actions.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../stdlib_checks.dart';
import '../test_clipboard.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  group('ZulipActions', () {
    TestZulipBinding.ensureInitialized();

    late PerAccountStore store;
    late FakeApiConnection connection;
    late BuildContext context;

    Future<void> prepare(WidgetTester tester, {
      UnreadMessagesSnapshot? unreadMsgs,
      String? ackedPushToken = '123',
      bool skipAssertAccountExists = false,
    }) async {
      addTearDown(testBinding.reset);
      final selfAccount = eg.selfAccount.copyWith(ackedPushToken: Value(ackedPushToken));
      await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
        unreadMsgs: unreadMsgs));
      store = await testBinding.globalStore.perAccount(selfAccount.id);
      connection = store.connection as FakeApiConnection;

      await tester.pumpWidget(TestZulipApp(
        accountId: selfAccount.id,
        skipAssertAccountExists: skipAssertAccountExists,
        child: const Scaffold(body: Placeholder())));
      await tester.pump();
      context = tester.element(find.byType(Placeholder));
    }

    group('markNarrowAsRead', () {
      (Widget, Widget) checkConfirmDialog(WidgetTester tester, int unreadCount) {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        return checkSuggestedActionDialog(tester,
          expectedTitle: zulipLocalizations.markAllAsReadConfirmationDialogTitle,
          expectedMessage: zulipLocalizations.markAllAsReadConfirmationDialogMessage(unreadCount),
          expectDestructiveActionButton: false,
          expectedActionButtonText: zulipLocalizations.markAllAsReadConfirmationDialogConfirmButton);
      }

      testWidgets('smoke test on modern server', (tester) async {
        final narrow = TopicNarrow.ofMessage(eg.streamMessage());
        await prepare(tester);
        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: true).toJson());
        final future = ZulipAction.markNarrowAsRead(context, narrow);
        await tester.pump(Duration.zero);
        await future;
        final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });
      });

      testWidgets('use is:unread optimization', (tester) async {
        const narrow = CombinedFeedNarrow();
        await prepare(tester);
        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: true).toJson());
        final unreadCount = store.unreads.countInCombinedFeedNarrow();
        final future = ZulipAction.markNarrowAsRead(context, narrow);
        await tester.pump(); // confirmation dialog appears
        final (confirmButton, _) = checkConfirmDialog(tester, unreadCount);
        await tester.tap(find.byWidget(confirmButton));
        await tester.pump(Duration.zero); // wait through API request
        await future;
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': json.encode([{'operator': 'is', 'operand': 'unread'}]),
              'op': 'add',
              'flag': 'read',
            });
      });

      testWidgets('on mark-all-as-read when Unreads.oldUnreadsMissing: true', (tester) async {
        const narrow = CombinedFeedNarrow();
        await prepare(tester);
        store.unreads.oldUnreadsMissing = true;

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: true).toJson());
        final unreadCount = store.unreads.countInCombinedFeedNarrow();
        final future = ZulipAction.markNarrowAsRead(context, narrow);
        await tester.pump(); // confirmation dialog appears
        final (confirmButton, _) = checkConfirmDialog(tester, unreadCount);
        await tester.tap(find.byWidget(confirmButton));
        await tester.pump(Duration.zero); // wait through API request
        await future;
        check(store.unreads.oldUnreadsMissing).isFalse();
      });
    });

    group('updateMessageFlagsStartingFromAnchor', () {
      String onCompletedMessage(int count) => 'onCompletedMessage($count)';
      const progressMessage = 'progressMessage';
      const onFailedTitle = 'onFailedTitle';
      final narrow = TopicNarrow.ofMessage(eg.streamMessage());
      final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));

      Future<bool> invokeUpdateMessageFlagsStartingFromAnchor() =>
        ZulipAction.updateMessageFlagsStartingFromAnchor(
          context: context,
          apiNarrow: apiNarrow,
          op: UpdateMessageFlagsOp.add,
          flag: MessageFlag.read,
          includeAnchor: false,
          anchor: AnchorCode.oldest,
          onCompletedMessage: onCompletedMessage,
          onFailedTitle: onFailedTitle,
          progressMessage: progressMessage);

      testWidgets('smoke test', (tester) async {
        await prepare(tester);
        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 11, updatedCount: 3,
          firstProcessedId: 1, lastProcessedId: 1980,
          foundOldest: true, foundNewest: true).toJson());
        final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
        await tester.pump(Duration.zero);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });
        check(await didPass).isTrue();
      });

      testWidgets('pagination', (tester) async {
        // Check that `lastProcessedId` returned from an initial
        // response is used as `anchorId` for the subsequent request.
        await prepare(tester);

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 1000, updatedCount: 890,
          firstProcessedId: 1, lastProcessedId: 1989,
          foundOldest: true, foundNewest: false).toJson());
        final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 20, updatedCount: 10,
          firstProcessedId: 2000, lastProcessedId: 2023,
          foundOldest: false, foundNewest: true).toJson());
        await tester.pump(Duration.zero);
        check(find.bySubtype<SnackBar>().evaluate()).length.equals(1);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': '1989',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });
        check(await didPass).isTrue();
      });

      testWidgets('on invalid response', (tester) async {
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        await prepare(tester);
        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 1000, updatedCount: 0,
          firstProcessedId: null, lastProcessedId: null,
          foundOldest: true, foundNewest: false).toJson());
        final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
        await tester.pump(Duration.zero);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
              'anchor': 'oldest',
              'include_anchor': 'false',
              'num_before': '0',
              'num_after': '1000',
              'narrow': jsonEncode(resolveApiNarrowForServer(apiNarrow, connection.zulipFeatureLevel!)),
              'op': 'add',
              'flag': 'read',
            });
        checkErrorDialog(tester,
          expectedTitle: onFailedTitle,
          expectedMessage: zulipLocalizations.errorInvalidResponse);
        check(await didPass).isFalse();
      });

      testWidgets('catch-all api errors', (tester) async {
        await prepare(tester);
        connection.prepare(httpException: http.ClientException('Oops'));
        final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
        await tester.pump(Duration.zero);
        checkErrorDialog(tester,
          expectedTitle: onFailedTitle,
          expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
        check(await didPass).isFalse();
      });
    });

    group('getFileTemporaryUrl', () {
      testWidgets('smoke', (tester) async {
        await prepare(tester);
        connection.prepare(json: GetFileTemporaryUrlResult(
          url: '/temp/s3kr1t-auth-token/paper.pdf').toJson());
        final link = parseInternalLink(
          store.tryResolveUrl('/user_uploads/123/ab/paper.pdf')!, store);

        final future = ZulipAction.getFileTemporaryUrl(context,
          link as UserUploadLink);
        await tester.pump(Duration.zero);
        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/user_uploads/123/ab/paper.pdf')
          ..url.query.isEmpty()
          ..body.isEmpty();
        check(await future).equals(
          store.tryResolveUrl('/temp/s3kr1t-auth-token/paper.pdf')!);
      });
    });
  });

  group('PlatformActions', () {
    TestZulipBinding.ensureInitialized();
    TestWidgetsFlutterBinding.ensureInitialized();

    tearDown(() async {
      testBinding.reset();
    });

    group('copyWithPopup', () {
      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          MockClipboard().handleMethodCall,
        );
      });

      Future<void> call(WidgetTester tester, {required String text}) async {
        await tester.pumpWidget(TestZulipApp(
          child: Scaffold(
            body: Builder(builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  PlatformActions.copyWithPopup(context: context,
                    successContent: const Text('Text copied'),
                    data: ClipboardData(text: text));
                },
                child: const Text('Copy')))))));
        await tester.pump();
        await tester.tap(find.text('Copy'));
        await tester.pump(); // copy
        await tester.pump(Duration.zero); // await platform info (awkwardly async)
      }

      Future<void> checkSnackBar(WidgetTester tester, {required bool expected}) async {
        if (!expected) {
          check(tester.widgetList(find.byType(SnackBar))).isEmpty();
          return;
        }
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        check(snackBar.behavior).equals(SnackBarBehavior.floating);
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(snackBar.content), matching: find.text('Text copied')));
      }

      Future<void> checkClipboardText(String expected) async {
        check(await Clipboard.getData('text/plain')).isNotNull().text.equals(expected);
      }

      testWidgets('iOS', (tester) async {
        testBinding.deviceInfoResult = const IosDeviceInfo(systemVersion: '16.0');
        await call(tester, text: 'asdf');
        await checkClipboardText('asdf');
        await checkSnackBar(tester, expected: true);
      });

      testWidgets('Android', (tester) async {
        testBinding.deviceInfoResult = const AndroidDeviceInfo(sdkInt: 33, release: '13');
        await call(tester, text: 'asdf');
        await checkClipboardText('asdf');
        await checkSnackBar(tester, expected: false);
      });

      testWidgets('Android <13', (tester) async {
        testBinding.deviceInfoResult = const AndroidDeviceInfo(sdkInt: 32, release: '12');
        await call(tester, text: 'asdf');
        await checkClipboardText('asdf');
        await checkSnackBar(tester, expected: true);
      });
    });

    group('launchUrl', () {
      Future<void> call(WidgetTester tester, {required Uri url}) async {
        await tester.pumpWidget(TestZulipApp(
          child: Builder(builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                await PlatformActions.launchUrl(context, url);
              },
              child: const Text('link'))))));
        await tester.pump();
        await tester.tap(find.text('link'));
        await tester.pump(Duration.zero);
      }

      final httpUrl = Uri.parse('https://chat.example');
      final nonHttpUrl = Uri.parse('mailto:chat@example');

      Future<void> runAndCheckSuccess(WidgetTester tester, {
        required Uri url,
        required UrlLaunchMode expectedModeAndroid,
        required UrlLaunchMode expectedModeIos,
      }) async {
        await call(tester, url: url);

        final expectedMode = switch (defaultTargetPlatform) {
          TargetPlatform.android => expectedModeAndroid,
          TargetPlatform.iOS =>     expectedModeIos,
          _ => throw StateError('attempted to test with $defaultTargetPlatform'),
        };
        check(testBinding.takeLaunchUrlCalls()).single
          .equals((url: url, mode: expectedMode));
      }

      final androidIosVariant = TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android});

      testWidgets('globalSettings.browserPreference is null; use our per-platform defaults for HTTP links', (tester) async {
        await testBinding.globalStore.settings.setBrowserPreference(null);
        await runAndCheckSuccess(tester,
          url: httpUrl,
          expectedModeAndroid: UrlLaunchMode.inAppBrowserView,
          expectedModeIos: UrlLaunchMode.externalApplication);
      }, variant: androidIosVariant);

      testWidgets('globalSettings.browserPreference is null; use our per-platform defaults for non-HTTP links', (tester) async {
        await testBinding.globalStore.settings.setBrowserPreference(null);
        await runAndCheckSuccess(tester,
          url: nonHttpUrl,
          expectedModeAndroid: UrlLaunchMode.platformDefault,
          expectedModeIos: UrlLaunchMode.externalApplication);
      }, variant: androidIosVariant);

      testWidgets('globalSettings.browserPreference is inApp; follow the user preference for http links', (tester) async {
        await testBinding.globalStore.settings.setBrowserPreference(BrowserPreference.inApp);
        await runAndCheckSuccess(tester,
          url: httpUrl,
          expectedModeAndroid: UrlLaunchMode.inAppBrowserView,
          expectedModeIos: UrlLaunchMode.inAppBrowserView);
      }, variant: androidIosVariant);

      testWidgets('globalSettings.browserPreference is inApp; use platform default for non-http links', (tester) async {
        await testBinding.globalStore.settings.setBrowserPreference(BrowserPreference.inApp);
        await runAndCheckSuccess(tester,
          url: nonHttpUrl,
          expectedModeAndroid: UrlLaunchMode.platformDefault,
          expectedModeIos: UrlLaunchMode.platformDefault);
      }, variant: androidIosVariant);

      testWidgets('globalSettings.browserPreference is external; follow the user preference', (tester) async {
        await testBinding.globalStore.settings.setBrowserPreference(BrowserPreference.external);
        await runAndCheckSuccess(tester,
          url: httpUrl,
          expectedModeAndroid: UrlLaunchMode.externalApplication,
          expectedModeIos: UrlLaunchMode.externalApplication);
      }, variant: androidIosVariant);

      testWidgets('ZulipBinding.launchUrl returns false', (tester) async {
        testBinding.launchUrlResult = false;
        await call(tester, url: httpUrl);
        checkErrorDialog(tester, expectedTitle: 'Unable to open link');
      }, variant: androidIosVariant);

      testWidgets('ZulipBinding.launchUrl throws PlatformException', (tester) async {
        testBinding.launchUrlException = PlatformException(code: 'code', message: 'error message');
        await call(tester, url: httpUrl);
        checkErrorDialog(tester,
          expectedTitle: 'Unable to open link',
          expectedMessage: 'Link could not be opened: ${httpUrl.toString()}\n\nerror message');
      }, variant: androidIosVariant);
    });
  });
}
