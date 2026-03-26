import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/domains/presence/presence_service.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/binding.dart';
import '../../../../model/presence.dart';
import '../../../values/theme.dart';

class LastActiveTime extends StatefulWidget {
  const LastActiveTime({super.key, required this.userId});

  final int userId;

  @override
  State<LastActiveTime> createState() => _LastActiveTimeState();
}

class _LastActiveTimeState extends State<LastActiveTime> {
  Presence? _model;

  @override
  void initState() {
    super.initState();
    ever(StoreService.to.currentStore, (_) => _onStoreChanged());
    _initFromStore();
  }

  void _onStoreChanged() {
    _model?.removeListener(_modelChanged);
    _initFromStore();
  }

  void _initFromStore() {
    final presence = PresenceService.to.presence;
    if (presence != null) {
      _model = presence..addListener(_modelChanged);
    }
  }

  @override
  void dispose() {
    _model?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [_model].
    });
  }

  String _lastActiveText(ZulipLocalizations zulipLocalizations) {
    // TODO(#45): revise this relative-time logic in light of a future solution
    //   for the lightbox, e.g. using ICU/CLDR via FFI.  See discussion:
    //     https://github.com/zulip/zulip-flutter/pull/1793#issuecomment-3169228753

    // TODO(#293), TODO(#891): auto-rebuild as relative time changes
    final nowDate = ZulipBinding.instance.utcNow();

    final status = _model!.presenceStatusForUser(
      widget.userId,
      utcNow: nowDate,
    );
    switch (status) {
      case PresenceStatus.active:
        return zulipLocalizations.userActiveNow;
      case PresenceStatus.idle:
        return zulipLocalizations.userIdle;
      case null:
        break; // handle below
    }

    final timestamp = _model!.userLastActive(widget.userId);
    if (timestamp == null) return zulipLocalizations.userNotActiveInYear;

    // Compare web's timerender.last_seen_status_from_date.
    final now = nowDate.millisecondsSinceEpoch ~/ 1000;
    final ageSeconds = now - timestamp;
    if (ageSeconds <= 0) {
      // TODO or perhaps show full time, to help user in case of clock skew
      return zulipLocalizations.userActiveNow;
    } else if (ageSeconds < 60 * 60) {
      return zulipLocalizations.userActiveMinutesAgo(ageSeconds ~/ 60);
    } else if (ageSeconds < 24 * 60 * 60) {
      return zulipLocalizations.userActiveHoursAgo(ageSeconds ~/ (60 * 60));
    }

    final todayNoon = nowDate.toLocal().copyWith(
      hour: 12,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final presenceNoon = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: false,
    ).copyWith(hour: 12, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final ageCalendarDays =
        (todayNoon.difference(presenceNoon).inSeconds / (24 * 60 * 60)).round();
    if (ageCalendarDays <= 0) {
      // The timestamp was at least 24 hours ago.
      // If it's somehow the same or a future calendar day, then this must be a
      // really messy time zone.  Hopefully no real time zone makes this possible.
      return zulipLocalizations.userActiveYesterday;
    } else if (ageCalendarDays == 1) {
      return zulipLocalizations.userActiveYesterday;
    } else if (ageCalendarDays < 90) {
      return zulipLocalizations.userActiveDaysAgo(ageCalendarDays);
    }

    final DateFormat format;
    if (presenceNoon.year == todayNoon.year) {
      format = DateFormat.MMMd();
    } else {
      format = DateFormat.yMMMd();
    }
    return zulipLocalizations.userActiveDate(format.format(presenceNoon));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Text(
      _lastActiveText(zulipLocalizations),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        height: 22 / 18,
        color: DesignVariables.of(context).userStatusText,
      ),
    );
  }
}
