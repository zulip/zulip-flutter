/// `package:checks`-related extensions for the Dart standard library.
///
/// Use this file for types in the Dart SDK, as well as in other
/// packages published by the Dart team that function as
/// part of the Dart standard library.
library;

import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

extension ListChecks<T> on Subject<List<T>> {
  Subject<T> operator [](int index) => has((l) => l[index], '[$index]');
}

extension MapEntryChecks<K, V> on Subject<MapEntry<K, V>> {
  Subject<K> get key => has((e) => e.key, 'key');
  Subject<V> get value => has((e) => e.value, 'value');
}

extension NullableMapChecks<K, V> on Subject<Map<K, V>?> {
  void deepEquals(Map<Object?, Object?>? expected) {
    if (expected == null) {
      return isNull();
    } else {
      return isNotNull().deepEquals(expected);
    }
  }
}

extension ErrorChecks on Subject<Error> {
  Subject<String> get asString => has((x) => x.toString(), 'toString'); // TODO(checks): what's a good convention for this?
}

/// Convert [object] to a pure JSON-like value.
///
/// The result is similar to `jsonDecode(jsonEncode(object))`, but without
/// passing through a serialized form.
///
/// All JSON atoms (numbers, booleans, null, and strings) are used directly.
/// All JSON containers (lists, and maps with string keys) are copied
/// as their elements are converted recursively.
/// For any other value, a dynamic call `.toJson()` is made and
/// should return either a JSON atom or a JSON container.
Object? deepToJson(Object? object) {
  // Implementation is based on the recursion underlying [jsonEncode],
  // at [_JsonStringifier.writeObject] in the stdlib's convert/json.dart .
  // (We leave out the cycle-checking, for simplicity / out of laziness.)

  var (result, success) = _deeplyConvertShallowJsonValue(object);
  if (success) return result;

  final Object? shallowlyConverted;
  try {
    shallowlyConverted = (object as dynamic).toJson();
  } catch (e) {
    throw JsonUnsupportedObjectError(object, cause: e);
  }

  (result, success) = _deeplyConvertShallowJsonValue(shallowlyConverted);
  if (success) return result;
  throw JsonUnsupportedObjectError(object);
}

(Object? result, bool success) _deeplyConvertShallowJsonValue(Object? object) {
  final Object? result;
  switch (object) {
    case null || bool() || String() || num():
      result = object;
    case List():
      result = object.map((x) => deepToJson(x)).toList();
    case Map() when object.keys.every((k) => k is String):
      result = object.map((k, v) => MapEntry<String, dynamic>(k as String, deepToJson(v)));
    default:
      return (null, false);
  }
  return (result, true);
}

extension CompleterChecks<T> on Subject<Completer<T>> {
  Subject<bool> get isCompleted => has((x) => x.isCompleted, 'isCompleted');
}

extension JsonChecks on Subject<Object?> {
  /// Expects that the value is deeply equal to [expected],
  /// after calling [deepToJson] on both.
  ///
  /// Deep equality is computed by [MapChecks.deepEquals]
  /// or [IterableChecks.deepEquals].
  void jsonEquals(Object? expected) {
    final expectedJson = deepToJson(expected);
    final actualJson = has((e) => deepToJson(e), 'deepToJson');
    switch (expectedJson) {
      case null || bool() || String() || num():
        return actualJson.equals(expectedJson);
      case List():
        return actualJson.isA<List<dynamic>>().deepEquals(expectedJson);
      case Map():
        return actualJson.isA<Map<dynamic, dynamic>>().deepEquals(expectedJson);
      case _:
        assert(false);
    }
  }
}

extension UriChecks on Subject<Uri> {
  Subject<String> get asString => has((u) => u.toString(), 'toString'); // TODO(checks): what's a good convention for this?

  Subject<String> get scheme => has((u) => u.scheme, 'scheme');
  Subject<String> get authority => has((u) => u.authority, 'authority');
  Subject<String> get userInfo => has((u) => u.userInfo, 'userInfo');
  Subject<String> get host => has((u) => u.host, 'host');
  Subject<int> get port => has((u) => u.port, 'port');
  Subject<String> get path => has((u) => u.path, 'path');
  Subject<String> get query => has((u) => u.query, 'query');
  Subject<String> get fragment => has((u) => u.fragment, 'fragment');
  Subject<List<String>> get pathSegments => has((u) => u.pathSegments, 'pathSegments');
  Subject<Map<String, String>> get queryParameters => has((u) => u.queryParameters, 'queryParameters');
  Subject<Map<String, List<String>>> get queryParametersAll => has((u) => u.queryParametersAll, 'queryParametersAll');
  Subject<bool> get isAbsolute => has((u) => u.isAbsolute, 'isAbsolute');
  Subject<String> get origin => has((u) => u.origin, 'origin');
  // TODO hasScheme, other has*, data
}

extension HttpBaseRequestChecks on Subject<http.BaseRequest> {
  Subject<String> get method => has((r) => r.method, 'method');
  Subject<Uri> get url => has((r) => r.url, 'url');
  Subject<int?> get contentLength => has((r) => r.contentLength, 'contentLength');
  Subject<Map<String, String>> get headers => has((r) => r.headers, 'headers');
  // TODO persistentConnection, followRedirects, maxRedirects, finalized
}

extension HttpRequestChecks on Subject<http.Request> {
  Subject<int> get contentLength => has((r) => r.contentLength, 'contentLength');
  Subject<Encoding> get encoding => has((r) => r.encoding, 'encoding');
  Subject<List<int>> get bodyBytes => has((r) => r.bodyBytes, 'bodyBytes'); // TODO or Uint8List?
  Subject<String> get body => has((r) => r.body, 'body');
  Subject<Map<String, String>> get bodyFields => has((r) => r.bodyFields, 'bodyFields');
}

extension HttpMultipartRequestChecks on Subject<http.MultipartRequest> {
  Subject<Map<String, String>> get fields => has((r) => r.fields, 'fields');
  Subject<List<http.MultipartFile>> get files => has((r) => r.files, 'files');
  Subject<int> get contentLength => has((r) => r.contentLength, 'contentLength');
}

extension HttpMultipartFileChecks on Subject<http.MultipartFile> {
  Subject<String> get field => has((f) => f.field, 'field');
  Subject<int> get length => has((f) => f.length, 'length');
  Subject<String?> get filename => has((f) => f.filename, 'filename');
  Subject<MediaType> get contentType => has((f) => f.contentType, 'contentType');
  Subject<bool> get isFinalized => has((f) => f.isFinalized, 'isFinalized');
}

extension MediaTypeChecks on Subject<MediaType> {
  Subject<String> get asString => has((x) => x.toString(), 'toString'); // TODO(checks): what's a good convention for this?
}
