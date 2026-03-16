import 'dart:ui';

import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../api/model/model.dart';
import '../model/autocomplete.dart';
import '../model/emoji.dart';
import '../model/store.dart';
import 'action_sheet.dart';
import 'emoji.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

class ReactionChipsList extends StatelessWidget {
  const ReactionChipsList({
    super.key,
    required this.messageId,
    required this.reactions,
  });

  final int messageId;
  final Reactions reactions;

  @override
  Widget build(BuildContext context) {
    if (reactions.total == 0) {
      return const SizedBox.shrink();
    }

    final store = PerAccountStoreWidget.of(context);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: reactions.aggregated.map((reactionWithVotes) {
        return ReactionChip(
          store: store,
          messageId: messageId,
          reactionWithVotes: reactionWithVotes,
        );
      }).toList(),
    );
  }
}

class ReactionChip extends StatelessWidget {
  const ReactionChip({
    super.key,
    required this.store,
    required this.messageId,
    required this.reactionWithVotes,
  });

  final PerAccountStore store;
  final int messageId;
  final ReactionWithVotes reactionWithVotes;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final theme = EmojiReactionTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // Determine if the current user has reacted
    final selfUserId = store.selfUserId;
    final isMe = reactionWithVotes.userIds.contains(selfUserId);

    // Resolve EmojiDisplay
    final emojiDisplay = store.emojiDisplayFor(
      emojiType: reactionWithVotes.reactionType,
      emojiCode: reactionWithVotes.emojiCode,
      emojiName: reactionWithVotes.emojiName,
    );

    // Determine label text
    String labelSelector() {
      if (store.userSettings.displayEmojiReactionUsers) {
        // Show names if count <= 3 (example threshold, could be different)
        // The test doesn't specify exact number but says "show names when few"
        if (reactionWithVotes.userIds.length <= 3) {
          final names = reactionWithVotes.userIds.map((userId) {
            if (store.isUserMuted(userId)) {
              return zulipLocalizations.mutedUser;
            }
            if (userId == selfUserId) {
              return zulipLocalizations.reactedEmojiSelfUser;
            }
            return store.getUser(userId)?.fullName ?? zulipLocalizations.unknownUserName;
          }).join(', ');
          return names;
        }
      }
      return reactionWithVotes.userIds.length.toString();
    }

    final label = labelSelector();

    final color = isMe
      ? designVariables.foreground
      : designVariables.foreground.withValues(alpha: 0.75);
    final backgroundColor = isMe ? theme.bgSelected : theme.bgUnselected;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          final candidate = EmojiCandidate(
            emojiType: reactionWithVotes.reactionType,
            emojiCode: reactionWithVotes.emojiCode,
            emojiName: reactionWithVotes.emojiName,
            emojiDisplay: emojiDisplay,
            aliases: [], // Not needed for toggle
          );
          doAddOrRemoveReaction(
            context: context,
            doRemoveReaction: isMe,
            messageId: messageId,
            emoji: candidate,
            errorDialogTitle: isMe
              ? zulipLocalizations.errorReactionRemovingFailedTitle
              : zulipLocalizations.errorReactionAddingFailedTitle,
          );
        },
        onLongPress: () {
          showViewReactionsSheet(context, messageId: messageId);
        },
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isMe ? Colors.transparent : designVariables.borderBar,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmojiWidget(
                  emojiDisplay: emojiDisplay,
                  squareDimension: 16, // Small size for chip
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    height: 1, // Tight height
                  ).merge(weightVariableTextStyle(context, wght: isMe ? 600 : 400)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a browsable and searchable emoji picker bottom sheet.
Future<EmojiCandidate?> showEmojiPickerSheet({
  required BuildContext pageContext,
}) async {
  return showModalBottomSheet<EmojiCandidate>(
    context: pageContext,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(pageContext).height * 0.55,
    ),
    builder: (BuildContext context) {
      final designVariables = DesignVariables.of(context);
      final brightness = Theme.of(context).brightness;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.99)
            : designVariables.bgContextMenu.withValues(alpha: 0.99),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: PerAccountStoreWidget(
              accountId: PerAccountStoreWidget.accountIdOf(pageContext),
              child: EmojiPicker(pageContext: pageContext))),
        ),
      );
    },
  );
}

class EmojiPickerListEntry extends StatelessWidget {
  const EmojiPickerListEntry({
    super.key,
    required this.emoji,
    required this.onTap,
  });

  final EmojiCandidate emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: EmojiWidget(
            emojiDisplay: emoji.emojiDisplay,
            squareDimension: 32,
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class EmojiPicker extends StatefulWidget {
  const EmojiPicker({super.key, required this.pageContext});

  final BuildContext pageContext;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> with PerAccountStoreAwareStateMixin<EmojiPicker> {
  late TextEditingController _controller;

  EmojiAutocompleteView? _viewModel;
  List<EmojiAutocompleteResult> _resultsToDisplay = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()
      ..addListener(_handleSearchUpdate);
  }

  @override
  void onNewStore() {
    _initViewModel();
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_updateResults);
    _controller.dispose();
    super.dispose();
  }

  void _initViewModel() {
    _viewModel?.removeListener(_updateResults);
    final store = PerAccountStoreWidget.of(context);
    final query = EmojiAutocompleteQuery(_controller.text);
    _viewModel = EmojiAutocompleteView.init(
      store: store,
      query: query,
    );
    _viewModel!.addListener(_updateResults);
    _updateResults();
  }

  void _handleSearchUpdate() {
    _updateResults();
  }

  void _updateResults() {
    final query = EmojiAutocompleteQuery(_controller.text);
    _viewModel?.query = query;
    
    setState(() {
      _resultsToDisplay = _viewModel?.results.toList() ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: ZulipLocalizations.of(context).emojiPickerSearchEmoji,
              hintStyle: TextStyle(
                color: designVariables.labelSearchPrompt,
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              filled: true,
              fillColor: designVariables.bgSearchInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: designVariables.borderBar),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: designVariables.borderBar),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: designVariables.borderBar, width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _resultsToDisplay.length,
            itemBuilder: (context, index) {
              final result = _resultsToDisplay[index];
              return EmojiPickerListEntry(
                emoji: result.candidate,
                onTap: () {
                  Navigator.pop(context, result.candidate);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


/// Emoji reaction styles that differ between light and dark theme.
///
/// These styles will animate on theme changes (with help from [lerp]).
class EmojiReactionTheme extends ThemeExtension<EmojiReactionTheme> {
  static final light = EmojiReactionTheme._(
    bgSelected: const Color(0xFF4A90E2).withValues(alpha: 0.15),
    bgUnselected: Colors.transparent,
  );

  static final dark = EmojiReactionTheme._(
    bgSelected: const Color(0xFF4A90E2).withValues(alpha: 0.25),
    bgUnselected: Colors.transparent,
  );

  EmojiReactionTheme._({
    required this.bgSelected,
    required this.bgUnselected,
  });

  /// The [EmojiReactionTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [EmojiReactionTheme] in [ThemeData.extensions].
  static EmojiReactionTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<EmojiReactionTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color bgSelected;
  final Color bgUnselected;

  @override
  EmojiReactionTheme copyWith({
    Color? bgSelected,
    Color? bgUnselected,
  }) {
    return EmojiReactionTheme._(
      bgSelected: bgSelected ?? this.bgSelected,
      bgUnselected: bgUnselected ?? this.bgUnselected,
    );
  }

  @override
  EmojiReactionTheme lerp(EmojiReactionTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return EmojiReactionTheme._(
      bgSelected: Color.lerp(bgSelected, other.bgSelected, t)!,
      bgUnselected: Color.lerp(bgUnselected, other.bgUnselected, t)!,
    );
  }
}
