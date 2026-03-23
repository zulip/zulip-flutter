import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model/submessage.dart';
import '../api/route/submessage.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'content.dart';
import 'store.dart';
import 'text.dart';

class PollWidget extends StatefulWidget {
  const PollWidget({super.key, required this.messageId, required this.poll});

  final int messageId;
  final Poll poll;

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  @override
  void initState() {
    super.initState();
    widget.poll.addListener(_modelChanged);
  }

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.poll != oldWidget.poll) {
      oldWidget.poll.removeListener(_modelChanged);
      widget.poll.addListener(_modelChanged);
    }
  }

  @override
  void dispose() {
    widget.poll.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in the [Poll] model.
      // This method was called because that just changed.
    });
  }

  void _toggleVote(PollOption option) async {
    final store = PerAccountStoreWidget.of(context);
    final op = option.voters.contains(store.selfUserId)
      ? PollVoteOp.remove
      : PollVoteOp.add;
    unawaited(sendSubmessage(store.connection, messageId: widget.messageId,
      submessageType: SubmessageType.widget,
      content: PollVoteEventSubmessage(key: option.key, op: op)));
  }

  @override
  Widget build(BuildContext context) {
    const verticalPadding = 2.5;

    final zulipLocalizations = ZulipLocalizations.of(context);
    final theme = ContentTheme.of(context);
    final store = PerAccountStoreWidget.of(context);

    final textStyleBold = weightVariableTextStyle(context, wght: 600);
    final textStyleVoterNames = TextStyle(
      fontSize: 16, color: theme.colorPollNames);

    Text question = (widget.poll.question.isNotEmpty)
      ? Text(widget.poll.question, style: textStyleBold.copyWith(fontSize: 18))
      : Text(zulipLocalizations.pollWidgetQuestionMissing,
          style: textStyleBold.copyWith(fontSize: 18, fontStyle: FontStyle.italic));

    Widget buildOptionItem(PollOption option) {
      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Zixuan'])
      //   // 'Chris、Greg、Alya、Zixuan'
      final voterNames = option.voters
        .map(store.userDisplayName)
        .join(', ');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Padding(
              // For accessibility, the touch target is padded to be larger
              // than the vote count box.  Still, we avoid padding at the
              // start because we want to align all the poll options to the
              // surrounding messages.
              padding: const EdgeInsetsDirectional.only(
                end: 5, top: verticalPadding, bottom: verticalPadding),
              child: Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                  side: BorderSide(color: theme.colorPollVoteCountBorder)),
                color: theme.colorPollVoteCountBackground,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _toggleVote(option),
                  child: Padding(
                    // Inner padding preserves whitespace even when the text's
                    // width approaches the button's min-width (e.g. because
                    // there are more than three digits).
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: Text(option.voters.length.toString(),
                        style: textStyleBold.copyWith(
                          color: theme.colorPollVoteCountText, fontSize: 20)))))))),
          Expanded(
            child: Padding(
              // This and the padding on the vote count box both extend the row
              // by the same extent. This ensures that there still will be
              // consistent spacing between rows when the text takes more
              // vertical space than the vote count box.
              padding: const EdgeInsets.symmetric(vertical: verticalPadding),
              child: Wrap(
                spacing: 5,
                children: [
                  Text(option.text, style: textStyleBold.copyWith(fontSize: 16)),
                  if (option.voters.isNotEmpty)
                    Text(zulipLocalizations.pollVoterNames(voterNames),
                      style: textStyleVoterNames),
                ]))),
        ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        question,
        // `verticalPadding` out of 6px comes from the first option row.
        const SizedBox(height: 6 - verticalPadding),
        if (widget.poll.options.isEmpty)
          Padding(
            // This is consistent with the option rows' padding.
            padding: const EdgeInsets.symmetric(vertical: verticalPadding),
            child: Text(zulipLocalizations.pollWidgetOptionsMissing,
              style: textStyleVoterNames.copyWith(fontStyle: FontStyle.italic))),
        for (final option in widget.poll.options)
          buildOptionItem(option),
        // `verticalPadding` out of 5px comes from the last option row.
        const SizedBox(height: 5 - verticalPadding),
      ]);
  }
}
