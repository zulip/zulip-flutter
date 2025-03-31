import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/localizations.dart';

/// Some kind of error from a Zulip API network request.
sealed class ApiRequestException implements Exception {
  /// The name of the Zulip API route for the request.
  ///
  /// Generally this is the OpenAPI operation ID for the endpoint
  /// (as seen in the URL of the endpoint's API documentation),
  /// converted to camel case.
  /// For example, the endpoint documented at <https://zulip.com/api/get-messages>
  /// is the one with OpenAPI operation ID "get-messages",
  /// and its route name would be "getMessages".
  final String routeName;

  /// A user-facing description of the error.
  ///
  /// For [ZulipApiException] this is supplied by the server as the `message`
  /// property in the JSON response, and is translated into the user's language.
  final String message;

  ApiRequestException({required this.routeName, required this.message});

  @override
  String toString() => message;
}

/// A network-level error that prevented even getting an HTTP response
/// to some Zulip API network request.
///
/// This is the antonym of [HttpException].
class NetworkException extends ApiRequestException {
  /// The exception describing the underlying error.
  ///
  /// This can be any exception value that [http.Client.send] throws.
  /// Ideally that would always be an [http.ClientException],
  /// but empirically it can be [TlsException] and possibly others.
  final Object cause;

  NetworkException({required super.routeName, required super.message, required this.cause});

  @override
  String toString() {
    return 'NetworkException: $message ($cause)';
  }
}

/// Some kind of [ApiRequestException] that came as an HTTP response.
///
/// This is the antonym of [NetworkException].
sealed class HttpException extends ApiRequestException {
  /// The HTTP status code returned by the server.
  ///
  /// On [ZulipApiException], this is always in the range 400..499.
  final int httpStatus;

  HttpException({required super.routeName, required this.httpStatus, required super.message});
}

/// An error returned through the Zulip server API,
/// and with a 4xx HTTP status code.
///
/// See API docs: https://zulip.com/api/rest-error-handling
class ZulipApiException extends HttpException {
  /// The Zulip API error code returned by the server.
  final String code;

  /// The error's JSON data, if any, beyond the properties common to all errors.
  ///
  /// This consists of the properties other than `result`, `code`, and `msg`.
  ///
  /// For most types of errors, this will be empty.
  final Map<String, dynamic> data;

  ZulipApiException({
    required super.routeName,
    required super.httpStatus,
    required this.code,
    required this.data,
    required super.message,
  }) : assert(400 <= httpStatus && httpStatus <= 499),
       assert(!data.containsKey('result')
           && !data.containsKey('code')
           && !data.containsKey('msg'));

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('${objectRuntimeType(this, 'ZulipApiException')}:');
    if (httpStatus != 400) sb.write(" $httpStatus");
    if (code != 'BAD_REQUEST') sb.write(" $code");
    if (data.isNotEmpty) sb.write(" ${jsonEncode(data)}");
    sb.write(" $routeName");
    sb.write(": $message");
    return sb.toString();
  }
}

/// Some kind of server-side error in handling the request.
///
/// This should always represent either some kind of operational issue
/// on the server, or a bug in the server where its responses don't
/// agree with the documented API.
sealed class ServerException extends HttpException {
  /// The response body, decoded as a JSON object.
  ///
  /// This is null if the body could not be read, or was not a valid JSON object.
  final Map<String, dynamic>? data;

  ServerException({
    required super.routeName,
    required super.httpStatus,
    required this.data,
    required super.message,
  });
}

/// A server error, acknowledged by the server via a 5xx HTTP status code.
class Server5xxException extends ServerException {
  Server5xxException({
    required super.routeName,
    required super.httpStatus,
    required super.data,
  }) : assert(500 <= httpStatus && httpStatus <= 599),
       super(message: GlobalLocalizations.zulipLocalizations
         .errorRequestFailed(httpStatus));
}

/// An error where the server's response doesn't match the Zulip API.
///
/// This means either the server's HTTP status wasn't one that the docs say the
/// server may give, or the body didn't contain appropriately-shaped JSON
/// for the HTTP status.
///
/// When the HTTP status is 200 (success), this means the body didn't match
/// the specific JSON schema expected for the particular route.
///
/// When the HTTP status is 4xx (client error), this means the body didn't match
/// the JSON schema expected for error results in the Zulip API in general.
///
/// See docs: https://zulip.com/api/rest-error-handling
class MalformedServerResponseException extends ServerException {
  /// The underlying exception from trying to parse the response, when applicable.
  ///
  /// This should be paired with the use of [Error.throwWithStackTrace]
  /// in order to preserve the underlying exception's stack trace, which
  /// may be more informative than the exception object itself.
  final Object? causeException;

  MalformedServerResponseException({
    required super.routeName,
    required super.httpStatus,
    required super.data,
    this.causeException,
  }) : super(message: causeException == null
         ? GlobalLocalizations.zulipLocalizations
            .errorMalformedResponse(httpStatus)
         : GlobalLocalizations.zulipLocalizations
            .errorMalformedResponseWithCause(
              httpStatus, causeException.toString()));
}
