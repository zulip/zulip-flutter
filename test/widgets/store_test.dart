import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/exception.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../example_data.dart' as eg;
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'page_checks.dart';

/// A widget whose state uses [PerAccountStoreAwareStateMixin].
class MyWidgetWithMixin extends StatefulWidget {
  const MyWidgetWithMixin({super.key});

  @override
  State<MyWidgetWithMixin> createState() => MyWidgetWithMixinState();
}

class MyWidgetWithMixinState extends State<MyWidgetWithMixin> with PerAccountStoreAwareStateMixin<MyWidgetWithMixin> {
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

extension MyWidgetWithMixinStateChecks on Subject<MyWidgetWithMixinState> {
  Subject<int> get anyDepChangeCounter => has((w) => w.anyDepChangeCounter, 'anyDepChangeCounter');
  Subject<int> get storeChangeCounter => has((w) => w.storeChangeCounter, 'storeChangeCounter');
}

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('GlobalStoreWidget', (tester) async {
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
    check(tester.any(find.byType(CircularProgressIndicator))).isTrue();
    check(globalStore).isNull();

    await tester.pump();
    // Then after loading, mounts child instead, with provided store.
    check(tester.any(find.byType(CircularProgressIndicator))).isFalse();
    check(globalStore).identicalTo(testBinding.globalStore);

    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    check(globalStore).isNotNull()
      .accountEntries.single
      .equals((accountId: eg.selfAccount.id, account: eg.selfAccount));
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

  testWidgets('PerAccountStoreWidget when log out, do not push route to non-empty navigator stack', (tester) async {
    addTearDown(testBinding.reset);

    final testNavObserver = TestNavigatorObserver();
    final pushedRoutes = <Route<void>>[];
    testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);

    const loadPerAccountDuration = Duration(seconds: 30);
    assert(loadPerAccountDuration > kTryAnotherAccountWaitPeriod);
    testBinding.globalStore.loadPerAccountDuration = loadPerAccountDuration;
    testBinding.globalStore.loadPerAccountException = ZulipApiException(
      routeName: '/register', code: 'INVALID_API_KEY', httpStatus: 400,
      data: {}, message: '');
    await testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
    await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
    await tester.pump(); // start to load account
    check(pushedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
    pushedRoutes.clear();

    final removedRoutes = <Route<void>>[];
    testNavObserver.onRemoved = (route, prevRoute) => removedRoutes.add(route);
    await tester.pump(kTryAnotherAccountWaitPeriod);
    await tester.tap(find.text('Try another account'));
    await tester.pump(); // tap the button
    check(pushedRoutes).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
    pushedRoutes.clear();

    await tester.pump(loadPerAccountDuration); // got the error
    await tester.pump(TestGlobalStore.removeAccountDuration);
    check(pushedRoutes).single.isA<DialogRoute<void>>();
    pushedRoutes.clear();
    check(removedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
    check(testBinding.globalStore.takeDoRemoveAccountCalls())
      .single.equals(eg.selfAccount.id);

    await tester.tap(find.byWidget(checkErrorDialog(tester,
      expectedTitle: 'Could not connect',
      expectedMessage:
        'Your account at https://chat.example/ could not be authenticated.'
        ' Please try logging in again or use another account.')));
    // No more routes are pushed after dismissing the error dialog.
    check(pushedRoutes).isEmpty();
  });

  testWidgets('PerAccountStoreWidget when log out, push route when popping root level route', (tester) async {
    addTearDown(testBinding.reset);

    final testNavObserver = TestNavigatorObserver();
    final pushedRoutes = <Route<void>>[];
    testNavObserver.onPushed = (route, prevRoute) => pushedRoutes.add(route);

    testBinding.globalStore.loadPerAccountDuration = Duration.zero;
    testBinding.globalStore.loadPerAccountException = ZulipApiException(
      routeName: '/register', code: 'INVALID_API_KEY', httpStatus: 400,
      data: {}, message: '');
    await testBinding.globalStore.insertAccount(eg.selfAccount.toCompanion(false));
    await tester.pumpWidget(ZulipApp(navigatorObservers: [testNavObserver]));
    await tester.pump(); // start to load account
    check(pushedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
    pushedRoutes.clear();

    final removedRoutes = <Route<void>>[];
    testNavObserver.onRemoved = (route, prevRoute) => removedRoutes.add(route);
    await tester.pump(); // got the error
    await tester.pump(TestGlobalStore.removeAccountDuration);
    check(pushedRoutes).single.isA<DialogRoute<void>>();
    pushedRoutes.clear();
    check(removedRoutes).single.isA<WidgetRoute>().page.isA<HomePage>();
    check(testBinding.globalStore.takeDoRemoveAccountCalls())
      .single.equals(eg.selfAccount.id);

    await tester.tap(find.byWidget(checkErrorDialog(tester,
      expectedTitle: 'Could not connect',
      expectedMessage:
        'Your account at https://chat.example/ could not be authenticated.'
        ' Please try logging in again or use another account.')));
    // The navigator stack became empty after dismissing the error dialog,
    // so a choose-account page route was pushed.
    check(pushedRoutes).single.isA<WidgetRoute>().page.isA<ChooseAccountPage>();
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

  testWidgets('PerAccountStoreAwareStateMixin', (tester) async {
    final widgetWithMixinKey = GlobalKey<MyWidgetWithMixinState>();
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
    await testBinding.globalStore.add(eg.otherAccount, eg.initialSnapshot());
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
