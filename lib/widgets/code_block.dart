import 'package:flutter/material.dart';

import '../model/code_block.dart';
import 'content.dart';
import 'text.dart';

/// [TextStyle]s used to render code blocks.
///
/// Use [forSpan] for syntax highlighting.
// TODO(#749) follow web for dark-theme colors
class CodeBlockTextStyles {
  factory CodeBlockTextStyles(BuildContext context) {
    final bold = weightVariableTextStyle(context, wght: 700);
    return CodeBlockTextStyles._(
      plain: kMonospaceTextStyle
        .merge(const TextStyle(
          fontSize: 0.825 * kBaseFontSize,
          height: 1.4))
        .merge(weightVariableTextStyle(context)),

      // .hll { background-color: hsl(60deg 100% 90%); }
      hll: TextStyle(backgroundColor: const HSLColor.fromAHSL(1, 60, 1, 0.90).toColor()),

      // .c { color: hsl(180deg 33% 37%); font-style: italic; }
      c: TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic),

      // TODO: Borders are hard in TextSpan, see the comment in `_buildInlineCode`
      // So instead, using a background color for now.
      //
      // .err { border: 1px solid hsl(0deg 100% 50%); }
      err: const TextStyle(backgroundColor: Color(0xffe2706e)),

      // .k { color: hsl(332deg 70% 38%); }
      k: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor()),

      // .o { color: hsl(332deg 70% 38%); }
      o: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor()),

      // .cm { color: hsl(180deg 33% 37%); font-style: italic; }
      cm: TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic),

      // .cp { color: hsl(38deg 100% 36%); }
      cp: TextStyle(color: const HSLColor.fromAHSL(1, 38, 1, 0.36).toColor()),

      // .c1 { color: hsl(0deg 0% 67%); font-style: italic; }
      c1: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.67).toColor(), fontStyle: FontStyle.italic),

      // .cs { color: hsl(180deg 33% 37%); font-style: italic; }
      cs: TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic),

      // .gd { color: hsl(0deg 100% 31%); }
      gd: TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.31).toColor()),

      // .ge { font-style: italic; }
      ge: const TextStyle(fontStyle: FontStyle.italic),

      // .gr { color: hsl(0deg 100% 50%); }
      gr: TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.50).toColor()),

      // .gh { color: hsl(240deg 100% 25%); font-weight: bold; }
      gh: TextStyle(color: const HSLColor.fromAHSL(1, 240, 1, 0.25).toColor()).merge(bold),

      // .gi { color: hsl(120deg 100% 31%); }
      gi: TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.31).toColor()),

      // .go { color: hsl(0deg 0% 50%); }
      go: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.50).toColor()),

      // .gp { color: hsl(240deg 100% 25%); font-weight: bold; }
      gp: TextStyle(color: const HSLColor.fromAHSL(1, 240, 1, 0.25).toColor()).merge(bold),

      // .gs { font-weight: bold; }
      gs: const TextStyle().merge(bold),

      // .gu { color: hsl(300deg 100% 25%); font-weight: bold; }
      gu: TextStyle(color: const HSLColor.fromAHSL(1, 300, 1, 0.25).toColor()).merge(bold),

      // .gt { color: hsl(221deg 100% 40%); }
      gt: TextStyle(color: const HSLColor.fromAHSL(1, 221, 1, 0.40).toColor()),

      // .kc { color: hsl(332deg 70% 38%); font-weight: bold; }
      kc: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()).merge(bold),

      // .kd { color: hsl(332deg 70% 38%); }
      kd: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()),

      // .kn { color: hsl(332deg 70% 38%); font-weight: bold; }
      kn: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()).merge(bold),

      // .kp { color: hsl(332deg 70% 38%); }
      kp: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()),

      // .kr { color: hsl(332deg 70% 38%); font-weight: bold; }
      kr: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()).merge(bold),

      // .kt { color: hsl(332deg 70% 38%); }
      kt: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.70, 0.38).toColor()),

      // .m { color: hsl(0deg 0% 40%); }
      m: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.40).toColor()),

      // .s { color: hsl(86deg 57% 40%); }
      s: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .na { color: hsl(71deg 55% 36%); }
      na: TextStyle(color: const HSLColor.fromAHSL(1, 71, 0.55, 0.36).toColor()),

      // .nb { color: hsl(195deg 100% 35%); }
      nb: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .nc { color: hsl(264deg 27% 50%); font-weight: bold; }
      nc: TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor()).merge(bold),

      // .no { color: hsl(0deg 100% 26%); }
      no: TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.26).toColor()),

      // .nd { color: hsl(276deg 100% 56%); }
      nd: TextStyle(color: const HSLColor.fromAHSL(1, 276, 1, 0.56).toColor()),

      // .ni { color: hsl(0deg 0% 60%); font-weight: bold; }
      ni: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.60).toColor()).merge(bold),

      // .ne { color: hsl(2deg 62% 52%); font-weight: bold; }
      ne: TextStyle(color: const HSLColor.fromAHSL(1, 2, 0.62, 0.52).toColor()).merge(bold),

      // .nf { color: hsl(264deg 27% 50%); }
      nf: TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor()),

      // .nl { color: hsl(60deg 100% 31%); }
      nl: TextStyle(color: const HSLColor.fromAHSL(1, 60, 1, 0.31).toColor()),

      // .nn { color: hsl(264deg 27% 50%); font-weight: bold; }
      nn: TextStyle(color: const HSLColor.fromAHSL(1, 264, 0.27, 0.50).toColor()).merge(bold),

      // .nt { color: hsl(120deg 100% 25%); font-weight: bold; }
      nt: TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor()).merge(bold),

      // .nv { color: hsl(241deg 68% 28%); }
      nv: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .nx { color: hsl(0deg 0% 26%); }
      nx: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.26).toColor()),

      // .ow { color: hsl(276deg 100% 56%); font-weight: bold; }
      ow: TextStyle(color: const HSLColor.fromAHSL(1, 276, 1, 0.56).toColor()).merge(bold),

      // .w { color: hsl(0deg 0% 73%); }
      w: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.73).toColor()),

      // .mf { color: hsl(195deg 100% 35%); }
      mf: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mh { color: hsl(195deg 100% 35%); }
      mh: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mi { color: hsl(195deg 100% 35%); }
      mi: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mo { color: hsl(195deg 100% 35%); }
      mo: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .sb { color: hsl(86deg 57% 40%); }
      sb: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .sc { color: hsl(86deg 57% 40%); }
      sc: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .sd { color: hsl(86deg 57% 40%); font-style: italic; }
      sd: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor(), fontStyle: FontStyle.italic),

      // .s2 { color: hsl(225deg 71% 33%); }
      s2: TextStyle(color: const HSLColor.fromAHSL(1, 225, 0.71, 0.33).toColor()),

      // .se { color: hsl(26deg 69% 43%); font-weight: bold; }
      se: TextStyle(color: const HSLColor.fromAHSL(1, 26, 0.69, 0.43).toColor()).merge(bold),

      // .sh { color: hsl(86deg 57% 40%); }
      sh: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .si { color: hsl(336deg 38% 56%); font-weight: bold; }
      si: TextStyle(color: const HSLColor.fromAHSL(1, 336, 0.38, 0.56).toColor()).merge(bold),

      // .sx { color: hsl(120deg 100% 25%); }
      sx: TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor()),

      // .sr { color: hsl(189deg 54% 49%); }
      sr: TextStyle(color: const HSLColor.fromAHSL(1, 189, 0.54, 0.49).toColor()),

      // .s1 { color: hsl(86deg 57% 40%); }
      s1: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .ss { color: hsl(241deg 68% 28%); }
      ss: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .bp { color: hsl(120deg 100% 25%); }
      bp: TextStyle(color: const HSLColor.fromAHSL(1, 120, 1, 0.25).toColor()),

      // .vc { color: hsl(241deg 68% 28%); }
      vc: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .vg { color: hsl(241deg 68% 28%); }
      vg: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .vi { color: hsl(241deg 68% 28%); }
      vi: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .il { color: hsl(0deg 0% 40%); }
      il: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.40).toColor())
    );
  }

  CodeBlockTextStyles._({
    required this.plain,
    required TextStyle hll,
    required TextStyle c,
    required TextStyle err,
    required TextStyle k,
    required TextStyle o,
    required TextStyle cm,
    required TextStyle cp,
    required TextStyle c1,
    required TextStyle cs,
    required TextStyle gd,
    required TextStyle ge,
    required TextStyle gr,
    required TextStyle gh,
    required TextStyle gi,
    required TextStyle go,
    required TextStyle gp,
    required TextStyle gs,
    required TextStyle gu,
    required TextStyle gt,
    required TextStyle kc,
    required TextStyle kd,
    required TextStyle kn,
    required TextStyle kp,
    required TextStyle kr,
    required TextStyle kt,
    required TextStyle m,
    required TextStyle s,
    required TextStyle na,
    required TextStyle nb,
    required TextStyle nc,
    required TextStyle no,
    required TextStyle nd,
    required TextStyle ni,
    required TextStyle ne,
    required TextStyle nf,
    required TextStyle nl,
    required TextStyle nn,
    required TextStyle nt,
    required TextStyle nv,
    required TextStyle nx,
    required TextStyle ow,
    required TextStyle w,
    required TextStyle mf,
    required TextStyle mh,
    required TextStyle mi,
    required TextStyle mo,
    required TextStyle sb,
    required TextStyle sc,
    required TextStyle sd,
    required TextStyle s2,
    required TextStyle se,
    required TextStyle sh,
    required TextStyle si,
    required TextStyle sx,
    required TextStyle sr,
    required TextStyle s1,
    required TextStyle ss,
    required TextStyle bp,
    required TextStyle vc,
    required TextStyle vg,
    required TextStyle vi,
    required TextStyle il,
  }) :
    _hll = hll,
    _c = c,
    _err = err,
    _k = k,
    _o = o,
    _cm = cm,
    _cp = cp,
    _c1 = c1,
    _cs = cs,
    _gd = gd,
    _ge = ge,
    _gr = gr,
    _gh = gh,
    _gi = gi,
    _go = go,
    _gp = gp,
    _gs = gs,
    _gu = gu,
    _gt = gt,
    _kc = kc,
    _kd = kd,
    _kn = kn,
    _kp = kp,
    _kr = kr,
    _kt = kt,
    _m = m,
    _s = s,
    _na = na,
    _nb = nb,
    _nc = nc,
    _no = no,
    _nd = nd,
    _ni = ni,
    _ne = ne,
    _nf = nf,
    _nl = nl,
    _nn = nn,
    _nt = nt,
    _nv = nv,
    _nx = nx,
    _ow = ow,
    _w = w,
    _mf = mf,
    _mh = mh,
    _mi = mi,
    _mo = mo,
    _sb = sb,
    _sc = sc,
    _sd = sd,
    _s2 = s2,
    _se = se,
    _sh = sh,
    _si = si,
    _sx = sx,
    _sr = sr,
    _s1 = s1,
    _ss = ss,
    _bp = bp,
    _vc = vc,
    _vg = vg,
    _vi = vi,
    _il = il;

  /// The baseline style that the [forSpan] styles get applied on top of.
  final TextStyle plain;

  final TextStyle _hll;
  final TextStyle _c;
  final TextStyle _err;
  final TextStyle _k;
  final TextStyle _o;
  final TextStyle _cm;
  final TextStyle _cp;
  final TextStyle _c1;
  final TextStyle _cs;
  final TextStyle _gd;
  final TextStyle _ge;
  final TextStyle _gr;
  final TextStyle _gh;
  final TextStyle _gi;
  final TextStyle _go;
  final TextStyle _gp;
  final TextStyle _gs;
  final TextStyle _gu;
  final TextStyle _gt;
  final TextStyle _kc;
  final TextStyle _kd;
  final TextStyle _kn;
  final TextStyle _kp;
  final TextStyle _kr;
  final TextStyle _kt;
  final TextStyle _m;
  final TextStyle _s;
  final TextStyle _na;
  final TextStyle _nb;
  final TextStyle _nc;
  final TextStyle _no;
  final TextStyle _nd;
  final TextStyle _ni;
  final TextStyle _ne;
  final TextStyle _nf;
  final TextStyle _nl;
  final TextStyle _nn;
  final TextStyle _nt;
  final TextStyle _nv;
  final TextStyle _nx;
  final TextStyle _ow;
  final TextStyle _w;
  final TextStyle _mf;
  final TextStyle _mh;
  final TextStyle _mi;
  final TextStyle _mo;
  final TextStyle _sb;
  final TextStyle _sc;
  final TextStyle _sd;
  final TextStyle _s2;
  final TextStyle _se;
  final TextStyle _sh;
  final TextStyle _si;
  final TextStyle _sx;
  final TextStyle _sr;
  final TextStyle _s1;
  final TextStyle _ss;
  final TextStyle _bp;
  final TextStyle _vc;
  final TextStyle _vg;
  final TextStyle _vi;
  final TextStyle _il;

  /// The [TextStyle] for a [CodeBlockSpanType], if there is one.
  ///
  /// Used to render syntax highlighting.
  // Span styles adapted from:
  //   https://github.com/zulip/zulip/blob/213387249e7ba7772084411b22d8cef64b135dd0/web/styles/pygments.css
  TextStyle? forSpan(CodeBlockSpanType type) {
    return switch (type) {
      CodeBlockSpanType.text => null, // A span with type of text is always unstyled.
      CodeBlockSpanType.highlightedLines => _hll,
      CodeBlockSpanType.comment => _c,
      CodeBlockSpanType.error => _err,
      CodeBlockSpanType.keyword => _k,
      CodeBlockSpanType.operator => _o,
      CodeBlockSpanType.commentMultiline => _cm,
      CodeBlockSpanType.commentPreproc => _cp,
      CodeBlockSpanType.commentSingle => _c1,
      CodeBlockSpanType.commentSpecial => _cs,
      CodeBlockSpanType.genericDeleted => _gd,
      CodeBlockSpanType.genericEmph => _ge,
      CodeBlockSpanType.genericError => _gr,
      CodeBlockSpanType.genericHeading => _gh,
      CodeBlockSpanType.genericInserted => _gi,
      CodeBlockSpanType.genericOutput => _go,
      CodeBlockSpanType.genericPrompt => _gp,
      CodeBlockSpanType.genericStrong => _gs,
      CodeBlockSpanType.genericSubheading => _gu,
      CodeBlockSpanType.genericTraceback => _gt,
      CodeBlockSpanType.keywordConstant => _kc,
      CodeBlockSpanType.keywordDeclaration => _kd,
      CodeBlockSpanType.keywordNamespace => _kn,
      CodeBlockSpanType.keywordPseudo => _kp,
      CodeBlockSpanType.keywordReserved => _kr,
      CodeBlockSpanType.keywordType => _kt,
      CodeBlockSpanType.number => _m,
      CodeBlockSpanType.string => _s,
      CodeBlockSpanType.nameAttribute => _na,
      CodeBlockSpanType.nameBuiltin => _nb,
      CodeBlockSpanType.nameClass => _nc,
      CodeBlockSpanType.nameConstant => _no,
      CodeBlockSpanType.nameDecorator => _nd,
      CodeBlockSpanType.nameEntity => _ni,
      CodeBlockSpanType.nameException => _ne,
      CodeBlockSpanType.nameFunction => _nf,
      CodeBlockSpanType.nameLabel => _nl,
      CodeBlockSpanType.nameNamespace => _nn,
      CodeBlockSpanType.nameTag => _nt,
      CodeBlockSpanType.nameVariable => _nv,
      CodeBlockSpanType.nameOther => _nx,
      CodeBlockSpanType.operatorWord => _ow,
      CodeBlockSpanType.whitespace => _w,
      CodeBlockSpanType.numberFloat => _mf,
      CodeBlockSpanType.numberHex => _mh,
      CodeBlockSpanType.numberInteger => _mi,
      CodeBlockSpanType.numberOct => _mo,
      CodeBlockSpanType.stringBacktick => _sb,
      CodeBlockSpanType.stringChar => _sc,
      CodeBlockSpanType.stringDoc => _sd,
      CodeBlockSpanType.stringDouble => _s2,
      CodeBlockSpanType.stringEscape => _se,
      CodeBlockSpanType.stringHeredoc => _sh,
      CodeBlockSpanType.stringInterpol => _si,
      CodeBlockSpanType.stringOther => _sx,
      CodeBlockSpanType.stringRegex => _sr,
      CodeBlockSpanType.stringSingle => _s1,
      CodeBlockSpanType.stringSymbol => _ss,
      CodeBlockSpanType.nameBuiltinPseudo => _bp,
      CodeBlockSpanType.nameVariableClass => _vc,
      CodeBlockSpanType.nameVariableGlobal => _vg,
      CodeBlockSpanType.nameVariableInstance => _vi,
      CodeBlockSpanType.numberIntegerLong => _il,
      _ => null, // not every token is styled
    };
  }

  static CodeBlockTextStyles lerp(CodeBlockTextStyles a, CodeBlockTextStyles b, double t) {
    if (identical(a, b)) return a;

    return CodeBlockTextStyles._(
      plain: TextStyle.lerp(a.plain, b.plain, t)!,
      hll: TextStyle.lerp(a._hll, b._hll, t)!,
      c: TextStyle.lerp(a._c, b._c, t)!,
      err: TextStyle.lerp(a._err, b._err, t)!,
      k: TextStyle.lerp(a._k, b._k, t)!,
      o: TextStyle.lerp(a._o, b._o, t)!,
      cm: TextStyle.lerp(a._cm, b._cm, t)!,
      cp: TextStyle.lerp(a._cp, b._cp, t)!,
      c1: TextStyle.lerp(a._c1, b._c1, t)!,
      cs: TextStyle.lerp(a._cs, b._cs, t)!,
      gd: TextStyle.lerp(a._gd, b._gd, t)!,
      ge: TextStyle.lerp(a._ge, b._ge, t)!,
      gr: TextStyle.lerp(a._gr, b._gr, t)!,
      gh: TextStyle.lerp(a._gh, b._gh, t)!,
      gi: TextStyle.lerp(a._gi, b._gi, t)!,
      go: TextStyle.lerp(a._go, b._go, t)!,
      gp: TextStyle.lerp(a._gp, b._gp, t)!,
      gs: TextStyle.lerp(a._gs, b._gs, t)!,
      gu: TextStyle.lerp(a._gu, b._gu, t)!,
      gt: TextStyle.lerp(a._gt, b._gt, t)!,
      kc: TextStyle.lerp(a._kc, b._kc, t)!,
      kd: TextStyle.lerp(a._kd, b._kd, t)!,
      kn: TextStyle.lerp(a._kn, b._kn, t)!,
      kp: TextStyle.lerp(a._kp, b._kp, t)!,
      kr: TextStyle.lerp(a._kr, b._kr, t)!,
      kt: TextStyle.lerp(a._kt, b._kt, t)!,
      m: TextStyle.lerp(a._m, b._m, t)!,
      s: TextStyle.lerp(a._s, b._s, t)!,
      na: TextStyle.lerp(a._na, b._na, t)!,
      nb: TextStyle.lerp(a._nb, b._nb, t)!,
      nc: TextStyle.lerp(a._nc, b._nc, t)!,
      no: TextStyle.lerp(a._no, b._no, t)!,
      nd: TextStyle.lerp(a._nd, b._nd, t)!,
      ni: TextStyle.lerp(a._ni, b._ni, t)!,
      ne: TextStyle.lerp(a._ne, b._ne, t)!,
      nf: TextStyle.lerp(a._nf, b._nf, t)!,
      nl: TextStyle.lerp(a._nl, b._nl, t)!,
      nn: TextStyle.lerp(a._nn, b._nn, t)!,
      nt: TextStyle.lerp(a._nt, b._nt, t)!,
      nv: TextStyle.lerp(a._nv, b._nv, t)!,
      nx: TextStyle.lerp(a._nx, b._nx, t)!,
      ow: TextStyle.lerp(a._ow, b._ow, t)!,
      w: TextStyle.lerp(a._w, b._w, t)!,
      mf: TextStyle.lerp(a._mf, b._mf, t)!,
      mh: TextStyle.lerp(a._mh, b._mh, t)!,
      mi: TextStyle.lerp(a._mi, b._mi, t)!,
      mo: TextStyle.lerp(a._mo, b._mo, t)!,
      sb: TextStyle.lerp(a._sb, b._sb, t)!,
      sc: TextStyle.lerp(a._sc, b._sc, t)!,
      sd: TextStyle.lerp(a._sd, b._sd, t)!,
      s2: TextStyle.lerp(a._s2, b._s2, t)!,
      se: TextStyle.lerp(a._se, b._se, t)!,
      sh: TextStyle.lerp(a._sh, b._sh, t)!,
      si: TextStyle.lerp(a._si, b._si, t)!,
      sx: TextStyle.lerp(a._sx, b._sx, t)!,
      sr: TextStyle.lerp(a._sr, b._sr, t)!,
      s1: TextStyle.lerp(a._s1, b._s1, t)!,
      ss: TextStyle.lerp(a._ss, b._ss, t)!,
      bp: TextStyle.lerp(a._bp, b._bp, t)!,
      vc: TextStyle.lerp(a._vc, b._vc, t)!,
      vg: TextStyle.lerp(a._vg, b._vg, t)!,
      vi: TextStyle.lerp(a._vi, b._vi, t)!,
      il: TextStyle.lerp(a._il, b._il, t)!,
    );
  }
}
