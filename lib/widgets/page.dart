
import 'package:flutter/material.dart';

import '../model/store.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// An [InheritedWidget] for near the root of a page's widget subtree,
/// providing its [BuildContext].
///
/// Useful when needing a context that persists through the page's lifespan,
/// e.g. for a show-action-sheet function
/// whose buttons use a context to close the sheet
/// or show an error dialog / snackbar asynchronously.
///
/// (In this scenario, it would be buggy to use the context of the element
/// that was long-pressed,
/// if the element can unmount as part of handling a Zulip event.)
class PageRoot extends InheritedWidget {
  const PageRoot({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant PageRoot oldWidget) => false;

  static BuildContext contextOf(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<PageRoot>();
    assert(element != null, 'No PageRoot ancestor');
    return element!;
  }
}

/// A page route that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
abstract class WidgetRoute<T extends Object?> extends PageRoute<T> {
  /// The widget that this page route always builds.
  Widget get page;
}

/// A page route that specifies a particular Zulip account to use, by ID.
abstract class AccountRoute<T extends Object?> extends PageRoute<T> {
  /// The [Account.id] of the account to use for this page.
  int get accountId;
}

/// A [MaterialPageRoute] that always builds the same widget.
///
/// This is useful for making the route more transparent for a test to inspect.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which automates providing a
///    per-account store on the new route.
class MaterialWidgetRoute<T extends Object?> extends MaterialPageRoute<T> implements WidgetRoute<T> {
  MaterialWidgetRoute({
    required this.page,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (context) => page);

  @override
  final Widget page;
}

/// A mixin for providing a given account's per-account store on a page route.
mixin AccountPageRouteMixin<T extends Object?> on PageRoute<T> implements AccountRoute<T> {
  @override
  int get accountId;

  Widget? get loadingPlaceholderPage;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return PerAccountStoreWidget(
      accountId: accountId,
      placeholder: loadingPlaceholderPage ?? const LoadingPlaceholderPage(),
      routeToRemoveOnLogout: this,
      // PageRoot goes under PerAccountStoreWidget, so the provided context
      // can be used for PerAccountStoreWidget.of.
      child: PageRoot(
        child: super.buildPage(context, animation, secondaryAnimation)));
  }
}

/// A [MaterialPageRoute] providing a per-account store for a given account.
///
/// See also:
///  * [MaterialAccountWidgetRoute], a subclass which is more transparent
///    for tests.
///  * [AccountPageRouteBuilder], for defining one-off page routes
///    in terms of callbacks.
class MaterialAccountPageRoute<T extends Object?> extends MaterialPageRoute<T> with AccountPageRouteMixin<T> {
  /// Construct a [MaterialAccountPageRoute] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  MaterialAccountPageRoute({
    int? accountId,
    BuildContext? context,
    this.loadingPlaceholderPage,
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : assert((accountId != null) ^ (context != null),
         "exactly one of accountId or context must be specified"),
       accountId = accountId ?? PerAccountStoreWidget.accountIdOf(context!);

  @override
  final int accountId;

  @override
  final Widget? loadingPlaceholderPage;
}

/// A [MaterialPageRoute] that provides a per-account store for a given account
/// and always builds the same widget.
///
/// This is the [PageRoute] subclass to use for most navigation in the app.
///
/// Always building the same widget is useful for making the route
/// more transparent for a test to inspect.
///
/// See also:
///  * [MaterialWidgetRoute], for routes that need no per-account store.
class MaterialAccountWidgetRoute<T extends Object?> extends MaterialAccountPageRoute<T> implements WidgetRoute<T> {
  /// Construct a [MaterialAccountWidgetRoute] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  MaterialAccountWidgetRoute({
    super.accountId,
    super.context,
    super.loadingPlaceholderPage,
    required this.page,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : super(builder: (context) => page);

  @override
  final Widget page;
}

/// A [PageRouteBuilder] providing a per-account store for a given account.
///
/// This is the [PageRouteBuilder] analogue of [MaterialAccountPageRoute].
class AccountPageRouteBuilder<T extends Object?> extends PageRouteBuilder<T> with AccountPageRouteMixin<T> {
  /// Construct an [AccountPageRouteBuilder] using either the given account ID,
  /// or the ambient one from the given context.
  ///
  /// The account ID used is [accountId] if specified,
  /// else the ambient account ID from [context].
  /// One of those parameters must be specified, and not both.
  ///
  /// Generally most navigation in the app is within a given account,
  /// and should use [context].  Using [accountId] is appropriate for
  /// navigating across accounts, or navigating into an account from contexts
  /// (like login or the choose-account page) that don't have an ambient account.
  AccountPageRouteBuilder({
    int? accountId,
    BuildContext? context,
    this.loadingPlaceholderPage,
    super.settings,
    required super.pageBuilder,
    super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.opaque,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  }) : assert((accountId != null) ^ (context != null),
         "exactly one of accountId or context must be specified"),
       accountId = accountId ?? PerAccountStoreWidget.accountIdOf(context!);

  @override
  final int accountId;

  @override
  final Widget? loadingPlaceholderPage;
}

class LoadingPlaceholderPage extends StatelessWidget {
  const LoadingPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const LoadingPlaceholder(),
    );
  }
}

/// A placeholder for when a page body has no content to show.
///
/// Pass [message] for a "no-content-here" message,
/// or pass true for [loading] if the content hasn't finished loading yet,
/// but don't pass both.
///
/// Suitable for the inbox, the message-list page, etc.
///
/// This handles the horizontal device insets
/// and the bottom inset when needed (in a message list with no compose box).
/// The top inset is handled externally by the app bar.
///
/// See also:
///  * [BottomSheetEmptyContentPlaceholder], for a similar element to use in
///    a bottom sheet.
// TODO(#311) If the message list gets a bottom nav, the bottom inset will
//   always be handled externally too; simplify implementation and dartdoc.
class PageBodyEmptyContentPlaceholder extends StatelessWidget {
  const PageBodyEmptyContentPlaceholder({
    super.key,
    this.message,
    this.loading = false,
  }) : assert((message != null) ^ loading);

  final String? message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final child = loading
      ? CircularProgressIndicator()
      : Text(
          textAlign: TextAlign.center,
          style: TextStyle(
            color: designVariables.labelSearchPrompt,
            fontSize: 17,
            height: 23 / 17,
          ).merge(weightVariableTextStyle(context, wght: 500)),
          message!);

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: Align(
          alignment: Alignment.topCenter,
          // TODO leading and trailing elements, like in Figma (given as SVGs):
          //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=5957-167736&m=dev
          child: child)));
  }
}

/// A [ChangeNotifier] that tracks a nullable account-ID selection.
///
/// Maintains a listener on [GlobalStore] and will clear the selection
/// if the account no longer exists because it was logged out.
///
/// Use [selectedAccountId] to read the selection
/// and [selectAccount] to update it.
class MultiAccountPageController extends ChangeNotifier {
  factory MultiAccountPageController.init(GlobalStore globalStore) {

    final result = MultiAccountPageController._(globalStore);
    globalStore.addListener(result._globalStoreChanged);
    // TODO initialize selectedAccountId to last-visited?
    result._reconcile();
    return result;
  }

  MultiAccountPageController._(this._globalStore);

  final GlobalStore _globalStore;

  int? get selectedAccountId => _selectedAccountId;
  int? _selectedAccountId;

  void selectAccount(int accountId) {
    _selectedAccountId = accountId;
    _reconcile();
    notifyListeners();
  }

  void _globalStoreChanged() {
    _reconcile();
  }

  void _reconcile() {
    if (_selectedAccountId == null) return;
    if (_globalStore.accountIds.contains(_selectedAccountId)) return;
    _selectedAccountId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _globalStore.removeListener(_globalStoreChanged);
    super.dispose();
  }
}

/// A widget that can efficiently provide a [MultiAccountPageController]
/// to its descendants, via [BuildContext.dependOnInheritedWidgetOfExactType].
class MultiAccountPageProvider extends StatefulWidget {
  const MultiAccountPageProvider({super.key, required this.child});

  final Widget child;

  /// The [MultiAccountPageController] of an assumed
  /// [MultiAccountPageProvider] ancestor.
  ///
  /// Creates a dependency on the controller via [InheritedNotifier].
  static MultiAccountPageController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_MultiAccountPageControllerInheritedWidget>();
    assert(widget != null, 'No MultiAccountPageProvider ancestor');
    return widget!.controller;
  }

  @override
  State<MultiAccountPageProvider> createState() => _MultiAccountPageProviderState();
}

class _MultiAccountPageProviderState extends State<MultiAccountPageProvider> {
  GlobalStore? _globalStore;

  MultiAccountPageController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = GlobalStoreWidget.of(context);
    if (_globalStore != store) {
      _controller?.dispose();
      _controller = MultiAccountPageController.init(store);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MultiAccountPageControllerInheritedWidget(
      controller: _controller!, child: widget.child);
  }
}

class _MultiAccountPageControllerInheritedWidget extends InheritedNotifier<MultiAccountPageController> {
  const _MultiAccountPageControllerInheritedWidget({
    required MultiAccountPageController controller,
    required super.child,
  }) : super(notifier: controller);

  MultiAccountPageController get controller => notifier!;
}
