import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('Heading', () {
    Future<void> prepareContent(WidgetTester tester, String html) async {
      await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes: parseContent(html).nodes)));
    }

    testWidgets('plain h6', (tester) async {
      await prepareContent(tester,
        // "###### six"
        '<h6>six</h6>');
      tester.widget(find.text('six'));
    });

    testWidgets('smoke test for h1, h2, h3, h4, h5', (tester) async {
      await prepareContent(tester,
        // "# one\n## two\n### three\n#### four\n##### five"
        '<h1>one</h1>\n<h2>two</h2>\n<h3>three</h3>\n<h4>four</h4>\n<h5>five</h5>');
      check(find.byType(Heading).evaluate()).length.equals(5);
    });
  });

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

  testWidgets('MathBlock', (tester) async {
    // "```math\n\\lambda\n```"
    await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes: parseContent(
      '<p><span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span></p>',
    ).nodes)));
    tester.widget(find.text(r'\lambda'));
  });

  Future<void> tapText(WidgetTester tester, Finder textFinder) async {
    final height = tester.getSize(textFinder).height;
    final target = tester.getTopLeft(textFinder)
      .translate(height/4, height/2); // aim for middle of first letter
    await tester.tapAt(target);
  }

  group('LinkNode interactions', () {
    // The Flutter test font uses square glyphs, so width equals height:
    //   https://github.com/flutter/flutter/wiki/Flutter-Test-Fonts
    const fontSize = 14.0;

    Future<void> prepareContent(WidgetTester tester, String html) async {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(testBinding.reset);

      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: BlockContentList(
            nodes: parseContent(html).nodes)))));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('can tap a link to open URL', (tester) async {
      await prepareContent(tester,
        '<p><a href="https://example/">hello</a></p>');

      await tapText(tester, find.text('hello'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://example/'), mode: LaunchMode.platformDefault));
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
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));

      await tester.tapAt(base.translate(9*fontSize, 0)); // "foo bar bXz"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://b/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('link nested in other spans', (tester) async {
      await prepareContent(tester,
        '<p><strong><em><a href="https://a/">word</a></em></strong></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('link containing other spans', (tester) async {
      await prepareContent(tester,
        '<p><a href="https://a/">two <strong><em><code>words</code></em></strong></a></p>');
      final base = tester.getTopLeft(find.text('two words'))
        .translate(fontSize/2, fontSize/2); // middle of first letter

      await tester.tapAt(base.translate(1*fontSize, 0)); // "tXo words"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));

      await tester.tapAt(base.translate(6*fontSize, 0)); // "two woXds"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('relative links are resolved', (tester) async {
      await prepareContent(tester,
        '<p><a href="/a/b?c#d">word</a></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('${eg.realmUrl}a/b?c#d'), mode: LaunchMode.platformDefault));
    });

    testWidgets('link inside HeadingNode', (tester) async {
      await prepareContent(tester,
        '<h6><a href="https://a/">word</a></h6>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('error dialog if invalid link', (tester) async {
      await prepareContent(tester,
        '<p><a href="file:///etc/bad">word</a></p>');
      testBinding.launchUrlResult = false;
      await tapText(tester, find.text('word'));
      await tester.pump();
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('file:///etc/bad'), mode: LaunchMode.platformDefault));
      checkErrorDialog(tester, expectedTitle: 'Unable to open link');
    });
  });

  group('LinkNode on internal links', () {
    Future<List<Route<dynamic>>> prepareContent(WidgetTester tester, {
      required String html,
    }) async {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
        streams: [eg.stream(streamId: 1, name: 'check')],
      ));
      addTearDown(testBinding.reset);
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        navigatorObservers: [testNavObserver],
        home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: BlockContentList(nodes: parseContent(html).nodes)))));
      await tester.pump(); // global store
      await tester.pump(); // per-account store
      // `tester.pumpWidget` introduces an initial route, remove so
      // consumers only have newly pushed routes.
      assert(pushedRoutes.length == 1);
      pushedRoutes.removeLast();
      return pushedRoutes;
    }

    testWidgets('valid internal links are navigated to within app', (tester) async {
      final pushedRoutes = await prepareContent(tester,
        html: '<p><a href="/#narrow/stream/1-check">stream</a></p>');

      await tapText(tester, find.text('stream'));
      check(testBinding.takeLaunchUrlCalls()).isEmpty();
      check(pushedRoutes).single.isA<WidgetRoute>()
        .page.isA<MessageListPage>().narrow.equals(const StreamNarrow(1));
    });

    testWidgets('invalid internal links are opened in browser', (tester) async {
      // Link is invalid due to `topic` operator missing an operand.
      final pushedRoutes = await prepareContent(tester,
        html: '<p><a href="/#narrow/stream/1-check/topic">invalid</a></p>');

      await tapText(tester, find.text('invalid'));
      final expectedUrl = eg.realmUrl.resolve('/#narrow/stream/1-check/topic');
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: expectedUrl, mode: LaunchMode.platformDefault));
      check(pushedRoutes).isEmpty();
    });
  });

  group('UnicodeEmoji', () {
    Future<void> prepareContent(WidgetTester tester, String html) async {
      await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes: parseContent(html).nodes)));
    }

    testWidgets('encoded emoji span', (tester) async {
      await prepareContent(tester,
        // ":thumbs_up:"
        '<p><span aria-label="thumbs up" class="emoji emoji-1f44d" role="img" title="thumbs up">:thumbs_up:</span></p>');
      tester.widget(find.text('\u{1f44d}')); // "👍"
    });

    testWidgets('encoded emoji span, with multiple codepoints', (tester) async {
      await prepareContent(tester,
        // ":transgender_flag:"
        '<p><span aria-label="transgender flag" class="emoji emoji-1f3f3-fe0f-200d-26a7-fe0f" role="img" title="transgender flag">:transgender_flag:</span></p>');
      tester.widget(find.text('\u{1f3f3}\u{fe0f}\u{200d}\u{26a7}\u{fe0f}')); // "🏳️‍⚧️"
    });

    testWidgets('non encoded emoji', (tester) async {
      await prepareContent(tester,
        // "\u{1fabf}"
        '<p>\u{1fabf}</p>');
      tester.widget(find.text('\u{1fabf}')); // "🪿"
    });
  });

  testWidgets('MathInlineNode', (tester) async {
    // "$$ \\lambda $$"
    await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes: parseContent(
      '<p><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></p>',
    ).nodes)));
    tester.widget(find.text(r'\lambda'));
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
