import 'package:checks/checks.dart';
import 'package:zulip/api/exception.dart';

extension ApiRequestExceptionChecks on Subject<ApiRequestException> {
  Subject<String> get routeName => has((e) => e.routeName, 'routeName');
  Subject<String> get message => has((e) => e.message, 'message');
  Subject<String> get asString => has((u) => u.toString(), 'toString'); // TODO(checks): what's a good convention for this?
}

extension ZulipApiExceptionChecks on Subject<ZulipApiException> {
  Subject<String> get code => has((e) => e.code, 'code');
  Subject<int> get httpStatus => has((e) => e.httpStatus, 'httpStatus');
  Subject<Map<String, dynamic>> get data => has((e) => e.data, 'data');
}

extension NetworkExceptionChecks on Subject<NetworkException> {
  Subject<Object> get cause => has((e) => e.cause, 'cause');
}

extension ServerExceptionChecks on Subject<ServerException> {
  Subject<int> get httpStatus => has((e) => e.httpStatus, 'httpStatus');
  Subject<Map<String, dynamic>?> get data => has((e) => e.data, 'data');
}

extension Server5xxExceptionChecks on Subject<Server5xxException> {
  // no properties not on ServerException
}

extension MalformedServerResponseExceptionChecks on Subject<MalformedServerResponseException> {
  Subject<Object?> get causeException => has((e) => e.causeException, 'causeException');
}
