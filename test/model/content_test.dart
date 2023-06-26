import 'package:checks/checks.dart';
import 'package:html/parser.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/content.dart';

import 'content_checks.dart';

void testParse(String name, String html, List<BlockContentNode> nodes) {
  test(name, () {
    check(parseContent(html))
      .equalsNode(ZulipContent(nodes: nodes));
  });
}

UnimplementedBlockContentNode blockUnimplemented(String html) {
  var fragment = HtmlParser(html, parseMeta: false).parseFragment();
  return UnimplementedBlockContentNode(htmlNode: fragment.nodes.single);
}

UnimplementedInlineContentNode inlineUnimplemented(String html) {
  var fragment = HtmlParser(html, parseMeta: false).parseFragment();
  return UnimplementedInlineContentNode(htmlNode: fragment.nodes.single);
}

void main() {
  // When writing test cases in this file:
  //
  //  * Try to use actual HTML emitted by a Zulip server.
  //    Record the corresponding Markdown source in a comment.
  //
  //  * Here's a handy `curl` command for getting the server's HTML.
  //    First, as one-time setup, create a file with a test account's
  //    Zulip credentials in "netrc" format, meaning one line that looks like:
  //       machine HOSTNAME login EMAIL password API_KEY
  //
  //  * Then send some test messages, and fetch with a command like this.
  //    (Change "sender" operand to your user ID, and "topic" etc. as desired.)
  /*    $ curl -sS --netrc-file ../.netrc -G https://chat.zulip.org/api/v1/messages \
            --data-urlencode 'narrow=[{"operator":"sender", "operand":2187},
                                      {"operator":"stream", "operand":"test here"},
                                      {"operator":"topic",  "operand":"content"}]' \
            --data-urlencode anchor=newest --data-urlencode num_before=10 --data-urlencode num_after=0 \
            --data-urlencode apply_markdown=true \
          | jq '.messages[] | .content'
   */
  //
  //  * To get the corresponding Markdown source, use the same command
  //    with `apply_markdown` changed to `false`.

  //
  // Inline content.
  //

  void testParseInline(String name, String html, InlineContentNode node) {
    testParse(name, html, [ParagraphNode(nodes: [node])]);
  }

  testParse('parse a plain-text paragraph',
    // "hello world"
    '<p>hello world</p>', const [ParagraphNode(nodes: [
      TextNode('hello world'),
    ])]);

  testParse('parse <br> inside a paragraph',
    // "a\nb"
    '<p>a<br>\nb</p>', const [ParagraphNode(nodes: [
      TextNode('a'),
      LineBreakInlineNode(),
      TextNode('\nb'),
    ])]);

  testParseInline('parse strong/bold',
    // "**bold**"
    '<p><strong>bold</strong></p>',
    const StrongNode(nodes: [TextNode('bold')]));

  testParseInline('parse emphasis/italic',
    // "*italic*"
    '<p><em>italic</em></p>',
    const EmphasisNode(nodes: [TextNode('italic')]));

  testParseInline('parse inline code',
    // "`inline code`"
    '<p><code>inline code</code></p>',
    const InlineCodeNode(nodes: [TextNode('inline code')]));

  testParseInline('parse nested strong, em, code',
    // "***`word`***"
    '<p><strong><em><code>word</code></em></strong></p>',
    const StrongNode(nodes: [EmphasisNode(nodes: [InlineCodeNode(nodes: [
      TextNode('word')])])]));

  testParseInline('parse link',
    // "[text](https://example/)"
    '<p><a href="https://example/">text</a></p>',
    const LinkNode(nodes: [TextNode('text')]));

  testParseInline('parse #-mention of stream',
    // "#**general**"
    '<p><a class="stream" data-stream-id="2" href="/#narrow/stream/2-general">'
        '#general</a></p>',
    const LinkNode(nodes: [TextNode('#general')]));

  testParseInline('parse #-mention of topic',
    // "#**mobile-team>zulip-flutter**"
    '<p><a class="stream-topic" data-stream-id="243" '
        'href="/#narrow/stream/243-mobile-team/topic/zulip-flutter">'
        '#mobile-team &gt; zulip-flutter</a></p>',
    const LinkNode(nodes: [TextNode('#mobile-team > zulip-flutter')]));

  testParseInline('parse nested link, strong, em, code',
    // "[***`word`***](https://example/)"
    '<p><a href="https://example/"><strong><em><code>word'
        '</code></em></strong></a></p>',
    const LinkNode(nodes: [StrongNode(nodes: [
      EmphasisNode(nodes: [InlineCodeNode(nodes: [
        TextNode('word')])])])]));

  group('parse @-mentions', () {
    testParseInline('plain user @-mention',
      // "@**Greg Price**"
      '<p><span class="user-mention" data-user-id="2187">@Greg Price</span></p>',
      const UserMentionNode(nodes: [TextNode('@Greg Price')]));

    testParseInline('silent user @-mention',
      // "@_**Greg Price**"
      '<p><span class="user-mention silent" data-user-id="2187">Greg Price</span></p>',
      const UserMentionNode(nodes: [TextNode('Greg Price')]));

    // TODO test group mentions and wildcard mentions
  });

  testParseInline('parse Unicode emoji',
    // ":thumbs_up:"
    '<p><span aria-label="thumbs up" class="emoji emoji-1f44d" role="img" title="thumbs up">:thumbs_up:</span></p>',
    const UnicodeEmojiNode(text: ':thumbs_up:'));

  testParseInline('parse custom emoji',
    // ":flutter:"
    '<p><img alt=":flutter:" class="emoji" src="/user_avatars/2/emoji/images/204.png" title="flutter"></p>',
    const ImageEmojiNode(
      src: '/user_avatars/2/emoji/images/204.png', alt: ':flutter:'));

  testParseInline('parse Zulip extra emoji',
    // ":zulip:"
    '<p><img alt=":zulip:" class="emoji" src="/static/generated/emoji/images/emoji/unicode/zulip.png" title="zulip"></p>',
    const ImageEmojiNode(
      src: '/static/generated/emoji/images/emoji/unicode/zulip.png', alt: ':zulip:'));

  //
  // Block content.
  //

  testParse('parse two plain-text paragraphs',
    // "hello\n\nworld"
    '<p>hello</p>\n<p>world</p>', const [
      ParagraphNode(nodes: [TextNode('hello')]),
      ParagraphNode(nodes: [TextNode('world')]),
    ]);

  group('parse headings', () {
    testParse('plain h6',
      // "###### six"
      '<h6>six</h6>', const [
        HeadingNode(level: HeadingLevel.h6, nodes: [TextNode('six')])]);

    testParse('containing inline markup',
      // "###### one [***`two`***](https://example/)"
      '<h6>one <a href="https://example/"><strong><em><code>two'
          '</code></em></strong></a></h6>', const [
        HeadingNode(level: HeadingLevel.h6, nodes: [
          TextNode('one '),
          LinkNode(nodes: [StrongNode(nodes: [
            EmphasisNode(nodes: [InlineCodeNode(nodes: [
              TextNode('two')])])])]),
        ])]);

    testParse('amidst paragraphs',
      // "intro\n###### section\ntext"
      "<p>intro</p>\n<h6>section</h6>\n<p>text</p>", const [
        ParagraphNode(nodes: [TextNode('intro')]),
        HeadingNode(level: HeadingLevel.h6, nodes: [TextNode('section')]),
        ParagraphNode(nodes: [TextNode('text')]),
      ]);

    testParse('h1, h2, h3, h4, h5 unimplemented',
      // "# one\n## two\n### three\n#### four\n##### five"
      '<h1>one</h1>\n<h2>two</h2>\n<h3>three</h3>\n<h4>four</h4>\n<h5>five</h5>', [
        blockUnimplemented('<h1>one</h1>'),
        blockUnimplemented('<h2>two</h2>'),
        blockUnimplemented('<h3>three</h3>'),
        blockUnimplemented('<h4>four</h4>'),
        blockUnimplemented('<h5>five</h5>'),
      ]);
  });

  // TODO write more tests for this code
}
