import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';

void main() {
  TestDataBinding.ensureInitialized();

  group('RealmContentNetworkImage', () {
    final authHeaders = authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey);

    Future<String?> actualAuthHeader(WidgetTester tester, String src) async {
      final globalStore = TestDataBinding.instance.globalStore;
      addTearDown(TestDataBinding.instance.reset);
      await globalStore.add(eg.selfAccount, eg.initialSnapshot());

      final httpClient = _FakeHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.ok
        ..content = kSolidBlueAvatar;

      await tester.pumpWidget(GlobalStoreWidget(
        child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: RealmContentNetworkImage(src))));
      await tester.pump();
      await tester.pump();

      final headers = httpClient.request.headers.values;
      check(authHeaders.keys).deepEquals(['Authorization']);
      return headers['Authorization']?.single;
    }

    testWidgets('includes auth header if `src` on-realm', (tester) async {
      check(await actualAuthHeader(tester, 'https://chat.example/image.png'))
        .isNotNull().equals(authHeaders['Authorization']!);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('excludes auth header if `src` off-realm', (tester) async {
      check(await actualAuthHeader(tester, 'https://other.example/image.png'))
        .isNull();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (WidgetTester tester) async {
      await tester.pumpWidget(
        const RealmContentNetworkImage('https://zulip.invalid/path/to/image.png', filterQuality: FilterQuality.medium));
      check(tester.takeException()).isA<AssertionError>();
    });
  });
}

class _FakeHttpClient extends Fake implements HttpClient {
  final _FakeHttpClientRequest request = _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => request;
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final _FakeHttpClientResponse response = _FakeHttpClientResponse();

  @override
  final _FakeHttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => response;
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> values = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (values[name] ??= []).add(value.toString());
  }
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int statusCode = HttpStatus.ok;

  late List<int> content;

  @override
  int get contentLength => content.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(content).listen(
      onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }
}

/// A 100x100 PNG image of solid Zulip blue, [kZulipBrandColor].
// Made from the following SVG:
//   <svg xmlns="http://www.w3.org/2000/svg" width="1" height="1" viewBox="0 0 1 1">
//     <rect style="fill:#6492fe;fill-opacity:1" width="1" height="1" x="0" y="0" />
//   </svg>
// with `inkscape tmp.svg -w 100 --export-png=tmp1.png`,
// `zopflipng tmp1.png tmp.png`,
// and `xxd -i tmp.png`.
const List<int> kSolidBlueAvatar = [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64,
  0x01, 0x03, 0x00, 0x00, 0x00, 0x4a, 0x2c, 0x07, 0x17, 0x00, 0x00, 0x00,
  0x03, 0x50, 0x4c, 0x54, 0x45, 0x64, 0x92, 0xfe, 0xf1, 0xd6, 0x69, 0xa5,
  0x00, 0x00, 0x00, 0x13, 0x49, 0x44, 0x41, 0x54, 0x78, 0x01, 0x63, 0xa0,
  0x2b, 0x18, 0x05, 0xa3, 0x60, 0x14, 0x8c, 0x82, 0x51, 0x00, 0x00, 0x05,
  0x78, 0x00, 0x01, 0x1e, 0xcd, 0x28, 0xcd, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
];
