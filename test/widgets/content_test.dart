import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/text.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/content_test.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'dialog_checks.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';

void main() {
  // For testing a new content feature:
  //
  //  * Start by writing parsing tests using [ContentExample].
  //    Then use [testContentSmoke] here to smoke-test the widgets.
  //
  //  * If the widgets have any interactive behavior, test that here too.
  //    Those tests might not use [ContentExample], because they're often
  //    clearest if the HTML text is visible directly in the test source code
  //    to compare with the other details of the test.
  //    For examples, see the "LinkNode interactions" group below.

  TestZulipBinding.ensureInitialized();

  Future<void> prepareContentBare(WidgetTester tester, String html) async {
    await tester.pumpWidget(Builder(
      builder: (context) {
        return MaterialApp(
          theme: ThemeData(typography: zulipTypography(context)),
          localizationsDelegates: ZulipLocalizations.localizationsDelegates,
          supportedLocales: ZulipLocalizations.supportedLocales,
          home: Scaffold(body: BlockContentList(nodes: parseContent(html).nodes)),
        );
      }
    ));
  }

  /// Test that the given content example renders without throwing an exception.
  ///
  /// This requires [ContentExample.expectedText] to be non-null in order to
  /// check that the content has actually rendered.  For examples where there's
  /// no suitable value for [ContentExample.expectedText], use [prepareContentBare]
  /// and write an appropriate content-has-rendered check directly.
  void testContentSmoke(ContentExample example) {
    testWidgets('smoke: ${example.description}', (tester) async {
      await prepareContentBare(tester, example.html);
      assert(example.expectedText != null,
        'testContentExample requires expectedText');
      tester.widget(find.text(example.expectedText!));
    });
  }

  group('ThematicBreak', () {
    testWidgets('smoke ThematicBreak', (tester) async {
      await prepareContentBare(tester, ContentExample.thematicBreak.html);
      tester.widget(find.byType(ThematicBreak));
    });
  });

  group('Heading', () {
    testWidgets('plain h6', (tester) async {
      await prepareContentBare(tester,
        // "###### six"
        '<h6>six</h6>');
      tester.widget(find.text('six'));
    });

    testWidgets('smoke test for h1, h2, h3, h4, h5', (tester) async {
      await prepareContentBare(tester,
        // "# one\n## two\n### three\n#### four\n##### five"
        '<h1>one</h1>\n<h2>two</h2>\n<h3>three</h3>\n<h4>four</h4>\n<h5>five</h5>');
      check(find.byType(Heading).evaluate()).length.equals(5);
    });
  });

  group('Spoiler', () {
    testContentSmoke(ContentExample.spoilerDefaultHeader);
    testContentSmoke(ContentExample.spoilerPlainCustomHeader);
    testContentSmoke(ContentExample.spoilerRichHeaderAndContent);

    group('interactions: spoiler with tappable content (an image) in the header', () {
      Future<List<Route<dynamic>>> prepareContent(WidgetTester tester, String html) async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        prepareBoringImageHttpClient();

        final pushedRoutes = <Route<dynamic>>[];
        final testNavObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

        await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
          localizationsDelegates: ZulipLocalizations.localizationsDelegates,
          supportedLocales: ZulipLocalizations.supportedLocales,
          navigatorObservers: [testNavObserver],
          home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
            child: MessageContent(
              message: eg.streamMessage(content: html),
              content: parseContent(html))))));
        await tester.pump(); // global store
        await tester.pump(); // per-account store
        debugNetworkImageHttpClientProvider = null;

        // `tester.pumpWidget` introduces an initial route;
        // remove it so consumers only have newly pushed routes.
        assert(pushedRoutes.length == 1);
        pushedRoutes.removeLast();
        return pushedRoutes;
      }

      void checkIsExpanded(WidgetTester tester,
        bool expected, {
        Finder? contentFinder,
      }) {
        final sizeTransition = tester.widget<SizeTransition>(find.ancestor(
          of: contentFinder ?? find.text('hello world'),
          matching: find.byType(SizeTransition),
        ));
        check(sizeTransition.sizeFactor)
          ..value.equals(expected ? 1 : 0)
          ..status.equals(expected ? AnimationStatus.completed : AnimationStatus.dismissed);
      }

      const example = ContentExample.spoilerHeaderHasImage;

      testWidgets('tap image', (tester) async {
        final pushedRoutes = await prepareContent(tester, example.html);

        await tester.tap(find.byType(RealmContentNetworkImage));
        check(pushedRoutes).single.isA<AccountPageRouteBuilder>()
          .fullscreenDialog.isTrue(); // recognize the lightbox
      });

      testWidgets('tap header on expand/collapse icon', (tester) async {
        final pushedRoutes = await prepareContent(tester, example.html);
        checkIsExpanded(tester, false);

        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();
        check(pushedRoutes).isEmpty(); // no lightbox
        checkIsExpanded(tester, true);

        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();
        check(pushedRoutes).isEmpty(); // no lightbox
        checkIsExpanded(tester, false);
      });

      testWidgets('tap header away from expand/collapse icon (and image)', (tester) async {
        final pushedRoutes = await prepareContent(tester, example.html);
        checkIsExpanded(tester, false);

        await tester.tapAt(
          tester.getTopRight(find.byType(RealmContentNetworkImage)) + const Offset(10, 0));
        await tester.pumpAndSettle();
        check(pushedRoutes).isEmpty(); // no lightbox
        checkIsExpanded(tester, true);

        await tester.tapAt(
          tester.getTopRight(find.byType(RealmContentNetworkImage)) + const Offset(10, 0));
        await tester.pumpAndSettle();
        check(pushedRoutes).isEmpty(); // no lightbox
        checkIsExpanded(tester, false);
      });
    });
  });

  testContentSmoke(ContentExample.quotation);

  group('MessageImage, MessageImageList', () {
    Future<void> prepareContent(WidgetTester tester, String html) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      prepareBoringImageHttpClient();

      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: MessageContent(
            message: eg.streamMessage(content: html),
            content: parseContent(html))))));
      await tester.pump(); // global store
      await tester.pump(); // per-account store
      debugNetworkImageHttpClientProvider = null;
    }

    testWidgets('single image', (tester) async {
      const example = ContentExample.imageSingle;
      await prepareContent(tester, example.html);
      final expectedImages = (example.expectedNodes[0] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('image with invalid src URL', (tester) async {
      const example = ContentExample.imageInvalidUrl;
      await prepareContent(tester, example.html);
      // The image indeed has an invalid URL.
      final expectedImages = (example.expectedNodes[0] as ImageNodeList).images;
      check(() => Uri.parse(expectedImages.single.srcUrl)).throws();
      check(tryResolveUrl(eg.realmUrl, expectedImages.single.srcUrl)).isNull();
      // The MessageImage has shown up, but it doesn't attempt a RealmContentNetworkImage.
      check(tester.widgetList(find.byType(MessageImage))).isNotEmpty();
      check(tester.widgetList(find.byType(RealmContentNetworkImage))).isEmpty();
    });

    testWidgets('multiple images', (tester) async {
      const example = ContentExample.imageCluster;
      await prepareContent(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('content after image cluster', (tester) async {
      const example = ContentExample.imageClusterThenContent;
      await prepareContent(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('multiple clusters of images', (tester) async {
      const example = ContentExample.imageMultipleClusters;
      await prepareContent(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images
        + (example.expectedNodes[4] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('image as immediate child in implicit paragraph', (tester) async {
      const example = ContentExample.imageInImplicitParagraph;
      await prepareContent(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][0] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('image cluster in implicit paragraph', (tester) async {
      const example = ContentExample.imageClusterInImplicitParagraph;
      await prepareContent(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });
  });

  group("CodeBlock", () {
    testContentSmoke(ContentExample.codeBlockPlain);
    testContentSmoke(ContentExample.codeBlockHighlightedShort);
    testContentSmoke(ContentExample.codeBlockHighlightedMultiline);
  });

  testContentSmoke(ContentExample.mathBlock);

  testContentSmoke(ContentExample.strong);

  testContentSmoke(ContentExample.emphasis);

  group('inline code', () {
    testContentSmoke(ContentExample.inlineCode);
  });

  group('UserMention', () {
    testContentSmoke(ContentExample.userMentionPlain);
    testContentSmoke(ContentExample.userMentionSilent);
    testContentSmoke(ContentExample.groupMentionPlain);
    testContentSmoke(ContentExample.groupMentionSilent);
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
    // We use this to simulate taps on specific glyphs.

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

      final expectedLaunchMode = defaultTargetPlatform == TargetPlatform.iOS ?
        LaunchMode.externalApplication : LaunchMode.platformDefault;
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://example/'), mode: expectedLaunchMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('multiple links in paragraph', (tester) async {
      final fontSize = Paragraph.textStyle.fontSize!;

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
      final fontSize = Paragraph.textStyle.fontSize!;

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
    testContentSmoke(ContentExample.emojiUnicode);
    testContentSmoke(ContentExample.emojiUnicodeMultiCodepoint);
    testContentSmoke(ContentExample.emojiUnicodeLiteral);
  });

  group('inline math', () {
    testContentSmoke(ContentExample.mathInline);
  });

  group('GlobalTime', () {
    // "<time:2024-01-30T17:33:00Z>"
    const timeSpanHtml = '<time datetime="2024-01-30T17:33:00Z">2024-01-30T17:33:00Z</time>';
    // The time is shown in the user's timezone and the result will depend on
    // the timezone of the environment running these tests. Accept here a wide
    // range of times. See comments in "show dates" test in
    // `test/widgets/message_list_test.dart`.
    final renderedTextRegexp = RegExp(r'^(Tue, Jan 30|Wed, Jan 31), 2024, \d+:\d\d [AP]M$');

    testWidgets('smoke', (tester) async {
      await tester.pumpWidget(MaterialApp(home: BlockContentList(nodes:
        parseContent('<p>$timeSpanHtml</p>').nodes)));
      tester.widget(find.textContaining(renderedTextRegexp));
    });
  });

  group('MessageImageEmoji', () {
    Future<void> prepareContent(WidgetTester tester, String html) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      prepareBoringImageHttpClient();

      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        home: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: BlockContentList(nodes: parseContent(html).nodes)))));
      await tester.pump(); // global store
      await tester.pump(); // per-account store
    }

    testWidgets('smoke: custom emoji', (tester) async {
      await prepareContent(tester, ContentExample.emojiCustom.html);
      tester.widget(find.byType(MessageImageEmoji));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: custom emoji with invalid URL', (tester) async {
      await prepareContent(tester, ContentExample.emojiCustomInvalidUrl.html);
      final url = tester.widget<MessageImageEmoji>(find.byType(MessageImageEmoji)).node.src;
      check(() => Uri.parse(url)).throws();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: Zulip extra emoji', (tester) async {
      await prepareContent(tester, ContentExample.emojiZulipExtra.html);
      tester.widget(find.byType(MessageImageEmoji));
      debugNetworkImageHttpClientProvider = null;
    });
  });

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

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (WidgetTester tester) async {
      await tester.pumpWidget(
        RealmContentNetworkImage(Uri.parse('https://zulip.invalid/path/to/image.png'), filterQuality: FilterQuality.medium));
      check(tester.takeException()).isA<AssertionError>();
    });
  });

  group('AvatarImage', () {
    late PerAccountStore store;

    Future<Uri?> actualUrl(WidgetTester tester, String avatarUrl, [double? size]) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: avatarUrl);
      store.addUser(user);

      prepareBoringImageHttpClient();
      await tester.pumpWidget(GlobalStoreWidget(
        child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: size ?? 30))));
      await tester.pump();
      await tester.pump();
      tester.widget(find.byType(AvatarImage));
      final widgets = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      return widgets.firstOrNull?.src;
    }

    testWidgets('smoke with absolute URL', (tester) async {
      const avatarUrl = 'https://example/avatar.png';
      check(await actualUrl(tester, avatarUrl)).isNotNull()
        .asString.equals(avatarUrl);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke with relative URL', (tester) async {
      const avatarUrl = '/avatar.png';
      check(await actualUrl(tester, avatarUrl))
        .equals(store.tryResolveUrl(avatarUrl)!);
      debugNetworkImageHttpClientProvider = null;
    });

   testWidgets('absolute URL, larger size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);

      const avatarUrl = 'https://example/avatar.png';
      check(await actualUrl(tester, avatarUrl, 50)).isNotNull()
        .asString.equals(avatarUrl.replaceAll('.png', '-medium.png'));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('relative URL, larger size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);

      const avatarUrl = '/avatar.png';
      check(await actualUrl(tester, avatarUrl, 50))
        .equals(store.tryResolveUrl('/avatar-medium.png')!);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke with invalid URL', (tester) async {
      const avatarUrl = '::not a URL::';
      check(await actualUrl(tester, avatarUrl)).isNull();
      debugNetworkImageHttpClientProvider = null;
    });
  });
}
