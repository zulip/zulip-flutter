import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/core.dart';
import 'package:zulip/api/exception.dart';
import 'package:zulip/model/store.dart';

import '../example_data.dart' as eg;

sealed class _PreparedResponse {
  final Duration delay;

  _PreparedResponse({this.delay = Duration.zero});
}

class _PreparedException extends _PreparedResponse {
  final Object exception;

  _PreparedException({super.delay, required this.exception});
}

class _PreparedSuccess extends _PreparedResponse {
  final int httpStatus;
  final List<int> bytes;
  final Duration bodyDelay;
  final Object? bodyException;

  _PreparedSuccess({
    super.delay,
    required this.httpStatus,
    required this.bytes,
    this.bodyDelay = Duration.zero,
    this.bodyException,
  });
}

/// An [http.Client] that accepts and replays canned responses, for testing.
class FakeHttpClient extends http.BaseClient {

  Iterable<http.BaseRequest> get requestHistory => _requestHistory;
  List<http.BaseRequest> _requestHistory = [];

  List<http.BaseRequest> takeRequests() {
    final result = _requestHistory;
    _requestHistory = [];
    return result;
  }

  final Queue<_PreparedResponse> _preparedResponses = Queue();

  // Please add more features to this mocking API as needed.

  /// Prepare the response for the next request.
  ///
  /// If `exception` is null, the next request will produce an [http.Response]
  /// with the given `httpStatus`, defaulting to 200.  The body of the response
  /// will be `body` if non-null, or `jsonEncode(json)` if `json` is non-null,
  /// or else ''.  The `body` and `json` parameters must not both be non-null.
  ///
  /// If `exception` is non-null, then `httpStatus`, `body`, and `json` must
  /// all be null, and the next request will throw the given exception.
  ///
  /// In each case, the next request will complete a duration of `delay`
  /// after being started.
  /// On success, the response body arrives a further `bodyDelay`
  /// after the response's headers.
  ///
  /// If `bodyException` is non-null, then `exception` must be null,
  /// and the response's body stream will throw the given exception
  /// after emitting the body's bytes,
  /// like when a network connection fails partway through
  /// receiving the response body.
  void prepare({
    Object? exception,
    int? httpStatus,
    Map<String, dynamic>? json,
    String? body,
    Object? bodyException,
    Duration delay = Duration.zero,
    Duration bodyDelay = Duration.zero,
  }) {
    // TODO: Prevent a source of bugs by ensuring that there are no outstanding
    //   prepared responses when the test ends.
    if (exception != null) {
      assert(httpStatus == null && json == null && body == null
        && bodyException == null && bodyDelay == Duration.zero);
      _preparedResponses.addLast(_PreparedException(exception: exception, delay: delay));
    } else {
      assert((json == null) || (body == null));
      final String resolvedBody = switch ((body, json)) {
        (var body?, _) => body,
        (_, var json?) => jsonEncode(json),
        _              => '',
      };
      _preparedResponses.addLast(_PreparedSuccess(
        httpStatus: httpStatus ?? 200,
        bytes: utf8.encode(resolvedBody),
        bodyException: bodyException,
        delay: delay,
        bodyDelay: bodyDelay,
      ));
    }
  }

  void clearPreparedResponses() {
    _preparedResponses.clear();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _requestHistory.add(request);

    if (_preparedResponses.isEmpty) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'An API request was attempted in a test when no response was prepared.'),
        ErrorDescription(
          'Each API request in a test context must be preceded by a corresponding '
          'call to [FakeApiConnection.prepare].'),
      ]);
    }
    final response = _preparedResponses.removeFirst();

    final abortTrigger =
      (request is http.Abortable) ? request.abortTrigger : null;

    final http.StreamedResponse Function() computation;
    switch (response) {
      case _PreparedException(:var exception):
        computation = () => throw exception;
      case _PreparedSuccess(:var bytes, :var httpStatus, :var bodyDelay,
                            :var bodyException):
        computation = () => http.StreamedResponse(
          _bodyStream(request, bytes: bytes, bodyDelay: bodyDelay,
            bodyException: bodyException, abortTrigger: abortTrigger),
          httpStatus, request: request);
    }
    final result = Future.delayed(response.delay, computation);
    if (abortTrigger == null) return result;
    // Mimic [IOClient]: if the trigger fires before the response headers
    // are delivered, [send]'s future throws instead.
    return Future.any([
      result,
      abortTrigger.then((_) => throw http.RequestAbortedException(request.url)),
    ]);
  }

  /// The response body, mimicking [IOClient]'s abort behavior:
  /// if [abortTrigger] fires before the body has been delivered,
  /// inject an [http.RequestAbortedException] and close the stream.
  ///
  /// If [bodyException] is non-null, it is delivered as an error
  /// on the stream, after the body's bytes.
  http.ByteStream _bodyStream(http.BaseRequest request, {
    required List<int> bytes,
    required Duration bodyDelay,
    required Object? bodyException,
    required Future<void>? abortTrigger,
  }) {
    if (abortTrigger == null && bodyDelay == Duration.zero
        && bodyException == null) {
      return http.ByteStream.fromBytes(bytes);
    }
    final controller = StreamController<List<int>>();
    Timer(bodyDelay, () {
      if (controller.isClosed) return;
      controller.add(bytes);
      if (bodyException != null) controller.addError(bodyException);
      controller.close();
    });
    abortTrigger?.whenComplete(() {
      if (controller.isClosed) return;
      controller..addError(http.RequestAbortedException(request.url))..close();
    });
    return http.ByteStream(controller.stream);
  }
}

/// An [ApiConnection] that accepts and replays canned responses, for testing.
///
/// This is the [ApiConnection] subclass used by [TestGlobalStore].
/// In tests that use a store (including most of our widget tests),
/// one typically uses [PerAccountStore.connection] to get
/// the relevant instance of this class.
///
/// Tests that don't use a store (in particular our API-binding tests)
/// typically use [FakeApiConnection.with_] to obtain an instance of this class.
class FakeApiConnection extends ApiConnection {
  /// Construct an [ApiConnection] that accepts and replays canned responses, for testing.
  ///
  /// Typically a test does not call this constructor directly.  Instead:
  ///  * when a test store is being used, invoke [PerAccountStore.connection]
  ///    to get the [FakeApiConnection] used by the relevant store;
  ///  * otherwise, call [FakeApiConnection.with_] to make a fresh
  ///    [FakeApiConnection] and cleanly close it.
  ///
  /// If `zulipFeatureLevel` is omitted, it defaults to [eg.futureZulipFeatureLevel],
  /// which causes route bindings to behave as they would for the
  /// latest Zulip server versions.
  /// To set `zulipFeatureLevel` to null, pass null explicitly.
  FakeApiConnection({
    Uri? realmUrl,
    int? zulipFeatureLevel = eg.futureZulipFeatureLevel,
    String? email,
    String? apiKey,
    bool useBinding = false,
  }) : this._(
         realmUrl: realmUrl ?? eg.realmUrl,
         zulipFeatureLevel: zulipFeatureLevel,
         email: email,
         apiKey: apiKey,
         client: FakeHttpClient(),
         useBinding: useBinding,
       );

  FakeApiConnection.fromAccount(Account account, {required bool useBinding})
    : this(
        realmUrl: account.realmUrl,
        zulipFeatureLevel: account.zulipFeatureLevel,
        email: account.email,
        apiKey: account.apiKey,
        useBinding: useBinding);

  FakeApiConnection._({
    required super.realmUrl,
    required super.zulipFeatureLevel,
    super.email,
    super.apiKey,
    required this.client,
    required super.useBinding,
  }) : super(client: client);

  final FakeHttpClient client;

  /// Run the given callback on a fresh [FakeApiConnection], then close it,
  /// using try/finally.
  ///
  /// If `zulipFeatureLevel` is omitted, it defaults to [eg.futureZulipFeatureLevel],
  /// which causes route bindings to behave as they would for the
  /// latest Zulip server versions.
  /// To set `zulipFeatureLevel` to null, pass null explicitly.
  static Future<T> with_<T>(
    Future<T> Function(FakeApiConnection connection) fn, {
    Uri? realmUrl,
    int? zulipFeatureLevel = eg.futureZulipFeatureLevel,
    Account? account,
    bool useBinding = false,
  }) async {
    assert((account == null)
      || (realmUrl == null && zulipFeatureLevel == eg.futureZulipFeatureLevel));
    final connection = (account != null)
      ? FakeApiConnection.fromAccount(account, useBinding: useBinding)
      : FakeApiConnection(
          realmUrl: realmUrl,
          zulipFeatureLevel: zulipFeatureLevel,
          useBinding: useBinding);
    try {
      return await fn(connection);
    } finally {
      connection.close();
    }
  }

  /// True just if [close] has never been called on this connection.
  // In principle this could live on [ApiConnection]... but [http.Client]
  // offers no way to tell if [http.Client.close] has been called,
  // so we follow that library's lead on this point of API design.
  bool get isOpen => _isOpen;
  bool _isOpen = true;

  @override
  void close() {
    _isOpen = false;
    super.close();
  }

  http.BaseRequest? get lastRequest => client._requestHistory.lastOrNull;

  List<http.BaseRequest> takeRequests() => client.takeRequests();

  /// Prepare the HTTP response for the next request.
  ///
  /// If `httpException` and `apiException` are both null, then
  /// the next request will produce an [http.Response]
  /// with the given `httpStatus`, defaulting to 200.  The body of the response
  /// will be `body` if non-null, or `jsonEncode(json)` if `json` is non-null,
  /// or else ''.  The `body` and `json` parameters must not both be non-null.
  ///
  /// If `httpException` is non-null, then `apiException`,
  /// `httpStatus`, `body`, and `json` must all be null, and the next request
  /// will throw the given exception within the HTTP client layer,
  /// causing the API request to throw a [NetworkException]
  /// wrapping the given exception.
  ///
  /// If `apiException` is non-null, then `httpException`,
  /// `httpStatus`, `body`, and `json` must all be null, and the next request
  /// will throw an exception equivalent to the given exception
  /// (except [ApiRequestException.routeName], which is ignored).
  ///
  /// In each case, the next request will complete a duration of `delay`
  /// after being started.
  /// On success, the response body arrives a further `bodyDelay`
  /// after the response's headers.
  ///
  /// If `bodyException` is non-null, then `httpException` and `apiException`
  /// must be null, and the response's body stream will throw
  /// the given exception after emitting the body's bytes,
  /// like when a network connection fails partway through
  /// receiving the response body.
  void prepare({
    Object? httpException,
    ZulipApiException? apiException,
    int? httpStatus,
    Map<String, dynamic>? json,
    String? body,
    Object? bodyException,
    Duration delay = Duration.zero,
    Duration bodyDelay = Duration.zero,
  }) {
    assert(isOpen);

    // The doc on [http.BaseClient.send] goes further than the following
    // condition, suggesting that any exception thrown there should be an
    // [http.ClientException].  But from the upstream implementation, in the
    // actual live app, we already get TlsException and SocketException,
    // without them getting wrapped in http.ClientException as that specifies.
    // So naturally our tests need to simulate those too.
    if (httpException is ApiRequestException) {
      throw FlutterError.fromParts([
        ErrorSummary('FakeApiConnection.prepare was passed an ApiRequestException.'),
        ErrorDescription(
          'The `httpException` parameter to FakeApiConnection.prepare describes '
          'an exception for the underlying HTTP request to throw.  '
          'In the actual app, that will never be a Zulip-specific exception '
          'like an ApiRequestException.'),
        ErrorHint('Try using the `apiException` parameter instead.')
      ]);
    }

    if (apiException != null) {
      assert(httpException == null && bodyException == null
        && httpStatus == null && json == null && body == null);
      httpStatus = apiException.httpStatus;
      json = {
        'result': 'error',
        'code': apiException.code,
        'msg': apiException.message,
        ...apiException.data,
      };
    }

    client.prepare(
      exception: httpException,
      httpStatus: httpStatus, json: json, body: body,
      bodyException: bodyException,
      delay: delay, bodyDelay: bodyDelay,
    );
  }

  void clearPreparedResponses() {
    client.clearPreparedResponses();
  }
}

extension FakeApiConnectionChecks on Subject<FakeApiConnection> {
  Subject<bool> get isOpen => has((x) => x.isOpen, 'isOpen');
}
