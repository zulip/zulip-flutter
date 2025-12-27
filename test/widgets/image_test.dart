import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_images.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('RealmContentNetworkImage', () {
    final authHeaders = authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey);

    Future<Map<String, List<String>>> actualHeaders(WidgetTester tester, Uri src) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      final httpClient = prepareBoringImageHttpClient();

      await tester.pumpWidget(GlobalStoreWidget(
        child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: RealmContentNetworkImage(src))));
      await tester.pump();
      await tester.pump();

      return httpClient.request.headers.values;
    }

    testWidgets('includes auth header if `src` on-realm', (tester) async {
      check(await actualHeaders(tester, Uri.parse('https://chat.example/image.png')))
        .deepEquals({
          'Authorization': [authHeaders['Authorization']!],
          'User-Agent': [userAgentHeader()['User-Agent']!],
        });
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('excludes auth header if `src` off-realm', (tester) async {
      check(await actualHeaders(tester, Uri.parse('https://other.example/image.png')))
        .deepEquals({'User-Agent': [userAgentHeader()['User-Agent']!]});
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (tester) async {
      await tester.pumpWidget(
        RealmContentNetworkImage(Uri.parse('https://zulip.invalid/path/to/image.png'), filterQuality: FilterQuality.medium));
      check(tester.takeException()).isA<AssertionError>();
    });
  });
}
