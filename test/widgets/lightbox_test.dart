import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/lightbox.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import 'content_test.dart';

Future<void> setupToMessageActionSheet(WidgetTester tester, {
  required Message message,
  required Narrow narrow,
}) async {
  addTearDown(() {
    TestZulipBinding.instance.reset(); 
  });

  await TestZulipBinding.instance.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await TestZulipBinding.instance.globalStore.perAccount(eg.selfAccount.id);
  store.addUser(eg.user(userId: message.senderId));

  await tester.pumpWidget(
    MaterialApp(
        home: GlobalStoreWidget(
        child: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: LightboxPage(
          message: message,
          routeEntranceAnimation: const AlwaysStoppedAnimation<double>(1),
          src: "https://zulip.com/",
        )))));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('lightbox', () {
    setUp(() {
      final httpClient = _FakeHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
      ..statusCode = HttpStatus.ok
      ..content = kSolidBlueAvatar;
    });
    
    testWidgets('tries to render an image', (WidgetTester tester) async {
      await setupToMessageActionSheet(tester, message: eg.streamMessage(), narrow: StreamNarrow(eg.streamMessage().streamId));

      expect(find.byType(RealmContentNetworkImage), findsOneWidget);
      // unset the client here, otherwise the test will always fail
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('appbar is invisible at first', (WidgetTester tester) async {
      await setupToMessageActionSheet(tester, message: eg.streamMessage(), narrow: StreamNarrow(eg.streamMessage().streamId));

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      expect(tester.getSize(appBarFinder).height, 0);

      // unset the client here, otherwise the test will always fail
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('appbar is visible after a time', (WidgetTester tester) async {
      await setupToMessageActionSheet(tester, message: eg.streamMessage(), narrow: StreamNarrow(eg.streamMessage().streamId));

      expect(find.byType(AppBar), findsOneWidget);
      await tester.tap(find.byType(RealmContentNetworkImage));

      await tester.pumpAndSettle(const Duration(milliseconds: 3000));
      expect(tester.getSize(find.byType(AppBar)).height, greaterThan(20));

      // unset the client here, otherwise the test will always fail
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('appbar hides again after a time', (WidgetTester tester) async {
      await setupToMessageActionSheet(tester, message: eg.streamMessage(), narrow: StreamNarrow(eg.streamMessage().streamId));

      expect(find.byType(AppBar), findsOneWidget);
      await tester.tap(find.byType(RealmContentNetworkImage));
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));

      await tester.tap(find.byType(RealmContentNetworkImage));
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));
      
      expect(tester.getSize(find.byType(AppBar)).height, 0);

      // unset the client here, otherwise the test will always fail
      debugNetworkImageHttpClientProvider = null;
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
