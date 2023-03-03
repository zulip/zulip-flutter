import 'package:flutter/material.dart';

import '../model/store.dart';

class PerAccountRoot extends StatefulWidget {
  const PerAccountRoot({super.key, required this.child});

  final Widget child;

  @override
  State<PerAccountRoot> createState() => _PerAccountRootState();
}

class _PerAccountRootState extends State<PerAccountRoot> {
  PerAccountStore? store;

  @override
  void initState() {
    super.initState();
    (() async {
      final store = await PerAccountStore.load();
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
