import 'package:flutter/material.dart';

import '../model/code_block.dart';

// Highlighted code block styles adapted from:
// https://github.com/zulip/zulip/blob/213387249e7ba7772084411b22d8cef64b135dd0/web/styles/pygments.css

// .hll { background-color: hsl(60deg 100% 90%); }
final _kCodeBlockStyleHll = TextStyle(backgroundColor: const HSLColor.fromAHSL(1, 60, 1, 0.90).toColor());

// .c { color: hsl(180deg 33% 37%); font-style: italic; }
final _kCodeBlockStyleC = TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic);

// TODO: Borders are hard in TextSpan, see the comment in `_buildInlineCode`
// So, using a lighter background color for now (precisely it's
// the text color used in web app in `.err` class in dark mode)
//
// .err { border: 1px solid hsl(0deg 100% 50%); }
const _kCodeBlockStyleErr = TextStyle(backgroundColor: Color(0xffe2706e));

// .k { color: hsl(332deg 70% 38%); }
final _kCodeBlockStyleK = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor());

// .o { color: hsl(332deg 70% 38%); }
final _kCodeBlockStyleO = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor());

// .cm { color: hsl(180deg 33% 37%); font-style: italic; }
final _kCodeBlockStyleCm = TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic);

// .cp { color: hsl(38deg 100% 36%); }
final _kCodeBlockStyleCp = TextStyle(color: const HSLColor.fromAHSL(1, 38, 1, 0.36).toColor());

// .c1 { color: hsl(0deg 0% 67%); font-style: italic; }
final _kCodeBlockStyleC1 = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.67).toColor(), fontStyle: FontStyle.italic);

// .cs { color: hsl(180deg 33% 37%); font-style: italic; }
final _kCodeBlockStyleCs = TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic);

// .gd { color: hsl(0deg 100% 31%); }
final _kCodeBlockStyleGd = TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.31).toColor());

// .ge { font-style: italic; }
const _kCodeBlockStyleGe = TextStyle(fontStyle: FontStyle.italic);

// .gr { color: hsl(0deg 100% 50%); }
final _kCodeBlockStyleGr = TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.50).toColor());

// .gh { color: hsl(240deg 100% 25%); font-weight: bold; }
final _kCodeBlockStyleGh = TextStyle(color: const HSLColor.fromAHSL(1, 240, 1, 0.25).toColor(), fontWeight: FontWeight.bold);

// .gi { color: hsl(120deg 100% 31%); }
final _kCodeBlockStyleGi = TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.31).toColor());

// .go { color: hsl(0deg 0% 50%); }
final _kCodeBlockStyleGo = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.50).toColor());

// .gp { color: hsl(240deg 100% 25%); font-weight: bold; }
final _kCodeBlockStyleGp = TextStyle(color: const HSLColor.fromAHSL(1, 240, 1, 0.25).toColor(), fontWeight: FontWeight.bold);

// .gs { font-weight: bold; }
const _kCodeBlockStyleGs = TextStyle(fontWeight: FontWeight.bold);

// .gu { color: hsl(300deg 100% 25%); font-weight: bold; }
final _kCodeBlockStyleGu = TextStyle(color: const HSLColor.fromAHSL(1, 300, 1, 0.25).toColor(), fontWeight: FontWeight.bold);

// .gt { color: hsl(221deg 100% 40%); }
final _kCodeBlockStyleGt = TextStyle(color: const HSLColor.fromAHSL(1, 221, 1, 0.40).toColor());

// .kc { color: hsl(332deg 70% 38%); font-weight: bold; }
final _kCodeBlockStyleKc = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor(), fontWeight: FontWeight.bold);

// .kd { color: hsl(332deg 70% 38%); }
final _kCodeBlockStyleKd = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor());

// .kn { color: hsl(332deg 70% 38%); font-weight: bold; }
final _kCodeBlockStyleKn = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor(), fontWeight: FontWeight.bold);

// .kp { color: hsl(332deg 70% 38%); }
final _kCodeBlockStyleKp = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor());

// .kr { color: hsl(332deg 70% 38%); font-weight: bold; }
final _kCodeBlockStyleKr = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor(), fontWeight: FontWeight.bold);

// .kt { color: hsl(332deg 70% 38%); }
final _kCodeBlockStyleKt = TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor());

// .m { color: hsl(0deg 0% 40%); }
final _kCodeBlockStyleM = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.40).toColor());

// .s { color: hsl(86deg 57% 40%); }
final _kCodeBlockStyleS = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor());

// .na { color: hsl(71deg 55% 36%); }
final _kCodeBlockStyleNa = TextStyle(color: const HSLColor.fromAHSL(1, 71, 0.55, 0.36).toColor());

// .nb { color: hsl(195deg 100% 35%); }
final _kCodeBlockStyleNb = TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor());

// .nc { color: hsl(264deg 27% 50%); font-weight: bold; }
final _kCodeBlockStyleNc = TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor(), fontWeight: FontWeight.bold);

// .no { color: hsl(0deg 100% 26%); }
final _kCodeBlockStyleNo = TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.26).toColor());

// .nd { color: hsl(276deg 100% 56%); }
final _kCodeBlockStyleNd = TextStyle(color: const HSLColor.fromAHSL(1, 276, 1, 0.56).toColor());

// .ni { color: hsl(0deg 0% 60%); font-weight: bold; }
final _kCodeBlockStyleNi = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.60).toColor(), fontWeight: FontWeight.bold);

// .ne { color: hsl(2deg 62% 52%); font-weight: bold; }
final _kCodeBlockStyleNe = TextStyle(color: const HSLColor.fromAHSL(1, 2, 0.62, 0.52).toColor(), fontWeight: FontWeight.bold);

// .nf { color: hsl(264deg 27% 50%); }
final _kCodeBlockStyleNf = TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor());

// .nl { color: hsl(60deg 100% 31%); }
final _kCodeBlockStyleNl = TextStyle(color: const HSLColor.fromAHSL(1, 60, 1, 0.31).toColor());

// .nn { color: hsl(264deg 27% 50%); font-weight: bold; }
final _kCodeBlockStyleNn = TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor(), fontWeight: FontWeight.bold);

// .nt { color: hsl(120deg 100% 25%); font-weight: bold; }
final _kCodeBlockStyleNt = TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor(), fontWeight: FontWeight.bold);

// .nv { color: hsl(241deg 68% 28%); }
final _kCodeBlockStyleNv = TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor());

// .nx { color: hsl(0deg 0% 26%); }
final _kCodeBlockStyleNx = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.26).toColor());

// .ow { color: hsl(276deg 100% 56%); font-weight: bold; }
final _kCodeBlockStyleOw = TextStyle(color: const HSLColor.fromAHSL(1, 276, 1, 0.56).toColor(), fontWeight: FontWeight.bold);

// .w { color: hsl(0deg 0% 73%); }
final _kCodeBlockStyleW = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.73).toColor());

// .mf { color: hsl(195deg 100% 35%); }
final _kCodeBlockStyleMf = TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor());

// .mh { color: hsl(195deg 100% 35%); }
final _kCodeBlockStyleMh = TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor());

// .mi { color: hsl(195deg 100% 35%); }
final _kCodeBlockStyleMi = TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor());

// .mo { color: hsl(195deg 100% 35%); }
final _kCodeBlockStyleMo = TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor());

// .sb { color: hsl(86deg 57% 40%); }
final _kCodeBlockStyleSb = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor());

// .sc { color: hsl(86deg 57% 40%); }
final _kCodeBlockStyleSc = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor());

// .sd { color: hsl(86deg 57% 40%); font-style: italic; }
final _kCodeBlockStyleSd = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor(), fontStyle: FontStyle.italic);

// .s2 { color: hsl(225deg 71% 33%); }
final _kCodeBlockStyleS2 = TextStyle(color: const HSLColor.fromAHSL(1, 225, 0.71, 0.33).toColor());

// .se { color: hsl(26deg 69% 43%); font-weight: bold; }
final _kCodeBlockStyleSe = TextStyle(color: const HSLColor.fromAHSL(1, 26, 0.69, 0.43).toColor(), fontWeight: FontWeight.bold);

// .sh { color: hsl(86deg 57% 40%); }
final _kCodeBlockStyleSh = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor());

// .si { color: hsl(336deg 38% 56%); font-weight: bold; }
final _kCodeBlockStyleSi = TextStyle(color: const HSLColor.fromAHSL(1, 336, 0.38, 0.56).toColor(), fontWeight: FontWeight.bold);

// .sx { color: hsl(120deg 100% 25%); }
final _kCodeBlockStyleSx = TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor());

// .sr { color: hsl(189deg 54% 49%); }
final _kCodeBlockStyleSr = TextStyle(color: const HSLColor.fromAHSL(1, 189, 0.54, 0.49).toColor());

// .s1 { color: hsl(86deg 57% 40%); }
final _kCodeBlockStyleS1 = TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor());

// .ss { color: hsl(241deg 68% 28%); }
final _kCodeBlockStyleSs = TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor());

// .bp { color: hsl(120deg 100% 25%); }
final _kCodeBlockStyleBp = TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor());

// .vc { color: hsl(241deg 68% 28%); }
final _kCodeBlockStyleVc = TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor());

// .vg { color: hsl(241deg 68% 28%); }
final _kCodeBlockStyleVg = TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor());

// .vi { color: hsl(241deg 68% 28%); }
final _kCodeBlockStyleVi = TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor());

// .il { color: hsl(0deg 0% 40%); }
final _kCodeBlockStyleIl = TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.40).toColor());

TextStyle? codeBlockTextStyle(CodeBlockSpanType type) {
  return switch (type) {
    CodeBlockSpanType.text => null, // A span with type of text is always unstyled.
    CodeBlockSpanType.highlightedLines => _kCodeBlockStyleHll,
    CodeBlockSpanType.comment => _kCodeBlockStyleC,
    CodeBlockSpanType.error => _kCodeBlockStyleErr,
    CodeBlockSpanType.keyword => _kCodeBlockStyleK,
    CodeBlockSpanType.operator => _kCodeBlockStyleO,
    CodeBlockSpanType.commentMultiline => _kCodeBlockStyleCm,
    CodeBlockSpanType.commentPreproc => _kCodeBlockStyleCp,
    CodeBlockSpanType.commentSingle => _kCodeBlockStyleC1,
    CodeBlockSpanType.commentSpecial => _kCodeBlockStyleCs,
    CodeBlockSpanType.genericDeleted => _kCodeBlockStyleGd,
    CodeBlockSpanType.genericEmph => _kCodeBlockStyleGe,
    CodeBlockSpanType.genericError => _kCodeBlockStyleGr,
    CodeBlockSpanType.genericHeading => _kCodeBlockStyleGh,
    CodeBlockSpanType.genericInserted => _kCodeBlockStyleGi,
    CodeBlockSpanType.genericOutput => _kCodeBlockStyleGo,
    CodeBlockSpanType.genericPrompt => _kCodeBlockStyleGp,
    CodeBlockSpanType.genericStrong => _kCodeBlockStyleGs,
    CodeBlockSpanType.genericSubheading => _kCodeBlockStyleGu,
    CodeBlockSpanType.genericTraceback => _kCodeBlockStyleGt,
    CodeBlockSpanType.keywordConstant => _kCodeBlockStyleKc,
    CodeBlockSpanType.keywordDeclaration => _kCodeBlockStyleKd,
    CodeBlockSpanType.keywordNamespace => _kCodeBlockStyleKn,
    CodeBlockSpanType.keywordPseudo => _kCodeBlockStyleKp,
    CodeBlockSpanType.keywordReserved => _kCodeBlockStyleKr,
    CodeBlockSpanType.keywordType => _kCodeBlockStyleKt,
    CodeBlockSpanType.number => _kCodeBlockStyleM,
    CodeBlockSpanType.string => _kCodeBlockStyleS,
    CodeBlockSpanType.nameAttribute => _kCodeBlockStyleNa,
    CodeBlockSpanType.nameBuiltin => _kCodeBlockStyleNb,
    CodeBlockSpanType.nameClass => _kCodeBlockStyleNc,
    CodeBlockSpanType.nameConstant => _kCodeBlockStyleNo,
    CodeBlockSpanType.nameDecorator => _kCodeBlockStyleNd,
    CodeBlockSpanType.nameEntity => _kCodeBlockStyleNi,
    CodeBlockSpanType.nameException => _kCodeBlockStyleNe,
    CodeBlockSpanType.nameFunction => _kCodeBlockStyleNf,
    CodeBlockSpanType.nameLabel => _kCodeBlockStyleNl,
    CodeBlockSpanType.nameNamespace => _kCodeBlockStyleNn,
    CodeBlockSpanType.nameTag => _kCodeBlockStyleNt,
    CodeBlockSpanType.nameVariable => _kCodeBlockStyleNv,
    CodeBlockSpanType.nameOther => _kCodeBlockStyleNx,
    CodeBlockSpanType.operatorWord => _kCodeBlockStyleOw,
    CodeBlockSpanType.whitespace => _kCodeBlockStyleW,
    CodeBlockSpanType.numberFloat => _kCodeBlockStyleMf,
    CodeBlockSpanType.numberHex => _kCodeBlockStyleMh,
    CodeBlockSpanType.numberInteger => _kCodeBlockStyleMi,
    CodeBlockSpanType.numberOct => _kCodeBlockStyleMo,
    CodeBlockSpanType.stringBacktick => _kCodeBlockStyleSb,
    CodeBlockSpanType.stringChar => _kCodeBlockStyleSc,
    CodeBlockSpanType.stringDoc => _kCodeBlockStyleSd,
    CodeBlockSpanType.stringDouble => _kCodeBlockStyleS2,
    CodeBlockSpanType.stringEscape => _kCodeBlockStyleSe,
    CodeBlockSpanType.stringHeredoc => _kCodeBlockStyleSh,
    CodeBlockSpanType.stringInterpol => _kCodeBlockStyleSi,
    CodeBlockSpanType.stringOther => _kCodeBlockStyleSx,
    CodeBlockSpanType.stringRegex => _kCodeBlockStyleSr,
    CodeBlockSpanType.stringSingle => _kCodeBlockStyleS1,
    CodeBlockSpanType.stringSymbol => _kCodeBlockStyleSs,
    CodeBlockSpanType.nameBuiltinPseudo => _kCodeBlockStyleBp,
    CodeBlockSpanType.nameVariableClass => _kCodeBlockStyleVc,
    CodeBlockSpanType.nameVariableGlobal => _kCodeBlockStyleVg,
    CodeBlockSpanType.nameVariableInstance => _kCodeBlockStyleVi,
    CodeBlockSpanType.numberIntegerLong => _kCodeBlockStyleIl,
    _ => null, // not every token is styled
  };
}
