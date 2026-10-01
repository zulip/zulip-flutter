import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/attachment.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/delete_uploaded_files.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late FakeApiConnection connection;
  final attachments = [
    Attachment(id: 42, name: 'photo.png'),
    Attachment(id: 73, name: 'notes.txt'),
    Attachment(id: 91, name: 'data.csv'),
  ];

  Future<void> setup(WidgetTester tester, {
    List<Attachment>? files,
    bool useOtherAccount = false,
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await testBinding.globalStore.add(eg.otherAccount,
      eg.initialSnapshot(realmUsers: [eg.otherUser]));
    final account = useOtherAccount ? eg.otherAccount : eg.selfAccount;
    final store = await testBinding.globalStore.perAccount(account.id);
    connection = store.connection as FakeApiConnection;
    await tester.pumpWidget(TestZulipApp(accountId: account.id,
      child: Builder(builder: (context) => TextButton(
        onPressed: () => DeleteUploadedFilesDialog.show(pageContext: context,
          attachments: files ?? attachments),
        child: const Text('Open')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Delete'));
    await tester.pump();
  }

  void checkRequests(List<int> ids) {
    final requests = connection.takeRequests();
    check(requests.length).equals(ids.length);
    for (var i = 0; i < ids.length; i++) {
      check(requests[i].method).equals('DELETE');
      check(requests[i].url.path).equals('/api/v1/attachments/${ids[i]}');
    }
  }

  testWidgets('one filename and successful deletion on the account connection', (tester) async {
    await setup(tester, files: [attachments.first]);
    check(find.text('photo.png')).findsOne();
    connection.prepare(json: {});
    await submit(tester);
    await tester.pumpAndSettle();
    checkRequests([42]);
    checkNoDialog(tester);
    check(find.text('Open')).findsOne();
  });

  testWidgets('uses the opening account when multiple accounts exist', (tester) async {
    await setup(tester, files: [attachments.first], useOtherAccount: true);
    final selfStore = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    final selfConnection = selfStore.connection as FakeApiConnection;
    connection.prepare(json: {});
    await submit(tester);
    await tester.pumpAndSettle();
    checkRequests([42]);
    check(selfConnection.takeRequests()).isEmpty();
    checkNoDialog(tester);
  });

  testWidgets('multiple filenames and sequential deletion', (tester) async {
    await setup(tester);
    for (final file in attachments) {
      check(find.text(file.name)).findsOne();
      connection.prepare(json: {}, delay: const Duration(seconds: 1));
    }
    await submit(tester);
    checkRequests([42]);
    await tester.pump(const Duration(seconds: 1));
    checkRequests([73]);
    await tester.pump(const Duration(seconds: 1));
    checkRequests([91]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    checkNoDialog(tester);
  });

  testWidgets('long filenames and a long list scroll without overflow', (tester) async {
    final files = List.generate(30, (i) => Attachment(id: i,
      name: '${'long_filename_' * 20}$i.txt'));
    await setup(tester, files: files);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -10000));
    await tester.pumpAndSettle();
    check(tester.takeException()).isNull();
    check(find.text("Don't delete").hitTestable()).findsOne();
    checkRequests([]);
  });

  for (final dismiss in ['cancel', 'barrier', 'back']) {
    testWidgets('$dismiss sends no requests', (tester) async {
      await setup(tester);
      switch (dismiss) {
        case 'cancel': await tester.tap(find.text("Don't delete"));
        case 'barrier': await tester.tapAt(const Offset(5, 5));
        case 'back': await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      checkNoDialog(tester);
      checkRequests([]);
    });
  }

  testWidgets('duplicate submissions are ignored before and after rebuild', (tester) async {
    await setup(tester, files: [attachments.first]);
    connection.prepare(json: {}, delay: const Duration(seconds: 1));
    final button = tester.widget<ZulipWebUiKitButton>(
      find.widgetWithText(ZulipWebUiKitButton, 'Delete'));
    button.onPressed!();
    button.onPressed!();
    await tester.pump();
    check(tester.widget<ZulipWebUiKitButton>(
      find.widgetWithText(ZulipWebUiKitButton, 'Delete')).onPressed).isNull();
    await tester.tap(find.text('Delete'));
    checkRequests([42]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    checkRequests([]);
    checkNoDialog(tester);
  });

  for (final network in [false, true]) {
    testWidgets('${network ? 'network' : 'API'} failure allows retry', (tester) async {
      await setup(tester, files: [attachments.first]);
      if (network) {
        connection.prepare(httpException: http.ClientException('offline'));
      } else {
        connection.prepare(apiException: eg.apiBadRequest(message: 'Cannot delete'));
      }
      await submit(tester);
      await tester.pumpAndSettle();
      final ok = checkErrorDialog(tester, allowOtherAlertDialogs: true,
        expectedTitle: 'Failed to delete uploaded files',
        expectedMessage: network ? null : 'Cannot delete');
      checkRequests([42]);
      await tester.tap(find.byWidget(ok));
      await tester.pumpAndSettle();
      check(find.text('photo.png')).findsOne();
      connection.prepare(json: {});
      await submit(tester);
      await tester.pumpAndSettle();
      checkRequests([42]);
      checkNoDialog(tester);
    });
  }

  testWidgets('partial failure stops; retry skips successful IDs', (tester) async {
    await setup(tester);
    connection.prepare(json: {});
    connection.prepare(apiException: eg.apiBadRequest());
    await submit(tester);
    await tester.pumpAndSettle();
    final ok = checkErrorDialog(tester, allowOtherAlertDialogs: true,
      expectedTitle: 'Failed to delete uploaded files');
    checkRequests([42, 73]);
    await tester.tap(find.byWidget(ok));
    await tester.pumpAndSettle();
    check(find.text('photo.png')).findsNothing();
    check(find.text('notes.txt')).findsOne();
    check(find.text('data.csv')).findsOne();
    connection.prepare(json: {});
    connection.prepare(json: {});
    await submit(tester);
    await tester.pumpAndSettle();
    checkRequests([73, 91]);
    checkNoDialog(tester);
  });

  group('covered while deleting', () {
    Future<MaterialPageRoute<void>> coverDialog(WidgetTester tester) async {
      final dialogContext = tester.element(find.byType(DeleteUploadedFilesDialog));
      final dialogRoute = ModalRoute.of(dialogContext)!;
      final coveringRoute = MaterialPageRoute<void>(
        builder: (context) => const Scaffold(body: Text('Covering page')));
      unawaited(Navigator.of(dialogContext).push(coveringRoute));
      await tester.pumpAndSettle();
      check(dialogContext.mounted).isTrue();
      check(dialogRoute.isActive).isTrue();
      check(dialogRoute.isCurrent).isFalse();
      check(coveringRoute.isCurrent).isTrue();
      return coveringRoute;
    }

    testWidgets('success removes only the deletion dialog', (tester) async {
      await setup(tester, files: [attachments.first]);
      final dialogContext = tester.element(find.byType(DeleteUploadedFilesDialog));
      connection.prepare(json: {}, delay: const Duration(seconds: 5));
      await submit(tester);
      checkRequests([42]);
      final coveringRoute = await coverDialog(tester);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      check(coveringRoute.isCurrent).isTrue();
      check(find.text('Covering page')).findsOne();
      check(dialogContext.mounted).isFalse();
      check(find.byType(DeleteUploadedFilesDialog, skipOffstage: false)).findsNothing();
      checkRequests([]);

      coveringRoute.navigator!.pop();
      await tester.pumpAndSettle();
      checkNoDialog(tester);
      check(find.text('Open')).findsOne();
      check(tester.takeException()).isNull();
    });

    for (final failure in ['API', 'network', 'partial']) {
      testWidgets('$failure failure preserves remaining files for retry', (tester) async {
        await setup(tester);
        final dialogContext = tester.element(find.byType(DeleteUploadedFilesDialog));
        final dialogRoute = ModalRoute.of(dialogContext)!;
        final partial = failure == 'partial';
        if (partial) connection.prepare(json: {});
        if (failure == 'network') {
          connection.prepare(httpException: http.ClientException('offline'),
            delay: const Duration(seconds: 5));
        } else {
          connection.prepare(apiException: eg.apiBadRequest(),
            delay: const Duration(seconds: 5));
        }
        await submit(tester);
        if (partial) await tester.pumpAndSettle();
        checkRequests(partial ? [42, 73] : [42]);
        final coveringRoute = await coverDialog(tester);

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        // A failure in the covered dialog must not interrupt the current page.
        check(coveringRoute.isCurrent).isTrue();
        check(find.text('Covering page')).findsOne();
        check(find.text('Failed to delete uploaded files')).findsNothing();
        check(dialogContext.mounted).isTrue();
        check(dialogRoute.isActive).isTrue();
        checkRequests([]);

        coveringRoute.navigator!.pop();
        await tester.pumpAndSettle();
        check(dialogRoute.isCurrent).isTrue();
        final remaining = partial ? attachments.skip(1).toList() : attachments;
        if (partial) check(find.text('photo.png')).findsNothing();
        for (final attachment in remaining) {
          check(find.text(attachment.name)).findsOne();
          connection.prepare(json: {});
        }
        check(tester.widget<ZulipWebUiKitButton>(
          find.widgetWithText(ZulipWebUiKitButton, 'Delete')).onPressed).isNotNull();
        await submit(tester);
        await tester.pumpAndSettle();
        checkRequests(remaining.map((a) => a.id).toList());
        checkNoDialog(tester);
        check(find.text('Open')).findsOne();
        check(tester.takeException()).isNull();
      });
    }
  });

  for (final outcome in ['success', 'API failure', 'network failure']) {
    for (final dismissal in ['closing animation', 'disposed', 'app disposed']) {
      testWidgets('$outcome after $dismissal while request pending', (tester) async {
        await setup(tester);
        final delay = const Duration(seconds: 1);
        switch (outcome) {
          case 'success': connection.prepare(json: {}, delay: delay);
          case 'API failure': connection.prepare(apiException: eg.apiBadRequest(), delay: delay);
          case 'network failure': connection.prepare(httpException: http.ClientException('offline'), delay: delay);
        }
        await submit(tester);
        checkRequests([42]);
        if (dismissal == 'app disposed') {
          await tester.pumpWidget(const SizedBox());
        } else {
          if (dismissal == 'closing animation') {
            await tester.pump(const Duration(milliseconds: 999));
          }
          await tester.tap(find.text("Don't delete"));
          await tester.pump();
        }
        await tester.pump(dismissal == 'closing animation'
          ? const Duration(milliseconds: 1) : delay);
        await tester.pumpAndSettle();
        check(tester.takeException()).isNull();
        checkRequests([]);
        checkNoDialog(tester);
        if (dismissal != 'app disposed') check(find.text('Open')).findsOne();
      });
    }
  }
}
