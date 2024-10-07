import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/submessage.dart';
import 'content.dart';
import 'store.dart';
import 'text.dart';

class PollWidget extends StatefulWidget {
  const PollWidget({super.key, required this.poll});

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
        .map((userId) =>
          store.users[userId]?.fullName ?? zulipLocalizations.unknownUserName)
        .join(', ');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 39 + 5, minHeight: 39 + verticalPadding * 2),
            child: Padding(
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
                      color: theme.colorPollVoteCountText, fontSize: 20)))))),
          Expanded(
            child: Padding(
              // When the bottom of the text reaches farther than the vote count
              // box's padded bottom edge, this padding helps ensure that we
              // still maintain a consistent spacing of `verticalPadding * 2`
              // logical pixels between option rows.
              padding: const EdgeInsets.only(bottom: verticalPadding),
              child: Wrap(
                spacing: 5,
                children: [
                  Text(option.text, style: textStyleBold.copyWith(fontSize: 16)),
                  if (option.voters.isNotEmpty)
                    // TODO(i18n): Localize parenthesis characters.
                    Text('($voterNames)', style: textStyleVoterNames),
                ]))),
        ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // We expect 6 logical pixels of gap between the question and the
          // first option row, where `verticalPadding` of them come from the
          // padding of that row.
          padding: const EdgeInsets.only(bottom: 6 - verticalPadding),
          child: question),
        if (widget.poll.options.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: verticalPadding),
            child: Text(zulipLocalizations.pollWidgetOptionsMissing,
              style: textStyleVoterNames.copyWith(fontStyle: FontStyle.italic))),
        for (final option in widget.poll.options)
          buildOptionItem(option),
      ]);
  }
}
