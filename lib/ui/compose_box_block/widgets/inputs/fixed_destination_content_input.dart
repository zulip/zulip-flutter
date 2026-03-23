import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../compose_box.dart';
import '../../../some_features/store.dart';
import '../typing_notifier.dart';
import 'content_input.dart';

class FixedDestinationContentInput extends StatelessWidget {
  const FixedDestinationContentInput({
    super.key,
    required this.narrow,
    required this.controller,
  });

  final SendableNarrow narrow;
  final FixedDestinationComposeBoxController controller;

  String _hintText(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (narrow) {
      case TopicNarrow(:final streamId, :final topic):
        final store = PerAccountStoreWidget.of(context);
        final streamName =
            store.streams[streamId]?.name ??
            zulipLocalizations.unknownChannelName;
        return zulipLocalizations.composeBoxChannelContentHint(
          // No i18n of this use of "#" and ">" string; those are part of how
          // Zulip expresses channels and topics, not any normal English punctuation,
          // so don't make sense to translate. See:
          //   https://github.com/zulip/zulip-flutter/pull/1148#discussion_r1941990585
          '#$streamName > ${topic.displayName ?? store.realmEmptyTopicDisplayName}',
        );

      case DmNarrow(otherRecipientIds: []): // The self-1:1 thread.
        return zulipLocalizations.composeBoxSelfDmContentHint;

      case DmNarrow(otherRecipientIds: [final otherUserId]):
        final store = PerAccountStoreWidget.of(context);
        final user = store.getUser(otherUserId);
        if (user == null) {
          return zulipLocalizations.composeBoxGenericContentHint;
        }
        // TODO write a test where the user is muted
        return zulipLocalizations.composeBoxDmContentHint(
          store.userDisplayName(otherUserId, replaceIfMuted: false),
        );

      case DmNarrow(): // A group DM thread.
        return zulipLocalizations.composeBoxGroupDmContentHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TypingNotifier(
      destination: narrow,
      controller: controller,
      child: ContentInput(
        narrow: narrow,
        controller: controller,
        hintText: _hintText(context),
      ),
    );
  }
}
