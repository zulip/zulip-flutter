import '../core.dart';
import '../model/linkifier.dart';

Future<GetLinkifierResults> getLinkifiers(ApiConnection connection) {
  return connection.get('linkifier', GetLinkifierResults.fromJson, 'realm/linkifiers', null);
}