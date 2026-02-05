import 'package:flutter/widgets.dart';

import '../api/core.dart' as api_core;
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../model/internal_link.dart' as internal;
import '../model/store.dart' as store_model;
import '../widgets/store.dart' show PerAccountStoreWidget;

/// An abstraction for rendering Zulip-formatted content independent of
/// the full PerAccountStore. Provides just what the content widgets need
/// to resolve URLs, select user-facing settings, and build authenticated
/// requests when applicable.
abstract class ContentContext {
  const ContentContext();

  /// The realm base URL when known. Used to resolve relative links.
  Uri? get realmUrl;

  /// Resolve a URL reference against [realmUrl], returning null if invalid.
  Uri? tryResolveUrl(String reference);

  /// Preferred time format (12/24-hour vs locale default).
  TwentyFourHourTimeMode get twentyFourHourTime;

  /// HTTP headers to use for fetching a resource at [url].
  /// If content is account-backed and [url] is on-realm, include auth.
  Map<String, String> headersFor(Uri url);

  /// Parse an internal link if possible, otherwise return null.
  internal.InternalLink? parseInternalLink(Uri url);

  /// Optional PerAccountStore for account-backed contexts.
  store_model.PerAccountStore? get store;
}

/// A ContentContext backed by a PerAccountStore.
class AccountContentContext extends ContentContext {
  const AccountContentContext(this._store);

  final store_model.PerAccountStore _store;

  @override
  Uri get realmUrl => _store.realmUrl;

  @override
  Uri? tryResolveUrl(String reference) => _store.tryResolveUrl(reference);

  @override
  TwentyFourHourTimeMode get twentyFourHourTime => _store.userSettings.twentyFourHourTime;

  @override
  Map<String, String> headersFor(Uri url) {
    final account = _store.account;
    return {
      if (url.origin == account.realmUrl.origin) ...api_core.authHeader(
        email: account.email, apiKey: account.apiKey),
      ...api_core.userAgentHeader(),
    };
  }

  @override
  internal.InternalLink? parseInternalLink(Uri url) => internal.parseInternalLink(url, _store);

  @override
  store_model.PerAccountStore get store => _store;
}

/// A ContentContext usable outside any account context (e.g., login UI,
/// realm/stream descriptions shown pre-auth). No auth headers are supplied.
class StandaloneContentContext extends ContentContext {
  const StandaloneContentContext({
    Uri? realmUrl,
    TwentyFourHourTimeMode twentyFourHourTime = TwentyFourHourTimeMode.localeDefault,
  }) : _realmUrl = realmUrl, _twentyFourHourTime = twentyFourHourTime;

  final Uri? _realmUrl;
  final TwentyFourHourTimeMode _twentyFourHourTime;

  @override
  Uri? get realmUrl => _realmUrl;

  @override
  Uri? tryResolveUrl(String reference) {
    final base = _realmUrl;
    if (base == null) return null;
    return store_model.tryResolveUrl(base, reference);
  }

  @override
  TwentyFourHourTimeMode get twentyFourHourTime => _twentyFourHourTime;

  @override
  Map<String, String> headersFor(Uri url) => api_core.userAgentHeader();

  @override
  internal.InternalLink? parseInternalLink(Uri url) => null;

  @override
  store_model.PerAccountStore? get store => null;
}

/// An InheritedWidget to provide a ContentContext to a subtree.
///
/// For account-backed pages, you typically won’t construct this directly—
/// instead, use [ContentContext.of] which will synthesize an
/// [AccountContentContext] from the ambient PerAccountStoreWidget.
class ContentContextWidget extends InheritedWidget {
  const ContentContextWidget({super.key, required this.contextValue, required super.child});

  final ContentContext contextValue;

  @override
  bool updateShouldNotify(covariant ContentContextWidget oldWidget) =>
      !identical(oldWidget.contextValue, contextValue);

  static ContentContext of(BuildContext context) {
    // Prefer an explicit ContentContext if present.
    final inherited = context.dependOnInheritedWidgetOfExactType<ContentContextWidget>();
    if (inherited != null) return inherited.contextValue;

    // Fallback: synthesize from ambient PerAccountStore if available.
    if (PerAccountStoreWidget.debugExistsOf(context)) {
      final store = PerAccountStoreWidget.of(context);
      return AccountContentContext(store);
    }

    throw FlutterError.fromParts([
      ErrorSummary('No ContentContext available.'),
      ErrorDescription('Content rendering requires either a ContentContextWidget ancestor '
          'or a PerAccountStoreWidget for account-backed contexts.'),
      context.describeWidget('The widget that tried to read a ContentContext was'),
      context.describeOwnershipChain('The ownership chain for the affected widget is'),
    ]);
  }
}
