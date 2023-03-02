import 'package:flutter/material.dart';

import '../model/store.dart';

class DataRoot extends StatefulWidget {
  const DataRoot({super.key, required this.child});

  final Widget child;

  @override
  State<DataRoot> createState() => _DataRootState();
}

class _DataRootState extends State<DataRoot> {
  GlobalStore? store;

  @override
  void initState() {
    super.initState();
    (() async {
      final store = await GlobalStore.load();
      setState(() {
        this.store = store;
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    final store = this.store;
    // TODO: factor out the use of LoadingPage to be configured by the widget, like [widget.child] is
    if (store == null) return const LoadingPage();
    return GlobalStoreWidget(store: store, child: widget.child);
  }
}

class GlobalStoreWidget extends InheritedNotifier<GlobalStore> {
  const GlobalStoreWidget(
      {super.key, required GlobalStore store, required super.child})
      : super(notifier: store);

  GlobalStore get store => notifier!;

  static GlobalStore of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GlobalStoreWidget>();
    assert(widget != null, 'No GlobalStoreWidget ancestor');
    return widget!.store;
  }

  @override
  bool updateShouldNotify(covariant GlobalStoreWidget oldWidget) =>
      store != oldWidget.store;
}

class PerAccountRoot extends StatefulWidget {
  const PerAccountRoot(
      {super.key, required this.accountId, required this.child});

  final int accountId;
  final Widget child;

  @override
  State<PerAccountRoot> createState() => _PerAccountRootState();
}

class _PerAccountRootState extends State<PerAccountRoot> {
  PerAccountStore? store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final globalStore = GlobalStoreWidget.of(context);
    final account = globalStore.getAccount(widget.accountId);
    assert(account != null, 'Account not found on global store');
    if (store != null) {
      // The data we use to auth to the server should be unchanged;
      // changing those should mean a new account ID in our database.
      assert(account!.realmUrl == store!.account.realmUrl);
      assert(account!.email == store!.account.email);
      assert(account!.apiKey == store!.account.apiKey);
      // TODO if Account has anything else change, update the PerAccountStore for that
      return;
    }
    (() async {
      final store = await PerAccountStore.load(account!);
      setState(() {
        this.store = store;
      });
    })();
  }

  @override
  void reassemble() {
    // The [reassemble] method runs upon hot reload, in development.
    // Here, we rerun parsing the messages.  This gives us the same
    // highly productive workflow of Flutter hot reload when developing
    // changes there as we have on changes to widgets.
    store?.reassemble();
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: factor out the use of LoadingPage to be configured by the widget, like [widget.child] is
    if (store == null) return const LoadingPage();
    return PerAccountStoreWidget(store: store!, child: widget.child);
  }
}

class PerAccountStoreWidget extends InheritedNotifier<PerAccountStore> {
  const PerAccountStoreWidget(
      {super.key, required PerAccountStore store, required super.child})
      : super(notifier: store);

  PerAccountStore get store => notifier!;

  static PerAccountStore of(BuildContext context) {
    final widget =
    context.dependOnInheritedWidgetOfExactType<PerAccountStoreWidget>();
    assert(widget != null, 'No PerAccountStoreWidget ancestor');
    return widget!.store;
  }

  @override
  bool updateShouldNotify(covariant PerAccountStoreWidget oldWidget) =>
      store != oldWidget.store;
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
