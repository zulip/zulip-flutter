import 'package:flutter/material.dart';

import '../../../../../api/model/model.dart';
import '../../../../../api/route/messages.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../model/narrow.dart';
import '../../compose_box.dart';
import '../../../../utils/store.dart';
import 'content_input.dart';
import '../typing_notifier.dart';

class StreamContentInput extends StatefulWidget {
  const StreamContentInput({
    super.key,
    required this.narrow,
    required this.controller,
    required this.getDestination,
  });

  final ChannelNarrow narrow;
  final StreamComposeBoxController controller;
  final MessageDestination Function() getDestination;

  @override
  State<StreamContentInput> createState() => _StreamContentInputState();
}

class _StreamContentInputState extends State<StreamContentInput> {
  void _topicChanged() {
    setState(() {
      // The relevant state lives on widget.controller.topic itself.
    });
  }

  void _contentFocusChanged() {
    setState(() {
      // The relevant state lives on widget.controller.contentFocusNode itself.
    });
  }

  void _topicInteractionStatusChanged() {
    setState(() {
      // The relevant state lives on widget.controller.topicInteractionStatus itself.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.topic.addListener(_topicChanged);
    widget.controller.contentFocusNode.addListener(_contentFocusChanged);
    widget.controller.topicInteractionStatus.addListener(
      _topicInteractionStatusChanged,
    );
  }

  @override
  void didUpdateWidget(covariant StreamContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.topic != oldWidget.controller.topic) {
      oldWidget.controller.topic.removeListener(_topicChanged);
      widget.controller.topic.addListener(_topicChanged);
    }
    if (widget.controller.contentFocusNode !=
        oldWidget.controller.contentFocusNode) {
      oldWidget.controller.contentFocusNode.removeListener(
        _contentFocusChanged,
      );
      widget.controller.contentFocusNode.addListener(_contentFocusChanged);
    }
    if (widget.controller.topicInteractionStatus !=
        oldWidget.controller.topicInteractionStatus) {
      oldWidget.controller.topicInteractionStatus.removeListener(
        _topicInteractionStatusChanged,
      );
      widget.controller.topicInteractionStatus.addListener(
        _topicInteractionStatusChanged,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.topic.removeListener(_topicChanged);
    widget.controller.contentFocusNode.removeListener(_contentFocusChanged);
    widget.controller.topicInteractionStatus.removeListener(
      _topicInteractionStatusChanged,
    );
    super.dispose();
  }

  /// The topic name to show in the hint text, or null to show no topic.
  TopicName? _hintTopic() {
    if (widget.controller.topic.isTopicVacuous) {
      if (widget.controller.topic.mandatory) {
        // The chosen topic can't be sent to, so don't show it.
        return null;
      }
      if (widget.controller.topicInteractionStatus.value !=
          ComposeTopicInteractionStatus.hasChosen) {
        // Do not fall back to a vacuous topic unless the user explicitly
        // chooses to do so, so that the user is not encouraged to use vacuous
        // topic before they have interacted with the inputs at all.
        return null;
      }
    }

    return TopicName(widget.controller.topic.textNormalized);
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final streamName =
        store.streams[widget.narrow.streamId]?.name ??
        zulipLocalizations.unknownChannelName;
    final hintTopic = _hintTopic();
    final hintDestination = hintTopic == null
        // No i18n of this use of "#" and ">" string; those are part of how
        // Zulip expresses channels and topics, not any normal English punctuation,
        // so don't make sense to translate. See:
        //   https://github.com/zulip/zulip-flutter/pull/1148#discussion_r1941990585
        ? '#$streamName'
        : '#$streamName > ${hintTopic.displayName ?? store.realmEmptyTopicDisplayName}';

    return TypingNotifier(
      destination: TopicNarrow(
        widget.narrow.streamId,
        TopicName(widget.controller.topic.textNormalized),
      ),
      controller: widget.controller,
      child: ContentInput(
        narrow: widget.narrow,
        controller: widget.controller,
        hintText: zulipLocalizations.composeBoxChannelContentHint(
          hintDestination,
        ),
        getDestination: widget.getDestination,
      ),
    );
  }
}
