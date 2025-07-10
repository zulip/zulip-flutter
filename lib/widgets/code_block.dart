import 'package:flutter/material.dart';

import '../model/code_block.dart';
import 'content.dart';
import 'text.dart';

/// [TextStyle]s used to render code blocks.
///
/// Use [forSpan] for syntax highlighting.
class CodeBlockTextStyles {
  // TODO(#754) update these styles
  factory CodeBlockTextStyles.light(BuildContext context) {
    final bold = weightVariableTextStyle(context, wght: 700);
    return CodeBlockTextStyles._(
      plain: kMonospaceTextStyle
        .merge(const TextStyle(
          color: Colors.black, // --color-markdown-code-text in web
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

      esc: null,

      g: null,

      // .k { color: hsl(332deg 70% 38%); }
      k: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor()),

      l: null,

      n: null,

      // .o { color: hsl(332deg 70% 38%); }
      o: TextStyle(color: const HSLColor.fromAHSL(1, 332, 0.7, 0.38).toColor()),

      x: null,

      p: null,

      ch: null,

      // .cm { color: hsl(180deg 33% 37%); font-style: italic; }
      cm: TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic),

      // .cp { color: hsl(38deg 100% 36%); }
      cp: TextStyle(color: const HSLColor.fromAHSL(1, 38, 1, 0.36).toColor()),

      cpf: null,

      // .c1 { color: hsl(0deg 0% 67%); font-style: italic; }
      c1: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.67).toColor(), fontStyle: FontStyle.italic),

      // .cs { color: hsl(180deg 33% 37%); font-style: italic; }
      cs: TextStyle(color: const HSLColor.fromAHSL(1, 180, 0.33, 0.37).toColor(), fontStyle: FontStyle.italic),

      // .gd { color: hsl(0deg 100% 31%); }
      gd: TextStyle(color: const HSLColor.fromAHSL(1, 0, 1, 0.31).toColor()),

      // .ge { font-style: italic; }
      ge: const TextStyle(fontStyle: FontStyle.italic),

      ges: null,

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

      ld: null,

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

      py: null,

      // .ow { color: hsl(276deg 100% 56%); font-weight: bold; }
      ow: TextStyle(color: const HSLColor.fromAHSL(1, 276, 1, 0.56).toColor()).merge(bold),

      pm: null,

      // .w { color: hsl(0deg 0% 73%); }
      w: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.73).toColor()),

      mb: null,

      // .mf { color: hsl(195deg 100% 35%); }
      mf: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mh { color: hsl(195deg 100% 35%); }
      mh: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mi { color: hsl(195deg 100% 35%); }
      mi: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      // .mo { color: hsl(195deg 100% 35%); }
      mo: TextStyle(color: const HSLColor.fromAHSL(1, 195, 1, 0.35).toColor()),

      sa: null,

      // .sb { color: hsl(86deg 57% 40%); }
      sb: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      // .sc { color: hsl(86deg 57% 40%); }
      sc: TextStyle(color: const HSLColor.fromAHSL(1, 86, 0.57, 0.40).toColor()),

      dl: null,

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

      fm: null,

      // .vc { color: hsl(241deg 68% 28%); }
      vc: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .vg { color: hsl(241deg 68% 28%); }
      vg: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      // .vi { color: hsl(241deg 68% 28%); }
      vi: TextStyle(color: const HSLColor.fromAHSL(1, 241, 0.68, 0.28).toColor()),

      vm: null,

      // .il { color: hsl(0deg 0% 40%); }
      il: TextStyle(color: const HSLColor.fromAHSL(1, 0, 0, 0.40).toColor())
    );
  }

  // Pygments Monokai, following web in web/styles/pygments.css.
  // The CSS in comments is quoted from that file.
  // The styles ultimately come from here:
  //   https://github.com/pygments/pygments/blob/f64833d9d/pygments/styles/monokai.py
  factory CodeBlockTextStyles.dark(BuildContext context) {
    final bold = weightVariableTextStyle(context, wght: 700);
    return CodeBlockTextStyles._(
      plain: kMonospaceTextStyle
        .merge(TextStyle(
          // --color-markdown-code-text in web
          color: const HSLColor.fromAHSL(0.85, 0, 0, 1).toColor(),
          fontSize: 0.825 * kBaseFontSize,
          height: 1.4))
        .merge(weightVariableTextStyle(context)),

      // .hll { background-color: #49483e; }
      hll: const TextStyle(backgroundColor: Color(0xff49483e)),

      // .c { color: #959077; }
      c: const TextStyle(color: Color(0xff959077)),

      // .err { color: #ed007e; background-color: #1e0010; }
      err: const TextStyle(color: Color(0xffed007e), backgroundColor: Color(0xff1e0010)),

      // .esc { color: #f8f8f2; }
      esc: const TextStyle(color: Color(0xfff8f8f2)),

      // .g { color: #f8f8f2; }
      g: const TextStyle(color: Color(0xfff8f8f2)),

      // .k { color: #66d9ef; }
      k: const TextStyle(color: Color(0xff66d9ef)),

      // .l { color: #ae81ff; }
      l: const TextStyle(color: Color(0xffae81ff)),

      // .n { color: #f8f8f2; }
      n: const TextStyle(color: Color(0xfff8f8f2)),

      // .o { color: #ff4689; }
      o: const TextStyle(color: Color(0xffff4689)),

      // .x { color: #f8f8f2; }
      x: const TextStyle(color: Color(0xfff8f8f2)),

      // .p { color: #f8f8f2; }
      p: const TextStyle(color: Color(0xfff8f8f2)),

      // .ch { color: #959077; }
      ch: const TextStyle(color: Color(0xff959077)),

      // .cm { color: #959077; }
      cm: const TextStyle(color: Color(0xff959077)),

      // .cp { color: #959077; }
      cp: const TextStyle(color: Color(0xff959077)),

      // .cpf { color: #959077; }
      cpf: const TextStyle(color: Color(0xff959077)),

      // .c1 { color: #959077; }
      c1: const TextStyle(color: Color(0xff959077)),

      // .cs { color: #959077; }
      cs: const TextStyle(color: Color(0xff959077)),

      // .gd { color: #ff4689; }
      gd: const TextStyle(color: Color(0xffff4689)),

      // .ge { color: #f8f8f2; font-style: italic; }
      ge: const TextStyle(color: Color(0xfff8f8f2), fontStyle: FontStyle.italic),

      // .ges { color: #f8f8f2; font-weight: bold; font-style: italic; }
      ges: const TextStyle(color: Color(0xfff8f8f2), fontStyle: FontStyle.italic).merge(bold),

      // .gr { color: #f8f8f2; }
      gr: const TextStyle(color: Color(0xfff8f8f2)),

      // .gh { color: #f8f8f2; }
      gh: const TextStyle(color: Color(0xfff8f8f2)),

      // .gi { color: #a6e22e; }
      gi: const TextStyle(color: Color(0xffa6e22e)),

      // .go { color: #66d9ef; }
      go: const TextStyle(color: Color(0xff66d9ef)),

      // .gp { color: #ff4689; font-weight: bold; }
      gp: const TextStyle(color: Color(0xffff4689)).merge(bold),

      // .gs { color: #f8f8f2; font-weight: bold; }
      gs: const TextStyle(color: Color(0xfff8f8f2)).merge(bold),

      // .gu { color: #959077; }
      gu: const TextStyle(color: Color(0xff959077)),

      // .gt { color: #f8f8f2; }
      gt: const TextStyle(color: Color(0xfff8f8f2)),

      // .kc { color: #66d9ef; }
      kc: const TextStyle(color: Color(0xff66d9ef)),

      // .kd { color: #66d9ef; }
      kd: const TextStyle(color: Color(0xff66d9ef)),

      // .kn { color: #ff4689; }
      kn: const TextStyle(color: Color(0xffff4689)),

      // .kp { color: #66d9ef; }
      kp: const TextStyle(color: Color(0xff66d9ef)),

      // .kr { color: #66d9ef; }
      kr: const TextStyle(color: Color(0xff66d9ef)),

      // .kt { color: #66d9ef; }
      kt: const TextStyle(color: Color(0xff66d9ef)),

      // .ld { color: #e6db74; }
      ld: const TextStyle(color: Color(0xffe6db74)),

      // .m { color: #ae81ff; }
      m: const TextStyle(color: Color(0xffae81ff)),

      // .s { color: #e6db74; }
      s: const TextStyle(color: Color(0xffe6db74)),

      // .na { color: #a6e22e; }
      na: const TextStyle(color: Color(0xffa6e22e)),

      // .nb { color: #f8f8f2; }
      nb: const TextStyle(color: Color(0xfff8f8f2)),

      // .nc { color: #a6e22e; }
      nc: const TextStyle(color: Color(0xffa6e22e)),

      // .no { color: #66d9ef; }
      no: const TextStyle(color: Color(0xff66d9ef)),

      // .nd { color: #a6e22e; }
      nd: const TextStyle(color: Color(0xffa6e22e)),

      // .ni { color: #f8f8f2; }
      ni: const TextStyle(color: Color(0xfff8f8f2)),

      // .ne { color: #a6e22e; }
      ne: const TextStyle(color: Color(0xffa6e22e)),

      // .nf { color: #a6e22e; }
      nf: const TextStyle(color: Color(0xffa6e22e)),

      // .nl { color: #f8f8f2; }
      nl: const TextStyle(color: Color(0xfff8f8f2)),

      // .nn { color: #f8f8f2; }
      nn: const TextStyle(color: Color(0xfff8f8f2)),

      // .nx { color: #a6e22e; }
      nx: const TextStyle(color: Color(0xffa6e22e)),

      // .py { color: #f8f8f2; }
      py: const TextStyle(color: Color(0xfff8f8f2)),

      // .nt { color: #ff4689; }
      nt: const TextStyle(color: Color(0xffff4689)),

      // .nv { color: #f8f8f2; }
      nv: const TextStyle(color: Color(0xfff8f8f2)),

      // .ow { color: #ff4689; }
      ow: const TextStyle(color: Color(0xffff4689)),

      // .pm { color: #f8f8f2; }
      pm: const TextStyle(color: Color(0xfff8f8f2)),

      // .w { color: #f8f8f2; }
      w: const TextStyle(color: Color(0xfff8f8f2)),

      // .mb { color: #ae81ff; }
      mb: const TextStyle(color: Color(0xffae81ff)),

      // .mf { color: #ae81ff; }
      mf: const TextStyle(color: Color(0xffae81ff)),

      // .mh { color: #ae81ff; }
      mh: const TextStyle(color: Color(0xffae81ff)),

      // .mi { color: #ae81ff; }
      mi: const TextStyle(color: Color(0xffae81ff)),

      // .mo { color: #ae81ff; }
      mo: const TextStyle(color: Color(0xffae81ff)),

      // .sa { color: #e6db74; }
      sa: const TextStyle(color: Color(0xffe6db74)),

      // .sb { color: #e6db74; }
      sb: const TextStyle(color: Color(0xffe6db74)),

      // .sc { color: #e6db74; }
      sc: const TextStyle(color: Color(0xffe6db74)),

      // .dl { color: #e6db74; }
      dl: const TextStyle(color: Color(0xffe6db74)),

      // .sd { color: #e6db74; }
      sd: const TextStyle(color: Color(0xffe6db74)),

      // .s2 { color: #e6db74; }
      s2: const TextStyle(color: Color(0xffe6db74)),

      // .se { color: #ae81ff; }
      se: const TextStyle(color: Color(0xffae81ff)),

      // .sh { color: #e6db74; }
      sh: const TextStyle(color: Color(0xffe6db74)),

      // .si { color: #e6db74; }
      si: const TextStyle(color: Color(0xffe6db74)),

      // .sx { color: #e6db74; }
      sx: const TextStyle(color: Color(0xffe6db74)),

      // .sr { color: #e6db74; }
      sr: const TextStyle(color: Color(0xffe6db74)),

      // .s1 { color: #e6db74; }
      s1: const TextStyle(color: Color(0xffe6db74)),

      // .ss { color: #e6db74; }
      ss: const TextStyle(color: Color(0xffe6db74)),

      // .bp { color: #f8f8f2; }
      bp: const TextStyle(color: Color(0xfff8f8f2)),

      // .fm { color: #a6e22e; }
      fm: const TextStyle(color: Color(0xffa6e22e)),

      // .vc { color: #f8f8f2; }
      vc: const TextStyle(color: Color(0xfff8f8f2)),

      // .vg { color: #f8f8f2; }
      vg: const TextStyle(color: Color(0xfff8f8f2)),

      // .vi { color: #f8f8f2; }
      vi: const TextStyle(color: Color(0xfff8f8f2)),

      // .vm { color: #f8f8f2; }
      vm: const TextStyle(color: Color(0xfff8f8f2)),

      // .il { color: #ae81ff; }
      il: const TextStyle(color: Color(0xffae81ff)),
    );
  }

  CodeBlockTextStyles._({
    required this.plain,
    required TextStyle hll,
    required TextStyle c,
    required TextStyle err,
    required TextStyle? esc,
    required TextStyle? g,
    required TextStyle k,
    required TextStyle? l,
    required TextStyle? n,
    required TextStyle o,
    required TextStyle? x,
    required TextStyle? p,
    required TextStyle? ch,
    required TextStyle cm,
    required TextStyle cp,
    required TextStyle? cpf,
    required TextStyle c1,
    required TextStyle cs,
    required TextStyle gd,
    required TextStyle ge,
    required TextStyle? ges,
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
    required TextStyle? ld,
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
    required TextStyle? py,
    required TextStyle ow,
    required TextStyle? pm,
    required TextStyle w,
    required TextStyle? mb,
    required TextStyle mf,
    required TextStyle mh,
    required TextStyle mi,
    required TextStyle mo,
    required TextStyle? sa,
    required TextStyle sb,
    required TextStyle sc,
    required TextStyle? dl,
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
    required TextStyle? fm,
    required TextStyle vc,
    required TextStyle vg,
    required TextStyle vi,
    required TextStyle? vm,
    required TextStyle il,
  }) :
    _hll = hll,
    _c = c,
    _err = err,
    _esc = esc,
    _g = g,
    _k = k,
    _l = l,
    _n = n,
    _o = o,
    _x = x,
    _p = p,
    _ch = ch,
    _cm = cm,
    _cp = cp,
    _cpf = cpf,
    _c1 = c1,
    _cs = cs,
    _gd = gd,
    _ge = ge,
    _ges = ges,
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
    _ld = ld,
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
    _py = py,
    _ow = ow,
    _pm = pm,
    _w = w,
    _mb = mb,
    _mf = mf,
    _mh = mh,
    _mi = mi,
    _mo = mo,
    _sa = sa,
    _sb = sb,
    _sc = sc,
    _dl = dl,
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
    _fm = fm,
    _vc = vc,
    _vg = vg,
    _vi = vi,
    _vm = vm,
    _il = il;

  /// The baseline style that the [forSpan] styles get applied on top of.
  final TextStyle plain;

  final TextStyle _hll;
  final TextStyle _c;
  final TextStyle _err;
  final TextStyle? _esc;
  final TextStyle? _g;
  final TextStyle _k;
  final TextStyle? _l;
  final TextStyle? _n;
  final TextStyle _o;
  final TextStyle? _x;
  final TextStyle? _p;
  final TextStyle? _ch;
  final TextStyle _cm;
  final TextStyle _cp;
  final TextStyle? _cpf;
  final TextStyle _c1;
  final TextStyle _cs;
  final TextStyle _gd;
  final TextStyle _ge;
  final TextStyle? _ges;
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
  final TextStyle? _ld;
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
  final TextStyle? _py;
  final TextStyle _ow;
  final TextStyle? _pm;
  final TextStyle _w;
  final TextStyle? _mb;
  final TextStyle _mf;
  final TextStyle _mh;
  final TextStyle _mi;
  final TextStyle _mo;
  final TextStyle? _sa;
  final TextStyle _sb;
  final TextStyle _sc;
  final TextStyle? _dl;
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
  final TextStyle? _fm;
  final TextStyle _vc;
  final TextStyle _vg;
  final TextStyle _vi;
  final TextStyle? _vm;
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
      CodeBlockSpanType.escape => _esc,
      CodeBlockSpanType.generic => _g,
      CodeBlockSpanType.keyword => _k,
      CodeBlockSpanType.literal => _l,
      CodeBlockSpanType.name => _n,
      CodeBlockSpanType.operator => _o,
      CodeBlockSpanType.other => _x,
      CodeBlockSpanType.punctuation => _p,
      CodeBlockSpanType.commentHashbang => _ch,
      CodeBlockSpanType.commentMultiline => _cm,
      CodeBlockSpanType.commentPreproc => _cp,
      CodeBlockSpanType.commentPreprocFile => _cpf,
      CodeBlockSpanType.commentSingle => _c1,
      CodeBlockSpanType.commentSpecial => _cs,
      CodeBlockSpanType.genericDeleted => _gd,
      CodeBlockSpanType.genericEmph => _ge,
      CodeBlockSpanType.genericEmphStrong => _ges,
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
      CodeBlockSpanType.literalDate => _ld,
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
      CodeBlockSpanType.nameProperty => _py,
      CodeBlockSpanType.operatorWord => _ow,
      CodeBlockSpanType.punctuationMarker => _pm,
      CodeBlockSpanType.whitespace => _w,
      CodeBlockSpanType.numberBin => _mb,
      CodeBlockSpanType.numberFloat => _mf,
      CodeBlockSpanType.numberHex => _mh,
      CodeBlockSpanType.numberInteger => _mi,
      CodeBlockSpanType.numberOct => _mo,
      CodeBlockSpanType.stringAffix => _sa,
      CodeBlockSpanType.stringBacktick => _sb,
      CodeBlockSpanType.stringChar => _sc,
      CodeBlockSpanType.stringDelimiter => _dl,
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
      CodeBlockSpanType.nameFunctionMagic => _fm,
      CodeBlockSpanType.nameVariableClass => _vc,
      CodeBlockSpanType.nameVariableGlobal => _vg,
      CodeBlockSpanType.nameVariableInstance => _vi,
      CodeBlockSpanType.nameVariableMagic => _vm,
      CodeBlockSpanType.numberIntegerLong => _il,
      CodeBlockSpanType.unknown => null,
    };
  }

  static CodeBlockTextStyles lerp(CodeBlockTextStyles a, CodeBlockTextStyles b, double t) {
    if (identical(a, b)) return a;

    return CodeBlockTextStyles._(
      plain: TextStyle.lerp(a.plain, b.plain, t)!,
      hll: TextStyle.lerp(a._hll, b._hll, t)!,
      c: TextStyle.lerp(a._c, b._c, t)!,
      err: TextStyle.lerp(a._err, b._err, t)!,
      esc: TextStyle.lerp(a._esc, b._esc, t),
      g: TextStyle.lerp(a._g, b._g, t),
      k: TextStyle.lerp(a._k, b._k, t)!,
      l: TextStyle.lerp(a._l, b._l, t),
      n: TextStyle.lerp(a._n, b._n, t),
      o: TextStyle.lerp(a._o, b._o, t)!,
      x: TextStyle.lerp(a._x, b._x, t),
      p: TextStyle.lerp(a._p, b._p, t),
      ch: TextStyle.lerp(a._ch, b._ch, t),
      cm: TextStyle.lerp(a._cm, b._cm, t)!,
      cp: TextStyle.lerp(a._cp, b._cp, t)!,
      cpf: TextStyle.lerp(a._cpf, b._cpf, t),
      c1: TextStyle.lerp(a._c1, b._c1, t)!,
      cs: TextStyle.lerp(a._cs, b._cs, t)!,
      gd: TextStyle.lerp(a._gd, b._gd, t)!,
      ge: TextStyle.lerp(a._ge, b._ge, t)!,
      ges: TextStyle.lerp(a._ges, b._ges, t),
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
      ld: TextStyle.lerp(a._ld, b._ld, t),
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
      py: TextStyle.lerp(a._py, b._py, t),
      ow: TextStyle.lerp(a._ow, b._ow, t)!,
      pm: TextStyle.lerp(a._pm, b._pm, t),
      w: TextStyle.lerp(a._w, b._w, t)!,
      mb: TextStyle.lerp(a._mb, b._mb, t),
      mf: TextStyle.lerp(a._mf, b._mf, t)!,
      mh: TextStyle.lerp(a._mh, b._mh, t)!,
      mi: TextStyle.lerp(a._mi, b._mi, t)!,
      mo: TextStyle.lerp(a._mo, b._mo, t)!,
      sa: TextStyle.lerp(a._sa, b._sa, t),
      sb: TextStyle.lerp(a._sb, b._sb, t)!,
      sc: TextStyle.lerp(a._sc, b._sc, t)!,
      dl: TextStyle.lerp(a._dl, b._dl, t),
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
      fm: TextStyle.lerp(a._fm, b._fm, t),
      vc: TextStyle.lerp(a._vc, b._vc, t)!,
      vg: TextStyle.lerp(a._vg, b._vg, t)!,
      vi: TextStyle.lerp(a._vi, b._vi, t)!,
      vm: TextStyle.lerp(a._vm, b._vm, t),
      il: TextStyle.lerp(a._il, b._il, t)!,
    );
  }
}
