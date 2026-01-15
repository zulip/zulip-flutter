import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/model/model.dart';
import '../api/route/users.dart';
import '../basic.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import 'app_bar.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'image.dart';
import 'inset_shadow.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

/// Options for automatically clearing status.
enum StatusExpirationOption {
  never,
  in30Minutes,
  in1Hour,
  todayAt5PM,
  tomorrow,
  custom,
}


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

  /// Currently selected expiration option.
  StatusExpirationOption _selectedExpiration = StatusExpirationOption.never;

  /// Custom expiration time when "Custom" is selected.
  DateTime? _customExpirationTime;

  /// Whether the user has manually changed the expiration.
  bool _hasUserChangedExpiration = false;

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

  /// Returns the default expiration option for a given preset status emoji code.
  StatusExpirationOption _getDefaultExpiration(String emojiCode) {
    return switch (emojiCode) {
      '1f6e0' => StatusExpirationOption.in1Hour,       // Busy
      '1f4c5' => StatusExpirationOption.in1Hour,       // In a meeting
      '1f68c' => StatusExpirationOption.in30Minutes,   // Commuting
      '1f912' => StatusExpirationOption.tomorrow,       // Out sick
      '1f334' => StatusExpirationOption.never,          // Vacationing
      '1f3e0' => StatusExpirationOption.todayAt5PM,     // Working remotely
      '1f3e2' => StatusExpirationOption.todayAt5PM,     // At the office
      _ => StatusExpirationOption.never,                // Default/Custom
    };
  }

  /// Computes the Unix timestamp (in seconds) for the selected expiration option.
  int? _computeExpirationTimestamp() {
    final now = DateTime.now();
    return switch (_selectedExpiration) {
      StatusExpirationOption.never => null,
      StatusExpirationOption.in30Minutes =>
        now.add(const Duration(minutes: 30)).millisecondsSinceEpoch ~/ 1000,
      StatusExpirationOption.in1Hour =>
        now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      StatusExpirationOption.todayAt5PM =>
        DateTime(now.year, now.month, now.day, 17, 0).millisecondsSinceEpoch ~/ 1000,
      StatusExpirationOption.tomorrow =>
        DateTime(now.year, now.month, now.day + 1, 0, 0).millisecondsSinceEpoch ~/ 1000,
      StatusExpirationOption.custom => _customExpirationTime != null
        ? _customExpirationTime!.millisecondsSinceEpoch ~/ 1000
        : null,
    };
  }

  /// Returns the display name for an expiration option.
  String _getExpirationOptionLabel(StatusExpirationOption option, ZulipLocalizations zulipLocalizations) {
    final store = PerAccountStoreWidget.of(context);
    final use24Hour = store.userSettings.twentyFourHourTime == TwentyFourHourTimeMode.twentyFourHour;

    return switch (option) {
      StatusExpirationOption.never => zulipLocalizations.statusExpirationNever,
      StatusExpirationOption.in30Minutes => zulipLocalizations.statusExpirationIn30Minutes,
      StatusExpirationOption.in1Hour => zulipLocalizations.statusExpirationIn1Hour,
      StatusExpirationOption.todayAt5PM => zulipLocalizations.statusExpirationTodayAtTime(
        use24Hour ? '17:00' : '5:00 PM'),
      StatusExpirationOption.tomorrow => zulipLocalizations.statusExpirationTomorrow,
      StatusExpirationOption.custom => zulipLocalizations.statusExpirationCustom,
    };
  }

  /// Formats the expiration time for display.
  String? _formatExpirationTime() {
    final timestamp = _computeExpirationTimestamp();
    if (timestamp == null) return null;

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final store = PerAccountStoreWidget.of(context);
    final use24Hour = store.userSettings.twentyFourHourTime == TwentyFourHourTimeMode.twentyFourHour;

    final dateFormat = DateFormat.MMMd();
    final timeFormat = use24Hour ? DateFormat.Hm() : DateFormat('h:mm a');

    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  /// Opens a date and time picker for custom expiration.
  Future<void> _pickCustomTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (pickedTime == null || !mounted) return;

    final customDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate the time is in the future
    if (customDateTime.isBefore(DateTime.now())) {
      return;
    }

    setState(() {
      _customExpirationTime = customDateTime;
    });
  }


  List<UserStatus> statusSuggestions(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final values = [
      ('1f6e0', zulipLocalizations.userStatusBusy),
      ('1f4c5', zulipLocalizations.userStatusInAMeeting),
      ('1f68c', zulipLocalizations.userStatusCommuting),
      ('1f912', zulipLocalizations.userStatusOutSick),
      ('1f334', zulipLocalizations.userStatusVacationing),
      ('1f3e0', zulipLocalizations.userStatusWorkingRemotely),
      ('1f3e2', zulipLocalizations.userStatusAtTheOffice),
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
    final zulipLocalizations = ZulipLocalizations.of(context);

    Navigator.pop(context);
    if (newStatus == oldStatus && _selectedExpiration == StatusExpirationOption.never) return;

    // Include the expiration timestamp in the status change
    final changeWithExpiration = statusChange.value.copyWith(
      scheduledEndTime: OptionSome(_computeExpirationTimestamp()),
    );

    try {
      await updateStatus(store.connection, change: changeWithExpiration);
    } catch (e) {
      reportErrorToUserBriefly(zulipLocalizations.updateStatusErrorTitle);
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

    // Auto-set expiration based on the status emoji if user hasn't manually changed it
    if (!_hasUserChangedExpiration && status.emoji != null) {
      setState(() {
        _selectedExpiration = _getDefaultExpiration(status.emoji!.emojiCode);
      });
    }
  }

  Option<T> asChange<T>(T new_, {required T old}) =>
    new_ == old ? OptionNone() : OptionSome(new_);

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final suggestions = statusSuggestions(context);

    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.setStatusPageTitle),
        actions: [
          ValueListenableBuilder(
            valueListenable: statusChange,
            builder: (_, _, _) {
              return _ActionButton(
                label: zulipLocalizations.statusClearButtonLabel,
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
                label: zulipLocalizations.statusSaveButtonLabel,
                icon: ZulipIcons.check,
                onPressed: switch ((change.text, change.emoji)) {
                  (OptionNone(), OptionNone()) => null,
                  _                            => handleStatusSave,
                });
            }),
        ],
      ),
      body: SafeArea(
        bottom: false,
        minimum: EdgeInsets.symmetric(horizontal: 8),
        child: Column(children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 8,
              // In Figma design, this is 4px, be we compensate for that in
              // [SingleChildScrollView.padding] below.
              bottom: 0),
            child: Row(
              spacing: 4,
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
                          : UserStatusEmoji(
                              emoji: emoji,
                              size: 24,
                              animationMode: ImageAnimationMode.animateConditionally,
                            );
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
                    hintText: zulipLocalizations.statusTextHint,
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
            top: 6,
            color: designVariables.mainBackground,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 6),
              child: Column(children: [
                for (final status in suggestions)
                  StatusSuggestionsListEntry(
                    status: status,
                    onTap: () => chooseStatusSuggestion(status)),
                const SizedBox(height: 16),
                // Expiration dropdown section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zulipLocalizations.statusExpirationLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: designVariables.labelMenuButton,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: designVariables.bgSearchInput,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<StatusExpirationOption>(
                          value: _selectedExpiration,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: designVariables.bgSearchInput,
                          items: StatusExpirationOption.values.map((option) {
                            return DropdownMenuItem<StatusExpirationOption>(
                              value: option,
                              child: Text(
                                _getExpirationOptionLabel(option, zulipLocalizations),
                                style: TextStyle(
                                  fontSize: 17,
                                  color: designVariables.textInput,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            if (value == StatusExpirationOption.custom) {
                              await _pickCustomTime();
                              if (_customExpirationTime != null) {
                                setState(() {
                                  _selectedExpiration = value;
                                  _hasUserChangedExpiration = true;
                                });
                              }
                            } else {
                              setState(() {
                                _selectedExpiration = value;
                                _hasUserChangedExpiration = true;
                              });
                            }
                          },
                        ),
                      ),
                      if (_selectedExpiration != StatusExpirationOption.never)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatExpirationTime() ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: designVariables.labelMenuButton,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ])))),
        ])),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7, horizontal: 8),
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
