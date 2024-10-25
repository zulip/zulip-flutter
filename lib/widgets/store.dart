import 'package:flutter/material.dart';

import '../model/binding.dart';
import '../model/store.dart';

/// Provides access to the app's data.
///
/// There should be one of this widget, near the root of the tree.
///
/// See also:
///  * [GlobalStoreWidget.of], to get access to the data.
///  * [PerAccountStoreWidget], for the user's data associated with a
///    particular Zulip account.
class GlobalStoreWidget extends StatefulWidget {
  const GlobalStoreWidget({
    super.key,
    this.placeholder = const LoadingPlaceholder(),
    required this.child,
  });

  final Widget placeholder;
  final Widget child;

  /// The app's global data store.
  ///
  /// The given build context will be registered as a dependency of the
  /// store.  This means that when the data in the store changes,
  /// the element at that build context will be rebuilt.
  ///
  /// This method is typically called near the top of a build method or a
  /// [State.didChangeDependencies] method, like so:
  /// ```
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final globalStore = GlobalStoreWidget.of(context);
  /// ```
  ///
  /// This method should not be called from a [State.initState] method;
  /// use [State.didChangeDependencies] instead.  For discussion, see
  /// [BuildContext.dependOnInheritedWidgetOfExactType].
  ///
  /// See also:
  ///  * [InheritedNotifier], which provides the "dependency" mechanism.
  ///  * [PerAccountStoreWidget.of], for the user's data associated with a
  ///    particular Zulip account.
  static GlobalStore of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_GlobalStoreInheritedWidget>();
    assert(widget != null, 'No GlobalStoreWidget ancestor');
    return widget!.store;
  }

  @override
  State<GlobalStoreWidget> createState() => _GlobalStoreWidgetState();
}

class _GlobalStoreWidgetState extends State<GlobalStoreWidget> {
  GlobalStore? store;

  @override
  void initState() {
    super.initState();
    (() async {
      final store = await ZulipBinding.instance.getGlobalStoreUniquely();
      setState(() {
        this.store = store;
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    final store = this.store;
    if (store == null) return widget.placeholder;
    return _GlobalStoreInheritedWidget(store: store, child: widget.child);
  }
}

// This is separate from [GlobalStoreWidget] only because we need
// a [StatefulWidget] to get hold of the store, and an [InheritedWidget] to
// provide it to descendants, and one widget can't be both of those.
class _GlobalStoreInheritedWidget extends InheritedNotifier<GlobalStore> {
  const _GlobalStoreInheritedWidget({
    required GlobalStore store,
    required super.child,
  }) : super(notifier: store);

  GlobalStore get store => notifier!;

  @override
  bool updateShouldNotify(covariant _GlobalStoreInheritedWidget oldWidget) =>
    store != oldWidget.store;
}

/// Provides access to the user's data for a particular Zulip account.
///
/// Widgets that need information that comes from the Zulip server, or need to
/// interact with the Zulip server, should use [PerAccountStoreWidget.of] to get
/// the [PerAccountStore] for the relevant account.
///
/// A page that is all about a single Zulip account (which includes most of
/// the pages in the app) should have one of this widget, near the root of
/// the page's tree.  Where the UI shows information from several accounts,
/// this widget can be used to specify the account that each subtree should
/// interact with.
///
/// See also:
///  * [PerAccountStoreWidget.of], to get access to the data.
///  * [GlobalStoreWidget], for the app's data beyond that of a
///    particular account.
class PerAccountStoreWidget extends StatefulWidget {
  const PerAccountStoreWidget({
    super.key,
    required this.accountId,
    this.placeholder = const LoadingPlaceholder(),
    required this.child,
  });

  final int accountId;
  final Widget placeholder;
  final Widget child;

  /// The user's data for the relevant Zulip account for this widget.
  ///
  /// The data is taken from the closest [PerAccountStoreWidget] that encloses
  /// the given context.  Throws an error if there is no enclosing
  /// [PerAccountStoreWidget].
  ///
  /// The given build context will be registered as a dependency of the
  /// returned store.  This means that when the data in the store changes,
  /// the element at that build context will be rebuilt.
  ///
  /// This method is typically called near the top of a build method or a
  /// [State.didChangeDependencies] method, like so:
  /// ```
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final store = PerAccountStoreWidget.of(context);
  /// ```
  ///
  /// This method should not be called from a [State.initState] method;
  /// use [State.didChangeDependencies] instead.  For discussion, see
  /// [BuildContext.dependOnInheritedWidgetOfExactType].
  ///
  /// A [State] that calls this method in [State.didChangeDependencies]
  /// should typically also mix in [PerAccountStoreAwareStateMixin],
  /// in order to handle the store itself being replaced with a new store.
  /// This happens in particular if the old store's event queue expires
  /// on the server.
  ///
  /// See also:
  ///  * [accountIdOf], for the account ID corresponding to the same data.
  ///  * [GlobalStoreWidget.of], for the app's data beyond that of a
  ///    particular account.
  ///  * [InheritedNotifier], which provides the "dependency" mechanism.
  static PerAccountStore of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_PerAccountStoreInheritedWidget>();
    assert(widget != null, 'No PerAccountStoreWidget ancestor');
    return widget!.store;
  }

  /// Our account ID for the relevant account for this widget.
  ///
  /// As with [of], the data is taken from the closest [PerAccountStoreWidget]
  /// that encloses the given context.  Throws an error if there is no enclosing
  /// [PerAccountStoreWidget].
  ///
  /// Unlike [of], this method does not create a dependency relationship, and
  /// updates to the [PerAccountStoreWidget] will not cause the calling widget
  /// to be rebuilt.  As a result, this should not be called from build methods,
  /// but is appropriate to use in interaction event handlers.  For more, see
  /// [BuildContext.findAncestorWidgetOfExactType].
  ///
  /// Like [of], the cost of this method is O(1) with a small constant factor.
  static int accountIdOf(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<_PerAccountStoreInheritedWidget>();
    assert(element != null, 'No PerAccountStoreWidget ancestor');
    final widget = element!.findAncestorWidgetOfExactType<PerAccountStoreWidget>();
    assert(widget != null);
    return widget!.accountId;
  }

  /// Whether there is a relevant account specified for this widget.
  static bool debugExistsOf(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_PerAccountStoreInheritedWidget>() != null;
  }

  @override
  State<PerAccountStoreWidget> createState() => _PerAccountStoreWidgetState();
}

class _PerAccountStoreWidgetState extends State<PerAccountStoreWidget> {
  PerAccountStore? store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final globalStore = GlobalStoreWidget.of(context);
    // If we already have data, get it immediately. This avoids showing one
    // frame of loading indicator each time we have a new PerAccountStoreWidget.
    final store = globalStore.perAccountSync(widget.accountId);
    if (store != null) {
      _setStore(store);
    } else {
      // If we don't already have data, request it.
      () async {
        try {
          // If this succeeds, globalStore will notify listeners, and
          // [didChangeDependencies] will run again, this time in the
          // `store != null` case above.
          await globalStore.perAccount(widget.accountId);
        } on AccountNotFoundException {
          // The account was logged out while its store was loading.
          // This widget will be showing [placeholder] perpetually,
          // but that's OK as long as other code will be removing it from the UI
          // (for example by removing a per-account route from the nav).
        }
      }();
    }
  }

  void _setStore(PerAccountStore store) {
    if (store != this.store) {
      setState(() {
        this.store = store;
      });
    }
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
    if (store == null) return widget.placeholder;
    return _PerAccountStoreInheritedWidget(store: store!, child: widget.child);
  }
}

// This is separate from [PerAccountStoreWidget] only because we need a
// [StatefulWidget] to get hold of the store, and an [InheritedWidget] to
// provide it to descendants, and one widget can't be both of those.
class _PerAccountStoreInheritedWidget extends InheritedNotifier<PerAccountStore> {
  const _PerAccountStoreInheritedWidget({
    required PerAccountStore store,
    required super.child,
  }) : super(notifier: store);

  PerAccountStore get store => notifier!;

  @override
  bool updateShouldNotify(covariant _PerAccountStoreInheritedWidget oldWidget) =>
    store != oldWidget.store;
}

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// A [State] that uses the ambient [PerAccountStore].
///
/// The ambient [PerAccountStore] can be replaced in some circumstances,
/// such as when an event queue expires. See [PerAccountStoreWidget.of].
/// When that happens, stateful widgets should
/// - stop using the old [PerAccountStore], which will already have
///   been disposed;
/// - add listeners on the new one.
///
/// Use this mixin, overriding [onNewStore], to do that concisely.
mixin PerAccountStoreAwareStateMixin<T extends StatefulWidget> on State<T> {
  PerAccountStore? _store;

  /// Called when there is a new ambient [PerAccountStore].
  ///
  /// Specifically this is called when this element is first inserted into the tree
  /// (so that it has an ambient [PerAccountStore] for the first time),
  /// and again whenever dependencies change so that [PerAccountStoreWidget.of]
  /// would return a different store from previously.
  ///
  /// In this, add any needed listeners on the new store
  /// and drop any references to the old store, which will already
  /// have been disposed.
  void onNewStore();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final storeNow = PerAccountStoreWidget.of(context);
    if (_store != storeNow) {
      _store = storeNow;
      onNewStore();
    }
  }
}
