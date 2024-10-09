import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/submessage.dart';
import '../api/route/submessage.dart';
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
    // The poll data in store might be obselete before we get the event
    // that updates it.  This is fine because the result will be consistent
    // eventually, regardless of the possible duplicate requests.
    final op = widget.poll.hasUserVotedFor(userId: store.selfUserId, key: option.key)
      ? PollVoteOp.remove
      : PollVoteOp.add;
    unawaited(sendSubmessage(store.connection, messageId: widget.messageId,
      content: PollVoteEventSubmessage(key: option.key, op: op)));
    // TODO: Implement a visual indicator while waiting for the corresponding
    //   event that updates the poll.
  }

  @override
  Widget build(BuildContext context) {
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
      const verticalPadding = 2.5;
      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Zixuan'])
      //   // 'Chris、Greg、Alya、Zixuan'
      final voterNames = option.voters
        .map((userId) =>
          store.users[userId]?.fullName ?? zulipLocalizations.unknownUserName)
        .join(', ');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          GestureDetector(
            onTap: () => _toggleVote(option),
            behavior: HitTestBehavior.translucent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 39 + 5).tighten(height: 39 + verticalPadding * 2),
              child: Padding(
                // For accessibility, the touch target is padded to be larger
                // than the vote count box.  Still, we avoid padding at the
                // start because we want to align all the poll options to the
                // surrounding messages.
                padding: const EdgeInsetsDirectional.only(
                  end: 5, top: verticalPadding, bottom: verticalPadding),
                child: Container(
                  // Inner padding preserves whitespace even when the text's
                  // width approaches the button's min-width (e.g. because
                  // there are more than three digits).
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: theme.colorPollVoteCountBackground,
                    border: Border.all(color: theme.colorPollVoteCountBorder),
                    borderRadius: BorderRadius.circular(3)),
                  child: Center(
                    child: Text(option.voters.length.toString(),
                      textAlign: TextAlign.center,
                      style: textStyleBold.copyWith(
                        color: theme.colorPollVoteCountText, fontSize: 20))))))),
          Expanded(
            child: Wrap(
              spacing: 5,
              children: [
                Text(option.text, style: textStyleBold.copyWith(fontSize: 16)),
                if (option.voters.isNotEmpty)
                  // TODO(i18n): Localize parenthesis characters.
                  Text('($voterNames)', style: textStyleVoterNames),
              ])),
        ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 6), child: question),
        if (widget.poll.options.isEmpty)
          Text(zulipLocalizations.pollWidgetOptionsMissing,
            style: textStyleVoterNames.copyWith(fontStyle: FontStyle.italic)),
        for (final option in widget.poll.options)
          buildOptionItem(option),
      ]);
  }
}
