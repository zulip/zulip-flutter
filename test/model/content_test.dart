import 'package:checks/checks.dart';
import 'package:html/parser.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/code_block.dart';
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
    testParse(name, html, [ParagraphNode(links: null, nodes: [node])]);
  }

  testParse('parse a plain-text paragraph',
    // "hello world"
    '<p>hello world</p>', const [ParagraphNode(links: null, nodes: [
      TextNode('hello world'),
    ])]);

  testParse('parse <br> inside a paragraph',
    // "a\nb"
    '<p>a<br>\nb</p>', const [ParagraphNode(links: null, nodes: [
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

  group('LinkNode', () {
    testParseInline('parse link',
      // "[text](https://example/)"
      '<p><a href="https://example/">text</a></p>',
      const LinkNode(url: 'https://example/', nodes: [TextNode('text')]));

    testParseInline('parse #-mention of stream',
      // "#**general**"
      '<p><a class="stream" data-stream-id="2" href="/#narrow/stream/2-general">'
          '#general</a></p>',
      const LinkNode(url: '/#narrow/stream/2-general',
        nodes: [TextNode('#general')]));

    testParseInline('parse #-mention of topic',
      // "#**mobile-team>zulip-flutter**"
      '<p><a class="stream-topic" data-stream-id="243" '
          'href="/#narrow/stream/243-mobile-team/topic/zulip-flutter">'
          '#mobile-team &gt; zulip-flutter</a></p>',
      const LinkNode(url: '/#narrow/stream/243-mobile-team/topic/zulip-flutter',
        nodes: [TextNode('#mobile-team > zulip-flutter')]));
  });

  testParseInline('parse nested link, strong, em, code',
    // "[***`word`***](https://example/)"
    '<p><a href="https://example/"><strong><em><code>word'
        '</code></em></strong></a></p>',
    const LinkNode(url: 'https://example/',
      nodes: [StrongNode(nodes: [EmphasisNode(nodes: [InlineCodeNode(nodes: [
        TextNode('word')])])])]));

  testParseInline('parse nested strong, em, link',
    // "***[t](/u)***"
    '<p><strong><em><a href="/u">t</a></em></strong></p>',
    const StrongNode(nodes: [EmphasisNode(nodes: [LinkNode(url: '/u',
      nodes: [TextNode('t')])])]));

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

  testParseInline('parse Unicode emoji, encoded in span element',
    // ":thumbs_up:"
    '<p><span aria-label="thumbs up" class="emoji emoji-1f44d" role="img" title="thumbs up">:thumbs_up:</span></p>',
    const UnicodeEmojiNode(emojiUnicode: '\u{1f44d}')); // "👍"

  testParseInline('parse Unicode emoji, encoded in span element, multiple codepoints',
    // ":transgender_flag:"
    '<p><span aria-label="transgender flag" class="emoji emoji-1f3f3-fe0f-200d-26a7-fe0f" role="img" title="transgender flag">:transgender_flag:</span></p>',
    const UnicodeEmojiNode(emojiUnicode: '\u{1f3f3}\u{fe0f}\u{200d}\u{26a7}\u{fe0f}')); // "🏳️‍⚧️"

  testParseInline('parse Unicode emoji, not encoded in span element',
    // "\u{1fabf}"
    '<p>\u{1fabf}</p>',
    const TextNode('\u{1fabf}')); // "🪿"

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

  testParseInline('parse inline math',
    // "$$ \\lambda $$"
    '<p><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></p>',
    const MathInlineNode(texSource: r'\lambda'));

  //
  // Block content.
  //

  testParse('parse <br> in block context',
    '<br><p>a</p><br>', const [ // TODO not sure how to reproduce this example
      LineBreakNode(),
      ParagraphNode(links: null, nodes: [TextNode('a')]),
      LineBreakNode(),
    ]);

  testParse('parse two plain-text paragraphs',
    // "hello\n\nworld"
    '<p>hello</p>\n<p>world</p>', const [
      ParagraphNode(links: null, nodes: [TextNode('hello')]),
      ParagraphNode(links: null, nodes: [TextNode('world')]),
    ]);

  group('parse headings', () {
    testParse('plain h6',
      // "###### six"
      '<h6>six</h6>', const [
        HeadingNode(level: HeadingLevel.h6, links: null, nodes: [TextNode('six')])]);

    testParse('containing inline markup',
      // "###### one [***`two`***](https://example/)"
      '<h6>one <a href="https://example/"><strong><em><code>two'
          '</code></em></strong></a></h6>', const [
        HeadingNode(level: HeadingLevel.h6, links: null, nodes: [
          TextNode('one '),
          LinkNode(url: 'https://example/',
            nodes: [StrongNode(nodes: [EmphasisNode(nodes: [
              InlineCodeNode(nodes: [TextNode('two')])])])]),
        ])]);

    testParse('amidst paragraphs',
      // "intro\n###### section\ntext"
      "<p>intro</p>\n<h6>section</h6>\n<p>text</p>", const [
        ParagraphNode(links: null, nodes: [TextNode('intro')]),
        HeadingNode(level: HeadingLevel.h6, links: null, nodes: [TextNode('section')]),
        ParagraphNode(links: null, nodes: [TextNode('text')]),
      ]);

    testParse('h1, h2, h3, h4, h5',
      // "# one\n## two\n### three\n#### four\n##### five"
      '<h1>one</h1>\n<h2>two</h2>\n<h3>three</h3>\n<h4>four</h4>\n<h5>five</h5>', const [
        HeadingNode(level: HeadingLevel.h1, links: null, nodes: [TextNode('one')]),
        HeadingNode(level: HeadingLevel.h2, links: null, nodes: [TextNode('two')]),
        HeadingNode(level: HeadingLevel.h3, links: null, nodes: [TextNode('three')]),
        HeadingNode(level: HeadingLevel.h4, links: null, nodes: [TextNode('four')]),
        HeadingNode(level: HeadingLevel.h5, links: null, nodes: [TextNode('five')]),
      ]);
  });

  group('parse lists', () {
    testParse('<ol>',
      // "1. first\n2. then"
      '<ol>\n<li>first</li>\n<li>then</li>\n</ol>', const [
        ListNode(ListStyle.ordered, [
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('first')])],
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('then')])],
        ]),
      ]);

    testParse('<ul>',
      // "* something\n* another"
      '<ul>\n<li>something</li>\n<li>another</li>\n</ul>', const [
        ListNode(ListStyle.unordered, [
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('something')])],
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('another')])],
        ]),
      ]);

    testParse('implicit paragraph with internal <br>',
      // "* a\n  b"
      '<ul>\n<li>a<br>\n  b</li>\n</ul>', const [
        ListNode(ListStyle.unordered, [
          [ParagraphNode(wasImplicit: true, links: null, nodes: [
            TextNode('a'),
            LineBreakInlineNode(),
            TextNode('\n  b'), // TODO: this renders misaligned
          ])],
        ])
      ]);

    testParse('explicit paragraphs',
      // "* a\n\n  b"
      '<ul>\n<li>\n<p>a</p>\n<p>b</p>\n</li>\n</ul>', const [
        ListNode(ListStyle.unordered, [
          [
            ParagraphNode(links: null, nodes: [TextNode('a')]),
            ParagraphNode(links: null, nodes: [TextNode('b')]),
          ],
        ]),
      ]);
  });

  group('track links inside block-inline containers', () {
    testParse('multiple links in paragraph',
      // "before[text](/there)mid[other](/else)after"
      '<p>before<a href="/there">text</a>mid'
          '<a href="/else">other</a>after</p>', const [
        ParagraphNode(links: null, nodes: [
          TextNode('before'),
          LinkNode(url: '/there', nodes: [TextNode('text')]),
          TextNode('mid'),
          LinkNode(url: '/else', nodes: [TextNode('other')]),
          TextNode('after'),
        ])]);

    testParse('link in heading',
      // "###### [t](/u)\nhi"
      '<h6><a href="/u">t</a></h6>\n<p>hi</p>', const [
        HeadingNode(links: null, level: HeadingLevel.h6, nodes: [
          LinkNode(url: '/u', nodes: [TextNode('t')]),
        ]),
        ParagraphNode(links: null, nodes: [TextNode('hi')]),
      ]);

    testParse('link in list item',
      // "* [t](/u)"
      '<ul>\n<li><a href="/u">t</a></li>\n</ul>', const [
        ListNode(ListStyle.unordered, [
          [ParagraphNode(links: null, wasImplicit: true, nodes: [
            LinkNode(url: '/u', nodes: [TextNode('t')]),
          ])],
        ])]);
  });

  testParse('parse quotations',
    // "```quote\nwords\n```"
    '<blockquote>\n<p>words</p>\n</blockquote>', const [
      QuotationNode([ParagraphNode(links: null, nodes: [TextNode('words')])]),
    ]);

  testParse('parse code blocks, without syntax highlighting',
    // "```\nverb\natim\n```"
    '<div class="codehilite"><pre><span></span><code>verb\natim\n</code></pre></div>', const [
      CodeBlockNode([
        CodeBlockSpanNode(text: 'verb\natim', type: CodeBlockSpanType.text),
      ]),
    ]);

  testParse('parse code blocks, with syntax highlighting',
    // "```dart\nclass A {}\n```"
    '<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="kd">class</span><span class="w"> </span>'
        '<span class="nc">A</span><span class="w"> </span><span class="p">{}</span>'
        '\n</code></pre></div>', const [
      CodeBlockNode([
        CodeBlockSpanNode(text: 'class', type: CodeBlockSpanType.keywordDeclaration),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: 'A', type: CodeBlockSpanType.nameClass),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: '{}', type: CodeBlockSpanType.punctuation),
      ]),
    ]);

  testParse('parse code blocks, multiline, with syntax highlighting',
    // '```rust\nfn main() {\n    print!("Hello ");\n\n    print!("world!\\n");\n}\n```'
    '<div class="codehilite" data-code-language="Rust"><pre>'
        '<span></span><code><span class="k">fn</span> <span class="nf">main</span>'
        '<span class="p">()</span><span class="w"> </span><span class="p">{</span>\n'
        '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
        '<span class="s">"Hello "</span><span class="p">);</span>\n\n'
        '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
        '<span class="s">"world!</span><span class="se">\\n</span><span class="s">"</span>'
        '<span class="p">);</span>\n<span class="p">}</span>\n'
        '</code></pre></div>', const [
      CodeBlockNode([
        CodeBlockSpanNode(text: 'fn', type: CodeBlockSpanType.keyword),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.text),
        CodeBlockSpanNode(text: 'main', type: CodeBlockSpanType.nameFunction),
        CodeBlockSpanNode(text: '()', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: '{', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: '\n', type: CodeBlockSpanType.text),
        CodeBlockSpanNode(text: '    ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: 'print!', type: CodeBlockSpanType.nameFunctionMagic),
        CodeBlockSpanNode(text: '(', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: '"Hello "', type: CodeBlockSpanType.string),
        CodeBlockSpanNode(text: ');', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: '\n\n', type: CodeBlockSpanType.text),
        CodeBlockSpanNode(text: '    ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: 'print!', type: CodeBlockSpanType.nameFunctionMagic),
        CodeBlockSpanNode(text: '(', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: '"world!', type: CodeBlockSpanType.string),
        CodeBlockSpanNode(text: '\\n', type: CodeBlockSpanType.stringEscape),
        CodeBlockSpanNode(text: '"', type: CodeBlockSpanType.string),
        CodeBlockSpanNode(text: ');', type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: '\n', type: CodeBlockSpanType.text),
        CodeBlockSpanNode(text: '}', type: CodeBlockSpanType.punctuation),
      ]),
    ]);

  testParse('parse code blocks, with syntax highlighting and highlighted lines',
    // '```\n::markdown hl_lines="2 4"\n# he\n## llo\n### world\n```'
    '<div class="codehilite"><pre>'
        '<span></span><code>::markdown hl_lines=&quot;2 4&quot;\n'
        '<span class="hll"><span class="gh"># he</span>\n'
        '</span><span class="gu">## llo</span>\n'
        '<span class="hll"><span class="gu">### world</span>\n'
        '</span></code></pre></div>', [
      // TODO: Fix this, see comment under `CodeBlockSpanType.highlightedLines` case in lib/model/content.dart.
      blockUnimplemented('<div class="codehilite"><pre>'
        '<span></span><code>::markdown hl_lines=&quot;2 4&quot;\n'
        '<span class="hll"><span class="gh"># he</span>\n'
        '</span><span class="gu">## llo</span>\n'
        '<span class="hll"><span class="gu">### world</span>\n'
        '</span></code></pre></div>'),
    ]);

  testParse('parse code blocks, unknown span type',
    // (no markdown; this test is for future Pygments versions adding new token types)
    '<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="unknown">class</span>'
        '\n</code></pre></div>', [
      blockUnimplemented('<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="unknown">class</span>'
        '\n</code></pre></div>'),
    ]);

  testParse('parse math block',
    // "```math\n\\lambda\n```"
    '<p><span class="katex-display"><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span></p>',
    [const MathBlockNode(texSource: r'\lambda')]);

  testParse('parse math block in quote',
    // There's sometimes a quirky extra `<br>\n` at the end of the `<p>` that
    // encloses the math block.  In particular this happens when the math block
    // is the last thing in the quote; though not in a doubly-nested quote;
    // and there might be further wrinkles yet to be found.  Some experiments:
    //   https://chat.zulip.org/#narrow/stream/7-test-here/topic/content/near/1715732
    // "````quote\n```math\n\\lambda\n```\n````"
    '<blockquote>\n<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span>'
      '<br>\n</p>\n</blockquote>',
    [const QuotationNode([MathBlockNode(texSource: r'\lambda')])]);

  testParse('parse image',
    // "https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3"
    '<div class="message_inline_image">'
        '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">'
        '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">'
        '</a></div>', const [
      ImageNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3'),
    ]);

  testParse('parse nested lists, quotes, headings, code blocks',
    // "1. > ###### two\n   > * three\n\n      four"
    '<ol>\n<li>\n<blockquote>\n<h6>two</h6>\n<ul>\n<li>three</li>\n'
        '</ul>\n</blockquote>\n<div class="codehilite"><pre><span></span>'
        '<code>four\n</code></pre></div>\n\n</li>\n</ol>', const [
      ListNode(ListStyle.ordered, [[
        QuotationNode([
          HeadingNode(level: HeadingLevel.h6, links: null, nodes: [TextNode('two')]),
          ListNode(ListStyle.unordered, [[
            ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('three')]),
          ]]),
        ]),
        CodeBlockNode([
          CodeBlockSpanNode(text: 'four', type: CodeBlockSpanType.text),
        ]),
        ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('\n\n')]), // TODO avoid this; it renders wrong
      ]]),
    ]);
}
