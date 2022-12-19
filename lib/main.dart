import 'package:flutter/material.dart';

import 'store.dart';

void main() {
  runApp(const ZulipApp());
}

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Just one account for now.
    return const PerAccountRoot();
  }
}

class PerAccountRoot extends StatefulWidget {
  const PerAccountRoot({super.key});

  @override
  State<PerAccountRoot> createState() => _PerAccountRootState();
}

class _PerAccountRootState extends State<PerAccountRoot> {
  late final PerAccountStore store;

  @override
  void initState() {
    super.initState();
    store = PerAccountStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return PerAccountStoreWidget(
        store: store,
        child: MaterialApp(
          title: 'Zulip',
          theme: ThemeData(primarySwatch: Colors.blue), // TODO Zulip purple
          home: const HomePage(),
        ));
  }
}

class PerAccountStoreWidget extends InheritedNotifier<PerAccountStore> {
  const PerAccountStoreWidget({super.key, required store, required super.child})
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: const Center(child: Text('Under construction 🚧')));
  }
}
