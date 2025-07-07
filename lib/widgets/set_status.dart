import 'package:flutter/material.dart';

import '../api/core.dart';
import '../api/model/model.dart';
import '../basic.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'app_bar.dart';
import 'color.dart';
import 'content.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

class SetStatusPage extends StatefulWidget {
  const SetStatusPage({super.key, required this.oldStatus});

  final UserStatus oldStatus;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required UserStatus oldStatus,
  }) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: SetStatusPage(oldStatus: oldStatus),
    );
  }

  @override
  State<SetStatusPage> createState() => _SetStatusPageState();
}

class _SetStatusPageState extends State<SetStatusPage> {
  List<UserStatus> _statusSuggestions(ZulipLocalizations localizations) => [
    UserStatus(text: localizations.userStatusBusy, emoji: StatusEmoji(emojiName: 'working_on_it', emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusInAMeeting, emoji: StatusEmoji(emojiName: 'calendar', emojiCode: '1f4c5', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusCommuting, emoji: StatusEmoji(emojiName: 'bus', emojiCode: '1f68c', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusOutSick, emoji: StatusEmoji(emojiName: 'sick', emojiCode: '1f912', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusVacationing, emoji: StatusEmoji(emojiName: 'palm_tree', emojiCode: '1f334', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusWorkingRemotely, emoji: StatusEmoji(emojiName: 'house', emojiCode: '1f3e0', reactionType: ReactionType.unicodeEmoji)),
    UserStatus(text: localizations.userStatusAtTheOffice, emoji: StatusEmoji(emojiName: 'office', emojiCode: '1f3e2', reactionType: ReactionType.unicodeEmoji)),
  ];

  late final TextEditingController statusTextController;
  late final ValueNotifier<UserStatusChange> statusChange;

  UserStatus get oldStatus => widget.oldStatus;
  UserStatus get currentStatus => statusChange.value.apply(widget.oldStatus);

  bool saving = false;

  @override
  void initState() {
    super.initState();
    statusTextController = TextEditingController(text: oldStatus.text)
      ..addListener(() {
        final trimmedValue = statusTextController.text.trim();
        final text = trimmedValue.isNotEmpty ? trimmedValue : null;
        if (text == currentStatus.text) return;
        statusChange.value = statusChange.value.copyWith(
          text: text == oldStatus.text
            ? OptionNone()
            : OptionSome(text),
        );
      });
    statusChange =
      ValueNotifier(UserStatusChange(text: OptionNone(), emoji: OptionNone()))
        ..addListener(() {
          final text = statusChange.value.text;
          switch (text) {
            case OptionNone<String?>():
              statusTextController.text = oldStatus.text ?? '';
            case OptionSome<String?>(:var value):
              statusTextController.text = value ?? '';
          }
        });
  }

  @override
  void dispose() {
    statusTextController.dispose();
    statusChange.dispose();
    super.dispose();
  }

  Future<void> handleSave(BuildContext context) async {
    final store = PerAccountStoreWidget.of(context);
    if (currentStatus == oldStatus) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      saving = true;
    });

    await updateStatus(store.connection, status: currentStatus);

    setState(() {
      saving = false;
    });

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final localizations = ZulipLocalizations.of(context);

    return Scaffold(
      appBar: ZulipAppBar(title: Text(localizations.myStatus,),
        actions: [
          ValueListenableBuilder(
            valueListenable: statusChange,
            builder: (_, _, _) {
              return _ActionButton(
                label: localizations.statusClear,
                icon: ZulipIcons.remove,
                onPressed: currentStatus != UserStatus.zero
                  ? () {
                      statusChange.value = UserStatusChange(
                        text: oldStatus.text == null ? OptionNone() : OptionSome(null),
                        emoji: oldStatus.emoji == null ? OptionNone() : OptionSome(null),
                      );
                    }
                  : null,
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: statusChange,
            builder: (_, change, _) {
              return _ActionButton(
                label: saving ? localizations.statusSaving : localizations.statusSave,
                icon: ZulipIcons.check,
                onPressed: switch ((change.text, change.emoji)) {
                  (OptionNone(), OptionNone()) => null,
                  _ => () => handleSave(context),
                },
              );
            })],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            TextButton(
              onPressed: () async {
                final emojiCandidate = await showEmojiPickerSheet(pageContext: context);
                if (emojiCandidate == null) return;
                final emoji = StatusEmoji(
                  emojiName: emojiCandidate.emojiName,
                  emojiCode: emojiCandidate.emojiCode,
                  reactionType: emojiCandidate.emojiType,
                );
                statusChange.value = statusChange.value.copyWith(
                  emoji: emoji == oldStatus.emoji
                    ? OptionNone()
                    : OptionSome(
                        StatusEmoji(
                          emojiName: emojiCandidate.emojiName,
                          emojiCode: emojiCandidate.emojiCode,
                          reactionType: emojiCandidate.emojiType,
                        ),
                      ),
                );
              },
              style: IconButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                foregroundColor: designVariables.icon,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              child: Row(children: [
                ValueListenableBuilder(
                  valueListenable: statusChange,
                  builder: (_, change, icon) {
                    final emoji = switch(change.emoji) {
                      OptionNone<StatusEmoji?>() => oldStatus.emoji,
                      OptionSome<StatusEmoji?>(:var value) => value,
                    };
                    return emoji != null
                      ? UserStatusEmoji(emoji: emoji, size: 24, neverAnimate: false)
                      : icon!;
                  },
                  child: Icon(ZulipIcons.smile, size: 24),
                ),
                SizedBox(width: 6),
                Text(
                  localizations.emoji,
                  style: TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                  ).merge(weightVariableTextStyle(context, wght: 400)),
                ),
                SizedBox(width: 2),
                Icon(ZulipIcons.chevron_down, size: 16),
              ]),
            ),
            Expanded(child: TextField(
              controller: statusTextController,
              cursorColor: designVariables.textInput,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 19, height: 24 / 19),
              decoration: InputDecoration(
                hintText: localizations.yourStatus,
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
                )),
            )),
          ]),
        ),
        Flexible(child: InsetShadowBox(
          top: 6, color: designVariables.mainBackground,
          child: SingleChildScrollView(
            child: Column(children: [
              for (final status in _statusSuggestions(localizations))
                InkWell(
                  onTap: () {
                    statusChange.value = UserStatusChange(
                      text: oldStatus.text == status.text
                        ? OptionNone()
                        : OptionSome(status.text),
                      emoji: oldStatus.emoji == status.emoji
                        ? OptionNone()
                        : OptionSome(status.emoji)
                    );
                  },
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
                        UserStatusEmoji(emoji: status.emoji!, size: 19),
                        Flexible(child: Text(status.text!,
                          style: TextStyle(fontSize: 19, height: 24 / 19),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                      ])),
                ),
            ]),
          ),
        )),
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
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      child: Row(
        spacing: 4,
        children: [
          Icon(icon, size: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              height: 30 / 20,
            ).merge(weightVariableTextStyle(context, wght: 600)),
          )]));
  }
}

/// https://zulip.com/api/update-status
Future<void> updateStatus(ApiConnection connection, {
  required UserStatus status,
}) {
  return connection.post('updateStatus', (_) {}, 'users/me/status', {
    'status_text': RawParameter(status.text ?? ''),
    'emoji_name': RawParameter(status.emoji?.emojiName ?? ''),
    'emoji_code': RawParameter(status.emoji?.emojiCode ?? ''),
    'reaction_type': RawParameter(status.emoji?.reactionType.toJson() ?? ''),
  });
}
