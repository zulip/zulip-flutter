import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_images.dart';
import 'dialog_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group("CodeBlock", () {
    Future<void> prepareContent(WidgetTester tester, String html) async {
      await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes: parseContent(html).nodes)));
    }

    testWidgets('without syntax highlighting', (WidgetTester tester) async {
      // "```\nverb\natim\n```"
      await prepareContent(tester,
        '<div class="codehilite"><pre><span></span><code>verb\natim\n</code></pre></div>');
      tester.widget(find.text('verb\natim'));
    });

    testWidgets('with syntax highlighting', (WidgetTester tester) async {
      // "```dart\nclass A {}\n```"
      await prepareContent(tester,
        '<div class="codehilite" data-code-language="Dart"><pre>'
          '<span></span><code><span class="kd">class</span><span class="w"> </span>'
          '<span class="nc">A</span><span class="w"> </span><span class="p">{}</span>'
          '\n</code></pre></div>');
      tester.widget(find.text('class A {}'));
    });

    testWidgets('multiline, with syntax highlighting', (WidgetTester tester) async {
      // '```rust\nfn main() {\n    print!("Hello ");\n\n    print!("world!\\n");\n}\n```'
      await prepareContent(tester,
        '<div class="codehilite" data-code-language="Rust"><pre>'
            '<span></span><code><span class="k">fn</span> <span class="nf">main</span>'
            '<span class="p">()</span><span class="w"> </span><span class="p">{</span>\n'
            '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
            '<span class="s">"Hello "</span><span class="p">);</span>\n\n'
            '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
            '<span class="s">"world!</span><span class="se">\\n</span><span class="s">"</span>'
            '<span class="p">);</span>\n<span class="p">}</span>\n'
            '</code></pre></div>');
      tester.widget(find.text('fn main() {\n    print!("Hello ");\n\n    print!("world!\\n");\n}'));
    });
  });

  group('LinkNode interactions', () {
    const expectedModeAndroid = LaunchMode.externalApplication;

    // The Flutter test font uses square glyphs, so width equals height:
    //   https://github.com/flutter/flutter/wiki/Flutter-Test-Fonts
    const fontSize = 48.0;

    Future<void> prepareContent(WidgetTester tester, String html) async {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(testBinding.reset);

      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: BlockContentList(
            nodes: parseContent(html).nodes)))));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('can tap a link to open URL', (tester) async {
      await prepareContent(tester,
        '<p><a href="https://example/">hello</a></p>');

      await tester.tap(find.text('hello'));
      final expectedMode = defaultTargetPlatform == TargetPlatform.android ?
        LaunchMode.externalApplication : LaunchMode.platformDefault;
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://example/'), mode: expectedMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('multiple links in paragraph', (tester) async {
      await prepareContent(tester,
        '<p><a href="https://a/">foo</a> bar <a href="https://b/">baz</a></p>');
      final base = tester.getTopLeft(find.text('foo bar baz'))
        .translate(fontSize/2, fontSize/2); // middle of first letter

      await tester.tapAt(base.translate(5*fontSize, 0)); // "foo bXr baz"
      check(testBinding.takeLaunchUrlCalls()).isEmpty();

      await tester.tapAt(base.translate(1*fontSize, 0)); // "fXo bar baz"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: expectedModeAndroid));

      await tester.tapAt(base.translate(9*fontSize, 0)); // "foo bar bXz"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://b/'), mode: expectedModeAndroid));
    });

    testWidgets('link nested in other spans', (tester) async {
      await prepareContent(tester,
        '<p><strong><em><a href="https://a/">word</a></em></strong></p>');
      await tester.tap(find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: expectedModeAndroid));
    });

    testWidgets('link containing other spans', (tester) async {
      await prepareContent(tester,
        '<p><a href="https://a/">two <strong><em><code>words</code></em></strong></a></p>');
      final base = tester.getTopLeft(find.text('two words'))
        .translate(fontSize/2, fontSize/2); // middle of first letter

      await tester.tapAt(base.translate(1*fontSize, 0)); // "tXo words"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: expectedModeAndroid));

      await tester.tapAt(base.translate(6*fontSize, 0)); // "two woXds"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: expectedModeAndroid));
    });

    testWidgets('relative links are resolved', (tester) async {
      await prepareContent(tester,
        '<p><a href="/a/b?c#d">word</a></p>');
      await tester.tap(find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('${eg.realmUrl}a/b?c#d'), mode: expectedModeAndroid));
    });

    testWidgets('link inside HeadingNode', (tester) async {
      await prepareContent(tester,
        '<h6><a href="https://a/">word</a></h6>');
      await tester.tap(find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: expectedModeAndroid));
    });

    testWidgets('error dialog if invalid link', (tester) async {
      await prepareContent(tester,
        '<p><a href="file:///etc/bad">word</a></p>');
      testBinding.launchUrlResult = false;
      await tester.tap(find.text('word'));
      await tester.pump();
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('file:///etc/bad'), mode: expectedModeAndroid));
      checkErrorDialog(tester, expectedTitle: 'Unable to open link');
    });
  });

  group('RealmContentNetworkImage', () {
    final authHeaders = authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey);

    Future<String?> actualAuthHeader(WidgetTester tester, Uri src) async {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(testBinding.reset);

      final httpClient = FakeImageHttpClient();
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
      check(await actualAuthHeader(tester, Uri.parse('https://chat.example/image.png')))
        .isNotNull().equals(authHeaders['Authorization']!);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('excludes auth header if `src` off-realm', (tester) async {
      check(await actualAuthHeader(tester, Uri.parse('https://other.example/image.png')))
        .isNull();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (WidgetTester tester) async {
      await tester.pumpWidget(
        RealmContentNetworkImage(Uri.parse('https://zulip.invalid/path/to/image.png'), filterQuality: FilterQuality.medium));
      check(tester.takeException()).isA<AssertionError>();
    });
  });
}
