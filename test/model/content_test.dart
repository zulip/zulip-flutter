import 'dart:io';

import 'package:checks/checks.dart';
import 'package:html/parser.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/code_block.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/katex.dart';

import 'binding.dart';
import 'content_checks.dart';

/// An example of Zulip content for test cases.
//
// When writing examples:
//
//  * Try to use actual HTML emitted by a Zulip server for [html].
//    Record the corresponding Markdown source in [markdown].
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
class ContentExample {
  const ContentExample(this.description, this.markdown, this.html,
    this.expectedNodes, {this.expectedText});

  ContentExample.inline(this.description, this.markdown, this.html,
      InlineContentNode parsed, {this.expectedText})
    : expectedNodes = [ParagraphNode(links: null, nodes: [parsed])];

  /// A description string, for use in names of tests.
  final String description;

  /// The Zulip Markdown source, if any, that the server renders as [html].
  ///
  /// This is useful for reproducing the example content for live use in the
  /// app, and as a starting point for variations on it.
  ///
  /// Currently the test suite does not verify the relationship between
  /// [markdown] and [html].
  ///
  /// If there is no known Markdown that a Zulip server can render as [html],
  /// then this should be null and a comment should explain why the test uses
  /// such an example.
  final String? markdown;

  /// A fragment of Zulip HTML, to be parsed as a [ZulipContent].
  ///
  /// Generally this should be actual HTML emitted by a Zulip server.
  /// See the example `curl` command in comments on this class for help in
  /// conveniently getting such HTML.
  final String html;

  /// The [ZulipContent.nodes] expected from parsing [html].
  final List<BlockContentNode> expectedNodes;

  /// The text, if applicable, of a text widget expected from
  /// rendering [expectedNodes].
  ///
  /// Strictly this belongs to the widget tests, not the model tests, as it
  /// encodes choices about how the content widgets work.  But it's convenient
  /// to have it defined for each test case right next to [html] and [expectedNodes].
  final String? expectedText;

  static final strong = ContentExample.inline(
    'strong/bold',
    '**bold**',
    expectedText: 'bold',
    '<p><strong>bold</strong></p>',
    const StrongNode(nodes: [TextNode('bold')]));

  static final deleted = ContentExample.inline(
    'deleted/strike-through',
    '~~strike through~~',
    expectedText: 'strike through',
    '<p><del>strike through</del></p>',
    const DeletedNode(nodes: [TextNode('strike through')]));

  static final emphasis = ContentExample.inline(
    'emphasis/italic',
    '*italic*',
    expectedText: 'italic',
    '<p><em>italic</em></p>',
    const EmphasisNode(nodes: [TextNode('italic')]));

  static final inlineCode = ContentExample.inline(
    'inline code',
    '`inline code`',
    expectedText: 'inline code',
    '<p><code>inline code</code></p>',
    const InlineCodeNode(nodes: [TextNode('inline code')]));

  static final userMentionPlain = ContentExample.inline(
    'plain user @-mention',
    "@**Greg Price**",
    expectedText: '@Greg Price',
    '<p><span class="user-mention" data-user-id="2187">@Greg Price</span></p>',
    const UserMentionNode(nodes: [TextNode('@Greg Price')]));

  static final userMentionSilent = ContentExample.inline(
    'silent user @-mention',
    "@_**Greg Price**",
    expectedText: 'Greg Price',
    '<p><span class="user-mention silent" data-user-id="2187">Greg Price</span></p>',
    const UserMentionNode(nodes: [TextNode('Greg Price')]));

  static final userMentionSilentClassOrderReversed = ContentExample.inline(
    'silent user @-mention, class order reversed',
    "@_**Greg Price**", // (hypothetical server variation)
    expectedText: 'Greg Price',
    '<p><span class="silent user-mention" data-user-id="2187">Greg Price</span></p>',
    const UserMentionNode(nodes: [TextNode('Greg Price')]));

  static final groupMentionPlain = ContentExample.inline(
    'plain group @-mention',
    "@*test-empty*",
    expectedText: '@test-empty',
    '<p><span class="user-group-mention" data-user-group-id="186">@test-empty</span></p>',
    const UserMentionNode(nodes: [TextNode('@test-empty')]));

  static final groupMentionSilent = ContentExample.inline(
    'silent group @-mention',
    "@_*test-empty*",
    expectedText: 'test-empty',
    '<p><span class="user-group-mention silent" data-user-group-id="186">test-empty</span></p>',
    const UserMentionNode(nodes: [TextNode('test-empty')]));

  static final groupMentionSilentClassOrderReversed = ContentExample.inline(
    'silent group @-mention, class order reversed',
    "@_*test-empty*", // (hypothetical server variation)
    expectedText: 'test-empty',
    '<p><span class="silent user-group-mention" data-user-group-id="186">test-empty</span></p>',
    const UserMentionNode(nodes: [TextNode('test-empty')]));

  static final channelWildcardMentionPlain = ContentExample.inline(
    'plain channel wildcard @-mention',
    "@**all**",
    expectedText: '@all',
    '<p><span class="user-mention channel-wildcard-mention" data-user-id="*">@all</span></p>',
    const UserMentionNode(nodes: [TextNode('@all')]));

  static final channelWildcardMentionSilent = ContentExample.inline(
    'silent channel wildcard @-mention',
    "@_**everyone**",
    expectedText: 'everyone',
    '<p><span class="user-mention channel-wildcard-mention silent" data-user-id="*">everyone</span></p>',
    const UserMentionNode(nodes: [TextNode('everyone')]));

  static final channelWildcardMentionSilentClassOrderReversed = ContentExample.inline(
    'silent channel wildcard @-mention, class order reversed',
    "@_**channel**", // (hypothetical server variation)
    expectedText: 'channel',
    '<p><span class="silent user-mention channel-wildcard-mention" data-user-id="*">channel</span></p>',
    const UserMentionNode(nodes: [TextNode('channel')]));

  static final legacyChannelWildcardMentionPlain = ContentExample.inline(
    'legacy plain channel wildcard @-mention',
    "@**channel**",
    expectedText: '@channel',
    '<p><span class="user-mention" data-user-id="*">@channel</span></p>',
    const UserMentionNode(nodes: [TextNode('@channel')]));

  static final legacyChannelWildcardMentionSilent = ContentExample.inline(
    'legacy silent channel wildcard @-mention',
    "@_**stream**",
    expectedText: 'stream',
    '<p><span class="user-mention silent" data-user-id="*">stream</span></p>',
    const UserMentionNode(nodes: [TextNode('stream')]));

  static final legacyChannelWildcardMentionSilentClassOrderReversed = ContentExample.inline(
    'legacy silent channel wildcard @-mention, class order reversed',
    "@_**all**", // (hypothetical server variation)
    expectedText: 'all',
    '<p><span class="silent user-mention" data-user-id="*">all</span></p>',
    const UserMentionNode(nodes: [TextNode('all')]));

  static final topicMentionPlain = ContentExample.inline(
    'plain @-topic',
    "@**topic**",
    expectedText: '@topic',
    '<p><span class="topic-mention">@topic</span></p>',
    const UserMentionNode(nodes: [TextNode('@topic')]));

  static final topicMentionSilent = ContentExample.inline(
    'silent @-topic',
    "@_**topic**",
    expectedText: 'topic',
    '<p><span class="topic-mention silent">topic</span></p>',
    const UserMentionNode(nodes: [TextNode('topic')]));

  static final topicMentionSilentClassOrderReversed = ContentExample.inline(
    'silent @-topic, class order reversed',
    "@_**topic**", // (hypothetical server variation)
    expectedText: 'topic',
    '<p><span class="silent topic-mention">topic</span></p>',
    const UserMentionNode(nodes: [TextNode('topic')]));

  static final emojiUnicode = ContentExample.inline(
    'Unicode emoji, encoded in span element',
    ":thumbs_up:",
    expectedText: '\u{1f44d}', // "👍"
    '<p><span aria-label="thumbs up" class="emoji emoji-1f44d" role="img" title="thumbs up">:thumbs_up:</span></p>',
    const UnicodeEmojiNode(emojiUnicode: '\u{1f44d}'));

  static final emojiUnicodeClassesFlipped = ContentExample.inline(
    'Unicode emoji, encoded in span element, class order reversed',
    null, // ":thumbs_up:" (hypothetical server variation)
    expectedText: '\u{1f44d}', // "👍"
    '<p><span aria-label="thumbs up" class="emoji-1f44d emoji" role="img" title="thumbs up">:thumbs_up:</span></p>',
    const UnicodeEmojiNode(emojiUnicode: '\u{1f44d}'));

  static final emojiUnicodeMultiCodepoint = ContentExample.inline(
    'Unicode emoji, encoded in span element, multiple codepoints',
    ":transgender_flag:",
    expectedText: '\u{1f3f3}\u{fe0f}\u{200d}\u{26a7}\u{fe0f}', // "🏳️‍⚧️"
    '<p><span aria-label="transgender flag" class="emoji emoji-1f3f3-fe0f-200d-26a7-fe0f" role="img" title="transgender flag">:transgender_flag:</span></p>',
    const UnicodeEmojiNode(emojiUnicode: '\u{1f3f3}\u{fe0f}\u{200d}\u{26a7}\u{fe0f}'));

  static final emojiUnicodeLiteral = ContentExample.inline(
    'Unicode emoji, not encoded in span element',
    "\u{1fabf}",
    expectedText: '\u{1fabf}', // "🪿"
    '<p>\u{1fabf}</p>',
    const TextNode('\u{1fabf}'));

  static final emojiCustom = ContentExample.inline(
    'custom emoji',
    ":flutter:",
    '<p><img alt=":flutter:" class="emoji" src="/user_avatars/2/emoji/images/204.png" title="flutter"></p>',
    const ImageEmojiNode(
      src: '/user_avatars/2/emoji/images/204.png', alt: ':flutter:'));

  static final emojiCustomInvalidUrl = ContentExample.inline(
    'custom emoji with invalid URL',
    null, // hypothetical, to test for a risk of crashing
    '<p><img alt=":invalid:" class="emoji" src="::not a URL::" title="invalid"></p>',
    const ImageEmojiNode(
      src: '::not a URL::', alt: ':invalid:'));

  static final emojiZulipExtra = ContentExample.inline(
    'Zulip extra emoji',
    ":zulip:",
    '<p><img alt=":zulip:" class="emoji" src="/static/generated/emoji/images/emoji/unicode/zulip.png" title="zulip"></p>',
    const ImageEmojiNode(
      src: '/static/generated/emoji/images/emoji/unicode/zulip.png', alt: ':zulip:'));

  static final globalTime = ContentExample.inline(
    'global time',
    "<time:2024-03-07T15:00:00-08:00>",
    '<p><time datetime="2024-03-07T23:00:00Z">2024-03-07T15:00:00-08:00</time></p>',
    GlobalTimeNode(
      datetime: DateTime.parse("2024-03-07T23:00:00Z")));

  static final messageLink = ContentExample.inline(
    'message link',
    '#**api design>notation for near links@1972281**',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/1976383
    '<p><a class="message-link" '
      'href="/#narrow/channel/378-api-design/topic/notation.20for.20near.20links/near/1972281">'
      '#api design &gt; notation for near links @ 💬</a></p>',
    const LinkNode(
      url: '/#narrow/channel/378-api-design/topic/notation.20for.20near.20links/near/1972281',
      nodes: [TextNode('#api design > notation for near links @ 💬')]));

  static const orderedListCustomStart = ContentExample(
    'ordered list with custom start',
    '5. fifth\n6. sixth',
    '<ol start="5">\n<li>fifth</li>\n<li>sixth</li>\n</ol>',
    [OrderedListNode(start: 5, [
      [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('fifth')])],
      [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('sixth')])],
    ])],
  );

  static const orderedListLargeStart = ContentExample(
    'ordered list with large start number',
    '9999. first\n10000. second',
    '<ol start="9999">\n<li>first</li>\n<li>second</li>\n</ol>',
    [OrderedListNode(start: 9999, [
      [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('first')])],
      [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('second')])],
    ])],
  );

  static const spoilerDefaultHeader = ContentExample(
    'spoiler with default header',
    '```spoiler\nhello world\n```',
    expectedText: 'Spoiler', // or a translation
    '<div class="spoiler-block"><div class="spoiler-header">\n'
        '</div><div class="spoiler-content" aria-hidden="true">\n'
        '<p>hello world</p>\n'
        '</div></div>',
    [SpoilerNode(
      header: [],
      content: [ParagraphNode(links: null, nodes: [TextNode('hello world')])],
    )]);

  static const spoilerPlainCustomHeader = ContentExample(
    'spoiler with plain custom header',
    '```spoiler hello\nworld\n```',
    expectedText: 'hello',
    '<div class="spoiler-block"><div class="spoiler-header">\n'
        '<p>hello</p>\n'
        '</div><div class="spoiler-content" aria-hidden="true">\n'
        '<p>world</p>\n'
        '</div></div>',
    [SpoilerNode(
      header: [ParagraphNode(links: null, nodes: [TextNode('hello')])],
      content: [ParagraphNode(links: null, nodes: [TextNode('world')])],
    )]);

  static const spoilerRichHeaderAndContent = ContentExample(
    'spoiler with rich header and content',
    '```spoiler 1. * ## hello\n*italic* [zulip](https://zulip.com/)\n```',
    expectedText: 'hello',
    '<div class="spoiler-block"><div class="spoiler-header">\n'
        '<ol>\n<li>\n<ul>\n<li>\n<h2>hello</h2>\n</li>\n</ul>\n</li>\n</ol>\n</div>'
        '<div class="spoiler-content" aria-hidden="true">\n'
        '<p><em>italic</em> <a href="https://zulip.com/">zulip</a></p>\n'
        '</div></div>',
    [SpoilerNode(
      header: [OrderedListNode(start: 1, [
        [UnorderedListNode([
          [HeadingNode(level: HeadingLevel.h2, links: null, nodes: [
            TextNode('hello'),
          ])]
        ])],
      ])],
      content: [ParagraphNode(links: null, nodes: [
        EmphasisNode(nodes: [TextNode('italic')]),
        TextNode(' '),
        LinkNode(url: 'https://zulip.com/', nodes: [TextNode('zulip')])
      ])],
    )]);

  static const spoilerHeaderHasImagePreview = ContentExample(
    'spoiler with a header that has an image preview in it',
    '```spoiler [image](https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3)\nhello world\n```',
    '<div class="spoiler-block"><div class="spoiler-header">\n'
      '<p><a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">image</a></p>\n'
      '<div class="message_inline_image"><a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3" title="image"><img src="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3"></a></div></div>'
      '<div class="spoiler-content" aria-hidden="true">\n'
      '<p>hello world</p>\n'
      '</div></div>\n',
    [SpoilerNode(
      header: [
        ParagraphNode(links: null, nodes: [
          LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3',
            nodes: [TextNode('image')]),
        ]),
        ImagePreviewNodeList([
          ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3',
            thumbnail: null, loading: false,
            originalWidth: null, originalHeight: null),
        ]),
      ],
      content: [ParagraphNode(links: null, nodes: [TextNode('hello world')])],
    )]);

  static const quotation = ContentExample(
    'quotation',
    "```quote\nwords\n```",
    expectedText: 'words',
    '<blockquote>\n<p>words</p>\n</blockquote>', [
      QuotationNode([ParagraphNode(links: null, nodes: [TextNode('words')])])
    ]);

  static const codeBlockPlain = ContentExample(
    'code block without syntax highlighting',
    "```\nverb\natim\n```",
    expectedText: 'verb\natim',
    '<div class="codehilite"><pre><span></span><code>verb\natim\n</code></pre></div>', [
      CodeBlockNode([
        CodeBlockSpanNode(text: 'verb\natim', type: CodeBlockSpanType.text),
      ]),
    ]);

  static const codeBlockHighlightedShort = ContentExample(
    'code block with syntax highlighting',
    "```dart\nclass A {}\n```",
    expectedText: 'class A {}',
    '<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="kd">class</span><span class="w"> </span>'
        '<span class="nc">A</span><span class="w"> </span><span class="p">{}</span>'
        '\n</code></pre></div>', [
      CodeBlockNode([
        CodeBlockSpanNode(text: 'class', type: CodeBlockSpanType.keywordDeclaration),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: 'A', type: CodeBlockSpanType.nameClass),
        CodeBlockSpanNode(text: ' ', type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: '{}', type: CodeBlockSpanType.punctuation),
      ]),
    ]);

  static const codeBlockHighlightedMultiline = ContentExample(
    'code block, multiline, with syntax highlighting',
    '```rust\nfn main() {\n    print!("Hello ");\n\n    print!("world!\\n");\n}\n```',
    expectedText: 'fn main() {\n    print!("Hello ");\n\n    print!("world!\\n");\n}',
    '<div class="codehilite" data-code-language="Rust"><pre>'
        '<span></span><code><span class="k">fn</span> <span class="nf">main</span>'
        '<span class="p">()</span><span class="w"> </span><span class="p">{</span>\n'
        '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
        '<span class="s">"Hello "</span><span class="p">);</span>\n\n'
        '<span class="w">    </span><span class="fm">print!</span><span class="p">(</span>'
        '<span class="s">"world!</span><span class="se">\\n</span><span class="s">"</span>'
        '<span class="p">);</span>\n<span class="p">}</span>\n'
        '</code></pre></div>', [
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

  static const codeBlockSpansWithMultipleClasses = ContentExample(
    'code block spans with multiple CSS classes',
    '```yaml\n- item\n```',
    expectedText: '- item',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Greg/near/1949014
    '<div class="codehilite" data-code-language="YAML">'
        '<pre><span></span><code><span class="p p-Indicator">-</span>'
        '<span class="w"> </span>'
        '<span class="l l-Scalar l-Scalar-Plain">item</span>\n'
        '</code></pre></div>', [
      CodeBlockNode([
        CodeBlockSpanNode(text: "-", type: CodeBlockSpanType.punctuation),
        CodeBlockSpanNode(text: " ", type: CodeBlockSpanType.whitespace),
        CodeBlockSpanNode(text: "item", type: CodeBlockSpanType.literal)
      ]),
    ]);

  // Current servers no longer produce this, but it can be found in ancient
  // messages.  For example:
  //   https://chat.zulip.org/#narrow/stream/2-general/topic/Error.20in.20dev.20server/near/18765
  static final codeBlockWithEmptyBody = ContentExample(
      'code block, with an empty body',
      '```',
      '<div class="codehilite"><pre></pre></div>', [
      blockUnimplemented(
          '<div class="codehilite"><pre></pre></div>'),
  ]);

  static final codeBlockWithHighlightedLines = ContentExample(
    'code block, with syntax highlighting and highlighted lines',
    '```\n::markdown hl_lines="2 4"\n# he\n## llo\n### world\n```',
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

  static final codeBlockWithUnknownSpanType = ContentExample(
    'code block, with an unknown span type',
    null, // this test is for future Pygments versions adding new token types
    '<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="unknown">class</span>'
        '\n</code></pre></div>', [
      blockUnimplemented('<div class="codehilite" data-code-language="Dart"><pre>'
        '<span></span><code><span class="unknown">class</span>'
        '\n</code></pre></div>'),
    ]);

  static const codeBlockFollowedByMultipleLineBreaks = ContentExample(
    'blank text nodes after code blocks',
    '    code block.\n\nsome content',
    // https://chat.zulip.org/#narrow/stream/7-test-here/near/1774823
    '<div class="codehilite">'
      '<pre><span></span><code>code block.\n</code></pre></div>\n\n'
    '<p>some content</p>', [
      CodeBlockNode([CodeBlockSpanNode(text: "code block.", type: CodeBlockSpanType.text)]),
      ParagraphNode(links: null, nodes: [TextNode("some content")]),
    ]);

  static final mathInline = ContentExample.inline(
    'inline math',
    r"$$ \lambda $$",
    expectedText: r'λ',
    '<p><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></p>',
    MathInlineNode(texSource: r'\lambda', nodes: [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(
            fontFamily: 'KaTeX_Math',
            fontStyle: KatexSpanFontStyle.italic),
          text: 'λ'),
      ]),
    ]));

  // A test message to test the fallback behaviour of KaTeX implementation.
  static final mathInlineUnknown = ContentExample.inline(
    'inline math',
    null, // r"$$ \lambda $$" (hypothetical server variation)
    expectedText: r'\lambda',
    '<p><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true">'
        '<span class="base unknown">' // Server doesn't generate this 'unknown' class.
        '<span class="strut" style="height:0.6944em;"></span>'
        '<span class="mord mathnormal">λ</span></span></span></span></p>',
    MathInlineNode(texSource: r'\lambda', nodes: null));

  static const mathBlock = ContentExample(
    'math block',
    "```math\n\\lambda\n```",
    expectedText: r'λ',
    '<p><span class="katex-display"><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span></p>',
    [MathBlockNode(texSource: r'\lambda', nodes: [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(
            fontFamily: 'KaTeX_Math',
            fontStyle: KatexSpanFontStyle.italic),
          text: 'λ'),
      ]),
    ])]);

  // A test message to test the fallback behaviour of KaTeX implementation.
  static const mathBlockUnknown = ContentExample(
    'math block unknown, fallback to TeX source',
    null, // r"```math\n\lambda\n```" (hypothetical server variation)
    expectedText: r'\lambda',
    '<p><span class="katex-display"><span class="katex">'
      '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
        '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true">'
        '<span class="base unknown">' // Server doesn't generate this 'unknown' class.
          '<span class="strut" style="height:0.6944em;"></span>'
          '<span class="mord mathnormal">λ</span></span></span></span></span></p>',
    [MathBlockNode(texSource: r'\lambda', nodes: null)]);

  static const mathBlocksMultipleInParagraph = ContentExample(
    'math blocks, multiple in paragraph',
    '```math\na\n\nb\n```',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/2001490
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>a</mi></mrow>'
          '<annotation encoding="application/x-tex">a</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.4306em;"></span><span class="mord mathnormal">a</span></span></span></span></span>\n\n'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>b</mi></mrow>'
          '<annotation encoding="application/x-tex">b</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">b</span></span></span></span></span></p>', [
      MathBlockNode(texSource: 'a', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.4306, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'a'),
        ]),
      ]),
      MathBlockNode(texSource: 'b', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'b'),
        ]),
      ]),
    ]);

  static const mathBlockInQuote = ContentExample(
    'math block in quote',
    // There's sometimes a quirky extra `<br>\n` at the end of the `<p>` that
    // encloses the math block.  In particular this happens when the math block
    // is the last thing in the quote; though not in a doubly-nested quote;
    // and there might be further wrinkles yet to be found.  Some experiments:
    //   https://chat.zulip.org/#narrow/stream/7-test-here/topic/content/near/1715732
    "````quote\n```math\n\\lambda\n```\n````",
    '<blockquote>\n<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span>'
      '<br>\n</p>\n</blockquote>',
    [QuotationNode([
      MathBlockNode(texSource: r'\lambda', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'λ'),
        ]),
      ]),
    ])]);

  static const mathBlocksMultipleInQuote = ContentExample(
    'math blocks, multiple in quote',
    "````quote\n```math\na\n\nb\n```\n````",
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/2029236
    '<blockquote>\n<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>a</mi></mrow>'
          '<annotation encoding="application/x-tex">a</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.4306em;"></span><span class="mord mathnormal">a</span></span></span></span></span>'
      '\n\n'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>b</mi></mrow>'
          '<annotation encoding="application/x-tex">b</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">b</span></span></span></span></span>'
      '<br>\n</p>\n</blockquote>',
    [QuotationNode([
      MathBlockNode(texSource: 'a', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.4306, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'a'),
        ]),
      ]),
      MathBlockNode(texSource: 'b', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'b'),
        ]),
      ]),
    ])]);

  static const mathBlockBetweenImagePreviews = ContentExample(
    'math block between image previews',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Greg/near/2035891
    'https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg\n```math\na\n```\nhttps://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Zaadpluizen_van_een_Clematis_texensis_%27Princess_Diana%27._18-07-2023_%28actm.%29_02.jpg/1280px-Zaadpluizen_van_een_Clematis_texensis_%27Princess_Diana%27._18-07-2023_%28actm.%29_02.jpg',
    '<div class="message_inline_image">'
      '<a href="https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg">'
        '<img src="/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067"></a></div>'
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>a</mi></mrow>'
          '<annotation encoding="application/x-tex">a</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.4306em;"></span><span class="mord mathnormal">a</span></span></span></span></span>'
    '</p>\n'
    '<div class="message_inline_image">'
      '<a href="https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Zaadpluizen_van_een_Clematis_texensis_%27Princess_Diana%27._18-07-2023_%28actm.%29_02.jpg/1280px-Zaadpluizen_van_een_Clematis_texensis_%27Princess_Diana%27._18-07-2023_%28actm.%29_02.jpg">'
        '<img src="/external_content/58b0ef9a06d7bb24faec2b11df2f57f476e6f6bb/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f7468756d622f372f37312f5a616164706c75697a656e5f76616e5f65656e5f436c656d617469735f746578656e7369735f2532375072696e636573735f4469616e612532372e5f31382d30372d323032335f2532386163746d2e2532395f30322e6a70672f3132383070782d5a616164706c75697a656e5f76616e5f65656e5f436c656d617469735f746578656e7369735f2532375072696e636573735f4469616e612532372e5f31382d30372d323032335f2532386163746d2e2532395f30322e6a7067"></a></div>',
    [
      ImagePreviewNodeList([
        ImagePreviewNode(
          srcUrl: '/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067',
          thumbnail: null,
          loading: false,
          originalWidth: null,
          originalHeight: null),
      ]),
      MathBlockNode(texSource: 'a', nodes: [
        KatexSpanNode(nodes: [
          KatexStrutNode(heightEm: 0.4306, verticalAlignEm: null),
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math',
              fontStyle: KatexSpanFontStyle.italic),
            text: 'a'),
        ]),
      ]),
      ImagePreviewNodeList([
        ImagePreviewNode(
          srcUrl: '/external_content/58b0ef9a06d7bb24faec2b11df2f57f476e6f6bb/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f7468756d622f372f37312f5a616164706c75697a656e5f76616e5f65656e5f436c656d617469735f746578656e7369735f2532375072696e636573735f4469616e612532372e5f31382d30372d323032335f2532386163746d2e2532395f30322e6a70672f3132383070782d5a616164706c75697a656e5f76616e5f65656e5f436c656d617469735f746578656e7369735f2532375072696e636573735f4469616e612532372e5f31382d30372d323032335f2532386163746d2e2532395f30322e6a7067',
          thumbnail: null,
          loading: false,
          originalWidth: null,
          originalHeight: null),
      ]),
    ]);

  static final imagePreviewSingle = ContentExample(
    'single image preview',
    // https://chat.zulip.org/#narrow/stream/7-test-here/topic/Thumbnails/near/1900103
    "[image.jpg](/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg)",
    '<div class="message_inline_image">'
      '<a href="/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg" title="image.jpg">'
        '<img data-original-dimensions="6000x4000" src="/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg',
        thumbnail: ImageThumbnailLocator(animated: false,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp')),
        loading: false,
        originalWidth: 6000,
        originalHeight: 4000),
    ]),
  ]);

  static final imagePreviewSingleAnimated = ContentExample(
    'single image preview, animated',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Thumbnails/near/2298790
    "[2c8d985d.gif](/user_uploads/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif)",
    '<div class="message_inline_image">'
      '<a href="/user_uploads/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif" title="2c8d985d.gif">'
        '<img data-animated="true" data-original-content-type="image/gif" data-original-dimensions="64x64" src="/user_uploads/thumbnail/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif/840x560-anim.webp"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif',
        thumbnail: ImageThumbnailLocator(animated: true,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/9f/tZ9c5ZmsI_cSDZ6ZdJmW8pt4/2c8d985d.gif/840x560-anim.webp')),
        loading: false,
        originalWidth: 64,
        originalHeight: 64),
    ]),
  ]);

  static final imagePreviewSingleNoDimensions = ContentExample(
    'single image preview no dimensions',
    // https://chat.zulip.org/#narrow/stream/7-test-here/topic/Thumbnails/near/1893590
    "[image.jpg](/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg)",
    '<div class="message_inline_image">'
      '<a href="/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg" title="image.jpg">'
        '<img src="/user_uploads/thumbnail/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg/840x560.webp"/></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg',
        thumbnail: ImageThumbnailLocator(animated: false,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg/840x560.webp')),
        loading: false,
        originalWidth: null,
        originalHeight: null),
    ]),
  ]);

  static const imagePreviewSingleNoThumbnail = ContentExample(
    'single image preview no thumbnail',
    "https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3",
    '<div class="message_inline_image">'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">'
        '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewSingleLoadingPlaceholder = ContentExample(
    'single image preview loading placeholder',
    // https://chat.zulip.org/#narrow/stream/7-test-here/topic/Thumbnails/near/1893590
    "[image.jpg](/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg)",
    '<div class="message_inline_image">'
      '<a href="/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg" title="image.jpg">'
        '<img class="image-loading-placeholder" src="/static/images/loading/loader-black.svg"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/c3/wb9FXk8Ej6qIc28aWKcqUogD/image.jpg',
        thumbnail: null, loading: true,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewSingleExternal1 = ContentExample(
    'single image preview external, src starts with /external_content',
    // https://chat.zulip.org/#narrow/stream/7-test-here/topic/Greg/near/1892172
    "https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg",
    '<div class="message_inline_image">'
      '<a href="https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg">'
      '<img src="/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/external_content/de28eb3abf4b7786de4545023dc42d434a2ea0c2/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewSingleExternal2 = ContentExample(
    'single image preview external, src starts with https://uploads.zulipusercontent.net/',
    // Zulip Cloud has CAMO_URI = "https://uploads.zulipusercontent.net/";
    // this example is from a DM on a closed Zulip Cloud org.
    "https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg",
    '<div class="message_inline_image">'
      '<a href="https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg">'
      '<img src="https://uploads.zulipusercontent.net/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewSingleExternal3 = ContentExample(
    'single image preview external, src starts with https://custom.camo-uri.example/',
    // CAMO_URI (server variable) can be set arbitrarily;
    // for another possible value, see imagePreviewSingleExternal2.
    "https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg",
    '<div class="message_inline_image">'
      '<a href="https://upload.wikimedia.org/wikipedia/commons/7/78/Verregende_bloem_van_een_Helenium_%27El_Dorado%27._22-07-2023._%28d.j.b%29.jpg">'
      '<img src="https://custom.camo-uri.example/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://custom.camo-uri.example/99742b0f992be15283c428dd42f3b9f5db138d69/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f372f37382f566572726567656e64655f626c6f656d5f76616e5f65656e5f48656c656e69756d5f253237456c5f446f7261646f2532372e5f32322d30372d323032332e5f253238642e6a2e622532392e6a7067',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewInvalidUrl = ContentExample(
    'single image preview with invalid URL',
    null, // hypothetical, to test for a risk of crashing
    '<div class="message_inline_image">'
      '<a href="::not a URL::">'
        '<img src="::not a URL::"></a></div>', [
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '::not a URL::',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static final imagePreviewCluster = ContentExample(
    'multiple image previews',
    // https://chat.zulip.org/#narrow/stream/7-test-here/topic/Thumbnails/near/1893154
    "[image.jpg](/user_uploads/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg)\n[image2.jpg](/user_uploads/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg)",
    '<p>'
      '<a href="/user_uploads/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg">image.jpg</a><br/>\n'
      '<a href="/user_uploads/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg">image2.jpg</a></p>\n'
        '<div class="message_inline_image">'
          '<a href="/user_uploads/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg" title="image.jpg">'
            '<img src="/user_uploads/thumbnail/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg/840x560.webp"/></a></div>'
        '<div class="message_inline_image">'
          '<a href="/user_uploads/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg" title="image2.jpg">'
            '<img src="/user_uploads/thumbnail/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg/840x560.webp"/></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: '/user_uploads/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg', nodes: [TextNode('image.jpg')]),
      LineBreakInlineNode(),
      TextNode('\n'),
      LinkNode(url: '/user_uploads/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg', nodes: [TextNode('image2.jpg')]),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg',
        thumbnail: ImageThumbnailLocator(animated: false,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/9b/WkDt2Qsy79iwf3sM9EMp9fYL/image.jpg/840x560.webp')),
        loading: false,
        originalWidth: null,
        originalHeight: null),
      ImagePreviewNode(srcUrl: '/user_uploads/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg',
        thumbnail: ImageThumbnailLocator(animated: false,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/70/pVeI52TwFUEoFE2qT_u9AMCO/image2.jpg/840x560.webp')),
        loading: false,
        originalWidth: null,
        originalHeight: null),
    ]),
  ]);

  static const imagePreviewClusterNoThumbnails = ContentExample(
    'multiple image previews no thumbnails',
    "https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3\nhttps://chat.zulip.org/user_avatars/2/realm/icon.png?version=4",
    '<p>'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3</a><br>\n'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=4">https://chat.zulip.org/user_avatars/2/realm/icon.png?version=4</a></p>\n'
    '<div class="message_inline_image">'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3">'
        '<img src="https://uploads.zulipusercontent.net/f535ba07f95b99a83aa48e44fd62bbb6c6cf6615/68747470733a2f2f636861742e7a756c69702e6f72672f757365725f617661746172732f322f7265616c6d2f69636f6e2e706e673f76657273696f6e3d33"></a></div>'
    '<div class="message_inline_image">'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=4">'
        '<img src="https://uploads.zulipusercontent.net/8f63bc2632a0e41be3f457d86c077e61b4a03e7e/68747470733a2f2f636861742e7a756c69702e6f72672f757365725f617661746172732f322f7265616c6d2f69636f6e2e706e673f76657273696f6e3d34"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3', nodes: [TextNode('https://chat.zulip.org/user_avatars/2/realm/icon.png?version=3')]),
      LineBreakInlineNode(),
      TextNode('\n'),
      LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=4', nodes: [TextNode('https://chat.zulip.org/user_avatars/2/realm/icon.png?version=4')]),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/f535ba07f95b99a83aa48e44fd62bbb6c6cf6615/68747470733a2f2f636861742e7a756c69702e6f72672f757365725f617661746172732f322f7265616c6d2f69636f6e2e706e673f76657273696f6e3d33',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/8f63bc2632a0e41be3f457d86c077e61b4a03e7e/68747470733a2f2f636861742e7a756c69702e6f72672f757365725f617661746172732f322f7265616c6d2f69636f6e2e706e673f76657273696f6e3d34',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewClusterThenContent = ContentExample(
    'content after image preview cluster',
    "https://chat.zulip.org/user_avatars/2/realm/icon.png\nhttps://chat.zulip.org/user_avatars/2/realm/icon.png?version=2\n\nmore content",
    '<p>content '
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png">icon.png</a> '
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2">icon.png</a></p>\n'
    '<div class="message_inline_image">'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png" title="icon.png">'
        '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png"></a></div>'
    '<div class="message_inline_image">'
      '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2" title="icon.png">'
        '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2"></a></div>'
    '<p>more content</p>', [
    ParagraphNode(links: null, nodes: [
      TextNode('content '),
      LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png', nodes: [TextNode('icon.png')]),
      TextNode(' '),
      LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2', nodes: [TextNode('icon.png')]),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
      ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
    ParagraphNode(links: null, nodes: [
      TextNode('more content'),
    ]),
  ]);

  static const imagePreviewMultipleClusters = ContentExample(
    'multiple clusters of image previews',
    "https://en.wikipedia.org/static/images/icons/wikipedia.png\nhttps://en.wikipedia.org/static/images/icons/wikipedia.png?v=1\n\nTest\n\nhttps://en.wikipedia.org/static/images/icons/wikipedia.png?v=2\nhttps://en.wikipedia.org/static/images/icons/wikipedia.png?v=3",
    '<p>'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png">https://en.wikipedia.org/static/images/icons/wikipedia.png</a><br>\n' '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=1">https://en.wikipedia.org/static/images/icons/wikipedia.png?v=1</a></p>\n'
    '<div class="message_inline_image">'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png">'
        '<img src="https://uploads.zulipusercontent.net/34b2695ca83af76204b0b25a8f2019ee35ec38fa/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e67"></a></div>'
    '<div class="message_inline_image">'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=1">'
        '<img src="https://uploads.zulipusercontent.net/d200fb112aaccbff9df767373a201fa59601f362/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d31"></a></div>'
    '<p>Test</p>\n'
    '<p>'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=2">https://en.wikipedia.org/static/images/icons/wikipedia.png?v=2</a><br>\n'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=3">https://en.wikipedia.org/static/images/icons/wikipedia.png?v=3</a></p>\n'
    '<div class="message_inline_image">'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=2">'
        '<img src="https://uploads.zulipusercontent.net/c4db87e81348dac94eacaa966b46d968b34029cc/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d32"></a></div>'
    '<div class="message_inline_image">'
      '<a href="https://en.wikipedia.org/static/images/icons/wikipedia.png?v=3">'
        '<img src="https://uploads.zulipusercontent.net/51b70540cf6a5b3c8a0b919c893b8abddd447e88/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d33"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://en.wikipedia.org/static/images/icons/wikipedia.png', nodes: [TextNode('https://en.wikipedia.org/static/images/icons/wikipedia.png')]),
      LineBreakInlineNode(),
      TextNode('\n'),
      LinkNode(url: 'https://en.wikipedia.org/static/images/icons/wikipedia.png?v=1', nodes: [TextNode('https://en.wikipedia.org/static/images/icons/wikipedia.png?v=1')]),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/34b2695ca83af76204b0b25a8f2019ee35ec38fa/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e67',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/d200fb112aaccbff9df767373a201fa59601f362/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d31',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
    ParagraphNode(links: null, nodes: [
      TextNode('Test'),
    ]),
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://en.wikipedia.org/static/images/icons/wikipedia.png?v=2', nodes: [TextNode('https://en.wikipedia.org/static/images/icons/wikipedia.png?v=2')]),
      LineBreakInlineNode(),
      TextNode('\n'),
      LinkNode(url: 'https://en.wikipedia.org/static/images/icons/wikipedia.png?v=3', nodes: [TextNode('https://en.wikipedia.org/static/images/icons/wikipedia.png?v=3')]),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/c4db87e81348dac94eacaa966b46d968b34029cc/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d32',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
      ImagePreviewNode(srcUrl: 'https://uploads.zulipusercontent.net/51b70540cf6a5b3c8a0b919c893b8abddd447e88/68747470733a2f2f656e2e77696b6970656469612e6f72672f7374617469632f696d616765732f69636f6e732f77696b6970656469612e706e673f763d33',
        thumbnail: null, loading: false,
        originalWidth: null, originalHeight: null),
    ]),
  ]);

  static const imagePreviewInImplicitParagraph = ContentExample(
    'image preview as immediate child in implicit paragraph',
    "* https://chat.zulip.org/user_avatars/2/realm/icon.png",
    '<ul>\n'
      '<li>'
        '<div class="message_inline_image">'
          '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png">'
            '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png"></a></div></li>\n</ul>', [
    UnorderedListNode([[
      ImagePreviewNodeList([
        ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png',
          thumbnail: null, loading: false,
          originalWidth: null, originalHeight: null),
      ]),
    ]]),
  ]);

  static const imagePreviewClusterInImplicitParagraph = ContentExample(
    'image preview cluster in implicit paragraph',
    "* [icon.png](https://chat.zulip.org/user_avatars/2/realm/icon.png) [icon.png](https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2)",
    '<ul>\n'
      '<li>'
        '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png">icon.png</a> '
        '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2">icon.png</a>'
        '<div class="message_inline_image">'
          '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png" title="icon.png">'
            '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png"></a></div>'
        '<div class="message_inline_image">'
          '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2" title="icon.png">'
            '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2"></a></div></li>\n</ul>', [
    UnorderedListNode([[
      ParagraphNode(wasImplicit: true, links: null, nodes: [
        LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png', nodes: [TextNode('icon.png')]),
        TextNode(' '),
        LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2', nodes: [TextNode('icon.png')]),
      ]),
      ImagePreviewNodeList([
        ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png',
          thumbnail: null, loading: false,
          originalWidth: null, originalHeight: null),
        ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png?version=2',
          thumbnail: null, loading: false,
          originalWidth: null, originalHeight: null),
      ]),
    ]]),
  ]);

  static final imagePreviewClusterInImplicitParagraphThenContent = ContentExample(
    'impossible content after image preview cluster in implicit paragraph',
    // Image previews are always inserted at the end of the paragraph
    //  so it would be impossible to have content after.
    null,
    '<ul>\n'
      '<li>'
        '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png">icon.png</a> '
        '<div class="message_inline_image">'
          '<a href="https://chat.zulip.org/user_avatars/2/realm/icon.png" title="icon.png">'
            '<img src="https://chat.zulip.org/user_avatars/2/realm/icon.png"></a></div>'
        'more text</li>\n</ul>', [
    UnorderedListNode([[
      const ParagraphNode(wasImplicit: true, links: null, nodes: [
        LinkNode(url: 'https://chat.zulip.org/user_avatars/2/realm/icon.png', nodes: [TextNode('icon.png')]),
        TextNode(' '),
      ]),
      const ImagePreviewNodeList([
        ImagePreviewNode(srcUrl: 'https://chat.zulip.org/user_avatars/2/realm/icon.png',
          thumbnail: null, loading: false,
          originalWidth: null, originalHeight: null),
      ]),
      blockUnimplemented('more text'),
    ]]),
  ]);

  static const thematicBreak =  ContentExample(
    'parse thematic break (<hr>)',
    // https://chat.zulip.org/#narrow/stream/7-test-here/near/1774718
    'a\n---\nb',
    '<p>a</p>\n<hr>\n<p>b</p>',
    [
      ParagraphNode(links: null, nodes: [TextNode('a')]),
      ThematicBreakNode(),
      ParagraphNode(links: null, nodes: [TextNode('b')]),
    ]);

  static const videoEmbedYoutube = ContentExample(
    'video preview for youtube embed with thumbnail',
    'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
    '<p>'
      '<a href="https://www.youtube.com/watch?v=aqz-KE-bpKQ">https://www.youtube.com/watch?v=aqz-KE-bpKQ</a>'
    '</p>\n'
    '<div class="youtube-video message_inline_image">'
      '<a data-id="aqz-KE-bpKQ" href="https://www.youtube.com/watch?v=aqz-KE-bpKQ">'
        '<img src="/external_content/ecb96e8f884f481c4bc0179287a44ab9014aa78f/68747470733a2f2f692e7974696d672e636f6d2f76692f61717a2d4b452d62704b512f64656661756c742e6a7067"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ', nodes: [TextNode('https://www.youtube.com/watch?v=aqz-KE-bpKQ')]),
    ]),
    EmbedVideoNode(
      hrefUrl: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
      previewImageSrcUrl: '/external_content/ecb96e8f884f481c4bc0179287a44ab9014aa78f/68747470733a2f2f692e7974696d672e636f6d2f76692f61717a2d4b452d62704b512f64656661756c742e6a7067'
    ),
  ]);

  static const videoEmbedYoutubeClassesFlipped = ContentExample(
    'video preview for youtube embed with thumbnail, (hypothetical) class name reorder',
    null, // "https://www.youtube.com/watch?v=aqz-KE-bpKQ" (hypothetical server variation)
    '<p>'
      '<a href="https://www.youtube.com/watch?v=aqz-KE-bpKQ">https://www.youtube.com/watch?v=aqz-KE-bpKQ</a>'
    '</p>\n'
    '<div class="message_inline_image youtube-video">'
      '<a data-id="aqz-KE-bpKQ" href="https://www.youtube.com/watch?v=aqz-KE-bpKQ">'
        '<img src="/external_content/ecb96e8f884f481c4bc0179287a44ab9014aa78f/68747470733a2f2f692e7974696d672e636f6d2f76692f61717a2d4b452d62704b512f64656661756c742e6a7067"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ', nodes: [TextNode('https://www.youtube.com/watch?v=aqz-KE-bpKQ')]),
    ]),
    EmbedVideoNode(
      hrefUrl: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
      previewImageSrcUrl: '/external_content/ecb96e8f884f481c4bc0179287a44ab9014aa78f/68747470733a2f2f692e7974696d672e636f6d2f76692f61717a2d4b452d62704b512f64656661756c742e6a7067'
    ),
  ]);

  static const videoEmbedVimeoPreviewDisabled = ContentExample(
    'video non-preview for attempted vimeo embed with realm link previews disabled',
    'https://vimeo.com/1084537',
    '<p>'
      '<a href="https://vimeo.com/1084537">https://vimeo.com/1084537</a></p>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://vimeo.com/1084537', nodes: [TextNode('https://vimeo.com/1084537')]),
    ]),
  ]);

  static const videoEmbedVimeo = ContentExample(
    'video preview for vimeo embed with realm link previews enabled',
    'https://vimeo.com/1084537',
    // The server really does generate an attribute called "data-id" whose value
    // is a blob of HTML.  The web client uses this to show Vimeo's video player
    // inside a sandbox iframe.  The HTML comes from Vimeo and may change form;
    // that's OK the way web uses it, but we shouldn't try to parse it.  See:
    //   https://chat.zulip.org/#narrow/stream/9-issues/topic/Vimeo.20link.20previews.20HTML.20.22data-id.22.20isn't.20a.20.20Vimeo.20video.20ID/near/1767563
    '<p>'
      '<a href="https://vimeo.com/1084537">Vimeo - Big Buck Bunny</a>'
    '</p>\n'
    '<div class="embed-video message_inline_image">'
      '<a data-id="&lt;iframe src=&quot;https://player.vimeo.com/video/1084537?app_id=122963&quot; width=&quot;640&quot; height=&quot;360&quot; frameborder=&quot;0&quot; allow=&quot;autoplay; fullscreen; picture-in-picture; clipboard-write&quot; title=&quot;Big Buck Bunny&quot;&gt;&lt;/iframe&gt;" href="https://vimeo.com/1084537" title="Big Buck Bunny">'
        '<img src="https://uploads.zulipusercontent.net/75aed2df4a1e8657176fcd6159fc40876ace4070/68747470733a2f2f692e76696d656f63646e2e636f6d2f766964656f2f32303936333634392d663032383137343536666334386537633331376566346330376261323539636434623430613336343962643865623530613434313862353965633366356166352d645f363430"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://vimeo.com/1084537', nodes: [TextNode('Vimeo - Big Buck Bunny')]),
    ]),
    EmbedVideoNode(
      hrefUrl: 'https://vimeo.com/1084537',
      previewImageSrcUrl: 'https://uploads.zulipusercontent.net/75aed2df4a1e8657176fcd6159fc40876ace4070/68747470733a2f2f692e76696d656f63646e2e636f6d2f766964656f2f32303936333634392d663032383137343536666334386537633331376566346330376261323539636434623430613336343962643865623530613434313862353965633366356166352d645f363430'
    ),
  ]);

  static const videoEmbedVimeoClassesFlipped = ContentExample(
    'video preview for vimeo embed with realm link previews enabled, (hypothetical) class name reorder',
    'https://vimeo.com/1084537',
    '<p>'
      '<a href="https://vimeo.com/1084537">Vimeo - Big Buck Bunny</a>'
    '</p>\n'
    '<div class="message_inline_image embed-video">'
      '<a data-id="&lt;iframe src=&quot;https://player.vimeo.com/video/1084537?app_id=122963&quot; width=&quot;640&quot; height=&quot;360&quot; frameborder=&quot;0&quot; allow=&quot;autoplay; fullscreen; picture-in-picture; clipboard-write&quot; title=&quot;Big Buck Bunny&quot;&gt;&lt;/iframe&gt;" href="https://vimeo.com/1084537" title="Big Buck Bunny">'
        '<img src="https://uploads.zulipusercontent.net/75aed2df4a1e8657176fcd6159fc40876ace4070/68747470733a2f2f692e76696d656f63646e2e636f6d2f766964656f2f32303936333634392d663032383137343536666334386537633331376566346330376261323539636434623430613336343962643865623530613434313862353965633366356166352d645f363430"></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: 'https://vimeo.com/1084537', nodes: [TextNode('Vimeo - Big Buck Bunny')]),
    ]),
    EmbedVideoNode(
      hrefUrl: 'https://vimeo.com/1084537',
      previewImageSrcUrl: 'https://uploads.zulipusercontent.net/75aed2df4a1e8657176fcd6159fc40876ace4070/68747470733a2f2f692e76696d656f63646e2e636f6d2f766964656f2f32303936333634392d663032383137343536666334386537633331376566346330376261323539636434623430613336343962643865623530613434313862353965633366356166352d645f363430'
    ),
  ]);

  static const videoInline = ContentExample(
    'video preview for user uploaded video',
    '[Big-Buck-Bunny.webm](/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm)',
    '<p>'
      '<a href="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm">Big-Buck-Bunny.webm</a>'
    '</p>\n'
    '<div class="message_inline_image message_inline_video">'
      '<a href="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm" title="Big-Buck-Bunny.webm">'
        '<video preload="metadata" src="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm"></video></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: '/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm', nodes: [TextNode('Big-Buck-Bunny.webm')]),
    ]),
    InlineVideoNode(srcUrl: '/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm'),
  ]);

  static const videoInlineClassesFlipped = ContentExample(
    'video preview for user uploaded video, (hypothetical) class name reorder',
    '[Big-Buck-Bunny.webm](/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm)',
    '<p>'
      '<a href="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm">Big-Buck-Bunny.webm</a>'
    '</p>\n'
    '<div class="message_inline_video message_inline_image">'
      '<a href="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm" title="Big-Buck-Bunny.webm">'
        '<video preload="metadata" src="/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm"></video></a></div>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: '/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm', nodes: [TextNode('Big-Buck-Bunny.webm')]),
    ]),
    InlineVideoNode(srcUrl: '/user_uploads/2/78/_KoRecCHZTFrVtyTKCkIh5Hq/Big-Buck-Bunny.webm'),
  ]);

  static const audioInline = ContentExample(
    'audio inline',
    '![crab-rave.mp3](/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3)',
    '<p><audio controls preload="metadata" src="/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3" title="crab-rave.mp3"></audio></p>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: '/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3', nodes: [TextNode('crab-rave.mp3')]),
    ]),
  ]);

  static const audioInlineNoTitle = ContentExample(
    'audio inline no title',
    '![](/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3)',
    '<p><audio controls preload="metadata" src="/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3"></audio></p>', [
    ParagraphNode(links: null, nodes: [
      LinkNode(url: '/user_uploads/2/f2/a_WnijOXIeRnI6OSxo9F6gZM/crab-rave.mp3', nodes: [TextNode('crab-rave.mp3')]),
    ]),
  ]);

  static const websitePreviewSmoke = ContentExample(
    'website preview smoke',
    'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html',
    '<p><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html">https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html</a></p>\n'
    '<div class="message_embed">'
      '<a class="message_embed_image" href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html" style="background-image: url(&quot;https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67&quot;)"></a>'
      '<div class="data-container">'
        '<div class="message_embed_title"><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html" title="Zulip — organized team chat">Zulip — organized team chat</a></div>'
        '<div class="message_embed_description">Zulip is an organized team chat app for distributed teams of all sizes.</div></div></div>', [
    ParagraphNode(links: [], nodes: [
      LinkNode(
        nodes: [TextNode('https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html')],
        url: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html'),
    ]),
    WebsitePreviewNode(
      hrefUrl: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title+description.html',
      imageSrcUrl: 'https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67',
      title: 'Zulip — organized team chat',
      description: 'Zulip is an organized team chat app for distributed teams of all sizes.'),
  ]);

  static const websitePreviewWithoutTitle = ContentExample(
    'website preview without title',
    'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html',
    '<p><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html">https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html</a></p>\n'
    '<div class="message_embed">'
      '<a class="message_embed_image" href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html" style="background-image: url(&quot;https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67&quot;)"></a>'
      '<div class="data-container">'
        '<div class="message_embed_description">Zulip is an organized team chat app for distributed teams of all sizes.</div></div></div>', [
    ParagraphNode(links: [], nodes: [
      LinkNode(
        nodes: [TextNode('https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html')],
        url: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html'),
    ]),
    WebsitePreviewNode(
      hrefUrl: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+description+notitle.html',
      imageSrcUrl: 'https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67',
      title: null,
      description: 'Zulip is an organized team chat app for distributed teams of all sizes.'),
  ]);

  static const websitePreviewWithoutDescription = ContentExample(
    'website preview without description',
    'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html',
    '<p><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html">https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html</a></p>\n'
    '<div class="message_embed">'
      '<a class="message_embed_image" href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html" style="background-image: url(&quot;https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67&quot;)"></a>'
      '<div class="data-container">'
        '<div class="message_embed_title"><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html" title="Zulip — organized team chat">Zulip — organized team chat</a></div></div></div>', [
    ParagraphNode(links: [], nodes: [
      LinkNode(
        nodes: [TextNode('https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html')],
        url: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html'),
    ]),
    WebsitePreviewNode(
      hrefUrl: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+title.html',
      imageSrcUrl: 'https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67',
      title: 'Zulip — organized team chat',
      description: null),
  ]);

  static const websitePreviewWithoutTitleOrDescription = ContentExample(
    'website preview without title and description',
    'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html',
    '<p><a href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html">https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html</a></p>\n'
    '<div class="message_embed">'
      '<a class="message_embed_image" href="https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html" style="background-image: url(&quot;https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67&quot;)"></a>'
      '<div class="data-container"></div></div>', [
    ParagraphNode(links: [], nodes: [
      LinkNode(
        nodes: [TextNode('https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html')],
        url: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html'),
    ]),
    WebsitePreviewNode(
      hrefUrl: 'https://pub-14f7b5e1308d42b69c4a46608442a50c.r2.dev/image+nodescription+notitle.html',
      imageSrcUrl: 'https://uploads.zulipusercontent.net/98fe2fe57d1ac641d4d84b6de2c520ff48fcf498/68747470733a2f2f7374617469632e7a756c6970636861742e636f6d2f7374617469632f696d616765732f6c6f676f2f7a756c69702d69636f6e2d313238783132382e706e67',
      title: null,
      description: null),
  ]);

  static const legacyWebsitePreviewSmoke = ContentExample(
    'legacy website preview smoke',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/URL.20previews/near/192777
    'www.youtube.com',
    '<p><a href="http://www.youtube.com" target="_blank" title="http://www.youtube.com">www.youtube.com</a></p>\n'
    '<div class="message_embed">'
      '<a class="message_embed_image" href="http://www.youtube.com" style="background-image: url(https://youtube.com/yts/img/yt_1200-vfl4C3T0K.png)" target="_blank"></a>'
      '<div class="data-container">'
        '<div class="message_embed_title"><a href="http://www.youtube.com" target="_blank" title="YouTube">YouTube</a></div>'
        '<div class="message_embed_description">Enjoy the videos and music you love, upload original content, and share it all with friends, family, and the world on YouTube.</div></div></div>', [
    ParagraphNode(links: [], nodes: [
      LinkNode(
        nodes: [TextNode('www.youtube.com')],
        url: 'http://www.youtube.com'),
    ]),
    WebsitePreviewNode(
      hrefUrl: 'http://www.youtube.com',
      imageSrcUrl: 'https://youtube.com/yts/img/yt_1200-vfl4C3T0K.png',
      title: 'YouTube',
      description: 'Enjoy the videos and music you love, upload '
        'original content, and share it all with friends, family, and '
        'the world on YouTube.'),
  ]);

  static const tableWithSingleRow = ContentExample(
    'table with single row',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/1971202
    '| a | b | c | d |\n| - | - | - | - |\n| 1 | 2 | 3 | 4 |',
    '<table>\n<thead>\n<tr>\n<th>a</th>\n<th>b</th>\n<th>c</th>\n<th>d</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td>1</td>\n<td>2</td>\n<td>3</td>\n<td>4</td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('a')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('b')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('c')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('d')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('1')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('2')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('3')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('4')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static const tableWithMultipleRows = ContentExample(
    'table with multiple rows',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/1971203
    '| heading 1 | heading 2 | heading 3 |\n| - | - | - |\n| body11 | body12 | body13 |\n| body21 | body22 | body23 |\n| body31 | body32 | body33 |',
    '<table>\n<thead>\n<tr>\n<th>heading 1</th>\n<th>heading 2</th>\n<th>heading 3</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td>body11</td>\n<td>body12</td>\n<td>body13</td>\n</tr>\n'
      '<tr>\n<td>body21</td>\n<td>body22</td>\n<td>body23</td>\n</tr>\n'
      '<tr>\n<td>body31</td>\n<td>body32</td>\n<td>body33</td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('heading 1')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('heading 2')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('heading 3')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('body11')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body12')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body13')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('body21')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body22')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body23')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('body31')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body32')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('body33')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static const tableWithBoldAndItalicHeaders = ContentExample(
    'table with bold and italic headers',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/1971911
    '| normal heading | *italic heading* | **bold heading** | ***italic bold heading*** |\n| - | - | - | - |\n| text | text | text | text |',
    '<table>\n<thead>\n<tr>\n<th>normal heading</th>\n<th><em>italic heading</em></th>\n<th><strong>bold heading</strong></th>\n<th><strong><em>italic bold heading</em></strong></th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td>text</td>\n<td>text</td>\n<td>text</td>\n<td>text</td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('normal heading')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [EmphasisNode(nodes: [TextNode('italic heading')])], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [StrongNode(nodes: [TextNode('bold heading')])], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [StrongNode(nodes: [EmphasisNode(nodes: [TextNode('italic bold heading')])])], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static const tableWithLinksInCells = ContentExample(
    'table with links in cells',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/1987662
    '| https://zulip.com |\n| - |\n| https://zulip.com |',
    '<table>\n<thead>\n<tr>\n<th><a href="https://zulip.com">https://zulip.com</a></th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td><a href="https://zulip.com">https://zulip.com</a></td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [LinkNode(nodes: [TextNode('https://zulip.com')], url: 'https://zulip.com')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [LinkNode(nodes: [TextNode('https://zulip.com')], url: 'https://zulip.com')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static final tableWithImagePreview = ContentExample(
    'table with image preview',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/1987666
    '| a |\n| - |\n| [image2.jpg](/user_uploads/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg) |',
    '<table>\n<thead>\n<tr>\n<th>a</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td><a href="/user_uploads/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg">image2.jpg</a></td>\n</tr>\n</tbody>\n</table>\n'
      '<div class="message_inline_image"><a href="/user_uploads/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg" title="image2.jpg"><img data-original-dimensions="2760x4912" src="/user_uploads/thumbnail/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg/840x560.webp"></a></div>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('a')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [LinkNode(nodes: [TextNode('image2.jpg')], url: '/user_uploads/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
    ImagePreviewNodeList([
      ImagePreviewNode(srcUrl: '/user_uploads/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg',
        thumbnail: ImageThumbnailLocator(animated: false,
          defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/6f/KS3vNT9c2tbMfMBkSbQF_Jlj/image2.jpg/840x560.webp')),
        loading: false,
        originalWidth: 2760,
        originalHeight: 4912),
    ]),
  ]);

  // As is, this HTML doesn't look particularly different to our parser.
  // But if Zulip's table support followed GFM, this would have no <tbody>:
  //   https://github.github.com/gfm/#example-205
  //   https://github.com/zulip/zulip-flutter/pull/1031#discussion_r1855931989
  static const tableWithoutAnyBodyCellsInMarkdown = ContentExample(
    'table without any body cells in markdown',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/1987687
    '| table |\n| - |',
    '<table>\n<thead>\n<tr>\n<th>table</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td></td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('table')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static const tableMissingOneBodyColumnInMarkdown = ContentExample(
    'table missing one body column in markdown',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/1987693
    '| a | b |\n| - | - |\n| text |',
    '<table>\n<thead>\n<tr>\n<th>a</th>\n<th>b</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td>text</td>\n<td></td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('a')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('b')], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [], links: [], textAlignment: TableColumnTextAlignment.defaults),
      ], isHeader: false),
    ]),
  ]);

  static const tableWithDifferentTextAlignmentInColumns = ContentExample(
    'table with different text alignment in columns',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/1971201
    '| default-aligned | left-aligned | center-aligned | right-aligned |\n| - | :- | :-: | -: |\n| text | text | text | text |\n| long text long text long text  | long text long text long text  | long text long text long text | long text long text long text |',
    '<table>\n<thead>\n<tr>\n<th>default-aligned</th>\n<th style="text-align: left;">left-aligned</th>\n<th style="text-align: center;">center-aligned</th>\n<th style="text-align: right;">right-aligned</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td>text</td>\n<td style="text-align: left;">text</td>\n<td style="text-align: center;">text</td>\n<td style="text-align: right;">text</td>\n</tr>\n'
      '<tr>\n<td>long text long text long text</td>\n<td style="text-align: left;">long text long text long text</td>\n<td style="text-align: center;">long text long text long text</td>\n<td style="text-align: right;">long text long text long text</td>\n</tr>\n'
      '</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('default-aligned')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('left-aligned')], links: [], textAlignment: TableColumnTextAlignment.left),
        TableCellNode(nodes: [TextNode('center-aligned')], links: [], textAlignment: TableColumnTextAlignment.center),
        TableCellNode(nodes: [TextNode('right-aligned')], links: [], textAlignment: TableColumnTextAlignment.right),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.left),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.center),
        TableCellNode(nodes: [TextNode('text')], links: [], textAlignment: TableColumnTextAlignment.right),
      ], isHeader: false),
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('long text long text long text')], links: [], textAlignment: TableColumnTextAlignment.defaults),
        TableCellNode(nodes: [TextNode('long text long text long text')], links: [], textAlignment: TableColumnTextAlignment.left),
        TableCellNode(nodes: [TextNode('long text long text long text')], links: [], textAlignment: TableColumnTextAlignment.center),
        TableCellNode(nodes: [TextNode('long text long text long text')], links: [], textAlignment: TableColumnTextAlignment.right),
      ], isHeader: false),
    ]),
  ]);

  static const tableWithLinkCenterAligned = ContentExample(
    'table with link; center aligned',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/.E2.9C.94.20Rajesh/near/1987982
    '| header |\n| :-: |\n| https://zulip.com |',
    '<table>\n<thead>\n<tr>\n<th style="text-align: center;">header</th>\n</tr>\n</thead>\n'
      '<tbody>\n<tr>\n<td style="text-align: center;"><a href="https://zulip.com">https://zulip.com</a></td>\n</tr>\n</tbody>\n</table>', [
    TableNode(rows: [
      TableRowNode(cells: [
        TableCellNode(nodes: [TextNode('header')], links: [], textAlignment: TableColumnTextAlignment.center),
      ], isHeader: true),
      TableRowNode(cells: [
        TableCellNode(nodes: [LinkNode(nodes: [TextNode('https://zulip.com')], url: 'https://zulip.com')], links: [], textAlignment: TableColumnTextAlignment.center),
      ], isHeader: false),
    ]),
  ]);
}

UnimplementedBlockContentNode blockUnimplemented(String html) {
  var fragment = HtmlParser(html, parseMeta: false).parseFragment();
  return UnimplementedBlockContentNode(htmlNode: fragment.nodes.single);
}

UnimplementedInlineContentNode inlineUnimplemented(String html) {
  var fragment = HtmlParser(html, parseMeta: false).parseFragment();
  return UnimplementedInlineContentNode(htmlNode: fragment.nodes.single);
}

void testParse(String name, String html, List<BlockContentNode> nodes, {
  Object? skip,
}) {
  test(name, () {
    check(parseContent(html))
      .equalsNode(ZulipContent(nodes: nodes));
  }, skip: skip);
}

void testParseExample(ContentExample example, {Object? skip}) {
  testParse('parse ${example.description}', example.html, example.expectedNodes,
    skip: skip);
}

void main() async {
  // When writing test cases in this file:
  //
  //  * Prefer to add a [ContentExample] static and use [testParseExample].
  //    Then add one line of code to `test/widgets/content_test.dart`,
  //    calling `testContentSmoke`, for a widgets test on the same example.
  //
  //  * To write the example, see comment at top of [ContentExample].

  TestZulipBinding.ensureInitialized();

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

  testParseExample(ContentExample.strong);

  testParseExample(ContentExample.deleted);

  testParseExample(ContentExample.emphasis);

  testParseExample(ContentExample.inlineCode);

  testParseInline('parse nested del, strong, em, code',
    // "~~***`word`***~~"
    '<p><del><strong><em><code>word</code></em></strong></del></p>',
    const DeletedNode(
      nodes: [StrongNode(nodes: [EmphasisNode(nodes: [InlineCodeNode(nodes: [
        TextNode('word')])])])]));

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

    testParseExample(ContentExample.messageLink);
  });

  testParseInline('parse nested link, del, strong, em, code',
    // "[~~***`word`***~~](https://example/)"
    '<p><a href="https://example/"><del><strong><em><code>word'
        '</code></em></strong></del></a></p>',
    const LinkNode(url: 'https://example/',
      nodes: [DeletedNode(nodes: [
        StrongNode(nodes: [EmphasisNode(nodes: [InlineCodeNode(nodes: [
         TextNode('word')])])])])]));

  testParseInline('parse nested del, strong, em, link',
    // "~~***[t](/u)***~~"
    '<p><del><strong><em><a href="/u">t</a></em></strong></del></p>',
    const DeletedNode(
      nodes: [StrongNode(nodes: [EmphasisNode(nodes: [LinkNode(url: '/u',
        nodes: [TextNode('t')])])])]));

  group('parse @-mentions', () {
    testParseExample(ContentExample.userMentionPlain);
    testParseExample(ContentExample.userMentionSilent);
    testParseExample(ContentExample.userMentionSilentClassOrderReversed);

    testParseExample(ContentExample.groupMentionPlain);
    testParseExample(ContentExample.groupMentionSilent);
    testParseExample(ContentExample.groupMentionSilentClassOrderReversed);

    testParseExample(ContentExample.channelWildcardMentionPlain);
    testParseExample(ContentExample.channelWildcardMentionSilent);
    testParseExample(ContentExample.channelWildcardMentionSilentClassOrderReversed);

    testParseExample(ContentExample.legacyChannelWildcardMentionPlain);
    testParseExample(ContentExample.legacyChannelWildcardMentionSilent);
    testParseExample(ContentExample.legacyChannelWildcardMentionSilentClassOrderReversed);

    testParseExample(ContentExample.topicMentionPlain);
    testParseExample(ContentExample.topicMentionSilent);
    testParseExample(ContentExample.topicMentionSilentClassOrderReversed);
  });

  testParseExample(ContentExample.emojiUnicode);
  testParseExample(ContentExample.emojiUnicodeClassesFlipped);
  testParseExample(ContentExample.emojiUnicodeMultiCodepoint);
  testParseExample(ContentExample.emojiUnicodeLiteral);
  testParseExample(ContentExample.emojiCustom);
  testParseExample(ContentExample.emojiCustomInvalidUrl);
  testParseExample(ContentExample.emojiZulipExtra);

  testParseExample(ContentExample.mathInline);
  testParseExample(ContentExample.mathInlineUnknown);

  group('global times', () {
    testParseExample(ContentExample.globalTime);

    testParseInline('handles missing attribute',
      // No markdown, this is unexpected response
      '<p><time>2024-01-30T17:33:00Z</time></p>',
      inlineUnimplemented('<time>2024-01-30T17:33:00Z</time>'),
    );

    testParseInline('handles DateTime.parse failure',
      // No markdown, this is unexpected response
      '<p><time datetime="2024">2024-01-30T17:33:00Z</time></p>',
      inlineUnimplemented('<time datetime="2024">2024-01-30T17:33:00Z</time>'),
    );

    testParseInline('handles unexpected timezone',
      // No markdown, this is unexpected response
      '<p><time datetime="2024-01-30T17:33:00">2024-01-30T17:33:00</time></p>',
      inlineUnimplemented('<time datetime="2024-01-30T17:33:00">2024-01-30T17:33:00</time>'),
    );
  });

  //
  // Block content.
  //

  testParse('parse <br> in block context',
    '<br><p>a</p><br>', const [ // TODO not sure how to reproduce this example
      LineBreakNode(),
      ParagraphNode(links: null, nodes: [TextNode('a')]),
      LineBreakNode(),
    ]);

  testParseExample(ContentExample.thematicBreak);

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
      // "###### one [**~~*`two`*~~**](https://example/)"
      '<h6>one <a href="https://example/"><strong><del><em><code>two'
          '</code></em></del></strong></a></h6>', const [
        HeadingNode(level: HeadingLevel.h6, links: null, nodes: [
          TextNode('one '),
          LinkNode(url: 'https://example/',
            nodes: [StrongNode(
              nodes: [DeletedNode( nodes: [EmphasisNode(nodes: [
                InlineCodeNode(nodes: [TextNode('two')])])])])]),
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
        OrderedListNode(start: 1, [
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('first')])],
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('then')])],
        ]),
      ]);

    testParse('<ul>',
      // "* something\n* another"
      '<ul>\n<li>something</li>\n<li>another</li>\n</ul>', const [
        UnorderedListNode([
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('something')])],
          [ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('another')])],
        ]),
      ]);

    testParse('implicit paragraph with internal <br>',
      // "* a\n  b"
      '<ul>\n<li>a<br>\n  b</li>\n</ul>', const [
        UnorderedListNode([
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
        UnorderedListNode([
          [
            ParagraphNode(links: null, nodes: [TextNode('a')]),
            ParagraphNode(links: null, nodes: [TextNode('b')]),
          ],
        ]),
      ]);

    testParseExample(ContentExample.orderedListCustomStart);
    testParseExample(ContentExample.orderedListLargeStart);
  });

  testParseExample(ContentExample.spoilerDefaultHeader);
  testParseExample(ContentExample.spoilerPlainCustomHeader);
  testParseExample(ContentExample.spoilerRichHeaderAndContent);
  testParseExample(ContentExample.spoilerHeaderHasImagePreview);

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
        UnorderedListNode([
          [ParagraphNode(links: null, wasImplicit: true, nodes: [
            LinkNode(url: '/u', nodes: [TextNode('t')]),
          ])],
        ])]);
  });

  testParseExample(ContentExample.quotation);

  testParseExample(ContentExample.codeBlockPlain);
  testParseExample(ContentExample.codeBlockHighlightedShort);
  testParseExample(ContentExample.codeBlockHighlightedMultiline);
  testParseExample(ContentExample.codeBlockSpansWithMultipleClasses);
  testParseExample(ContentExample.codeBlockWithEmptyBody);
  testParseExample(ContentExample.codeBlockWithHighlightedLines);
  testParseExample(ContentExample.codeBlockWithUnknownSpanType);
  testParseExample(ContentExample.codeBlockFollowedByMultipleLineBreaks);

  // The math examples in this file are about how math blocks and spans fit
  // into the context of a Zulip message.
  // For tests going deeper inside KaTeX content, see katex_test.dart.
  testParseExample(ContentExample.mathBlock);
  testParseExample(ContentExample.mathBlockUnknown);

  testParseExample(ContentExample.mathBlocksMultipleInParagraph);
  testParseExample(ContentExample.mathBlockInQuote);
  testParseExample(ContentExample.mathBlocksMultipleInQuote);
  testParseExample(ContentExample.mathBlockBetweenImagePreviews);

  testParseExample(ContentExample.imagePreviewSingle);

  testParse('image preview: if thumbnail URL has query and fragment, accept and preserve them',
    // Hypothetical server behavior, so there's no example message to point to.
    // Discussion: https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/.60server_thumbnail_formats.60.20in.20register.20response/near/2324602
    '<div class="message_inline_image">'
      '<a href="/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg" title="image.jpg">'
        '<img data-original-dimensions="6000x4000" src="/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp?x=y#abc"></a></div>',
    [
      ImagePreviewNodeList([
        ImagePreviewNode(srcUrl: '/user_uploads/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg',
          thumbnail: ImageThumbnailLocator(animated: false,
            defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/2/ce/nvoNL2LaZOciwGZ-FYagddtK/image.jpg/840x560.webp?x=y#abc')),
          loading: false,
          originalWidth: 6000,
          originalHeight: 4000),
      ]),
    ]);

  testParseExample(ContentExample.imagePreviewSingleAnimated);
  testParseExample(ContentExample.imagePreviewSingleNoDimensions);
  testParseExample(ContentExample.imagePreviewSingleNoThumbnail);
  testParseExample(ContentExample.imagePreviewSingleLoadingPlaceholder);
  testParseExample(ContentExample.imagePreviewSingleExternal1);
  testParseExample(ContentExample.imagePreviewSingleExternal2);
  testParseExample(ContentExample.imagePreviewSingleExternal3);
  testParseExample(ContentExample.imagePreviewInvalidUrl);
  testParseExample(ContentExample.imagePreviewCluster);
  testParseExample(ContentExample.imagePreviewClusterNoThumbnails);
  testParseExample(ContentExample.imagePreviewClusterThenContent);
  testParseExample(ContentExample.imagePreviewMultipleClusters);
  testParseExample(ContentExample.imagePreviewInImplicitParagraph);
  testParseExample(ContentExample.imagePreviewClusterInImplicitParagraph);
  testParseExample(ContentExample.imagePreviewClusterInImplicitParagraphThenContent);

  testParseExample(ContentExample.videoEmbedYoutube);
  testParseExample(ContentExample.videoEmbedYoutubeClassesFlipped);
  testParseExample(ContentExample.videoEmbedVimeoPreviewDisabled);
  testParseExample(ContentExample.videoEmbedVimeo);
  testParseExample(ContentExample.videoEmbedVimeoClassesFlipped);
  testParseExample(ContentExample.videoInline);
  testParseExample(ContentExample.videoInlineClassesFlipped);

  testParseExample(ContentExample.audioInline);
  testParseExample(ContentExample.audioInlineNoTitle);

  testParseExample(ContentExample.websitePreviewSmoke);
  testParseExample(ContentExample.websitePreviewWithoutTitle);
  testParseExample(ContentExample.websitePreviewWithoutDescription);
  testParseExample(ContentExample.websitePreviewWithoutTitleOrDescription);
  testParseExample(ContentExample.legacyWebsitePreviewSmoke);

  testParseExample(ContentExample.tableWithSingleRow);
  testParseExample(ContentExample.tableWithMultipleRows);
  testParseExample(ContentExample.tableWithBoldAndItalicHeaders);
  testParseExample(ContentExample.tableWithLinksInCells);
  testParseExample(ContentExample.tableWithImagePreview);
  testParseExample(ContentExample.tableWithoutAnyBodyCellsInMarkdown);
  testParseExample(ContentExample.tableMissingOneBodyColumnInMarkdown);
  testParseExample(ContentExample.tableWithDifferentTextAlignmentInColumns);
  testParseExample(ContentExample.tableWithLinkCenterAligned);

  testParse('parse nested lists, quotes, headings, code blocks',
    // "1. > ###### two\n   > * three\n\n      four"
    '<ol>\n<li>\n<blockquote>\n<h6>two</h6>\n<ul>\n<li>three</li>\n'
        '</ul>\n</blockquote>\n<div class="codehilite"><pre><span></span>'
        '<code>four\n</code></pre></div>\n\n</li>\n</ol>', const [
      OrderedListNode(start: 1, [[
        QuotationNode([
          HeadingNode(level: HeadingLevel.h6, links: null, nodes: [TextNode('two')]),
          UnorderedListNode([[
            ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('three')]),
          ]]),
        ]),
        CodeBlockNode([
          CodeBlockSpanNode(text: 'four', type: CodeBlockSpanType.text),
        ]),
        ParagraphNode(wasImplicit: true, links: null, nodes: [TextNode('\n\n')]), // TODO avoid this; it renders wrong
      ]]),
    ]);

  test('all content examples are tested', () {
    // Check that every ContentExample defined above has a corresponding
    // actual test case that runs on it.  If you've added a new example
    // and this test breaks, remember to add a `testParseExample` call for it.

    // This implementation is a bit of a hack; it'd be cleaner to get the
    // actual Dart parse tree using package:analyzer.  Unfortunately that
    // approach takes several seconds just to load the parser library, enough
    // to add noticeably to the runtime of our whole test suite.
    final thisFilename = Trace.current().frames[0].uri.path;
    final source = File(thisFilename).readAsStringSync();
    final declaredExamples = RegExp(multiLine: true,
      r'^\s*static\s+(?:const|final)\s+(\w+)\s*=\s*ContentExample\s*(?:\.\s*inline\s*)?\(',
    ).allMatches(source).map((m) => m.group(1));
    final testedExamples = RegExp(multiLine: true,
      r'^\s*testParseExample\s*\(\s*ContentExample\s*\.\s*(\w+)(?:,\s*skip:\s*true)?\s*\);',
    ).allMatches(source).map((m) => m.group(1));
    check(testedExamples).unorderedEquals(declaredExamples);
  }, skip: Platform.isWindows, // [intended] purely analyzes source, so
       // any one platform is enough; avoid dealing with Windows file paths
  );
}
