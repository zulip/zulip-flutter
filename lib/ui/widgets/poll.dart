import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/model/submessage.dart';
import '../../api/route/submessage.dart';
import '../../generated/l10n/zulip_localizations.dart';
import '../../get/services/domains/users/users_service.dart';
import '../../get/services/store_service.dart';
import '../themes/content_theme.dart';
import '../values/text.dart';

class PollWidget extends StatelessWidget {
  const PollWidget({super.key, required this.messageId, required this.poll});

  final int messageId;
  final Poll poll;

  void _toggleVote(PollOption option) async {
    final connection = StoreService.to.connection;
    if (connection == null) return;
    final op = option.voters.contains(UsersService.to.selfUserId)
        ? PollVoteOp.remove
        : PollVoteOp.add;
    unawaited(
      sendSubmessage(
        connection,
        messageId: messageId,
        submessageType: SubmessageType.widget,
        content: PollVoteEventSubmessage(key: option.key, op: op),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const verticalPadding = 2.5;

    final zulipLocalizations = ZulipLocalizations.of(context);
    final theme = ContentTheme.of(context);

    final textStyleBold = weightVariableTextStyle(context, wght: 600);
    final textStyleVoterNames = TextStyle(
      fontSize: 16,
      color: theme.colorPollNames,
    );

    Text question = (poll.question.isNotEmpty)
        ? Text(poll.question, style: textStyleBold.copyWith(fontSize: 18))
        : Text(
            zulipLocalizations.pollWidgetQuestionMissing,
            style: textStyleBold.copyWith(
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          );

    Widget buildOptionItem(PollOption option) {
      final voterNames = option.voters
          .map(UsersService.to.userDisplayName)
          .join(', ');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: 5,
                top: verticalPadding,
                bottom: verticalPadding,
              ),
              child: Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                  side: BorderSide(color: theme.colorPollVoteCountBorder),
                ),
                color: theme.colorPollVoteCountBackground,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _toggleVote(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: Text(
                        option.voters.length.toString(),
                        style: textStyleBold.copyWith(
                          color: theme.colorPollVoteCountText,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: verticalPadding),
              child: Wrap(
                spacing: 5,
                children: [
                  Text(
                    option.text,
                    style: textStyleBold.copyWith(fontSize: 16),
                  ),
                  if (option.voters.isNotEmpty)
                    Text(
                      zulipLocalizations.pollVoterNames(voterNames),
                      style: textStyleVoterNames,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        question,
        const SizedBox(height: 6 - verticalPadding),
        if (poll.options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: verticalPadding),
            child: Text(
              zulipLocalizations.pollWidgetOptionsMissing,
              style: textStyleVoterNames.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        for (final option in poll.options) buildOptionItem(option),
        const SizedBox(height: 5 - verticalPadding),
      ],
    );
  }
}
