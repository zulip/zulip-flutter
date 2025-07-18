import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/users.dart';
import '../basic.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import 'app_bar.dart';
import 'color.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

class SetStatusPage extends StatefulWidget {
  const SetStatusPage({super.key, required this.oldStatus});

  final UserStatus oldStatus;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required UserStatus oldStatus,
  }) {
    return MaterialAccountWidgetRoute(context: context,
      page: SetStatusPage(oldStatus: oldStatus));
  }

  @override
  State<SetStatusPage> createState() => _SetStatusPageState();
}

class _SetStatusPageState extends State<SetStatusPage> {
  late final TextEditingController statusTextController;
  late final ValueNotifier<UserStatusChange> statusChange;

  UserStatus get oldStatus => widget.oldStatus;
  UserStatus get newStatus => statusChange.value.apply(widget.oldStatus);

  @override
  void initState() {
    super.initState();
    statusTextController = TextEditingController(text: oldStatus.text)
      ..addListener(() {
        final trimmedValue = statusTextController.text.trim();
        final text = trimmedValue.isNotEmpty ? trimmedValue : null;

        // Ignore updating [statusChange] for the additional updates with the
        // same value from TextField. For example, when there is a change in
        // selection or in composing range.
        if (text == newStatus.text) return;

        statusChange.value = statusChange.value.copyWith(
          text: asChange(text, old: oldStatus.text));
      });
    statusChange =
      ValueNotifier(UserStatusChange(text: OptionNone(), emoji: OptionNone()))
        ..addListener(() {
          final text = statusChange.value.text.or(oldStatus.text) ?? '';

          // Ignore updating the status text field if it already has the same
          // text. It can happen in the following cases:
          //   1. Only the emoji is changed.
          //   2. The same status is chosen consecutively from the suggested
          //      statuses list.
          //   3. This listener is called as a result of the change in status
          //      text field.
          if (text == statusTextController.text) return;

          statusTextController.text = text;
        });
  }

  @override
  void dispose() {
    statusTextController.dispose();
    statusChange.dispose();
    super.dispose();
  }

  List<UserStatus> statusSuggestions(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final localizations = ZulipLocalizations.of(context);

    final values = [
      ('1f6e0', localizations.userStatusBusy),
      ('1f4c5', localizations.userStatusInAMeeting),
      ('1f68c', localizations.userStatusCommuting),
      ('1f912', localizations.userStatusOutSick),
      ('1f334', localizations.userStatusVacationing),
      ('1f3e0', localizations.userStatusWorkingRemotely),
      ('1f3e2', localizations.userStatusAtTheOffice),
    ];
    return [
      for (final (emojiCode, statusText) in values)
        if (store.getUnicodeEmojiNameByCode(emojiCode) case final emojiName?)
          UserStatus(
            text: statusText,
            emoji: StatusEmoji(emojiName: emojiName, emojiCode: emojiCode,
              reactionType: ReactionType.unicodeEmoji)),
    ];
  }

  void handleStatusClear() {
    statusChange.value = UserStatusChange(
      text: asChange(null, old: oldStatus.text),
      emoji: asChange(null, old: oldStatus.emoji),
    );
  }

  Future<void> handleStatusSave() async {
    final store = PerAccountStoreWidget.of(context);
    final localizations = ZulipLocalizations.of(context);

    Navigator.pop(context);
    if (newStatus == oldStatus) return;

    try {
      await updateStatus(store.connection, change: statusChange.value);
    } catch (e) {
      reportErrorToUserBriefly(localizations.updateStatusErrorTitle);
    }
  }

  void chooseStatusEmoji() async {
    final emojiCandidate = await showEmojiPickerSheet(pageContext: context);
    if (emojiCandidate == null) return;

    final emoji = StatusEmoji(
      emojiName: emojiCandidate.emojiName,
      emojiCode: emojiCandidate.emojiCode,
      reactionType: emojiCandidate.emojiType,
    );
    statusChange.value = statusChange.value.copyWith(
      emoji: asChange(emoji, old: oldStatus.emoji));
  }

  void chooseStatusSuggestion(UserStatus status) {
    statusChange.value = UserStatusChange(
      text: asChange(status.text, old: oldStatus.text),
      emoji: asChange(status.emoji, old: oldStatus.emoji));
  }

  Option<T> asChange<T>(T new_, {required T old}) =>
    new_ == old ? OptionNone() : OptionSome(new_);

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final localizations = ZulipLocalizations.of(context);

    final suggestions = statusSuggestions(context);

    return Scaffold(
      appBar: ZulipAppBar(title: Text(localizations.setStatusPageTitle),
        actions: [
          ValueListenableBuilder(
            valueListenable: statusChange,
            builder: (_, _, _) {
              return _ActionButton(
                label: localizations.statusClearButtonLabel,
                icon: ZulipIcons.remove,
                onPressed: newStatus == UserStatus.zero
                  ? null
                  : handleStatusClear,
              );
            }),
          ValueListenableBuilder(
            valueListenable: statusChange,
            builder: (_, change, _) {
              return _ActionButton(
                label: localizations.statusSaveButtonLabel,
                icon: ZulipIcons.check,
                onPressed: switch ((change.text, change.emoji)) {
                  (OptionNone(), OptionNone()) => null,
                  _                            => handleStatusSave,
                });
            }),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            // In Figma design, this is 16px, but we compensate for that in
            // the icon button below.
            start: 8,
            top: 8, end: 10,
            // In Figma design, this is 4px, be we compensate for that in
            // [SingleChildScrollView.padding] below.
            bottom: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: chooseStatusEmoji,
                style: IconButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                  foregroundColor: designVariables.icon,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    // In Figma design, there is no horizontal padding, but we
                    // provide it in order to create a proper tap target size.
                    horizontal: 8)),
                icon: Row(spacing: 4, children: [
                  ValueListenableBuilder(
                    valueListenable: statusChange,
                    builder: (_, change, _) {
                      final emoji = change.emoji.or(oldStatus.emoji);
                      return emoji == null
                        ? const Icon(ZulipIcons.smile, size: 24)
                        : UserStatusEmoji(emoji: emoji, size: 24, neverAnimate: false);
                    }),
                  Icon(ZulipIcons.chevron_down, size: 16),
                ]),
              ),
              Expanded(child: TextField(
                controller: statusTextController,
                minLines: 1,
                maxLines: 2,
                // The limit on the size of the status text is 60 characters.
                // See: https://zulip.com/api/update-status#parameter-status_text
                maxLength: 60,
                cursorColor: designVariables.textInput,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 19, height: 24 / 19),
                decoration: InputDecoration(
                  // TODO: display a counter as suggested in CZO discussion:
                  //   https://chat.zulip.org/#narrow/channel/530-mobile-design/topic/Set.20user.20status/near/2224549
                  counterText: '',
                  hintText: localizations.statusTextHint,
                  hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    // Subtracting 4 pixels to account for the internal
                    // 4-pixel horizontal padding.
                    horizontal: 10 - 4,
                  ),
                  filled: true,
                  fillColor: designVariables.bgSearchInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  )))),
            ]),
        ),
        Expanded(child: InsetShadowBox(
          top: 6, bottom: 6,
          color: designVariables.mainBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final status in suggestions)
                StatusSuggestionsListEntry(
                  status: status,
                  onTap: () => chooseStatusSuggestion(status)),
            ])))),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return TextButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        foregroundColor: designVariables.icon,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8)),
      child: Row(
        spacing: 4,
        children: [
          Icon(icon, size: 24),
          Text(label,
            style: TextStyle(
              fontSize: 20,
              height: 30 / 20,
            ).merge(weightVariableTextStyle(context, wght: 600))),
        ]));
  }
}

@visibleForTesting
class StatusSuggestionsListEntry extends StatelessWidget {
  const StatusSuggestionsListEntry({
    super.key,
    required this.status,
    required this.onTap,
  });

  final UserStatus status;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateColor.resolveWith(
        (states) => states.any((e) => e == WidgetState.pressed)
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        child: Row(
          spacing: 8,
          children: [
            UserStatusEmoji(emoji: status.emoji!, size: 24),
            Flexible(child: Text(status.text!,
              style: TextStyle(fontSize: 19, height: 24 / 19),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          ])),
    );
  }
}
