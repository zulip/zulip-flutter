import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/content.dart';
import '../../../../model/internal_link.dart';
import '../../../themes/content_theme.dart';
import '../../message_list_block/message_list_block.dart';
import '../../../utils/actions.dart';
import '../../../utils/store.dart';
import '../../../widgets/dialog.dart';
import 'block_inline_container.dart';
import 'inline_content.dart';

void contentLaunchUrl(BuildContext context, String urlString) async {
  final store = PerAccountStoreWidget.of(context);
  final url = store.tryResolveUrl(urlString);
  if (url == null) {
    // TODO(log)
    final zulipLocalizations = ZulipLocalizations.of(context);
    showErrorDialog(
      context: context,
      title: zulipLocalizations.errorCouldNotOpenLinkTitle,
      message: zulipLocalizations.errorCouldNotOpenLink(urlString),
    );
    return;
  }

  final internalLink = parseInternalLink(url, store);
  assert(internalLink == null || internalLink.realmUrl == store.realmUrl);
  switch (internalLink) {
    case NarrowLink():
      unawaited(
        Navigator.push(
          context,
          MessageListBlockPage.buildRoute(
            context: context,
            narrow: internalLink.narrow,
            initAnchorMessageId: internalLink.nearMessageId,
          ),
        ),
      );

    case UserUploadLink():
      final tempUrl = await ZulipAction.getFileTemporaryUrl(
        context,
        internalLink,
      );
      if (!context.mounted) return null;
      if (tempUrl == null) return;
      await PlatformActions.launchUrl(context, tempUrl);

    case null:
      await PlatformActions.launchUrl(context, url);
  }
}

Widget contentBuildBlockInlineContainer({
  required TextStyle style,
  required BlockInlineContainerNode node,
  TextAlign? textAlign,
}) {
  if (node.links == null) {
    return InlineContent(
      recognizer: null,
      linkRecognizers: null,
      style: style,
      nodes: node.nodes,
      textAlign: textAlign,
    );
  }
  return BlockInlineContainer(
    links: node.links!,
    style: style,
    nodes: node.nodes,
    textAlign: textAlign,
  );
}

InlineSpan contentErrorUnimplemented(
  UnimplementedNode node, {
  required BuildContext context,
}) {
  final contentTheme = ContentTheme.of(context);
  final errorStyle = contentTheme.textStyleError;
  final errorCodeStyle = contentTheme.textStyleErrorCode;
  // For now this shows error-styled HTML code even in release mode,
  // because release mode isn't yet about general users but developer demos,
  // and we want to keep the demos honest.
  // TODO(#194) think through UX for general release
  // TODO(#1285) translate this
  final htmlNode = node.htmlNode;
  if (htmlNode is dom.Element) {
    return TextSpan(
      children: [
        TextSpan(text: "(unimplemented:", style: errorStyle),
        TextSpan(text: htmlNode.outerHtml, style: errorCodeStyle),
        TextSpan(text: ")", style: errorStyle),
      ],
    );
  } else if (htmlNode is dom.Text) {
    return TextSpan(
      children: [
        TextSpan(text: "(unimplemented: text «", style: errorStyle),
        TextSpan(text: htmlNode.text, style: errorCodeStyle),
        TextSpan(text: "»)", style: errorStyle),
      ],
    );
  } else {
    return TextSpan(
      text: "(unimplemented: DOM node type ${htmlNode.nodeType})",
      style: errorStyle,
    );
  }
}
