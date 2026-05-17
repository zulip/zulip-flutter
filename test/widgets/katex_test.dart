import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/katex_widget.dart';

import '../model/binding.dart';
import '../model/katex_test.dart';
import 'content_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('MathWidget', () {
    testWidgets('renders inline math', (tester) async {
      await prepareContent(tester, plainContent(KatexExample.vlistSuperscript.html));
      expect(find.byType(MathWidget), findsWidgets);
      expect(find.byType(Math), findsWidgets);
    });

    testWidgets('renders block math', (tester) async {
      await prepareContent(tester, plainContent(KatexExample.sizing.html));
      expect(find.byType(MathWidget), findsWidgets);
      expect(find.byType(Math), findsWidgets);
    });

    for (final example in [
      KatexExample.sizing,
      KatexExample.nestedSizing,
      KatexExample.delimsizing,
      KatexExample.spacing,
      KatexExample.vlistSuperscript,
      KatexExample.vlistSubscript,
      KatexExample.vlistSubAndSuperscript,
      KatexExample.vlistRaisebox,
      KatexExample.negativeMargin,
      KatexExample.katexLogo,
      KatexExample.vlistNegativeMargin,
      KatexExample.color,
      KatexExample.textColor,
      KatexExample.customColorMacro,
      KatexExample.phantom,
      KatexExample.bigOperators,
      KatexExample.colonEquals,
      KatexExample.nulldelimiter,
    ]) {
      testWidgets('smoke test: ${example.description}', (tester) async {
        await prepareContent(tester, plainContent(example.html));
        expect(find.byType(MathWidget), findsWidgets);
      });
    }
  });
}
