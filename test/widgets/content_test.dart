import 'package:checks/checks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/katex.dart';
import 'package:zulip/widgets/lightbox.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/text.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/content_test.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'checks.dart';
import 'dialog_checks.dart';
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

/// The "merged style" ([mergeSpanStylesOuterToInner]) of a text span
/// whose whole text matches the given pattern, under the given root span.
///
/// See also [mergedStyleOf], which can be more convenient.
TextStyle? mergedStyleOfSubstring(InlineSpan rootSpan, Pattern spanPattern) {
  return mergeSpanStylesOuterToInner(rootSpan,
    (span) {
      if (span is! TextSpan) return false;
      final text = span.text;
      if (text == null) return false;
      return switch (spanPattern) {
        String() => text == spanPattern,
        _ => spanPattern.allMatches(text)
          .any((match) => match.start == 0 && match.end == text.length),
      };
    });
}

/// The "merged style" ([mergeSpanStylesOuterToInner]) of a text span
/// whose whole text matches the given pattern, somewhere in the tree.
///
/// This finds the relevant [Text] widget by a search for [spanPattern].
/// If [findAncestor] is non-null, the search will only consider descendants
/// of widgets matching [findAncestor].
TextStyle? mergedStyleOf(WidgetTester tester, Pattern spanPattern, {
  Finder? findAncestor,
}) {
  var findTextWidget = find.textContaining(spanPattern);
  if (findAncestor != null) {
    findTextWidget = find.descendant(of: findAncestor, matching: findTextWidget);
  }
  final rootSpan = tester.renderObject<RenderParagraph>(findTextWidget).text;
  return mergedStyleOfSubstring(rootSpan, spanPattern);
}

/// A callback that finds some target subspan within the given span,
/// and reports the target's font size.
typedef TargetFontSizeFinder = double Function(InlineSpan rootSpan);

Widget plainContent(String html) {
  return Builder(builder: (context) =>
    DefaultTextStyle(
      style: ContentTheme.of(context).textStylePlainParagraph,
      child: BlockContentList(nodes: parseContent(html).nodes)));
}

// TODO(#488) For content that we need to show outside a per-message context
//   or a context without a full PerAccountStore, make sure to include tests
//   that don't provide such context.
Future<void> prepareContent(WidgetTester tester, Widget child, {
  List<NavigatorObserver> navObservers = const [],
  bool wrapWithPerAccountStoreWidget = false,
  InitialSnapshot? initialSnapshot,
}) async {
  if (wrapWithPerAccountStoreWidget) {
    initialSnapshot ??= eg.initialSnapshot();
    await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
  } else {
    assert(initialSnapshot == null);
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

  Widget messageContent(String html) {
    return MessageContent(message: eg.streamMessage(content: html),
       content: parseContent(html));
  }

  /// Test that the given content example renders without throwing an exception.
  ///
  /// This requires [ContentExample.expectedText] to be non-null in order to
  /// check that the content has actually rendered.  For examples where there's
  /// no suitable value for [ContentExample.expectedText], use [prepareContent]
  /// and write an appropriate content-has-rendered check directly.
  void testContentSmoke(ContentExample example, {bool wrapWithPerAccountStoreWidget = false}) {
    testWidgets('smoke: ${example.description}', (tester) async {
      await prepareContent(tester, plainContent(example.html),
        wrapWithPerAccountStoreWidget: wrapWithPerAccountStoreWidget);
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
  void testFontWeight(String description, {
    required Widget content,
    required double expectedWght,
    required TextStyle Function(WidgetTester tester) styleFinder,
    bool wrapWithPerAccountStoreWidget = false,
  }) {
    for (final platformRequestsBold in [false, true]) {
      testWidgets(
        description + (platformRequestsBold ? ' (platform requests bold)' : ''),
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(boldText: platformRequestsBold);
          await prepareContent(tester, content,
            wrapWithPerAccountStoreWidget: wrapWithPerAccountStoreWidget);
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

  group('ListNodeWidget', () {
    testWidgets('ordered list with custom start', (tester) async {
      await prepareContent(tester, plainContent('<ol start="3">\n<li>third</li>\n<li>fourth</li>\n</ol>'));
      expect(find.text('3. '), findsOneWidget);
      expect(find.text('4. '), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('fourth'), findsOneWidget);
    });

    testWidgets('list uses correct text baseline alignment', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.orderedListLargeStart.html));
      final table = tester.widget<Table>(find.byType(Table));
      check(table.defaultVerticalAlignment).equals(TableCellVerticalAlignment.baseline);
      check(table.textBaseline).equals(localizedTextBaseline(tester.element(find.byType(Table))));
    });

    testWidgets('ordered list markers have enough space to render completely', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.orderedListLargeStart.html));
      final marker = tester.renderObject(find.textContaining('9999.')) as RenderParagraph;
      // The marker has the height of just one line of text, not more.
      final textHeight = marker.size.height;
      final lineHeight = marker.text.style!.height! * marker.text.style!.fontSize!;
      check(textHeight).equals(lineHeight);
      // The marker's text didn't overflow to more lines
      // (and get cut off by a `maxLines: 1`).
      check(marker).didExceedMaxLines.isFalse();
    });

    testWidgets('ordered list markers are end-aligned', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.orderedListLargeStart.html));
      final marker9999 = tester.getRect(find.textContaining('9999.'));
      final marker10000 = tester.getRect(find.textContaining('10000.'));
      // The markers are aligned at their right edge...
      check(marker9999).right.equals(marker10000.right);
      // ... and not because they somehow happen to have the same width.
      check(marker9999).width.isLessThan(marker10000.width);
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

      const example = ContentExample.spoilerHeaderHasImagePreview;

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

  group('MessageImagePreview, MessageImagePreviewList', () {
    Future<void> prepare(WidgetTester tester, String html, {
      List<NavigatorObserver> navObservers = const [],
    }) async {
      await prepareContent(tester,
        navObservers: navObservers,
        // Message is needed for an image's lightbox.
        messageContent(html),
        // We try to resolve image URLs on the self-account's realm.
        // For URLs on the self-account's realm, we include the auth credential.
        wrapWithPerAccountStoreWidget: true);
    }

    group('single image; URLs handled correctly', () {
      /// Test that the right URLs are used for the right things.
      ///
      /// [rawHref] and [rawSrc] are redundant with [example],
      /// but included so they're directly visible at the callsites.
      /// (The test asserts that the example HTML contains 'href="$rawHref"'
      /// and 'src="$rawSrc"'.)
      ///
      /// Pass null for [expectUrlInPreview]
      /// if [expectLoadingIndicator] is true
      /// or if we don't expect a preview image because of an invalid src.
      ///
      /// Pass null for [expectThumbnailUrlInLightbox] and [expectUrlInLightbox]
      /// if we don't expect to be able to offer the lightbox.
      Future<void> doTest(WidgetTester tester, {
        required String rawHref,
        required String rawSrc,
        required bool expectLoadingIndicator,
        required Uri? expectUrlInPreview,
        required Uri? expectThumbnailUrlInLightbox,
        required Uri? expectUrlInLightbox,
        // TODO(#42) required Uri expectUrlForDownload,
        required ContentExample example,
      }) async {
        assert(!(expectUrlInPreview != null && expectLoadingIndicator));
        check(example.html)
          ..contains('href="$rawHref"')
          ..contains('src="$rawSrc"');

        final findImagePreview = find.byType(MessageImagePreview);
        final findLoadingIndicator = find.descendant(
          of: findImagePreview, matching: find.byType(CupertinoActivityIndicator));

        final findLightboxPage = find.byType(ImageLightboxPage);

        final transitionDurationObserver = TransitionDurationObserver();
        await prepare(tester, example.html,
          navObservers: [transitionDurationObserver]);
        final imageInPreview = tester.widgetList<RealmContentNetworkImage>(
          find.descendant(
            of: findImagePreview, matching: find.byType(RealmContentNetworkImage))
        ).singleOrNull;
        check(imageInPreview?.src).equals(expectUrlInPreview);
        check(findLoadingIndicator).findsExactly(expectLoadingIndicator ? 1 : 0);

        prepareBoringImageHttpClient();

        final lightboxHeroInPreview = tester.widgetList<LightboxHero>(
          find.descendant(of: findImagePreview, matching: find.byType(LightboxHero))
        ).singleOrNull;

        if (expectUrlInLightbox != null) {
          check(lightboxHeroInPreview).isNotNull().src.equals(expectUrlInLightbox);
        } else {
          check(lightboxHeroInPreview).isNull();
        }

        await tester.tap(findImagePreview);
        await transitionDurationObserver.pumpPastTransition(tester);

        final lightboxPage = tester.widgetList<ImageLightboxPage>(findLightboxPage)
          .singleOrNull;
        check(lightboxPage?.thumbnailUrl).equals(expectThumbnailUrlInLightbox);
        check(lightboxPage?.src).equals(expectUrlInLightbox);

        debugNetworkImageHttpClientProvider = null;
      }

      Uri url(String reference) => eg.realmUrl.resolve(reference);

      testWidgets('thumbnail', (tester) async {
        final rawHref = '/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg';
        final rawSrc = '/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: url('/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp'),
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingle);
      });

      testWidgets('thumbnail (pre-FL 276)', (tester) async {
        final rawHref = '/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg';
        final rawSrc = '/user_uploads/thumbnail/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg/840x560.webp';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: url(rawSrc),
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingleNoDimensions);
      });

      testWidgets('thumbnail, animated', (tester) async {
        final rawHref = '/user_uploads/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif';
        final rawSrc = '/user_uploads/thumbnail/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif/840x560-anim.webp';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: url(rawSrc),
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingleAnimated);
      });

      testWidgets('thumbnail, loading', (tester) async {
        final rawHref = '/user_uploads/path/to/example.png';
        final rawSrc = '/static/images/loading/loader-black.svg';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: true,
          expectUrlInPreview: null,
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingleLoadingPlaceholder);
      });

      testWidgets('thumbnail, loading (pre-FL 278)', (tester) async {
        final rawHref = '/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg';
        final rawSrc = '/static/images/loading/loader-black.svg';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: true,
          expectUrlInPreview: null,
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingleLoadingPlaceholderNoDimensions);
      });

      testWidgets('thumbnail, loading, spinner image itself is a thumbnail', (tester) async {
        final rawHref = '/user_uploads/path/to/spinner.png';
        final rawSrc = '/user_uploads/thumbnail/path/to/spinner.png/840x560.webp';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: true,
          expectUrlInPreview: null,
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: url(rawHref),
          example: ContentExample.imagePreviewSingleLoadingPlaceholderSpinnerIsThumbnail);
      });

      testWidgets('no thumbnail', (tester) async {
        final rawHref = 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3';
        final rawSrc = 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: Uri.parse(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: Uri.parse(rawHref),
          example: ContentExample.imagePreviewSingleNoThumbnail);
      });

      testWidgets('external; src starts with /external_content', (tester) async {
        final rawHref = 'https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg';
        final rawSrc = '/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: url(rawSrc),
          example: ContentExample.imagePreviewSingleExternal1);
      });

      testWidgets('external; src starts with https://uploads.zulipusercontent.net/', (tester) async {
        final rawHref = 'https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg';
        final rawSrc = 'https://uploads.zulipusercontent.net/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: Uri.parse(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: Uri.parse(rawSrc),
          example: ContentExample.imagePreviewSingleExternal2);
      });

      testWidgets('external; src starts with https://custom.camo-uri.example/', (tester) async {
        final rawHref = 'https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg';
        final rawSrc = 'https://custom.camo-uri.example/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: Uri.parse(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: Uri.parse(rawSrc),
          example: ContentExample.imagePreviewSingleExternal3);
      });

      testWidgets('invalid src', (tester) async {
        final rawHref = '/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg';
        final rawSrc = '::not a URL::';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: null,
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: null,
          example: ContentExample.imagePreviewInvalidSrc);
      });

      testWidgets('invalid href; external src', (tester) async {
        final rawHref = '::not a URL::';
        final rawSrc = '/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: url(rawSrc),
          example: ContentExample.imagePreviewInvalidHref1);
      });

      testWidgets('invalid href; thumbnail src', (tester) async {
        final rawHref = '::not a URL::';
        final rawSrc = '/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: url(rawSrc),
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: null,
          example: ContentExample.imagePreviewInvalidHref2);
      });

      testWidgets('invalid src and href', (tester) async {
        final rawHref = '::not a URL::';
        final rawSrc = '::not a URL::';
        await doTest(tester,
          rawHref: rawHref,
          rawSrc: rawSrc,
          expectLoadingIndicator: false,
          expectUrlInPreview: null,
          expectThumbnailUrlInLightbox: null,
          expectUrlInLightbox: null,
          example: ContentExample.imagePreviewInvalidSrcAndHref);
      });
    });

    Uri thumbnailSrc(ImageNodeSrc src) {
      final value = (src as ImageNodeSrcThumbnail).value;
      return eg.realmUrl.resolve(value.defaultFormatSrc.toString());
    }

    Uri otherSrc(ImageNodeSrc src) {
      final value = (src as ImageNodeSrcOther).value;
      return eg.realmUrl.resolve(value);
    }

    testWidgets('multiple images', (tester) async {
      final example = ContentExample.imagePreviewCluster;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => thumbnailSrc(n.src)));
    });

    testWidgets('multiple images no thumbnails', (tester) async {
      const example = ContentExample.imagePreviewClusterNoThumbnails;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => otherSrc(n.src)));
    });

    testWidgets('content after image cluster', (tester) async {
      const example = ContentExample.imagePreviewClusterThenContent;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => otherSrc(n.src)));
    });

    testWidgets('multiple clusters of images', (tester) async {
      const example = ContentExample.imagePreviewMultipleClusters;
      await prepare(tester, example.html);
      final expectedImages = (example.expectedNodes[1] as ImagePreviewNodeList).imagePreviews
        + (example.expectedNodes[4] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => otherSrc(n.src)));
    });

    testWidgets('image as immediate child in implicit paragraph', (tester) async {
      const example = ContentExample.imagePreviewInImplicitParagraph;
      await prepare(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][0] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => otherSrc(n.src)));
    });

    testWidgets('image cluster in implicit paragraph', (tester) async {
      const example = ContentExample.imagePreviewClusterInImplicitParagraph;
      await prepare(tester, example.html);
      final expectedImages = ((example.expectedNodes[0] as ListNode)
        .items[0][1] as ImagePreviewNodeList).imagePreviews;
      final images = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(images.map((i) => i.src).toList())
        .deepEquals(expectedImages.map((n) => otherSrc(n.src)));
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
        .single.equals((url: Uri.parse(expectedLaunchUrl), mode: LaunchMode.inAppBrowserView));
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
    testContentSmoke(ContentExample.codeBlockSpansWithMultipleClasses);

    testFontWeight('syntax highlighting: non-bold span',
      expectedWght: 400,
      content: plainContent(ContentExample.codeBlockHighlightedShort.html),
      styleFinder: (tester) => mergedStyleOf(tester, 'class')!);

    testFontWeight('syntax highlighting: bold span',
      expectedWght: 700,
      content: plainContent(ContentExample.codeBlockHighlightedShort.html),
      styleFinder: (tester) => mergedStyleOf(tester, 'A')!);
  });

  group('MathBlock', () {
    // See also katex_test.dart for detailed tests of
    // how we render the inside of a math block.
    // These tests check how it relates to the enclosing Zulip message.

    testContentSmoke(ContentExample.mathBlock);

    testWidgets('displays KaTeX content', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.mathBlock.html));
      tester.widget(find.text('λ', findRichText: true));
    });

    testWidgets('fallback to displaying KaTeX source if unsupported KaTeX HTML', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.mathBlockUnknown.html));
      tester.widget(find.text(r'\lambda', findRichText: true));
    });
  });

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
    bool wrapWithPerAccountStoreWidget = false,
  }) async {
    await prepareContent(tester, wrapWithPerAccountStoreWidget: wrapWithPerAccountStoreWidget,
      plainContent(
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
      return mergedStyleOf(tester, 'bold')!;
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

    testFontWeight('in table column header',
      expectedWght: 900,
      // | **bold** |
      // | - |
      // | text |
      content: plainContent(
        '<table>\n'
          '<thead>\n<tr>\n<th><strong>bold</strong></th>\n</tr>\n</thead>\n'
          '<tbody>\n<tr>\n<td>text</td>\n</tr>\n</tbody>\n'
          '</table>'),
      styleFinder: findWordBold);

    testFontWeight('in different kind of span in table column header',
      expectedWght: 900,
      // | *italic **bold*** |
      // | - |
      // | text |
      content: plainContent(
        '<table>\n'
          '<thead>\n<tr>\n<th><em>italic <strong>bold</strong></em></th>\n</tr>\n</thead>\n'
          '<tbody>\n<tr>\n<td>text</td>\n</tr>\n</tbody>\n'
          '</table>'),
      styleFinder: findWordBold);

    testWidgets('has strike-through line in strike-through', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1817
      await prepareContent(tester,
        plainContent('<p><del><strong>bold</strong></del></p>'));
      final style = mergedStyleOf(tester, 'bold');
      check(style!.decoration).equals(TextDecoration.lineThrough);
    });
  });

  testContentSmoke(ContentExample.deleted);

  testContentSmoke(ContentExample.emphasis);

  group('inline code', () {
    testContentSmoke(ContentExample.inlineCode);

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      await checkFontSizeRatio(tester,
        targetHtml: '<code>code</code>',
        targetFontSizeFinder: mkTargetFontSizeFinderFromPattern('code'));
    });

    testFontWeight('is bold in bold span',
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1812
      expectedWght: 600,
      // **`bold`**
      content: plainContent('<p><strong><code>bold</code></strong></p>'),
      styleFinder: (tester) => mergedStyleOf(tester, 'bold')!,
    );

    testWidgets('is link-colored in link span', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/806
      await prepareContent(tester,
        plainContent('<p><a href="https://example/"><code>code</code></a></p>'));
      final style = mergedStyleOf(tester, 'code');
      check(style!.color).equals(const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor());
    });
  });

  group('Mention', () {
    testContentSmoke(ContentExample.userMentionPlain,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.userMentionSilent,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.groupMentionPlain,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.groupMentionSilent,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.channelWildcardMentionPlain,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.channelWildcardMentionSilent,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.channelWildcardMentionSilentClassOrderReversed,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.legacyChannelWildcardMentionPlain,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.legacyChannelWildcardMentionSilent,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.legacyChannelWildcardMentionSilentClassOrderReversed,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.topicMentionPlain,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.topicMentionSilent,
      wrapWithPerAccountStoreWidget: true);
    testContentSmoke(ContentExample.topicMentionSilentClassOrderReversed,
      wrapWithPerAccountStoreWidget: true);

    Mention? findMentionInSpan(InlineSpan rootSpan) {
      Mention? result;
      rootSpan.visitChildren((span) {
        if (span case (WidgetSpan(child: Mention() && var widget))) {
          result = widget;
          return false;
        }
        return true;
      });
      return result;
    }

    TextStyle textStyleFromWidget(WidgetTester tester, Mention widget, String mentionText) {
      return mergedStyleOf(tester,
        findAncestor: find.byWidget(widget), mentionText)!;
    }

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      await checkFontSizeRatio(tester,
        targetHtml: '<span class="user-mention" data-user-id="13313">@Chris Bobbe</span>',
        wrapWithPerAccountStoreWidget: true,
        targetFontSizeFinder: (rootSpan) {
          final widget = findMentionInSpan(rootSpan);
          final style = textStyleFromWidget(tester, widget!, '@Chris Bobbe');
          return style.fontSize!;
        });
    });

    testFontWeight('silent or non-self mention in plain paragraph',
      expectedWght: 400,
      // @_**Greg Price**
      content: plainContent(
        '<p><span class="user-mention silent" data-user-id="2187">Greg Price</span></p>'),
      wrapWithPerAccountStoreWidget: true,
      styleFinder: (tester) {
        return textStyleFromWidget(tester,
          tester.widget(find.byType(Mention)), 'Greg Price');
      });

    // TODO(#647):
    //  testFontWeight('non-silent self-user mention in plain paragraph',
    //    expectedWght: 600, // [etc.]

    testFontWeight('silent or non-self mention in bold context',
      expectedWght: 600,
      // # @_**Chris Bobbe**
      content: plainContent(
        '<h1><span class="user-mention silent" data-user-id="13313">Chris Bobbe</span></h1>'),
      wrapWithPerAccountStoreWidget: true,
      styleFinder: (tester) {
        return textStyleFromWidget(tester,
          tester.widget(find.byType(Mention)), 'Chris Bobbe');
      });

    // TODO(#647):
    //  testFontWeight('non-silent self-user mention in bold context',
    //    expectedWght: 800, // [etc.]

    group('user mention dynamic name resolution', () {
      Future<void> prepare({
        required WidgetTester tester,
        required String html,
        List<User>? users,
      }) async {
        final initialSnapshot = eg.initialSnapshot(realmUsers: users);
        await prepareContent(tester,
          wrapWithPerAccountStoreWidget: true,
          initialSnapshot: initialSnapshot,
          plainContent(html));
      }

      testWidgets('resolves current user name from store', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-mention" data-user-id="123">@Old Name</span></p>',
          users: [eg.selfUser, eg.user(userId: 123, fullName: 'New Name')]);
        check(find.text('@New Name')).findsOne();
        check(find.text('@Old Name')).findsNothing();
      });

      testWidgets('falls back to original text when user not found', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-mention" data-user-id="999">@Unknown User</span></p>');
        check(find.text('@Unknown User')).findsOne();
      });

      testWidgets('falls back to original text when userId is null', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-mention channel-wildcard-mention" data-user-id="*">@all</span></p>');
        check(find.text('@all')).findsOne();
      });

      testWidgets('handles silent mentions correctly', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-mention silent" data-user-id="123">Old Name</span></p>',
          users: [eg.selfUser, eg.user(userId: 123, fullName: 'New Name')]);
        check(find.text('New Name')).findsOne();
        check(find.text('@New Name')).findsNothing();
      });
    });

    group('user group mention dynamic name resolution', () {
      Future<void> prepare({
        required WidgetTester tester,
        required String html,
        List<UserGroup>? userGroups,
      }) async {
        final initialSnapshot = eg.initialSnapshot(realmUserGroups: userGroups);
        await prepareContent(tester,
          wrapWithPerAccountStoreWidget: true,
          initialSnapshot: initialSnapshot,
          plainContent(html));
      }

      testWidgets('resolves current user group name from store', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-group-mention" data-user-group-id="186">@old-name</span></p>',
          userGroups: [eg.userGroup(id: 186, name: 'new-name')]);
        check(find.text('@new-name')).findsOne();
        check(find.text('@old-name')).findsNothing();
      });

      testWidgets('falls back to original text when user group not found', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-group-mention" data-user-group-id="999">@Unknown Group</span></p>');
        check(find.text('@Unknown Group')).findsOne();
      });

      testWidgets('handles silent mentions correctly', (tester) async {
        await prepare(
          tester: tester,
          html: '<p><span class="user-group-mention silent" data-user-group-id="186">old-name</span></p>',
          userGroups: [eg.userGroup(id: 186, name: 'new-name')]);
        check(find.text('new-name')).findsOne();
        check(find.text('@new-name')).findsNothing();
      });
    });
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
        LaunchMode.externalApplication : LaunchMode.inAppBrowserView;
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://example/'), mode: expectedLaunchMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('follow browser preference setting to open URL', (tester) async {
      await testBinding.globalStore.settings
        .setBrowserPreference(BrowserPreference.inApp);
      await prepare(tester,
        '<p><a href="https://example/">hello</a></p>');

      await tapText(tester, find.text('hello'));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse('https://example/'), mode: LaunchMode.inAppBrowserView));
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
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.inAppBrowserView));

      await tester.tapAt(base.translate(9*fontSize, 0)); // "foo bar bXz"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://b/'), mode: LaunchMode.inAppBrowserView));
    });

    testWidgets('link nested in other spans', (tester) async {
      await prepare(tester,
        '<p><strong><em><a href="https://a/">word</a></em></strong></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.inAppBrowserView));
    });

    testWidgets('link containing other spans', (tester) async {
      const fontSize = kBaseFontSize;

      await prepare(tester,
        '<p><a href="https://a/">two <strong><em><code>words</code></em></strong></a></p>');
      final base = tester.getTopLeft(find.text('two words'))
        .translate(fontSize/2, fontSize/2); // middle of first letter

      await tester.tapAt(base.translate(1*fontSize, 0)); // "tXo words"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.inAppBrowserView));

      await tester.tapAt(base.translate(6*fontSize, 0)); // "two woXds"
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.inAppBrowserView));
    });

    testWidgets('relative links are resolved', (tester) async {
      await prepare(tester,
        '<p><a href="/a/b?c#d">word</a></p>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('${eg.realmUrl}a/b?c#d'), mode: LaunchMode.inAppBrowserView));
    });

    testWidgets('link inside HeadingNode', (tester) async {
      await prepare(tester,
        '<h6><a href="https://a/">word</a></h6>');
      await tapText(tester, find.text('word'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: Uri.parse('https://a/'), mode: LaunchMode.inAppBrowserView));
    });

    testWidgets('error dialog if invalid URL', (tester) async {
      await prepare(tester,
        '<p><a href="::invalid::">word</a></p>');
      await tapText(tester, find.text('word'));
      await tester.pump();
      check(testBinding.takeLaunchUrlCalls()).isEmpty();
      checkErrorDialog(tester,
        expectedTitle: 'Unable to open link',
        expectedMessage: 'Link could not be opened: ::invalid::');
    });

    testWidgets('error dialog if platform cannot open link', (tester) async {
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
    late PerAccountStore store;
    late FakeApiConnection connection;

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

      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;
      await store.addStream(eg.stream(name: 'stream'));
      return pushedRoutes;
    }

    testWidgets('narrow links are navigated to within app', (tester) async {
      final pushedRoutes = await prepare(tester,
        '<p><a href="/#narrow/stream/1-check">stream</a></p>');

      await tapText(tester, find.text('stream'));
      check(testBinding.takeLaunchUrlCalls()).isEmpty();
      check(pushedRoutes).single.isA<WidgetRoute>()
        .page.isA<MessageListPage>().initNarrow.equals(const ChannelNarrow(1));
    });

    // TODO(#1570): test links with /near/ go to the specific message

    testWidgets('uploaded-file links are opened with temporary authed URL', (tester) async {
      final pushedRoutes = await prepare(tester,
        '<p><a href="/user_uploads/123/ab/paper.pdf">paper.pdf</a></p>');

      final tempUrlString = '/temp/s3kr1t-auth-token/paper.pdf';
      final expectedUrl = eg.realmUrl.resolve(tempUrlString);

      connection.prepare(json: GetFileTemporaryUrlResult(
        url: tempUrlString).toJson());
      await tapText(tester, find.text('paper.pdf'));
      await tester.pump(Duration.zero);
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: expectedUrl, mode: LaunchMode.inAppBrowserView));
      check(pushedRoutes).isEmpty();
    });

    testWidgets('invalid internal links are opened in browser', (tester) async {
      // Link is invalid due to `topic` operator missing an operand.
      final pushedRoutes = await prepare(tester,
        '<p><a href="/#narrow/stream/1-check/topic">invalid</a></p>');

      await tapText(tester, find.text('invalid'));
      final expectedUrl = eg.realmUrl.resolve('/#narrow/stream/1-check/topic');
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: expectedUrl, mode: LaunchMode.inAppBrowserView));
      check(pushedRoutes).isEmpty();
    });
  });

  group('UnicodeEmoji', () {
    testContentSmoke(ContentExample.emojiUnicode);
    testContentSmoke(ContentExample.emojiUnicodeMultiCodepoint);
    testContentSmoke(ContentExample.emojiUnicodeLiteral);

    testWidgets('use emoji font', (tester) async {
      // Compare [ContentExample.emojiUnicode].
      const emojiHeartHtml =
        '<p><span aria-label="heart" class="emoji emoji-2764" role="img" title="heart">:heart:</span></p>';
      await prepareContent(tester, plainContent(emojiHeartHtml));
      check(mergedStyleOf(tester, '\u{2764}')).isNotNull()
        .fontFamily.equals(switch (defaultTargetPlatform) {
          TargetPlatform.android => 'Noto Color Emoji',
          TargetPlatform.iOS => 'Apple Color Emoji',
          _ => throw StateError('unexpected platform in test'),
        });
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('has strike-through line in strike-through', (tester) async {
      // Regression test for https://github.com/zulip/zulip-flutter/issues/1818
      await prepareContent(tester,
        plainContent('<p><del>foo<span aria-label="thumbs up" class="emoji emoji-1f44d" role="img" title="thumbs up">:thumbs_up:</span>bar</del></p>'));
      final style = mergedStyleOf(tester, '\u{1f44d}');
      check(style!.decoration).equals(TextDecoration.lineThrough);
    });

    testWidgets('UnicodeEmoji renders at double size when it is the only content', (tester) async {
      final example = ContentExample.emojiUnicode;
      await prepareContent(tester, messageContent(example.html));
      final style = mergedStyleOf(tester, example.expectedText!);
      check(style?.fontSize).equals(kBaseFontSize * 2);
    });

    testWidgets('UnicodeEmoji renders at base size when joined with text', (tester) async {
      final example = ContentExample.emojiUnicodeWithText;

      await prepareContent(tester, messageContent(example.html));
      final style = mergedStyleOf(tester, '\u{1f44d}');
      check(style?.fontSize).equals(kBaseFontSize);
    });

    testWidgets('UnicodeEmoji renders at base size when repeated', (tester) async {
      final example = ContentExample.emojiUnicodeRepeated;

      await prepareContent(tester, messageContent(example.html));
      final style = mergedStyleOf(tester, '\u{1f44d}');
      check(style?.fontSize).equals(kBaseFontSize);
    });
  });

  group('inline math', () {
    // See also katex_test.dart for detailed tests of
    // how we render the inside of a math span.
    // These tests check how it relates to the enclosing Zulip message.

    testContentSmoke(ContentExample.mathInline);

    testWidgets('maintains font-size ratio with surrounding text', (tester) async {
      const html = '<span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span>';
      await checkFontSizeRatio(tester,
        targetHtml: html,
        targetFontSizeFinder: (rootSpan) {
          late final double result;
          rootSpan.visitChildren((span) {
            if (span case WidgetSpan(child: KatexWidget() && var widget)) {
              result = mergedStyleOf(tester,
                findAncestor: find.byWidget(widget), r'λ')!.fontSize!;
              return false;
            }
            return true;
          });
          return result;
        });
    });

    group('fallback to displaying KaTeX source if unsupported KaTeX HTML', () {
      testContentSmoke(ContentExample.mathInlineUnknown);

      assert(ContentExample.mathInlineUnknown.html.startsWith('<p>'));
      assert(ContentExample.mathInlineUnknown.html.endsWith('</p>'));
      final unsupportedKatexHtml = ContentExample.mathInlineUnknown.html
        .substring(3, ContentExample.mathInlineUnknown.html.length - 4);
      final expectedText = ContentExample.mathInlineUnknown.expectedText!;

      testWidgets('maintains font-size ratio with surrounding text, when falling back to TeX source', (tester) async {
        await checkFontSizeRatio(tester,
          targetHtml: unsupportedKatexHtml,
          targetFontSizeFinder: mkTargetFontSizeFinderFromPattern(expectedText));
      });

      testFontWeight('is bold in bold span',
        // Regression test for: https://github.com/zulip/zulip-flutter/issues/1812
        expectedWght: 600,
        content: plainContent('<p><strong>$unsupportedKatexHtml</strong></p>'),
        styleFinder: (tester) => mergedStyleOf(tester, expectedText)!,
      );

      testWidgets('is link-colored in link span', (tester) async {
        // Regression test for: https://github.com/zulip/zulip-flutter/issues/806
        await prepareContent(tester,
          plainContent('<p><a href="https://example/">$unsupportedKatexHtml</a></p>'));
        final style = mergedStyleOf(tester, expectedText);
        check(style!.color).equals(const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor());
      });
    });
  });

  group('GlobalTime', () {
    // "<time:2024-01-30T17:33:00Z>"
    const timeSpanHtml = '<time datetime="2024-01-30T17:33:00Z">2024-01-30T17:33:00Z</time>';
    // The time is shown in the user's timezone and the result will depend on
    // the timezone of the environment running these tests. Accept here a wide
    // range of times. See comments in "show dates" test in
    // `test/widgets/message_list_test.dart`.
    final renderedTextRegexp = RegExp(r'^(Tue, Jan 30|Wed, Jan 31), 2024, \d+:\d\d(?: [AP]M)?$');
    final renderedTextRegexpTwelveHour = RegExp(r'^(Tue, Jan 30|Wed, Jan 31), 2024, \d+:\d\d [AP]M$');
    final renderedTextRegexpTwentyFourHour = RegExp(r'^(Tue, Jan 30|Wed, Jan 31), 2024, \d+:\d\d$');

    Future<void> prepare(
      WidgetTester tester,
      [TwentyFourHourTimeMode twentyFourHourTimeMode = TwentyFourHourTimeMode.localeDefault]
    ) async {
      final initialSnapshot = eg.initialSnapshot()
        ..userSettings.twentyFourHourTime = twentyFourHourTimeMode;
      await prepareContent(tester,
        // We use the self-account's time-format setting.
        wrapWithPerAccountStoreWidget: true,
        initialSnapshot: initialSnapshot,
        plainContent('<p>$timeSpanHtml</p>'));
    }

    testWidgets('smoke', (tester) async {
      await prepare(tester);
      tester.widget(find.textContaining(renderedTextRegexp));
    });

    testWidgets('TwentyFourHourTimeMode.twelveHour', (tester) async {
      await prepare(tester, TwentyFourHourTimeMode.twelveHour);
      check(find.textContaining(renderedTextRegexpTwelveHour)).findsOne();
    });

    testWidgets('TwentyFourHourTimeMode.twentyFourHour', (tester) async {
      await prepare(tester, TwentyFourHourTimeMode.twentyFourHour);
      check(find.textContaining(renderedTextRegexpTwentyFourHour)).findsOne();
    });

    testWidgets('TwentyFourHourTimeMode.localeDefault', (tester) async {
      await prepare(tester, TwentyFourHourTimeMode.localeDefault);
      // This expectation holds as long as we're always formatting in en_US,
      // the default locale, which uses the twelve-hour format.
      // TODO(#1727) follow the actual locale; test with different locales
      check(find.textContaining(renderedTextRegexpTwelveHour)).findsOne();
    });

    void testIconAndTextSameColor(String description, String html) {
      testWidgets('clock icon and text are the same color: $description', (tester) async {
        await prepareContent(tester,
          // We use the self-account's time-format setting.
          wrapWithPerAccountStoreWidget: true,
          plainContent(html));

        final icon = tester.widget<Icon>(
          find.descendant(of: find.byType(GlobalTime),
            matching: find.byIcon(ZulipIcons.clock)));

        final textColor = mergedStyleOf(tester,
          findAncestor: find.byType(GlobalTime), renderedTextRegexp)!.color;
        check(textColor).isNotNull();

        check(icon).color.isNotNull().isSameColorAs(textColor!);
      });
    }

    testIconAndTextSameColor('common case', '<p>$timeSpanHtml</p>');
    testIconAndTextSameColor('inside link', '<p><a href="https://example/">$timeSpanHtml</a></p>');

    group('maintains font-size ratio with surrounding text', () {
      Future<void> doCheck(WidgetTester tester, double Function(GlobalTime widget) sizeFromWidget) async {
        await checkFontSizeRatio(tester,
          // We use the self-account's time-format setting.
          wrapWithPerAccountStoreWidget: true,
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
          return mergedStyleOf(tester, findAncestor: find.byWidget(widget),
              renderedTextRegexp)!.fontSize!;
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

  group('InlineAudio', () {
    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester, plainContent(html),
        // We try to resolve relative links on the self-account's realm.
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('tapping on audio link opens it in browser', (tester) async {
      await prepare(tester, ContentExample.audioInline.html);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final connection = store.connection as FakeApiConnection;

      final url = eg.realmUrl.resolve('/temp/token/crab-rave.mp3');
      connection.prepare(json: GetFileTemporaryUrlResult(url: url.path).toJson());
      await tapText(tester, find.text('crab-rave.mp3'));
      await tester.pump(Duration.zero);

      final expectedLaunchMode = defaultTargetPlatform == TargetPlatform.iOS ?
        LaunchMode.externalApplication : LaunchMode.inAppBrowserView;
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: expectedLaunchMode));
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
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

    testWidgets('ImageEmoji renders at double size when it is the only content', (tester) async {
      await prepare(tester, ContentExample.emojiZulipExtra.html);

      final SizedBox sizeBox = tester.widget(find.descendant(
        of: find.byType(MessageImageEmoji),
        matching: find.byType(SizedBox)));
      check(sizeBox.width).equals(40.0);
      check(sizeBox.height).equals(kBaseFontSize * 2.0);
    });

    testWidgets('ImageEmoji renders at base size when joined with text', (tester) async {
      await prepare(tester, ContentExample.emojiZulipExtraWithText.html);

      final SizedBox sizeBox = tester.widget(find.descendant(
        of: find.byType(MessageImageEmoji),
        matching: find.byType(SizedBox)));
      check(sizeBox.width).equals(20.0);
      check(sizeBox.height).equals(kBaseFontSize);
    });

    testWidgets('ImageEmojis renders at base size when repeated', (tester) async {
      await prepare(tester, ContentExample.emojiZulipExtraRepeated.html);

      final SizedBox sizeBox = tester.widget(find.descendant(
          of: find.byType(MessageImageEmoji),
          matching: find.byType(SizedBox)).first);
      check(sizeBox.width).equals(20.0);
      check(sizeBox.height).equals(kBaseFontSize);
    });
  });

  group('InlineImage', () {
    late TransitionDurationObserver transitionDurationObserver;

    Future<void> prepare(WidgetTester tester, String html) async {
      transitionDurationObserver = TransitionDurationObserver();
      await prepareContent(tester,
        // Message is needed for the image's lightbox.
        messageContent(html),
        navObservers: [transitionDurationObserver],
        // We try to resolve the image's URL on the self-account's realm.
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('smoke: inline image', (tester) async {
      await prepare(tester, ContentExample.inlineImage.html);
      check(find.byType(InlineImage)).findsOne();

      prepareBoringImageHttpClient();
      await tester.tap(find.byType(InlineImage));
      await transitionDurationObserver.pumpPastTransition(tester);
      check(find.byType(InteractiveViewer)).findsOne(); // recognize the lightbox
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: inline image, loading', (tester) async {
      await prepare(tester, ContentExample.inlineImageLoading.html);
      check(find.byType(InlineImage)).findsOne();
      check(find.byType(CupertinoActivityIndicator)).findsOne();
    });

    testWidgets('smoke: inline image, animated', (tester) async {
      await prepare(tester, ContentExample.inlineImageAnimated.html);
      check(find.byType(InlineImage)).findsOne();
    });

    testWidgets('table with inline image', (tester) async {
      await prepare(tester, ContentExample.tableWithInlineImage.html);
      check(find.byType(InlineImage)).findsOne();

      prepareBoringImageHttpClient();
      await tester.tap(find.byType(InlineImage));
      await transitionDurationObserver.pumpPastTransition(tester);
      check(find.byType(InteractiveViewer)).findsOne(); // recognize the lightbox
      debugNetworkImageHttpClientProvider = null;
    });
  });

  group('WebsitePreview', () {
    Future<void> prepare(WidgetTester tester, String html) async {
      await prepareContent(tester, plainContent(html),
        wrapWithPerAccountStoreWidget: true);
    }

    testWidgets('smoke', (tester) async {
      final url = Uri.parse(ContentExample.websitePreviewSmoke.markdown!);
      await prepare(tester, ContentExample.websitePreviewSmoke.html);

      await tester.tap(find.textContaining(
        'Zulip is an organized team chat app for '
        'distributed teams of all sizes.'));

      await tester.tap(find.text('Zulip — organized team chat'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));

      await tester.tap(find.byType(RealmContentNetworkImage));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: without title', (tester) async {
      final url = Uri.parse(ContentExample.websitePreviewWithoutTitle.markdown!);
      await prepare(tester, ContentExample.websitePreviewWithoutTitle.html);

      await tester.tap(find.textContaining(
        'Zulip is an organized team chat app for '
        'distributed teams of all sizes.'));

      await tester.tap(find.byType(RealmContentNetworkImage));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: without description', (tester) async {
      final url = Uri.parse(ContentExample.websitePreviewWithoutDescription.markdown!);
      await prepare(tester, ContentExample.websitePreviewWithoutDescription.html);

      await tester.tap(find.text('Zulip — organized team chat'));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));

      await tester.tap(find.byType(RealmContentNetworkImage));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke: without title or description', (tester) async {
      final url = Uri.parse(ContentExample.websitePreviewWithoutTitleOrDescription.markdown!);
      await prepare(tester, ContentExample.websitePreviewWithoutTitleOrDescription.html);

      await tester.tap(find.byType(RealmContentNetworkImage));
      check(testBinding.takeLaunchUrlCalls())
        .single.equals((url: url, mode: LaunchMode.inAppBrowserView));
      debugNetworkImageHttpClientProvider = null;
    });
  });

  group('MessageTable', () {
    testFontWeight('bold column header label',
      // | a | b | c | d |
      // | - | - | - | - |
      // | 1 | 2 | 3 | 4 |
      content: plainContent(ContentExample.tableWithSingleRow.html),
      expectedWght: 700,
      styleFinder: (tester) => mergedStyleOf(tester, 'a')!);

    testWidgets('header row background color', (tester) async {
      await prepareContent(tester, plainContent(ContentExample.tableWithSingleRow.html));
      final BuildContext context = tester.element(find.byType(Table));
      check(tester.widget<Table>(find.byType(Table))).children.first
        .decoration
        .isA<BoxDecoration>()
        .color.equals(ContentTheme.of(context).colorTableHeaderBackground);
    });

    testWidgets('different text alignment in columns', (tester) async {
      await prepareContent(tester,
        // | default-aligned | left-aligned | center-aligned | right-aligned |
        // | - | :- | :-: | -: |
        // | text | text | text | text |
        // | long text long text long text  | long text long text long text  | long text long text long text | long text long text long text |
        plainContent(ContentExample.tableWithDifferentTextAlignmentInColumns.html));

      final defaultAlignedText = tester.renderObject<RenderParagraph>(find.textContaining('default-aligned'));
      check(defaultAlignedText.textAlign).equals(TextAlign.start);

      final leftAlignedText = tester.renderObject<RenderParagraph>(find.textContaining('left-aligned'));
      check(leftAlignedText.textAlign).equals(TextAlign.left);

      final centerAlignedText = tester.renderObject<RenderParagraph>(find.textContaining('center-aligned'));
      check(centerAlignedText.textAlign).equals(TextAlign.center);

      final rightAlignedText = tester.renderObject<RenderParagraph>(find.textContaining('right-aligned'));
      check(rightAlignedText.textAlign).equals(TextAlign.right);
    });

    testWidgets('text alignment in column; with link', (tester) async {
      await prepareContent(tester,
        // | header |
        // | :-: |
        // | https://zulip.com |
        plainContent(ContentExample.tableWithLinkCenterAligned.html));

      final linkText = tester.renderObject<RenderParagraph>(find.textContaining('https://zulip.com'));
      check(linkText.textAlign).equals(TextAlign.center);
    });
  });
}
