import 'dart:io';

import 'package:checks/checks.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test_api/scaffolding.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/katex.dart';

import 'binding.dart';
import 'content_test.dart';

/// An example of KaTeX Zulip content for test cases.
///
/// For guidance on writing examples, see comments on [ContentExample].
class KatexExample extends ContentExample {
  KatexExample.inline(String description, String texSource, String html,
      List<KatexNode>? expectedNodes)
    : super.inline(description, '\$\$ $texSource \$\$', html,
        MathInlineNode(texSource: texSource, nodes: expectedNodes));

  KatexExample.block(String description, String texSource, String html,
      List<KatexNode>? expectedNodes)
    : super(description, '```math\n$texSource\n```', html,
        [MathBlockNode(texSource: texSource, nodes: expectedNodes)]);

  // The font sizes can be compared using the katex.css generated
  // from katex.scss :
  //   https://unpkg.com/katex@0.16.21/dist/katex.css
  static final sizing = KatexExample.block(
    'different font sizes',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2155476
    '\\Huge 1\n\\huge 2\n\\LARGE 3\n\\Large 4\n\\large 5\n\\normalsize 6\n\\small 7\n\\footnotesize 8\n\\scriptsize 9\n\\tiny 0',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathsize="2.488em"><mn>1</mn><mstyle mathsize="2.074em"><mn>2</mn><mstyle mathsize="1.728em"><mn>3</mn><mstyle mathsize="1.44em"><mn>4</mn><mstyle mathsize="1.2em"><mn>5</mn><mstyle mathsize="1em"><mn>6</mn><mstyle mathsize="0.9em"><mn>7</mn><mstyle mathsize="0.8em"><mn>8</mn><mstyle mathsize="0.7em"><mn>9</mn><mstyle mathsize="0.5em"><mn>0</mn></mstyle></mstyle></mstyle></mstyle></mstyle></mstyle></mstyle></mstyle></mstyle></mstyle></mrow>'
          '<annotation encoding="application/x-tex">\\Huge 1\n\\huge 2\n\\LARGE 3\n\\Large 4\n\\large 5\n\\normalsize 6\n\\small 7\n\\footnotesize 8\n\\scriptsize 9\n\\tiny 0</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:1.6034em;"></span>'
            '<span class="mord sizing reset-size6 size11">1</span>'
            '<span class="mord sizing reset-size6 size10">2</span>'
            '<span class="mord sizing reset-size6 size9">3</span>'
            '<span class="mord sizing reset-size6 size8">4</span>'
            '<span class="mord sizing reset-size6 size7">5</span>'
            '<span class="mord sizing reset-size6 size6">6</span>'
            '<span class="mord sizing reset-size6 size5">7</span>'
            '<span class="mord sizing reset-size6 size4">8</span>'
            '<span class="mord sizing reset-size6 size3">9</span>'
            '<span class="mord sizing reset-size6 size1">0</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 1.6034, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 2.488), // .reset-size6.size11
          text: '1'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 2.074), // .reset-size6.size10
          text: '2'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 1.728), // .reset-size6.size9
          text: '3'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 1.44), // .reset-size6.size8
          text: '4'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 1.2), // .reset-size6.size7
          text: '5'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 1.0), // .reset-size6.size6
          text: '6'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 0.9), // .reset-size6.size5
          text: '7'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 0.8), // .reset-size6.size4
          text: '8'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 0.7), // .reset-size6.size3
          text: '9'),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 0.5), // .reset-size6.size1
          text: '0'),
      ]),
    ]);

  static final nestedSizing = KatexExample.block(
    'sizing spans nested',
    r'\tiny {1 \Huge 2}',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathsize="0.5em"><mrow><mn>1</mn><mstyle mathsize="2.488em"><mn>2</mn></mstyle></mrow></mstyle></mrow>'
          '<annotation encoding="application/x-tex">\\tiny {1 \\Huge 2}</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:1.6034em;"></span>'
            '<span class="mord sizing reset-size6 size1">'
              '<span class="mord">1</span>'
              '<span class="mord sizing reset-size1 size11">2</span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 1.6034, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(fontSizeEm: 0.5), // reset-size6 size1
          nodes: [
            KatexSpanNode(text: '1'),
            KatexSpanNode(
              styles: KatexSpanStyles(fontSizeEm: 4.976), // reset-size1 size11
              text: '2'),
          ]),
      ]),
    ]);

  static final delimsizing = KatexExample.block(
    'delimsizing spans, big delimiters',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2147135
    r'⟨ \big( \Big[ \bigg⌈ \Bigg⌊',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mo stretchy="false">⟨</mo><mo fence="false" stretchy="true" minsize="1.2em" maxsize="1.2em">(</mo><mo fence="false" stretchy="true" minsize="1.8em" maxsize="1.8em">[</mo><mo fence="false" stretchy="true" minsize="2.4em" maxsize="2.4em">⌈</mo><mo fence="false" stretchy="true" minsize="3em" maxsize="3em">⌊</mo></mrow>'
          '<annotation encoding="application/x-tex">⟨ \\big( \\Big[ \\bigg⌈ \\Bigg⌊</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:3em;vertical-align:-1.25em;"></span>'
            '<span class="mopen">⟨</span>'
            '<span class="mord"><span class="delimsizing size1">(</span></span>'
            '<span class="mord"><span class="delimsizing size2">[</span></span>'
            '<span class="mord"><span class="delimsizing size3">⌈</span></span>'
            '<span class="mord"><span class="delimsizing size4">⌊</span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 3, verticalAlignEm: -1.25),
        KatexSpanNode(text: '⟨'),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Size1'),
            text: '('),
        ]),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Size2'),
            text: '['),
        ]),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Size3'),
            text: '⌈'),
        ]),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Size4'),
            text: '⌊'),
        ]),
      ]),
    ]);

  static final spacing = KatexExample.block(
    'positive horizontal spacing with margin-right',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2214883
    '1:2',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mn>1</mn><mo>:</mo><mn>2</mn></mrow><annotation encoding="application/x-tex">1:2</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord">1</span>'
            '<span class="mspace" style="margin-right:0.2778em;"></span>'
            '<span class="mrel">:</span>'
            '<span class="mspace" style="margin-right:0.2778em;"></span></span>'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord">2</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(text: '1'),
        KatexSpanNode(
          styles: KatexSpanStyles(marginRightEm: 0.2778),
          nodes: []),
        KatexSpanNode(text: ':'),
        KatexSpanNode(
          styles: KatexSpanStyles(marginRightEm: 0.2778),
          nodes: []),
      ]),
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(text: '2'),
      ]),
    ]);

  static final vlistSuperscript = KatexExample.block(
    'superscript: single vlist-r, single vertical offset row',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2176734
    "a'",
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msup><mi>a</mi><mo mathvariant="normal" lspace="0em" rspace="0em">′</mo></msup></mrow>'
          '<annotation encoding="application/x-tex">a&#x27;</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.8019em;"></span>'
            '<span class="mord">'
              '<span class="mord mathnormal">a</span>'
              '<span class="msupsub">'
                '<span class="vlist-t">'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.8019em;">'
                      '<span style="top:-3.113em;margin-right:0.05em;">'
                        '<span class="pstrut" style="height:2.7em;"></span>'
                        '<span class="sizing reset-size6 size3 mtight">'
                          '<span class="mord mtight">'
                            '<span class="mord mtight">′</span></span></span></span></span></span></span></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.8019, verticalAlignEm: null),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
            text: 'a'),
          KatexSpanNode(
            styles: KatexSpanStyles(textAlign: KatexSpanTextAlign.left),
            nodes: [
              KatexVlistNode(rows: [
                KatexVlistRowNode(
                  verticalOffsetEm: -3.113 + 2.7,
                  node: KatexSpanNode(
                    styles: KatexSpanStyles(marginRightEm: 0.05),
                    nodes: [
                      KatexSpanNode(styles: KatexSpanStyles(fontSizeEm: 0.7), nodes: [
                        KatexSpanNode(nodes: [
                          KatexSpanNode(text: '′'),
                        ]),
                      ]),
                    ])),
              ]),
            ]),
        ]),
      ]),
    ]);

  static final vlistSubscript = KatexExample.block(
    'subscript: two vlist-r, single vertical offset row',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2176735
    'x_n',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msub><mi>x</mi><mi>n</mi></msub></mrow>'
          '<annotation encoding="application/x-tex">x_n</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.5806em;vertical-align:-0.15em;"></span>'
            '<span class="mord">'
              '<span class="mord mathnormal">x</span>'
              '<span class="msupsub">'
                '<span class="vlist-t vlist-t2">'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.1514em;">'
                      '<span style="top:-2.55em;margin-left:0em;margin-right:0.05em;">'
                        '<span class="pstrut" style="height:2.7em;"></span>'
                        '<span class="sizing reset-size6 size3 mtight">'
                          '<span class="mord mathnormal mtight">n</span></span></span></span>'
                    '<span class="vlist-s">​</span></span>'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.5806, verticalAlignEm: -0.15),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(
              fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
            text: 'x'),
          KatexSpanNode(
            styles: KatexSpanStyles(textAlign: KatexSpanTextAlign.left),
            nodes: [
              KatexVlistNode(rows: [
                KatexVlistRowNode(
                  verticalOffsetEm: -2.55 + 2.7,
                  node: KatexSpanNode(
                    styles: KatexSpanStyles(marginLeftEm: 0, marginRightEm: 0.05),
                    nodes: [
                      KatexSpanNode(
                        styles: KatexSpanStyles(fontSizeEm: 0.7), // .reset-size6.size3
                        nodes: [
                          KatexSpanNode(
                            styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
                            text: 'n'),
                        ]),
                    ])),
              ]),
            ]),
        ]),
      ]),
    ]);

  static final vlistSubAndSuperscript = KatexExample.block(
    'subscript and superscript: two vlist-r, multiple vertical offset rows',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2176738
    '_u^o',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msubsup><mrow></mrow><mi>u</mi><mi>o</mi></msubsup></mrow>'
          '<annotation encoding="application/x-tex">_u^o</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.9614em;vertical-align:-0.247em;"></span>'
            '<span class="mord">'
              '<span></span>'
              '<span class="msupsub">'
                '<span class="vlist-t vlist-t2">'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.7144em;">'
                      '<span style="top:-2.453em;margin-right:0.05em;">'
                        '<span class="pstrut" style="height:2.7em;"></span>'
                        '<span class="sizing reset-size6 size3 mtight">'
                          '<span class="mord mathnormal mtight">u</span></span></span>'
                      '<span style="top:-3.113em;margin-right:0.05em;">'
                        '<span class="pstrut" style="height:2.7em;"></span>'
                        '<span class="sizing reset-size6 size3 mtight">'
                          '<span class="mord mathnormal mtight">o</span></span></span></span>'
                    '<span class="vlist-s">​</span></span>'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.247em;"><span></span></span></span></span></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.9614, verticalAlignEm: -0.247),
        KatexSpanNode(nodes: [
          KatexSpanNode(nodes: []),
          KatexSpanNode(
            styles: KatexSpanStyles(textAlign: KatexSpanTextAlign.left),
            nodes: [
              KatexVlistNode(rows: [
                KatexVlistRowNode(
                  verticalOffsetEm: -2.453 + 2.7,
                  node: KatexSpanNode(
                    styles: KatexSpanStyles(marginRightEm: 0.05),
                    nodes: [
                      KatexSpanNode(
                        styles: KatexSpanStyles(fontSizeEm: 0.7), // .reset-size6.size3
                        nodes: [
                          KatexSpanNode(
                            styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
                            text: 'u'),
                        ]),
                    ])),
                KatexVlistRowNode(
                  verticalOffsetEm: -3.113 + 2.7,
                  node: KatexSpanNode(
                    styles: KatexSpanStyles(marginRightEm: 0.05),
                    nodes: [
                      KatexSpanNode(
                        styles: KatexSpanStyles(fontSizeEm: 0.7), // .reset-size6.size3
                        nodes: [
                          KatexSpanNode(
                            styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
                            text: 'o'),
                        ]),
                    ])),
              ]),
            ]),
        ]),
      ]),
    ]);

  static final vlistRaisebox = KatexExample.block(
    r'\raisebox: single vlist-r, single vertical offset row',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2176739
    r'a\raisebox{0.25em}{$b$}c',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>a</mi><mpadded voffset="0.25em"><mstyle scriptlevel="0" displaystyle="false"><mstyle scriptlevel="0" displaystyle="false"><mi>b</mi></mstyle></mstyle></mpadded><mi>c</mi></mrow>'
          '<annotation encoding="application/x-tex">a\\raisebox{0.25em}{\$b\$}c</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.9444em;"></span>'
            '<span class="mord mathnormal">a</span>'
            '<span class="vlist-t">'
              '<span class="vlist-r">'
                '<span class="vlist" style="height:0.9444em;">'
                  '<span style="top:-3.25em;">'
                    '<span class="pstrut" style="height:3em;"></span>'
                    '<span class="mord">'
                      '<span class="mord mathnormal">b</span></span></span></span></span></span>'
            '<span class="mord mathnormal">c</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.9444, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
          text: 'a'),
        KatexVlistNode(rows: [
          KatexVlistRowNode(
            verticalOffsetEm: -3.25 + 3,
            node: KatexSpanNode(nodes: [
              KatexSpanNode(nodes: [
                KatexSpanNode(
                  styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
                  text: 'b'),
              ]),
            ])),
        ]),
        KatexSpanNode(
          styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
          text: 'c'),
      ]),
    ]);

  static final negativeMargin = KatexExample.block(
    r'negative horizontal margin (\!)',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2223563
    r'1 \! 2',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mn>1</mn><mtext> ⁣</mtext><mn>2</mn></mrow><annotation encoding="application/x-tex">1 \\! 2</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord">1</span>'
            '<span class="mspace" style="margin-right:-0.1667em;"></span>'
            '<span class="mord">2</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(text: '1'),
        KatexSpanNode(nodes: []),
        KatexNegativeMarginNode(leftOffsetEm: -0.1667, nodes: [
          KatexSpanNode(text: '2'),
        ]),
      ]),
    ]);

  static final katexLogo = KatexExample.block(
    'KaTeX logo: vlists, negative margins',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2141902
    r'\KaTeX',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mtext>KaTeX</mtext></mrow>'
          '<annotation encoding="application/x-tex">\\KaTeX</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.8988em;vertical-align:-0.2155em;"></span>'
            '<span class="mord text">'
              '<span class="mord textrm">K</span>'
              '<span class="mspace" style="margin-right:-0.17em;"></span>'
              '<span class="vlist-t"><span class="vlist-r">'
                '<span class="vlist" style="height:0.6833em;">'
                  '<span style="top:-2.905em;">'
                    '<span class="pstrut" style="height:2.7em;"></span>'
                    '<span class="mord">'
                      '<span class="mord textrm mtight sizing reset-size6 size3">A</span></span></span></span></span></span>'
              '<span class="mspace" style="margin-right:-0.15em;"></span>'
              '<span class="mord text">'
                '<span class="mord textrm">T</span>'
                '<span class="mspace" style="margin-right:-0.1667em;"></span>'
                '<span class="vlist-t vlist-t2">'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.4678em;">'
                      '<span style="top:-2.7845em;">'
                        '<span class="pstrut" style="height:3em;"></span>'
                        '<span class="mord">'
                          '<span class="mord textrm">E</span></span></span></span>'
                    '<span class="vlist-s">​</span></span>'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.2155em;"><span></span></span></span></span>'
                '<span class="mspace" style="margin-right:-0.125em;"></span>'
                '<span class="mord textrm">X</span></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.8988, verticalAlignEm: -0.2155),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Main'),
            text: 'K'),
          KatexSpanNode(nodes: []),
          KatexNegativeMarginNode(leftOffsetEm: -0.17, nodes: [
            KatexVlistNode(rows: [
              KatexVlistRowNode(
                verticalOffsetEm: -2.905 + 2.7,
                node: KatexSpanNode(nodes: [
                  KatexSpanNode(nodes: [
                    KatexSpanNode(
                      styles: KatexSpanStyles(fontFamily: 'KaTeX_Main', fontSizeEm: 0.7), // .reset-size6.size3
                      text: 'A'),
                  ]),
                ])),
            ]),
            KatexSpanNode(nodes: []),
            KatexNegativeMarginNode(leftOffsetEm: -0.15, nodes: [
              KatexSpanNode(nodes: [
                KatexSpanNode(
                  styles: KatexSpanStyles(fontFamily: 'KaTeX_Main'),
                  text: 'T'),
                KatexSpanNode(nodes: []),
                KatexNegativeMarginNode(leftOffsetEm: -0.1667, nodes: [
                  KatexVlistNode(rows: [
                    KatexVlistRowNode(
                      verticalOffsetEm: -2.7845 + 3,
                      node: KatexSpanNode(nodes: [
                        KatexSpanNode(nodes: [
                          KatexSpanNode(
                            styles: KatexSpanStyles(fontFamily: 'KaTeX_Main'),
                            text: 'E'),
                        ]),
                      ])),
                  ]),
                  KatexSpanNode(nodes: []),
                  KatexNegativeMarginNode(leftOffsetEm: -0.125, nodes: [
                    KatexSpanNode(
                      styles: KatexSpanStyles(fontFamily: 'KaTeX_Main'),
                      text: 'X'),
                  ]),
                ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);

  static final vlistNegativeMargin = KatexExample.block(
    'vlist using negative margin (subscript X_n)',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2224918
    'X_n',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msub><mi>X</mi><mi>n</mi></msub></mrow><annotation encoding="application/x-tex">X_n</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.8333em;vertical-align:-0.15em;"></span>'
            '<span class="mord">'
              '<span class="mord mathnormal" style="margin-right:0.07847em;">X</span>'
              '<span class="msupsub">'
                '<span class="vlist-t vlist-t2">'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.1514em;">'
                      '<span style="top:-2.55em;margin-left:-0.0785em;margin-right:0.05em;">'
                        '<span class="pstrut" style="height:2.7em;"></span>'
                        '<span class="sizing reset-size6 size3 mtight">'
                          '<span class="mord mathnormal mtight">n</span></span></span></span>'
                    '<span class="vlist-s">​</span></span>'
                  '<span class="vlist-r">'
                    '<span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.8333, verticalAlignEm: -0.15),
        KatexSpanNode(nodes: [
          KatexSpanNode(
            styles: KatexSpanStyles(
              marginRightEm: 0.07847,
              fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
            text: 'X'),
          KatexSpanNode(
            styles: KatexSpanStyles(textAlign: KatexSpanTextAlign.left),
            nodes: [
              KatexVlistNode(rows: [
                KatexVlistRowNode(
                  verticalOffsetEm: -2.55 + 2.7,
                  node: KatexSpanNode(nodes: [
                    KatexNegativeMarginNode(leftOffsetEm: -0.0785, nodes: [
                      KatexSpanNode(
                        styles: KatexSpanStyles(marginRightEm: 0.05),
                        nodes: [
                          KatexSpanNode(
                            styles: KatexSpanStyles(fontSizeEm: 0.7), // .reset-size6.size3
                            nodes: [
                              KatexSpanNode(
                                styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
                                text: 'n'),
                            ]),
                        ]),
                    ]),
                  ])),
              ]),
            ]),
        ]),
      ]),
    ]);

  static final color = KatexExample.block(
    r'\color: 3-digit hex color',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2232197
    r'\color{#f00} 0',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="#f00"><mn>0</mn></mstyle></mrow><annotation encoding="application/x-tex">\\color{#f00} 0</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:#f00;">0</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(color: KatexSpanColor(255, 0, 0, 255)),
          text: '0'),
      ]),
    ]);

  static final textColor = KatexExample.block(
    r'\textcolor: CSS named color',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2232198
    r'\textcolor{red} 1',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="red"><mn>1</mn></mstyle></mrow><annotation encoding="application/x-tex">\\textcolor{red} 1</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:red;">1</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(color: KatexSpanColor(255, 0, 0, 255)),
          text: '1'),
      ]),
    ]);

  // KaTeX custom color macros, see https://github.com/KaTeX/KaTeX/blob/9fb63136e/src/macros.js#L977-L1033
  static final customColorMacro = KatexExample.block(
    r'\red, custom KaTeX color macro: CSS 6-digit hex color',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2232199
    r'\red 2',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="#df0030"><mn>2</mn></mstyle></mrow><annotation encoding="application/x-tex">\\red 2</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:#df0030;">2</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6444, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(color: KatexSpanColor(223, 0, 48, 255)),
          text: '2'),
      ]),
    ]);

  static final phantom = KatexExample.block(
    r'\phantom: span with "color: transparent"',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2229515
    r'\phantom{*}',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mphantom><mo>∗</mo></mphantom></mrow><annotation encoding="application/x-tex">\\phantom{*}</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.4653em;"></span>'
            '<span class="mord" style="color:transparent;">∗</span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.4653, verticalAlignEm: null),
        KatexSpanNode(
          styles: KatexSpanStyles(color: KatexSpanColor(0, 0, 0, 0)),
          text: '∗'),
      ]),
    ]);

  static final nulldelimiter = KatexExample.block(
    r'null delimiters, like `\left.`',
    // https://chat.zulip.org/#narrow/channel/7-test-here/topic/Rajesh/near/2205534
    r'\left. a \middle. b \right.',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>a</mi><mo fence="true" lspace="0.05em" rspace="0.05em">.</mo><mi>b</mi></mrow><annotation encoding="application/x-tex">\\left. a \\middle. b \\right.</annotation></semantics></math></span>'
      '<span class="katex-html" aria-hidden="true">'
        '<span class="base">'
          '<span class="strut" style="height:0.6944em;"></span>'
          '<span class="minner">'
            '<span class="mopen nulldelimiter"></span>'
            '<span class="mord mathnormal">a</span>'
            '<span class="nulldelimiter"></span>'
            '<span class="mord mathnormal">b</span>'
            '<span class="mclose nulldelimiter"></span></span></span></span></span></span></p>', [
      KatexSpanNode(nodes: [
        KatexStrutNode(heightEm: 0.6944, verticalAlignEm: null),
        KatexSpanNode(nodes: [
          KatexSpanNode(styles: KatexSpanStyles(widthEm: 0.12), nodes: []),
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
            text: 'a'),
          KatexSpanNode(styles: KatexSpanStyles(widthEm: 0.12), nodes: []),
          KatexSpanNode(
            styles: KatexSpanStyles(fontFamily: 'KaTeX_Math', fontStyle: KatexSpanFontStyle.italic),
            text: 'b'),
          KatexSpanNode(styles: KatexSpanStyles(widthEm: 0.12), nodes: []),
        ]),
      ]),
    ]);
}

void main() async {
  TestZulipBinding.ensureInitialized();

  testParseExample(KatexExample.sizing);
  testParseExample(KatexExample.nestedSizing);
  testParseExample(KatexExample.delimsizing);
  testParseExample(KatexExample.spacing);
  testParseExample(KatexExample.vlistSuperscript);
  testParseExample(KatexExample.vlistSubscript);
  testParseExample(KatexExample.vlistSubAndSuperscript);
  testParseExample(KatexExample.vlistRaisebox);
  testParseExample(KatexExample.negativeMargin);
  testParseExample(KatexExample.katexLogo);
  testParseExample(KatexExample.vlistNegativeMargin);
  testParseExample(KatexExample.color);
  testParseExample(KatexExample.textColor);
  testParseExample(KatexExample.customColorMacro);
  testParseExample(KatexExample.phantom);
  testParseExample(KatexExample.nulldelimiter);

  group('parseCssHexColor', () {
    const testCases = [
      ('#c0c0c0ff', KatexSpanColor(192, 192, 192, 255)),
      ('#f00ba4',   KatexSpanColor(240, 11, 164, 255)),
      ('#cafe',     KatexSpanColor(204, 170, 255, 238)),

      ('#ffffffff', KatexSpanColor(255, 255, 255, 255)),
      ('#ffffff',   KatexSpanColor(255, 255, 255, 255)),
      ('#ffff',     KatexSpanColor(255, 255, 255, 255)),
      ('#fff',      KatexSpanColor(255, 255, 255, 255)),
      ('#00ffffff', KatexSpanColor(0, 255, 255, 255)),
      ('#00ffff',   KatexSpanColor(0, 255, 255, 255)),
      ('#0fff',     KatexSpanColor(0, 255, 255, 255)),
      ('#0ff',      KatexSpanColor(0, 255, 255, 255)),
      ('#ff00ffff', KatexSpanColor(255, 0, 255, 255)),
      ('#ff00ff',   KatexSpanColor(255, 0, 255, 255)),
      ('#f0ff',     KatexSpanColor(255, 0, 255, 255)),
      ('#f0f',      KatexSpanColor(255, 0, 255, 255)),
      ('#ffff00ff', KatexSpanColor(255, 255, 0, 255)),
      ('#ffff00',   KatexSpanColor(255, 255, 0, 255)),
      ('#ff0f',     KatexSpanColor(255, 255, 0, 255)),
      ('#ff0',      KatexSpanColor(255, 255, 0, 255)),
      ('#ffffff00', KatexSpanColor(255, 255, 255, 0)),
      ('#fff0',     KatexSpanColor(255, 255, 255, 0)),

      ('#FF00FFFF', KatexSpanColor(255, 0, 255, 255)),
      ('#FF00FF',   KatexSpanColor(255, 0, 255, 255)),

      ('#ff00FFff', KatexSpanColor(255, 0, 255, 255)),
      ('#ff00FF',   KatexSpanColor(255, 0, 255, 255)),

      ('#F',        null),
      ('#FF',       null),
      ('#FFFFF',    null),
      ('#FFFFFFF',  null),
      ('FFF',       null),
    ];

    for (final testCase in testCases) {
      test(testCase.$1, () {
        check(parseCssHexColor(testCase.$1)).equals(testCase.$2);
      });
    }
  });

  test('all KaTeX content examples are tested', () {
    // Check that every KatexExample defined above has a corresponding
    // actual test case that runs on it.  If you've added a new example
    // and this test breaks, remember to add a `testParseExample` call for it.

    // This implementation is a bit of a hack; it'd be cleaner to get the
    // actual Dart parse tree using package:analyzer.  Unfortunately that
    // approach takes several seconds just to load the parser library, enough
    // to add noticeably to the runtime of our whole test suite.
    final thisFilename = Trace.current().frames[0].uri.path;
    final source = File(thisFilename).readAsStringSync();
    final declaredExamples = RegExp(multiLine: true,
      r'^\s*static\s+(?:const|final)\s+(\w+)\s*=\s*KatexExample\s*(?:\.\s*(?:inline|block)\s*)?\(',
    ).allMatches(source).map((m) => m.group(1));
    final testedExamples = RegExp(multiLine: true,
      r'^\s*testParseExample\s*\(\s*KatexExample\s*\.\s*(\w+)(?:,\s*skip:\s*true)?\s*\);',
    ).allMatches(source).map((m) => m.group(1));
    check(testedExamples).unorderedEquals(declaredExamples);
  }, skip: Platform.isWindows, // [intended] purely analyzes source, so
       // any one platform is enough; avoid dealing with Windows file paths
  );
}
