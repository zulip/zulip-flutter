import 'dart:io';

import 'package:checks/checks.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test_api/scaffolding.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/katex.dart';

import 'binding.dart';
import 'content_test.dart';

class KatexExample extends ContentExample {
  KatexExample.inline(String description, String texSource, String html)
    : super.inline(description, '\$\$ $texSource \$\$', html,
        MathInlineNode(texSource: texSource));

  KatexExample.block(String description, String texSource, String html)
    : super(description, '```math\n$texSource\n```', html,
        [MathBlockNode(texSource: texSource)]);

  static final sizing = KatexExample.block(
    'different font sizes',
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
            '<span class="mord sizing reset-size6 size1">0</span></span></span></span></span></p>');

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
              '<span class="mord sizing reset-size1 size11">2</span></span></span></span></span></span></p>');

  static final delimsizing = KatexExample.block(
    'delimsizing spans, big delimiters',
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
            '<span class="mord"><span class="delimsizing size4">⌊</span></span></span></span></span></span></p>');

  static final spacing = KatexExample.block(
    'positive horizontal spacing with margin-right',
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
            '<span class="mord">2</span></span></span></span></span></p>');

  static final vlistSuperscript = KatexExample.block(
    'superscript: single vlist-r, single vertical offset row',
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
                            '<span class="mord mtight">′</span></span></span></span></span></span></span></span></span></span></span></span></span></p>');

  static final vlistSubscript = KatexExample.block(
    'subscript: two vlist-r, single vertical offset row',
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
                    '<span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span></span></span></span></span></p>');

  static final vlistSubAndSuperscript = KatexExample.block(
    'subscript and superscript: two vlist-r, multiple vertical offset rows',
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
                    '<span class="vlist" style="height:0.247em;"><span></span></span></span></span></span></span></span></span></span></p>');

  static final vlistRaisebox = KatexExample.block(
    r'\raisebox: single vlist-r, single vertical offset row',
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
            '<span class="mord mathnormal">c</span></span></span></span></span></p>');

  static final negativeMargin = KatexExample.block(
    r'negative horizontal margin (\!)',
    r'1 \! 2',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mn>1</mn><mtext> ⁣</mtext><mn>2</mn></mrow><annotation encoding="application/x-tex">1 \\! 2</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord">1</span>'
            '<span class="mspace" style="margin-right:-0.1667em;"></span>'
            '<span class="mord">2</span></span></span></span></span></p>');

  static final katexLogo = KatexExample.block(
    'KaTeX logo: vlists, negative margins',
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
                '<span class="mord textrm">X</span></span></span></span></span></span></span></p>');

  static final vlistNegativeMargin = KatexExample.block(
    'vlist using negative margin (subscript X_n)',
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
                    '<span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span></span></span></span></p>');

  static final color = KatexExample.block(
    r'\color: 3-digit hex color',
    r'\color{#f00} 0',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="#f00"><mn>0</mn></mstyle></mrow><annotation encoding="application/x-tex">\\color{#f00} 0</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:#f00;">0</span></span></span></span></span></p>');

  static final textColor = KatexExample.block(
    r'\textcolor: CSS named color',
    r'\textcolor{red} 1',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="red"><mn>1</mn></mstyle></mrow><annotation encoding="application/x-tex">\\textcolor{red} 1</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:red;">1</span></span></span></span></span></p>');

  static final customColorMacro = KatexExample.block(
    r'\red, custom KaTeX color macro: CSS 6-digit hex color',
    r'\red 2',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mstyle mathcolor="#df0030"><mn>2</mn></mstyle></mrow><annotation encoding="application/x-tex">\\red 2</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.6444em;"></span>'
            '<span class="mord" style="color:#df0030;">2</span></span></span></span></span></p>');

  static final phantom = KatexExample.block(
    r'\phantom: span with "color: transparent"',
    r'\phantom{*}',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mphantom><mo>∗</mo></mphantom></mrow><annotation encoding="application/x-tex">\\phantom{*}</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.4653em;"></span>'
            '<span class="mord" style="color:transparent;">∗</span></span></span></span></span></p>');

  static final bigOperators = KatexExample.block(
    r'big operators: \int',
    r'\int',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mo>∫</mo></mrow><annotation encoding="application/x-tex">\\int</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:2.2222em;vertical-align:-0.8622em;"></span>'
            '<span class="mop op-symbol large-op" style="margin-right:0.44445em;position:relative;top:-0.0011em;">∫</span></span></span></span></span></p>');

  static final colonEquals = KatexExample.block(
    r'\colonequals relation',
    r'\colonequals',
    '<p>'
      '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mo><mi mathvariant="normal">≔</mi></mo></mrow><annotation encoding="application/x-tex">\\colonequals</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true">'
          '<span class="base">'
            '<span class="strut" style="height:0.4306em;"></span>'
            '<span class="mrel">'
              '<span class="mrel">'
                '<span class="mop" style="position:relative;top:-0.0347em;">:</span></span>'
              '<span class="mrel">'
                '<span class="mspace" style="margin-right:-0.0667em;"></span></span>'
              '<span class="mrel">=</span></span></span></span></span></span></p>');

  static final nulldelimiter = KatexExample.block(
    r'null delimiters, like `\left.`',
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
            '<span class="mclose nulldelimiter"></span></span></span></span></span></span></p>');
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
  testParseExample(KatexExample.bigOperators);
  testParseExample(KatexExample.colonEquals);
  testParseExample(KatexExample.nulldelimiter);

  group('parseMath', () {
    test('returns tex source for inline math', () {
      final html = '<span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex"> \\lambda </annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span>';
      final element = HtmlParser(html, parseMeta: false).parseFragment().nodes.single as dom.Element;
      check(parseMath(element, block: false)).equals(r'\lambda');
    });

    test('returns tex source for block math', () {
      final html = '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span>';
      final element = HtmlParser(html, parseMeta: false).parseFragment().nodes.single as dom.Element;
      check(parseMath(element, block: true)).equals(r'\lambda');
    });

    test('returns null for block math with wrong display attribute', () {
      final html = '<span class="katex-display"><span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '<annotation encoding="application/x-tex">\\lambda</annotation></semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span></span>';
      final element = HtmlParser(html, parseMeta: false).parseFragment().nodes.single as dom.Element;
      check(parseMath(element, block: true)).isNull();
    });

    test('returns null for block math with missing katex child', () {
      final html = '<span class="katex-display"><span class="other"></span></span>';
      final element = HtmlParser(html, parseMeta: false).parseFragment().nodes.single as dom.Element;
      check(parseMath(element, block: true)).isNull();
    });

    test('returns null for inline math with missing annotation', () {
      final html = '<span class="katex">'
        '<span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>λ</mi></mrow>'
          '</semantics></math></span>'
        '<span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:0.6944em;"></span><span class="mord mathnormal">λ</span></span></span></span>';
      final element = HtmlParser(html, parseMeta: false).parseFragment().nodes.single as dom.Element;
      check(parseMath(element, block: false)).isNull();
    });
  });

  test('all KaTeX content examples are tested', () {
    final thisFilename = Trace.current().frames[0].uri.path;
    final source = File(thisFilename).readAsStringSync();
    final declaredExamples = RegExp(multiLine: true,
      r'^\s*static\s+(?:const|final)\s+(\w+)\s*=\s*KatexExample\s*(?:\.\s*(?:inline|block)\s*)?\(',
    ).allMatches(source).map((m) => m.group(1));
    final testedExamples = RegExp(multiLine: true,
      r'^\s*testParseExample\s*\(\s*KatexExample\s*\.\s*(\w+)(?:,\s*skip:\s*true)?\s*\);',
    ).allMatches(source).map((m) => m.group(1));
    check(testedExamples).unorderedEquals(declaredExamples);
  }, skip: Platform.isWindows);
}
