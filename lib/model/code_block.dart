// List of all the tokens that pygments can emit for syntax highlighting
// https://github.com/pygments/pygments/blob/d0acfff1121f9ee3696b01a9077ebe9990216634/pygments/token.py#L123-L214
//
// Note: If you update this list make sure to update the permalink
//       and the `tryFromString` function below.
enum CodeBlockSpanType {
  /// A code-block span that is unrecognized by the parser.
  unknown,
  /// A run of unstyled text in a code block.
  text,
  /// A code-block span with CSS class `hll`.
  ///
  /// Unlike most `CodeBlockSpanToken` values, this does not correspond to
  /// a Pygments "token type". See discussion:
  ///   https://github.com/zulip/zulip-flutter/pull/242#issuecomment-1652450667
  highlightedLines,
  /// A code-block span with CSS class `w`.
  whitespace,
  /// A code-block span with CSS class `esc`.
  escape,
  /// A code-block span with CSS class `err`.
  error,
  /// A code-block span with CSS class `x`.
  other,
  /// A code-block span with CSS class `k`.
  keyword,
  /// A code-block span with CSS class `kc`.
  keywordConstant,
  /// A code-block span with CSS class `kd`.
  keywordDeclaration,
  /// A code-block span with CSS class `kn`.
  keywordNamespace,
  /// A code-block span with CSS class `kp`.
  keywordPseudo,
  /// A code-block span with CSS class `kr`.
  keywordReserved,
  /// A code-block span with CSS class `kt`.
  keywordType,
  /// A code-block span with CSS class `n`.
  name,
  /// A code-block span with CSS class `na`.
  nameAttribute,
  /// A code-block span with CSS class `nb`.
  nameBuiltin,
  /// A code-block span with CSS class `bp`.
  nameBuiltinPseudo,
  /// A code-block span with CSS class `nc`.
  nameClass,
  /// A code-block span with CSS class `no`.
  nameConstant,
  /// A code-block span with CSS class `nd`.
  nameDecorator,
  /// A code-block span with CSS class `ni`.
  nameEntity,
  /// A code-block span with CSS class `ne`.
  nameException,
  /// A code-block span with CSS class `nf`.
  nameFunction,
  /// A code-block span with CSS class `fm`.
  nameFunctionMagic,
  /// A code-block span with CSS class `py`.
  nameProperty,
  /// A code-block span with CSS class `nl`.
  nameLabel,
  /// A code-block span with CSS class `nn`.
  nameNamespace,
  /// A code-block span with CSS class `nx`.
  nameOther,
  /// A code-block span with CSS class `nt`.
  nameTag,
  /// A code-block span with CSS class `nv`.
  nameVariable,
  /// A code-block span with CSS class `vc`.
  nameVariableClass,
  /// A code-block span with CSS class `vg`.
  nameVariableGlobal,
  /// A code-block span with CSS class `vi`.
  nameVariableInstance,
  /// A code-block span with CSS class `vm`.
  nameVariableMagic,
  /// A code-block span with CSS class `l`.
  literal,
  /// A code-block span with CSS class `ld`.
  literalDate,
  /// A code-block span with CSS class `s`.
  string,
  /// A code-block span with CSS class `sa`.
  stringAffix,
  /// A code-block span with CSS class `sb`.
  stringBacktick,
  /// A code-block span with CSS class `sc`.
  stringChar,
  /// A code-block span with CSS class `dl`.
  stringDelimiter,
  /// A code-block span with CSS class `sd`.
  stringDoc,
  /// A code-block span with CSS class `s2`.
  stringDouble,
  /// A code-block span with CSS class `se`.
  stringEscape,
  /// A code-block span with CSS class `sh`.
  stringHeredoc,
  /// A code-block span with CSS class `si`.
  stringInterpol,
  /// A code-block span with CSS class `sx`.
  stringOther,
  /// A code-block span with CSS class `sr`.
  stringRegex,
  /// A code-block span with CSS class `s1`.
  stringSingle,
  /// A code-block span with CSS class `ss`.
  stringSymbol,
  /// A code-block span with CSS class `m`.
  number,
  /// A code-block span with CSS class `mb`.
  numberBin,
  /// A code-block span with CSS class `mf`.
  numberFloat,
  /// A code-block span with CSS class `mh`.
  numberHex,
  /// A code-block span with CSS class `mi`.
  numberInteger,
  /// A code-block span with CSS class `il`.
  numberIntegerLong,
  /// A code-block span with CSS class `mo`.
  numberOct,
  /// A code-block span with CSS class `o`.
  operator,
  /// A code-block span with CSS class `ow`.
  operatorWord,
  /// A code-block span with CSS class `p`.
  punctuation,
  /// A code-block span with CSS class `pm`.
  punctuationMarker,
  /// A code-block span with CSS class `c`.
  comment,
  /// A code-block span with CSS class `ch`.
  commentHashbang,
  /// A code-block span with CSS class `cm`.
  commentMultiline,
  /// A code-block span with CSS class `cp`.
  commentPreproc,
  /// A code-block span with CSS class `cpf`.
  commentPreprocFile,
  /// A code-block span with CSS class `c1`.
  commentSingle,
  /// A code-block span with CSS class `cs`.
  commentSpecial,
  /// A code-block span with CSS class `g`.
  generic,
  /// A code-block span with CSS class `gd`.
  genericDeleted,
  /// A code-block span with CSS class `ge`.
  genericEmph,
  /// A code-block span with CSS class `gr`.
  genericError,
  /// A code-block span with CSS class `gh`.
  genericHeading,
  /// A code-block span with CSS class `gi`.
  genericInserted,
  /// A code-block span with CSS class `go`.
  genericOutput,
  /// A code-block span with CSS class `gp`.
  genericPrompt,
  /// A code-block span with CSS class `gs`.
  genericStrong,
  /// A code-block span with CSS class `gu`.
  genericSubheading,
  /// A code-block span with CSS class `ges`.
  genericEmphStrong,
  /// A code-block span with CSS class `gt`.
  genericTraceback,
}

CodeBlockSpanType codeBlockSpanTypeFromClassName(String className) {
  return switch (className) {
    'hll' => CodeBlockSpanType.highlightedLines,
    'w' => CodeBlockSpanType.whitespace,
    'esc' => CodeBlockSpanType.escape,
    'err' => CodeBlockSpanType.error,
    'x' => CodeBlockSpanType.other,
    'k' => CodeBlockSpanType.keyword,
    'kc' => CodeBlockSpanType.keywordConstant,
    'kd' => CodeBlockSpanType.keywordDeclaration,
    'kn' => CodeBlockSpanType.keywordNamespace,
    'kp' => CodeBlockSpanType.keywordPseudo,
    'kr' => CodeBlockSpanType.keywordReserved,
    'kt' => CodeBlockSpanType.keywordType,
    'n' => CodeBlockSpanType.name,
    'na' => CodeBlockSpanType.nameAttribute,
    'nb' => CodeBlockSpanType.nameBuiltin,
    'bp' => CodeBlockSpanType.nameBuiltinPseudo,
    'nc' => CodeBlockSpanType.nameClass,
    'no' => CodeBlockSpanType.nameConstant,
    'nd' => CodeBlockSpanType.nameDecorator,
    'ni' => CodeBlockSpanType.nameEntity,
    'ne' => CodeBlockSpanType.nameException,
    'nf' => CodeBlockSpanType.nameFunction,
    'fm' => CodeBlockSpanType.nameFunctionMagic,
    'py' => CodeBlockSpanType.nameProperty,
    'nl' => CodeBlockSpanType.nameLabel,
    'nn' => CodeBlockSpanType.nameNamespace,
    'nx' => CodeBlockSpanType.nameOther,
    'nt' => CodeBlockSpanType.nameTag,
    'nv' => CodeBlockSpanType.nameVariable,
    'vc' => CodeBlockSpanType.nameVariableClass,
    'vg' => CodeBlockSpanType.nameVariableGlobal,
    'vi' => CodeBlockSpanType.nameVariableInstance,
    'vm' => CodeBlockSpanType.nameVariableMagic,
    'l' => CodeBlockSpanType.literal,
    'ld' => CodeBlockSpanType.literalDate,
    's' => CodeBlockSpanType.string,
    'sa' => CodeBlockSpanType.stringAffix,
    'sb' => CodeBlockSpanType.stringBacktick,
    'sc' => CodeBlockSpanType.stringChar,
    'dl' => CodeBlockSpanType.stringDelimiter,
    'sd' => CodeBlockSpanType.stringDoc,
    's2' => CodeBlockSpanType.stringDouble,
    'se' => CodeBlockSpanType.stringEscape,
    'sh' => CodeBlockSpanType.stringHeredoc,
    'si' => CodeBlockSpanType.stringInterpol,
    'sx' => CodeBlockSpanType.stringOther,
    'sr' => CodeBlockSpanType.stringRegex,
    's1' => CodeBlockSpanType.stringSingle,
    'ss' => CodeBlockSpanType.stringSymbol,
    'm' => CodeBlockSpanType.number,
    'mb' => CodeBlockSpanType.numberBin,
    'mf' => CodeBlockSpanType.numberFloat,
    'mh' => CodeBlockSpanType.numberHex,
    'mi' => CodeBlockSpanType.numberInteger,
    'il' => CodeBlockSpanType.numberIntegerLong,
    'mo' => CodeBlockSpanType.numberOct,
    'o' => CodeBlockSpanType.operator,
    'ow' => CodeBlockSpanType.operatorWord,
    'p' => CodeBlockSpanType.punctuation,
    'pm' => CodeBlockSpanType.punctuationMarker,
    'c' => CodeBlockSpanType.comment,
    'ch' => CodeBlockSpanType.commentHashbang,
    'cm' => CodeBlockSpanType.commentMultiline,
    'cp' => CodeBlockSpanType.commentPreproc,
    'cpf' => CodeBlockSpanType.commentPreprocFile,
    'c1' => CodeBlockSpanType.commentSingle,
    'cs' => CodeBlockSpanType.commentSpecial,
    'g' => CodeBlockSpanType.generic,
    'gd' => CodeBlockSpanType.genericDeleted,
    'ge' => CodeBlockSpanType.genericEmph,
    'gr' => CodeBlockSpanType.genericError,
    'gh' => CodeBlockSpanType.genericHeading,
    'gi' => CodeBlockSpanType.genericInserted,
    'go' => CodeBlockSpanType.genericOutput,
    'gp' => CodeBlockSpanType.genericPrompt,
    'gs' => CodeBlockSpanType.genericStrong,
    'gu' => CodeBlockSpanType.genericSubheading,
    'ges' => CodeBlockSpanType.genericEmphStrong,
    'gt' => CodeBlockSpanType.genericTraceback,
    _ => CodeBlockSpanType.unknown,
  };
}
