import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../api/model/permission.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/content.dart';
import '../../../themes/content_theme.dart';
import '../../../values/constants.dart';
import 'inline_content.dart';

class Mention extends StatelessWidget {
  const Mention({
    super.key,
    required this.ambientTextStyle,
    required this.node,
  });

  final TextStyle ambientTextStyle;
  final MentionNode node;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final contentTheme = ContentTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    var nodes = node.nodes;
    switch (node) {
      case UserGroupMentionNode(:final userGroupId):
        final userGroup = store.getGroup(userGroupId);
        if (userGroup case UserGroup(:final name, :final isSystemGroup)) {
          final String displayName;
          if (isSystemGroup) {
            final groupName = SystemGroupName.fromJson(
              name,
            ); // TODO(log) if null
            displayName = groupName?.displayName(zulipLocalizations) ?? name;
          } else {
            displayName = name;
          }

          nodes = [TextNode(node.isSilent ? displayName : '@$displayName')];
        }
      case UserMentionNode(:final userId?):
        final user = store.getUser(userId);
        if (user case User(:final fullName)) {
          nodes = [TextNode(node.isSilent ? fullName : '@$fullName')];
        }
      case UserMentionNode(userId: null):
      case WildcardMentionNode():
    }

    final backgroundPillColor = switch (node) {
      UserMentionNode() => contentTheme.colorDirectMentionBackground,
      UserGroupMentionNode() ||
      WildcardMentionNode() => contentTheme.colorGroupMentionBackground,
    };

    return Container(
      decoration: BoxDecoration(
        color: backgroundPillColor,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
      child: InlineContent(
        // If an @-mention is inside a link, let the @-mention override it.
        recognizer:
            null, // TODO(#1867) make @-mentions tappable, for info on user
        // One hopes an @-mention can't contain an embedded link.
        // (The parser on creating a MentionNode has a TODO to check that.)
        linkRecognizers: null,

        // TODO(#647) when self-user is mentioned, make bold, and change font color.
        style: ambientTextStyle,

        nodes: nodes,
      ),
    );
  }

  // This is a more literal translation of Zulip web's CSS.
  // But it turns out CSS `box-shadow` has a quirk we rely on there:
  // it doesn't apply under the element itself, even if the element's
  // own background is transparent.  Flutter's BoxShadow does apply,
  // which is after all more logical from the "shadow" metaphor.
  //
  // static const _kDecoration = ShapeDecoration(
  //   gradient: LinearGradient(
  //     colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
  //     begin: Alignment.topCenter,
  //     end: Alignment.bottomCenter),
  //   shadows: [
  //     BoxShadow(
  //       spreadRadius: 1,
  //       blurStyle: BlurStyle.outer,
  //       color: Color.fromRGBO(0xcc, 0xcc, 0xcc, 1)),
  //   ],
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.all(Radius.circular(3))));
}
