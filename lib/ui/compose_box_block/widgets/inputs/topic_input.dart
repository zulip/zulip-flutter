import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../widgets/autocomplete.dart';
import '../../../extensions/color.dart';
import '../../compose_box.dart';
import '../../../utils/store.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';

class TopicInput extends StatefulWidget {
  const TopicInput({
    super.key,
    required this.streamId,
    required this.controller,
  });

  final int streamId;
  final StreamComposeBoxController controller;

  @override
  State<TopicInput> createState() => _TopicInputState();
}

class _TopicInputState extends State<TopicInput> {
  void _topicOrContentFocusChanged() {
    setState(() {
      final status = widget.controller.topicInteractionStatus;
      if (widget.controller.topicFocusNode.hasFocus) {
        // topic input gains focus
        status.value = ComposeTopicInteractionStatus.isEditing;
      } else if (widget.controller.contentFocusNode.hasFocus) {
        // content input gains focus
        status.value = ComposeTopicInteractionStatus.hasChosen;
      } else {
        // neither input has focus, the new value of topicInteractionStatus
        // depends on its previous value
        if (status.value == ComposeTopicInteractionStatus.isEditing) {
          // topic input loses focus
          status.value = ComposeTopicInteractionStatus.notEditingNotChosen;
        } else {
          // content input loses focus; stay in hasChosen
          assert(status.value == ComposeTopicInteractionStatus.hasChosen);
        }
      }
    });
  }

  void _topicInteractionStatusChanged() {
    setState(() {
      // The actual state lives in widget.controller.topicInteractionStatus
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.topicFocusNode.addListener(_topicOrContentFocusChanged);
    widget.controller.contentFocusNode.addListener(_topicOrContentFocusChanged);
    widget.controller.topicInteractionStatus.addListener(
      _topicInteractionStatusChanged,
    );
  }

  @override
  void didUpdateWidget(covariant TopicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.topicFocusNode.removeListener(
        _topicOrContentFocusChanged,
      );
      widget.controller.topicFocusNode.addListener(_topicOrContentFocusChanged);
      oldWidget.controller.contentFocusNode.removeListener(
        _topicOrContentFocusChanged,
      );
      widget.controller.contentFocusNode.addListener(
        _topicOrContentFocusChanged,
      );
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
    widget.controller.topicFocusNode.removeListener(
      _topicOrContentFocusChanged,
    );
    widget.controller.contentFocusNode.removeListener(
      _topicOrContentFocusChanged,
    );
    widget.controller.topicInteractionStatus.removeListener(
      _topicInteractionStatusChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);

    final topicTextStyle = TextStyle(
      fontSize: 20,
      height: 22 / 20,
      color: designVariables.textInput.withFadedAlpha(0.9),
    ).merge(weightVariableTextStyle(context, wght: 600));

    // TODO(server-10) simplify away
    final emptyTopicsSupported = store.zulipFeatureLevel >= 334;

    final String hintText;
    TextStyle hintStyle = topicTextStyle.copyWith(
      color: designVariables.textInput.withFadedAlpha(0.5),
    );

    if (store.realmMandatoryTopics) {
      // Something short and not distracting.
      hintText = zulipLocalizations.composeBoxTopicHintText;
    } else {
      switch (widget.controller.topicInteractionStatus.value) {
        case ComposeTopicInteractionStatus.notEditingNotChosen:
          // Something short and not distracting.
          hintText = zulipLocalizations.composeBoxTopicHintText;
        case ComposeTopicInteractionStatus.isEditing:
          // The user is actively interacting with the input.  Since topics are
          // not mandatory, show a long hint text mentioning that they can be
          // left empty.
          hintText = zulipLocalizations.composeBoxEnterTopicOrSkipHintText(
            emptyTopicsSupported
                ? store.realmEmptyTopicDisplayName
                : kNoTopicTopic,
          );
        case ComposeTopicInteractionStatus.hasChosen:
          // The topic has likely been chosen.  Since topics are not mandatory,
          // show the default topic display name as if the user has entered that
          // when they left the input empty.
          if (emptyTopicsSupported) {
            hintText = store.realmEmptyTopicDisplayName;
            hintStyle = topicTextStyle.copyWith(fontStyle: FontStyle.italic);
          } else {
            hintText = kNoTopicTopic;
            hintStyle = topicTextStyle;
          }
      }
    }

    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
    );

    return TopicAutocomplete(
      streamId: widget.streamId,
      controller: widget.controller.topic,
      focusNode: widget.controller.topicFocusNode,
      contentFocusNode: widget.controller.contentFocusNode,
      fieldViewBuilder: (context) => Container(
        padding: const EdgeInsets.only(top: 10, bottom: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: designVariables.foreground.withFadedAlpha(0.2),
            ),
          ),
        ),
        child: TextField(
          controller: widget.controller.topic,
          focusNode: widget.controller.topicFocusNode,
          textInputAction: TextInputAction.next,
          style: topicTextStyle,
          decoration: decoration,
        ),
      ),
    );
  }
}
