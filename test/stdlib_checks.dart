/// `package:checks`-related extensions for the Dart standard library.
///
/// Use this file for types in the Dart SDK, as well as in other
/// packages published by the Dart team that function as
/// part of the Dart standard library.

import 'package:checks/checks.dart';

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
