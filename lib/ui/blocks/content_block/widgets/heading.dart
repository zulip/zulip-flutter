import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import '../../../values/constants.dart';
import '../../../values/text.dart';
import 'helpers.dart';

class Heading extends StatelessWidget {
  const Heading({super.key, required this.node});

  final HeadingNode node;

  @override
  Widget build(BuildContext context) {
    // Em-heights taken from zulip:web/styles/rendered_markdown.css .
    final emHeight = switch (node.level) {
      HeadingLevel.h1 => 1.4,
      HeadingLevel.h2 => 1.3,
      HeadingLevel.h3 => 1.2,
      HeadingLevel.h4 => 1.1,
      HeadingLevel.h5 => 1.05,
      HeadingLevel.h6 => 1.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: contentBuildBlockInlineContainer(
        style: TextStyle(fontSize: kBaseFontSize * emHeight, height: 1.4)
            // Could set boldness relative to ambient text style, which itself
            // might be bolder than normal (e.g. in spoiler headers).
            // But this didn't seem like a clear improvement and would make inline
            // **bold** spans less distinct; discussion:
            //   https://github.com/zulip/zulip-flutter/pull/706#issuecomment-2141326257
            .merge(weightVariableTextStyle(context, wght: 600)),
        node: node,
      ),
    );
  }
}
