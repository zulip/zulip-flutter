import 'package:checks/checks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
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
import 'test_app.dart';

/// Simulate a nested "inner" span's style by merging all ancestor-span
/// styles, starting from the root.
///
/// [isInnerSpan] must return true for some descendant of [outerSpan].
///
/// This isn't how the style actually gets applied in the code under test
/// (because that happens inside the engine, in SkParagraph),
/// but it should hopefully simulate it closely enough.
TextStyle? mergeSpanStylesOuterToInner(
  InlineSpan outerSpan,
  bool Function(InlineSpan) isInnerSpan,
) {
  final styles = <TextStyle?>[];
  bool recurse(InlineSpan span) {
    if (isInnerSpan(span)) {
      styles.add(span.style);
      return false;
    }
    final notInSubtree = span.visitDirectChildren(recurse);
    if (!notInSubtree) {
      styles.add(span.style);
    }
    return notInSubtree;
  }
  final recurseResult = recurse(outerSpan);
  check(recurseResult).isFalse(); // check inner span was actually found

  return styles.reversed.reduce((value, element) => switch ((value, element)) {
    (TextStyle(), TextStyle()) => value!.merge(element!),
    (TextStyle(), null)        => value,
    (null, TextStyle())        => element,
    (null, null)               => null,
  });
}

/// The "merged style" ([mergeSpanStylesOuterToInner]) of a nested span.
TextStyle? mergedStyleOfSubstring(InlineSpan rootSpan, Pattern substringPattern) {
  return mergeSpanStylesOuterToInner(rootSpan,
    (span) {
      if (span is! TextSpan) return false;
      final text = span.text;
      if (text == null) return false;
      return switch (substringPattern) {
        String() => text == substringPattern,
        _ => substringPattern.allMatches(text)
          .any((match) => match.start == 0 && match.end == text.length),
      };
    });
}

/// A callback that finds some target subspan within the given span,
/// and reports the target's font size.
typedef TargetFontSizeFinder = double Function(InlineSpan rootSpan);

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

  Widget plainContent(String html) {
    return Builder(builder: (context) =>
      DefaultTextStyle(
        style: ContentTheme.of(context).textStylePlainParagraph,
        child: BlockContentList(nodes: parseContent(html).nodes)));
  }

  Widget messageContent(String html) {
    return MessageContent(message: eg.streamMessage(content: html),
       content: parseContent(html));
  }

  // TODO(#488) For content that we need to show outside a per-message context
  //   or a context without a full PerAccountStore, make sure to include tests
  //   that don't provide such context.
  Future<void> prepareContent(WidgetTester tester, Widget child, {
    List<NavigatorObserver> navObservers = const [],
    bool wrapWithPerAccountStoreWidget = false,
  }) async {
    if (wrapWithPerAccountStoreWidget) {
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    }

    addTearDown(testBinding.reset);

    prepareBoringImageHttpClient();

    await tester.pumpWidget(TestZulipApp(
      accountId: wrapWithPerAccountStoreWidget ? eg.selfAccount.id : null,
      navigatorObservers: navObservers,
      child: child));
    await tester.pump(); // global store
    if (wrapWithPerAccountStoreWidget) {
      await tester.pump();
    }

    debugNetworkImageHttpClientProvider = null;
  }

  /// Test that the given content example renders without throwing an exception.
  ///
  /// This requires [ContentExample.expectedText] to be non-null in order to
  /// check that the content has actually rendered.  For examples where there's
  /// no suitable value for [ContentExample.expectedText], use [prepareContent]
  /// and write an appropriate content-has-rendered check directly.
  void testContentSmoke(ContentExample example) {
    testWidgets('smoke: ${example.description}', (tester) async {
      await prepareContent(tester, plainContent(example.html));
      assert(example.expectedText != null,
        'testContentExample requires expectedText');
      tester.widget(find.text(example.expectedText!));
    });
  }

  /// Test the font weight found by [styleFinder] in the rendering of [content].
  ///
  /// The weight will be expected to be [expectedWght] when the system
  /// bold-text setting is not set, and to vary appropriately when it is set.
  ///
  /// [styleFinder] must return the [TextStyle] containing the "wght"
  /// (in [TextStyle.fontVariations]) and the [TextStyle.fontWeight]
  /// to be checked.
  Future<void> testFontWeight(String description, {
    required Widget content,
    required double expectedWght,
    required TextStyle Function(WidgetTester tester) styleFinder,
  }) async {
    for (final platformRequestsBold in [false, true]) {
      testWidgets(
        description + (platformRequestsBold ? ' (platform requests bold)' : ''),
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(boldText: platformRequestsBold);
          await prepareContent(tester, content);
          final style = styleFinder(tester);
          double effectiveExpectedWght = expectedWght;
          if (platformRequestsBold) {
            // bolderWght because that's what [weightVariableTextStyle] uses
            effectiveExpectedWght = bolderWght(expectedWght);
          }
          check(style)
            ..fontVariations.isNotNull()
              .any((it) => it..axis.equals('wght')..value.equals(effectiveExpectedWght))
            ..fontWeight.equals(clampVariableFontWeight(effectiveExpectedWght));
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });
    }
  }

  group('ThematicBreak', () {
    testWidgets('smoke ThematicBreak', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.thematicBreak.html));
      tester.widget(find.byType(ThematicBreak));
    });
  });

  group('Heading', () {
    testWidgets('plain h6', (tester) async {
      await prepareContent(tester,
        // "###### six"
        plainContent('<h6>six</h6>'));
      tester.widget(find.text('six'));
    });

    testWidgets('smoke test for h1, h2, h3, h4, h5', (tester) async {
      await prepareContent(tester,
        // "# one\n## two\n### three\n#### four\n##### five"
        plainContent('<h1>one</h1>\n<h2>two</h2>\n<h3>three</h3>\n<h4>four</h4>\n<h5>five</h5>'));
      check(find.byType(Heading).evaluate()).length.equals(5);
    });
  });

  group('Spoiler', () {
    testContentSmoke(ContentExample.spoilerDefaultHeader);
    testContentSmoke(ContentExample.spoilerPlainCustomHeader);
    testContentSmoke(ContentExample.spoilerRichHeaderAndContent);

    group('interactions: spoiler with tappable content (an image) in the header', () {
      Future<List<Route<dynamic>>> prepare(WidgetTester tester, String html) async {
        final pushedRoutes = <Route<dynamic>>[];
        final testNavObserver = TestNavigatorObserver()
          ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
        await prepareContent(tester,
          // Message is needed for the image's lightbox.
          messageContent(html),
          navObservers: [testNavObserver],
          // We try to resolve the image's URL on the self-account's realm.
          wrapWithPerAccountStoreWidget: true);
        // `tester.pumpWidget` in prepareContent introduces an initial route;
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
        final pushedRoutes = await prepare(tester, example.html);

        await tester.tap(find.byType(RealmContentNetworkImage));
        check(pushedRoutes).single.isA<AccountPageRouteBuilder>()
          .fullscreenDialog.isTrue(); // recognize the lightbox
      });

      testWidgets('tap header on expand/collapse icon', (tester) async {
        final pushedRoutes = await prepare(tester, example.html);
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
        final pushedRoutes = await prepare(tester, example.html);
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
    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester,
        // Message is needed for an image's lightbox.
        messageContent(html),
        // We try to resolve image URLs on the self-account's realm.
        // For URLs on the self-account's realm, we include the auth credential.
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('single image', (tester) async {
      const example = ContentExample.imageSingle;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[0] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => eg.realmUrl.resolve(n.thumbnailUrl!).toString()));
    });

    testWidgets('single image no thumbnail', (tester) async {
      const example = ContentExample.imageSingleNoThumbnail;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[0] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('single image loading placeholder', (tester) async {
      const example = ContentExample.imageSingleLoadingPlaceholder;
      await prepare(tester, example.html);
      await tester.ensureVisible(find.byType(CupertinoActivityIndicator));
    });

    testWidgets('image with invalid src URL', (tester) async {
      const example = ContentExample.imageInvalidUrl;
      await prepare(tester, example.html);
      // The image indeed has an invalid URL.
      final expectedImages = (example.expectedNodes[0] as ImageNodeList).images;
      check(() => Uri.parse(expectedImages.single.srcUrl)).throws<void>();
      check(tryResolveUrl(eg.realmUrl, expectedImages.single.srcUrl)).isNull();
      // The MessageImage has shown up, but it doesn't attempt a RealmContentNetworkImage.
      check(tester.widgetList(find.byType(MessageImage))).isNotEmpty();
      check(tester.widgetList(find.byType(RealmContentNetworkImage))).isEmpty();
    });

    testWidgets('multiple images', (tester) async {
      const example = ContentExample.imageCluster;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => eg.realmUrl.resolve(n.thumbnailUrl!).toString()));
    });

    testWidgets('multiple images no thumbnails', (tester) async {
      const example = ContentExample.imageClusterNoThumbnails;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('content after image cluster', (tester) async {
      const example = ContentExample.imageClusterThenContent;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('multiple clusters of images', (tester) async {
      const example = ContentExample.imageMultipleClusters;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImageNodeList).images
        + (example.expectedNodes[4] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('image as immediate child in implicit paragraph', (tester) async {
      const example = ContentExample.imageInImplicitParagraph;
      await prepare(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][0] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });

    testWidgets('image cluster in implicit paragraph', (tester) async {
      const example = ContentExample.imageClusterInImplicitParagraph;
      await prepare(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][1] as ImageNodeList).images;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src.toString()).toList())
        .deepEquals(expectedImages.map((n) => n.srcUrl));
    });
  });

  group("MessageInlineVideo", () {
    Future<List<Route<dynamic>>> prepare(WidgetTester tester, String html) async {
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);
      await prepareContent(tester,
        // Message is needed for a video's lightbox.
        messageContent(html),
        navObservers: [testNavObserver],
        // We try to resolve video URLs on the self-account's realm.
        // With #656, we'll show a preview image. We'll try to resolve this
        // image's URL on the self-account's realm. If it's on the
        // self-account's realm, we'll request it with the auth credential.
        // TODO(#656) in above comment, change "we will" to "we do"
        wrapWithPerAccountStoreWidget: true);
      // `tester.pumpWidget` in prepareContent introduces an initial route;
      // remove it so consumers only have newly pushed routes.
      assert(pushedRoutes.length == 1);
      pushedRoutes.removeLast();
      return pushedRoutes;
    }

    testWidgets('tapping on preview opens lightbox', (tester) async {
      const example = ContentExample.videoInline;
      final pushedRoutes = await prepare(tester, example.html);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      check(pushedRoutes).single.isA<AccountPageRouteBuilder>()
        .fullscreenDialog.isTrue(); // opened lightbox
    });
  });

  group("MessageEmbedVideo", () {
    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester,
        // Message is needed for a video's lightbox.
        messageContent(html),
        // We try to resolve a video preview URL on the self-account's realm.
        wrapWithPerAccountStoreWidget: true);
    }

    Future<void> checkEmbedVideo(WidgetTester tester, ContentExample example) async {
      await prepare(tester, example.html);

      final expectedTitle = (((example.expectedNodes[0] as ParagraphNode)
        .nodes.single as LinkNode).nodes.single as TextNode).text;
      await tester.ensureVisible(find.text(expectedTitle));

      final expectedVideo = example.expectedNodes[1] as EmbedVideoNode;
      final expectedResolvedUrl = eg.store()
        .tryResolveUrl(expectedVideo.previewImageSrcUrl)!;
      final image = tester.widget<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(image.src).equals(expectedResolvedUrl);

      final expectedLaunchUrl = expectedVideo.hrefUrl;
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse(expectedLaunchUrl), mode: LaunchMode.platformDefault));
    }

    testWidgets('video preview for youtube embed', (tester) async {
      const example = ContentExample.videoEmbedYoutube;
      await checkEmbedVideo(tester, example);
    });

    testWidgets('video preview for vimeo embed', (tester) async {
      const example = ContentExample.videoEmbedVimeo;
      await checkEmbedVideo(tester, example);
    });
  });

  group("CodeBlock", () {
    testContentSmoke(ContentExample.codeBlockPlain);
    testContentSmoke(ContentExample.codeBlockHighlightedShort);
    testContentSmoke(ContentExample.codeBlockHighlightedMultiline);

    testFontWeight('syntax highlighting: non-bold span',
      expectedWght: 400,
      content: plainContent(ContentExample.codeBlockHighlightedShort.html),
      styleFinder: (tester) {
        final root = tester.renderObject<RenderParagraph>(find.textContaining('class')).text;
        return mergedStyleOfSubstring(root, 'class')!;
      });

    testFontWeight('syntax highlighting: bold span',
      expectedWght: 700,
      content: plainContent(ContentExample.codeBlockHighlightedShort.html),
      styleFinder: (tester) {
        final root = tester.renderObject<RenderParagraph>(find.textContaining('A')).text;
        return mergedStyleOfSubstring(root, 'A')!;
      });
  });

  testContentSmoke(ContentExample.mathBlock);

  /// Make a [TargetFontSizeFinder] to pass to [checkFontSizeRatio],
  /// from a target [Pattern] (such as a string).
  TargetFontSizeFinder mkTargetFontSizeFinderFromPattern(Pattern targetPattern)
    => (InlineSpan rootSpan)
    => mergedStyleOfSubstring(rootSpan, targetPattern)!.fontSize!;

  /// Check certain inline spans' font size are in a constant ratio with
  /// the text around them.
  ///
  /// The given `targetHtml` should be a self-contained HTML fragment
  /// that parses as an [InlineContentNode].
  ///
  /// [targetFontSizeFinder] should find some text in the given [InlineSpan]
  /// and return its size. (Or something text-like, anyway, like the clock icon
  /// in [GlobalTime].)
  Future<void> checkFontSizeRatio(WidgetTester tester, {
    required String targetHtml,
    required TargetFontSizeFinder targetFontSizeFinder,
  }) async {
    await prepareContent(tester, plainContent(
      '<h1>header-plain $targetHtml</h1>\n'
      '<p>paragraph-plain $targetHtml</p>'));

    final headerRootSpan = tester.renderObject<RenderParagraph>(find.textContaining('header')).text;
    final headerPlainStyle = mergedStyleOfSubstring(headerRootSpan, 'header-plain ');
    final headerTargetFontSize = targetFontSizeFinder(headerRootSpan);

    final paragraphRootSpan = tester.renderObject<RenderParagraph>(find.textContaining('paragraph')).text;
    final paragraphPlainStyle = mergedStyleOfSubstring(paragraphRootSpan, 'paragraph-plain ');
    final paragraphTargetFontSize = targetFontSizeFinder(paragraphRootSpan);

    // Check that the font sizes even differ -- that e.g. the test hasn't grown
    // some bug where we merge the [TextStyle]s in the wrong order and so get
    // the same answer for every span.
    check(headerPlainStyle!.fontSize! / paragraphPlainStyle!.fontSize!)
      .isGreaterOrEqual(1.1);

    final ratioInHeader = headerTargetFontSize / headerPlainStyle.fontSize!;
    final ratioInParagraph = paragraphTargetFontSize / paragraphPlainStyle.fontSize!;

    // Empirically we might have e.g. 0.825 and 0.8250000000000001.
    check((ratioInHeader - ratioInParagraph).abs()).isLessThan(0.001);
  }

  group('strong (bold)', () {
    testContentSmoke(ContentExample.strong);

    TextStyle findWordBold(WidgetTester tester) {
      final root = tester.renderObject<RenderParagraph>(find.textContaining('bold')).text;
      return mergedStyleOfSubstring(root, 'bold')!;
    }

    testFontWeight('in plain paragraph',
      expectedWght: 600,
      // **bold**
      content: plainContent('<p><strong>bold</strong></p>'),
      styleFinder: findWordBold,
    );

    for (final level in HeadingLevel.values) {
      final name = level.name;
      assert(RegExp(r'^h[1-6]$').hasMatch(name));
      testFontWeight('in $name',
        expectedWght: 800,
        // # **bold**, ## **bold**, ### **bold**, etc.
        content: plainContent('<$name><strong>bold</strong></$name>'),
        styleFinder: findWordBold,
      );
    }

    testFontWeight('in different kind of span in h1',
      expectedWght: 800,
      // # ~~**bold**~~
      content: plainContent('<h1><del><strong>bold</strong></del></h1>'),
      styleFinder: findWordBold,
    );

    testFontWeight('in spoiler header',
      expectedWght: 900,
      // ```spoiler regular **bold**
      // content
      // ```
      content: plainContent(
        '<div class="spoiler-block"><div class="spoiler-header">\n'
          '<p>regular <strong>bold</strong></p>\n'
          '</div><div class="spoiler-content" aria-hidden="true">\n'
          '<p>content</p>\n'
          '</div></div>'
      ),
      styleFinder: findWordBold,
    );

    testFontWeight('in different kind of span in spoiler header',
      expectedWght: 900,
      // ```spoiler *italic **bold***
      // content
      // ```
      content: plainContent(
        '<div class="spoiler-block"><div class="spoiler-header">\n'
          '<p><em>italic <strong>bold</strong></em></p>\n'
          '</div><div class="spoiler-content" aria-hidden="true">\n'
          '<p>content</p>\n'
          '</div></div>'
      ),
      styleFinder: findWordBold,
    );
  });

  testContentSmoke(ContentExample.emphasis);

  group('inline code', () {
    testContentSmoke(ContentExample.inlineCode);

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      await checkFontSizeRatio(tester,
        targetHtml: '<code>code</code>',
        targetFontSizeFinder: mkTargetFontSizeFinderFromPattern('code'));
    });
  });

  group('UserMention', () {
    testContentSmoke(ContentExample.userMentionPlain);
    testContentSmoke(ContentExample.userMentionSilent);
    testContentSmoke(ContentExample.groupMentionPlain);
    testContentSmoke(ContentExample.groupMentionSilent);

    UserMention? findUserMentionInSpan(InlineSpan rootSpan) {
      UserMention? result;
      rootSpan.visitChildren((span) {
        if (span case (WidgetSpan(child: UserMention() && var widget))) {
          result = widget;
          return false;
        }
        return true;
      });
      return result;
    }

    TextStyle textStyleFromWidget(WidgetTester tester, UserMention widget, String mentionText) {
      final fullNameSpan = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byWidget(widget), matching: find.text(mentionText))
      ).text;
      return mergedStyleOfSubstring(fullNameSpan, mentionText)!;
    }

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      await checkFontSizeRatio(tester,
        targetHtml: '<span class="user-mention" data-user-id="13313">@Chris Bobbe</span>',
        targetFontSizeFinder: (rootSpan) {
          final widget = findUserMentionInSpan(rootSpan);
          final style = textStyleFromWidget(tester, widget!, '@Chris Bobbe');
          return style.fontSize!;
        });
    });

    testFontWeight('silent or non-self mention in plain paragraph',
      expectedWght: 400,
      // @_**Greg Price**
      content: plainContent(
        '<p><span class="user-mention silent" data-user-id="2187">Greg Price</span></p>'),
      styleFinder: (tester) {
        return textStyleFromWidget(tester,
          tester.widget(find.byType(UserMention)), 'Greg Price');
      });

    // TODO(#647):
    //  testFontWeight('non-silent self-user mention in plain paragraph',
    //    expectedWght: 600, // [etc.]

    testFontWeight('silent or non-self mention in bold context',
      expectedWght: 600,
      // # @_**Chris Bobbe**
      content: plainContent(
        '<h1><span class="user-mention silent" data-user-id="13313">Chris Bobbe</span></h1>'),
      styleFinder: (tester) {
        return textStyleFromWidget(tester,
          tester.widget(find.byType(UserMention)), 'Chris Bobbe');
      });

    // TODO(#647):
    //  testFontWeight('non-silent self-user mention in bold context',
    //    expectedWght: 800, // [etc.]
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

    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester, plainContent(html),
        // We try to resolve relative links on the self-account's realm.
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('can tap a link to open URL', (tester) async {
      await prepare(tester,
        '<p><a href="https://example/">hello</a></p>');

      await tapText(tester, find.text('hello'));

      final expectedLaunchMode = defaultTargetPlatform == TargetPlatform.iOS ?
        LaunchMode.externalApplication : LaunchMode.platformDefault;
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://example/'), mode: expectedLaunchMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('multiple links in paragraph', (tester) async {
      const fontSize = kBaseFontSize;

      await prepare(tester,
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
      await prepare(tester,
        '<p><strong><em><a href="https://a/">word</a></em></strong></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('link containing other spans', (tester) async {
      const fontSize = kBaseFontSize;

      await prepare(tester,
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
      await prepare(tester,
        '<p><a href="/a/b?c#d">word</a></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('${eg.realmUrl}a/b?c#d'), mode: LaunchMode.platformDefault));
    });

    testWidgets('link inside HeadingNode', (tester) async {
      await prepare(tester,
        '<h6><a href="https://a/">word</a></h6>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.platformDefault));
    });

    testWidgets('error dialog if invalid link', (tester) async {
      await prepare(tester,
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
    Future<List<Route<dynamic>>> prepare(WidgetTester tester, String html) async {
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await prepareContent(tester, plainContent(html),
        navObservers: [testNavObserver],
        // We try to resolve relative links on the self-account's realm.
        wrapWithPerAccountStoreWidget: true);

      // `tester.pumpWidget` in prepareContent introduces an initial route;
      // remove it so consumers only have newly pushed routes.
      assert(pushedRoutes.length == 1);
      pushedRoutes.removeLast();

      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addStream(eg.stream(name: 'stream'));
      return pushedRoutes;
    }

    testWidgets('valid internal links are navigated to within app', (tester) async {
      final pushedRoutes = await prepare(tester,
        '<p><a href="/#narrow/stream/1-check">stream</a></p>');

      await tapText(tester, find.text('stream'));
      check(testBinding.takeLaunchUrlCalls()).isEmpty();
      check(pushedRoutes).single.isA<WidgetRoute>()
        .page.isA<MessageListPage>().initNarrow.equals(const ChannelNarrow(1));
    });

    testWidgets('invalid internal links are opened in browser', (tester) async {
      // Link is invalid due to `topic` operator missing an operand.
      final pushedRoutes = await prepare(tester,
        '<p><a href="/#narrow/stream/1-check/topic">invalid</a></p>');

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

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      const html = '<span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span>';
      await checkFontSizeRatio(tester,
        targetHtml: html,
        targetFontSizeFinder: mkTargetFontSizeFinderFromPattern(r'\lambda'));
    });
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
      await prepareContent(tester, plainContent('<p>$timeSpanHtml</p>'));
      tester.widget(find.textContaining(renderedTextRegexp));
    });

    void testIconAndTextSameColor(String description, String html) {
      testWidgets('clock icon and text are the same color: $description', (tester) async {
        await prepareContent(tester, plainContent(html));

        final icon = tester.widget<Icon>(
          find.descendant(of: find.byType(GlobalTime),
            matching: find.byIcon(ZulipIcons.clock)));

        final textSpan = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.byType(GlobalTime),
            matching: find.textContaining(renderedTextRegexp)
        )).text;
        final textColor = mergedStyleOfSubstring(textSpan, renderedTextRegexp)!.color;
        check(textColor).isNotNull();

        check(icon).color.isNotNull().isSameColorAs(textColor!);
      });
    }

    testIconAndTextSameColor('common case', '<p>$timeSpanHtml</p>');
    testIconAndTextSameColor('inside link', '<p><a href="https://example/">$timeSpanHtml</a></p>');

    group('maintains font-size ratio with surrounding text', () {
      Future<void> doCheck(WidgetTester tester, double Function(GlobalTime widget) sizeFromWidget) async {
        await checkFontSizeRatio(tester,
          targetHtml: '<time datetime="2024-01-30T17:33:00Z">2024-01-30T17:33:00Z</time>',
          targetFontSizeFinder: (rootSpan) {
            late final double result;
            rootSpan.visitChildren((span) {
              if (span case WidgetSpan(child: GlobalTime() && var widget)) {
                result = sizeFromWidget(widget);
                return false;
              }
              return true;
            });
            return result;
          });
      }

      testWidgets('text is scaled', (tester) async {
        await doCheck(tester, (widget) {
          final textSpan = tester.renderObject<RenderParagraph>(
            find.descendant(of: find.byWidget(widget),
              matching: find.textContaining(renderedTextRegexp)
          )).text;
          return mergedStyleOfSubstring(textSpan, renderedTextRegexp)!.fontSize!;
        });
      });

      testWidgets('clock icon is scaled', (tester) async {
        await doCheck(tester, (widget) {
          final icon = tester.widget<Icon>(
            find.descendant(of: find.byWidget(widget),
              matching: find.byIcon(ZulipIcons.clock)));
          return icon.size!;
        });
      });
    });
  });

  group('MessageImageEmoji', () {
    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester, plainContent(html),
        // We try to resolve image-emoji URLs on the self-account's realm.
        // For URLs on the self-account's realm, we include the auth credential.
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('smoke: custom emoji', (tester) async {
      await prepare(tester, ContentExample.emojiCustom.html);
      tester.widget(find.byType(MessageImageEmoji));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: custom emoji with invalid URL', (tester) async {
      await prepare(tester, ContentExample.emojiCustomInvalidUrl.html);
      final url = tester.widget<MessageImageEmoji>(find.byType(MessageImageEmoji)).node.src;
      check(() => Uri.parse(url)).throws<void>();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: Zulip extra emoji', (tester) async {
      await prepare(tester, ContentExample.emojiZulipExtra.html);
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

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (tester) async {
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
      await store.addUser(user);

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
