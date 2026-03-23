import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../../model/typing_status.dart';
import '../../some_features/store.dart';

class TypingStatusWidget extends StatefulWidget {
  const TypingStatusWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  State<StatefulWidget> createState() => _TypingStatusWidgetState();
}

class _TypingStatusWidgetState extends State<TypingStatusWidget>
    with PerAccountStoreAwareStateMixin<TypingStatusWidget> {
  TypingStatus? model;

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).typingStatus
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    model?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model].
      // This method was called because that just changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final narrow = widget.narrow;
    if (narrow is! SendableNarrow) return const SizedBox();

    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final typistIds = model!.typistIdsInNarrow(narrow);
    final filteredTypistIds = typistIds.whereNot(store.isUserMuted);
    if (filteredTypistIds.isEmpty) return const SizedBox();
    final text = switch (filteredTypistIds.length) {
      1 => zulipLocalizations.onePersonTyping(
        store.userDisplayName(filteredTypistIds.first),
      ),
      2 => zulipLocalizations.twoPeopleTyping(
        store.userDisplayName(filteredTypistIds.first),
        store.userDisplayName(filteredTypistIds.last),
      ),
      _ => zulipLocalizations.manyPeopleTyping,
    };

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          // Web has the same color in light and dark mode.
          color: HslColor(0, 0, 53),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
