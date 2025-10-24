import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/actions.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';

/// A widget whose state uses [PerAccountStoreAwareStateMixin].
class MyWidgetWithMixin extends StatefulWidget {
  const MyWidgetWithMixin({super.key});

  @override
  State<MyWidgetWithMixin> createState() => _MyWidgetWithMixinState();
}

class _MyWidgetWithMixinState extends State<MyWidgetWithMixin> with PerAccountStoreAwareStateMixin<MyWidgetWithMixin> {
  int anyDepChangeCounter = 0;
  int storeChangeCounter = 0;

  @override
  void onNewStore() {
    storeChangeCounter++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    anyDepChangeCounter++;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accountId = PerAccountStoreWidget.of(context).accountId;
    return Text('brightness: $brightness; accountId: $accountId');
  }
}

extension _MyWidgetWithMixinStateChecks on Subject<_MyWidgetWithMixinState> {
  Subject<int> get anyDepChangeCounter => has((w) => w.anyDepChangeCounter, 'anyDepChangeCounter');
  Subject<int> get storeChangeCounter => has((w) => w.storeChangeCounter, 'storeChangeCounter');
}

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('GlobalStoreWidget loads data while showing placeholder', (tester) async {
    addTearDown(testBinding.reset);

    GlobalStore? globalStore;
    await tester.pumpWidget(
      GlobalStoreWidget(
        child: Builder(
          builder: (context) {
            globalStore = GlobalStoreWidget.of(context);
            return const SizedBox.shrink();
          })));
    // First, shows a loading page instead of child.
    check(find.byType(BlankLoadingPlaceholder)).findsOne();
    check(globalStore).isNull();

    await tester.pump();
    // Then after loading, mounts child instead, with provided store.
    check(find.byType(BlankLoadingPlaceholder)).findsNothing();
    check(globalStore).identicalTo(testBinding.globalStore);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    check(globalStore).isNotNull()
      .accountEntries.single
      .equals((accountId: eg.selfAccount.id, account: eg.selfAccount));
  });

  testWidgets('GlobalStoreWidget awaits blockingFuture', (tester) async {
    addTearDown(testBinding.reset);

    final completer = Completer<void>();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: GlobalStoreWidget(
        blockingFuture: completer.future,
        child: Text('done'))));

    await tester.pump();
    await tester.pump();
    await tester.pump();
    // Even after the store must have loaded,
    // still shows loading page while blockingFuture is pending.
    check(find.byType(BlankLoadingPlaceholder)).findsOne();
    check(find.text('done')).findsNothing();

    // Once blockingFuture completes…
    completer.complete();
    await tester.pump();
    await tester.pump(); // TODO why does GlobalStoreWidget need this extra frame?
    // … mounts child instead of the loading page.
    check(find.byType(BlankLoadingPlaceholder)).findsNothing();
    check(find.text('done')).findsOne();
  });

  testWidgets('GlobalStoreWidget handles failed blockingFuture like success', (tester) async {
    addTearDown(testBinding.reset);

    final completer = Completer<void>();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: GlobalStoreWidget(
        blockingFuture: completer.future,
        child: Text('done'))));

    await tester.pump();
    await tester.pump();
    await tester.pump();
    // Even after the store must have loaded,
    // still shows loading page while blockingFuture is pending.
    check(find.byType(BlankLoadingPlaceholder)).findsOne();
    check(find.text('done')).findsNothing();

    // Once blockingFuture completes, even with an error…
    completer.completeError(Exception('oops'));
    await tester.pump();
    await tester.pump(); // TODO why does GlobalStoreWidget need this extra frame?
    // … mounts child instead of the loading page.
    check(find.byType(BlankLoadingPlaceholder)).findsNothing();
    check(find.text('done')).findsOne();
  });

  testWidgets('GlobalStoreWidget.of updates dependents', (tester) async {
    addTearDown(testBinding.reset);

    List<int>? accountIds;
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: Builder(builder: (context) {
            accountIds = GlobalStoreWidget.of(context).accountIds.toList();
            return SizedBox.shrink();
          }))));
    await tester.pump();
    check(accountIds).isNotNull().isEmpty();

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pump();
    check(accountIds).isNotNull().deepEquals([eg.selfAccount.id]);
  });

  testWidgets('GlobalStoreWidget.settingsOf updates on settings update', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.settings.setThemeSetting(ThemeSetting.dark);

    ThemeSetting? themeSetting;
    await tester.pumpWidget(
      GlobalStoreWidget(
        child: Builder(
          builder: (context) {
            themeSetting = GlobalStoreWidget.settingsOf(context).themeSetting;
            return const SizedBox.shrink();
          })));
    await tester.pump();
    check(themeSetting).equals(ThemeSetting.dark);

    await testBinding.globalStore.settings.setThemeSetting(ThemeSetting.light);
    await tester.pump();
    check(themeSetting).equals(ThemeSetting.light);
  });

  testWidgets('PerAccountStoreWidget basic', (tester) async {
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    addTearDown(testBinding.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.accountId}');
              })))));
    await tester.pump();
    await tester.pump();

    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));
  });

  testWidgets('PerAccountStoreWidget.of detailed error', (tester) async {
    addTearDown(testBinding.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          // no PerAccountStoreWidget
          child: Builder(
            builder: (context) {
              final store = PerAccountStoreWidget.of(context);
              return Text('found store, account: ${store.accountId}');
            }))));
    await tester.pump();
    check(tester.takeException())
      .has((x) => x.toString(), 'toString') // TODO(checks): what's a good convention for this?
      .contains('consider MaterialAccountWidgetRoute');
  });

  testWidgets('PerAccountStoreWidget immediate data after first loaded', (tester) async {
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    addTearDown(testBinding.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            key: const ValueKey(1),
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.accountId}');
              })))));

    // First, the global store has to load.
    check(tester.any(find.byType(PerAccountStoreWidget))).isFalse();
    await tester.pump();
    check(tester.any(find.byType(PerAccountStoreWidget))).isTrue();

    // Then the per-account store has to load.
    check(tester.any(find.textContaining('found store'))).isFalse();
    await tester.pump();
    check(tester.any(find.textContaining('found store'))).isTrue();

    // Specifically it has the expected data.
    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));

    // But then if we mount a separate PerAccountStoreWidget...
    final oldState = tester.state(find.byType(PerAccountStoreWidget));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            key: const ValueKey(2),
            accountId: eg.selfAccount.id,
            child: Builder(
              builder: (context) {
                final store = PerAccountStoreWidget.of(context);
                return Text('found store, account: ${store.accountId}');
              })))));

    // (... even one that really is separate, with its own fresh state node ...)
    check(tester.state(find.byType(PerAccountStoreWidget)))
      .not((it) => it.identicalTo(oldState));

    // ... then its child appears immediately, without waiting to load.
    check(tester.any(find.textContaining('found store'))).isTrue();
    tester.widget(find.text('found store, account: ${eg.selfAccount.id}'));
  });

  testWidgets("PerAccountStoreWidget.routeToRemoveOnLogout logged-out account's routes removed from nav; other accounts' remain", (tester) async {
    Future<void> makeUnreadTopicInInbox(int accountId, String topic) async {
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream, topic: topic);
      final store = await testBinding.globalStore.perAccount(accountId);
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      await store.addMessage(message);
      await tester.pump();
    }

    addTearDown(testBinding.reset);

    final user1 = eg.user();
    final user2 = eg.user();
    final account1 = eg.account(id: 1, user: user1);
    final account2 = eg.account(id: 2, user: user2);
    await testBinding.globalStore.add(account1, eg.initialSnapshot(
      realmUsers: [user1]));
    await testBinding.globalStore.add(account2, eg.initialSnapshot(
      realmUsers: [user2]));

    final testNavObserver = TestNavigatorObserver();
    await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
    await tester.pump();
    final navigator = await ZulipApp.navigator;
    navigator.popUntil((_) => false); // clear starting routes
    await tester.pumpAndSettle();

    final pushedRoutes = <Route<dynamic>>[];
    testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);
    // TODO: switch to a realistic setup:
    //   https://github.com/zulip/zulip-flutter/pull/1076#discussion_r1874124363
    final account1Route = MaterialAccountWidgetRoute(
      accountId: account1.id, page: const InboxPageBody());
    final account2Route = MaterialAccountWidgetRoute(
      accountId: account2.id, page: const InboxPageBody());
    unawaited(navigator.push(account1Route));
    unawaited(navigator.push(account2Route));
    await tester.pumpAndSettle();
    check(pushedRoutes).deepEquals([account1Route, account2Route]);

    await makeUnreadTopicInInbox(account1.id, 'topic in account1');
    final findAccount1PageContent = find.text('topic in account1', skipOffstage: false);

    await makeUnreadTopicInInbox(account2.id, 'topic in account2');
    final findAccount2PageContent = find.text('topic in account2', skipOffstage: false);

    final findLoadingPage = find.byType(LoadingPlaceholderPage, skipOffstage: false);

    check(findAccount1PageContent).findsOne();
    check(findLoadingPage).findsNothing();

    final removedRoutes = <Route<dynamic>>[];
    testNavObserver.onRemoved = (route, prevRoute) => removedRoutes.add(route);

    final future = logOutAccount(testBinding.globalStore, account1.id);
    await tester.pump(TestGlobalStore.removeAccountDuration);
    await future;
    check(removedRoutes).single.identicalTo(account1Route);
    check(findAccount1PageContent).findsNothing();
    check(findLoadingPage).findsOne();

    await tester.pump();
    check(findAccount1PageContent).findsNothing();
    check(findLoadingPage).findsNothing();
    check(findAccount2PageContent).findsOne();
  });

  testWidgets('PerAccountStoreAwareStateMixin', (tester) async {
    final widgetWithMixinKey = GlobalKey<_MyWidgetWithMixinState>();
    final accountId = eg.selfAccount.id;

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    Future<void> pumpWithParams({required bool light, required int accountId}) async {
      // TODO use [TestZulipApp]
      //   (seeing some extraneous dep changes when trying that)
      await tester.pumpWidget(
        MaterialApp(
          theme: light ? ThemeData.light() : ThemeData.dark(),
          home: GlobalStoreWidget(
            child: PerAccountStoreWidget(
              accountId: accountId,
              child: MyWidgetWithMixin(key: widgetWithMixinKey)))));
    }

    // [onNewStore] called initially
    await pumpWithParams(light: true, accountId: accountId);
    await tester.pump(); // global store
    await tester.pump(); // per-account store
    check(widgetWithMixinKey).currentState.isNotNull()
      ..anyDepChangeCounter.equals(1)
      ..storeChangeCounter.equals(1);

    // [onNewStore] not called on unrelated dependency change
    await pumpWithParams(light: false, accountId: accountId);
    await tester.pumpAndSettle(kThemeAnimationDuration);
    check(widgetWithMixinKey).currentState.isNotNull()
      ..anyDepChangeCounter.equals(2)
      ..storeChangeCounter.equals(1);

    // [onNewStore] called when store changes
    //
    // TODO: Trigger `store` change by simulating an event-queue renewal,
    //   instead of with this hack where we change the UI's backing Account
    //   out from under it. (That account-swapping would be suspicious in
    //   production code, where we could reasonably add an assert against it.
    //   If forced, we could let this test code proceed despite such an assert…)
    // hack; the snapshot probably corresponds to selfAccount, not otherAccount.
    await testBinding.globalStore.add(eg.otherAccount, eg.initialSnapshot(
      realmUsers: [eg.otherUser]));
    await pumpWithParams(light: false, accountId: eg.otherAccount.id);
    // Nudge PerAccountStoreWidget to send its updated store to MyWidgetWithMixin.
    //
    // A change in PerAccountStoreWidget's [accountId] field doesn't by itself
    // prompt dependent widgets (those using PerAccountStoreWidget.of) to update,
    // even though it holds a new store. (See its state's didUpdateWidget,
    // or lack thereof.) That's reasonable, since such a change is never expected;
    // see TODO above.
    //
    // But when PerAccountStoreWidget gets a notification from the GlobalStore,
    // it checks at that time whether it has a new PerAccountStore to distribute
    // (as it will when widget.accountId has changed), and if so,
    // it will notify dependent widgets. (See its state's didChangeDependencies.)
    // So, take advantage of that.
    testBinding.globalStore.notifyListeners();
    await tester.pumpAndSettle();
    check(widgetWithMixinKey).currentState.isNotNull()
      ..anyDepChangeCounter.equals(3)
      ..storeChangeCounter.equals(2);
  });
}
