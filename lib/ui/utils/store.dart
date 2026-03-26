import 'package:flutter/material.dart';

import '../../get/services/store_service.dart';
import '../../model/binding.dart';
import '../../model/database.dart';
import '../../model/settings.dart';
import '../../model/store.dart';

/// Get the current per-account store from the StoreService.
///
/// This is a convenience method that can be used instead of requirePerAccountStore().
/// The store is retrieved from the GetX StoreService.
///
/// Returns null if no store is available.
PerAccountStore? getPerAccountStore() {
  final service = StoreService.to;
  return service.store;
}

/// Check if a per-account store is available.
bool hasPerAccountStore() {
  final service = StoreService.to;
  return service.hasStore;
}

/// Provides access to the app's data.
///
/// There should be one of this widget, near the root of the tree.
///
/// See also:
///  * [GlobalStoreWidget.of], to get access to the data.
///  * [StoreService], for the user's data associated with a
///    particular Zulip account.
class GlobalStoreWidget extends StatefulWidget {
  const GlobalStoreWidget({
    super.key,
    this.blockingFuture,
    this.placeholder = const BlankLoadingPlaceholder(),
    required this.child,
  });

  /// An additional future to await before showing the child.
  ///
  /// If [blockingFuture] is non-null, then this widget will build [child]
  /// only after the future completes.  This widget's behavior is not affected
  /// by whether the future's completion is with a value or with an error.
  final Future<void>? blockingFuture;

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
  ///  * [StoreService], for the user's data associated with a
  ///    particular Zulip account.
  static GlobalStore of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_GlobalStoreInheritedWidget>();
    assert(widget != null, 'No GlobalStoreWidget ancestor');
    return widget!.store;
  }

  /// The user's [GlobalSettings] data within the app's global data store.
  ///
  /// The given build context will be registered as a dependency and
  /// subscribed to changes in the returned [GlobalSettingsStore].
  /// This means that when the setting values in the store change,
  /// the element at that build context will be rebuilt.
  ///
  /// This method is typically called near the top of a build method or a
  /// [State.didChangeDependencies] method, like so:
  /// ```
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final globalSettings = GlobalStoreWidget.settingsOf(context);
  /// ```
  ///
  /// See [of] for further discussion of how to use this kind of method.
  static GlobalSettingsStore settingsOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<
          _GlobalSettingsStoreInheritedWidget
        >();
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
      if (widget.blockingFuture != null) {
        await widget.blockingFuture!.catchError((_) {});
      }
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
  _GlobalStoreInheritedWidget({
    required GlobalStore store,
    required Widget child,
  }) : super(
         notifier: store,
         child: _GlobalSettingsStoreInheritedWidget(
           store: store.settings,
           child: child,
         ),
       );

  GlobalStore get store => notifier!;
}

// This is like [_GlobalStoreInheritedWidget] except it subscribes to the
// [GlobalSettingsStore] instead of the overall [GlobalStore].
// That enables [settingsOf] to do the same.
class _GlobalSettingsStoreInheritedWidget
    extends InheritedNotifier<GlobalSettingsStore> {
  const _GlobalSettingsStoreInheritedWidget({
    required GlobalSettingsStore store,
    required super.child,
  }) : super(notifier: store);

  GlobalSettingsStore get store => notifier!;
}

class BlankLoadingPlaceholder extends StatelessWidget {
  const BlankLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
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
/// such as when an event queue expires. See [StoreService].
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
  /// and again whenever dependencies change so that [StoreService]
  /// would return a different store from previously.
  ///
  /// In this, add any needed listeners on the new store
  /// and drop any references to the old store, which will already
  /// have been disposed.
  void onNewStore();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final storeNow = requirePerAccountStore();
    if (_store != storeNow) {
      _store = storeNow;
      onNewStore();
    }
  }
}
