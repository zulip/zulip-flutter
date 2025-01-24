import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../model/emoji.dart';
import '../model/store.dart';
import 'content.dart';
import 'emoji.dart';
import 'emoji_reaction.dart';
import 'profile.dart';
import 'text.dart';
import 'theme.dart';

class ReactionUsersSheet extends StatefulWidget {
  const ReactionUsersSheet({
    super.key,
    required this.reactions,
    required this.initialSelectedReaction,
    required this.store,
  });

  final Reactions reactions;
  final ReactionWithVotes initialSelectedReaction;
  final PerAccountStore store;

  @override
  State<ReactionUsersSheet> createState() => _ReactionUsersSheetState();
}

class _ReactionUsersSheetState extends State<ReactionUsersSheet> {
  late ReactionWithVotes? _selectedReaction;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.initialSelectedReaction;
    widget.store.addListener(_onStoreChanged);
    // Schedule scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedEmoji();
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    setState(() {
      // Rebuild the widget when store changes
    });
  }

  void _scrollToSelectedEmoji() {
    if (_selectedReaction == null) return;

    // Find the index of the selected reaction
    final index = widget.reactions.aggregated.indexOf(_selectedReaction!);
    if (index == -1) return;

    // Calculate approximate position and size of the emoji button
    const buttonWidth = 100.0; // Approximate width of each button including padding
    final scrollPosition = index * buttonWidth;

    // Check if the button is already visible
    final viewportStart = _scrollController.offset;
    final viewportEnd = viewportStart + _scrollController.position.viewportDimension;

    // If button is already in view, don't scroll
    if (scrollPosition >= viewportStart && scrollPosition + buttonWidth <= viewportEnd) {
      return;
    }

    // If not in view, animate to bring it into view
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _getEmojiWidget(ReactionWithVotes reaction) {
    final emojiDisplay = widget.store.emojiDisplayFor(
      emojiType: reaction.reactionType,
      emojiCode: reaction.emojiCode,
      emojiName: reaction.emojiName,
    ).resolve(widget.store.userSettings);

    final emoji = switch (emojiDisplay) {
      UnicodeEmojiDisplay() => _UnicodeEmoji(
        emojiDisplay: emojiDisplay),
      ImageEmojiDisplay() => _ImageEmoji(
        emojiDisplay: emojiDisplay, emojiName: reaction.emojiName, selected: false),
      TextEmojiDisplay() => _TextEmoji(
        emojiDisplay: emojiDisplay, selected: false),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: emoji,
    );
  }

  Widget _buildEmojiButton(ReactionWithVotes reaction) {
    final isSelected = _selectedReaction == reaction;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final designVariables = DesignVariables.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReaction = reaction;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: isSelected ? Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                    width: 1,
                  ) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(child: _getEmojiWidget(reaction)),
                    const SizedBox(height: 0.5),
                    Text(
                      reaction.userIds.length.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                          ? designVariables.textMessage
                          : designVariables.textMessage.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }


  List<({String name, Widget emoji, int userId})> _getUserNamesWithEmojis() {
    if (_selectedReaction == null) {
      // Show all users when "All" is selected
      final allUserReactions = <({String name, Widget emoji, int userId})>[];

      for (final reaction in widget.reactions.aggregated) {
        // Add each user-reaction combination separately
        for (final userId in reaction.userIds) {
          allUserReactions.add((
            name: widget.store.users[userId]?.fullName ?? '(unknown user)',
            emoji: _getEmojiWidget(reaction),
            userId: userId,
          ));
        }
      }

      // Sort by name to group the same user's reactions together
      return allUserReactions..sort((a, b) => a.name.compareTo(b.name));
    } else {
      // Show users for selected reaction
      return _selectedReaction!.userIds.map((userId) => (
        name: widget.store.users[userId]?.fullName ?? '(unknown user)',
        emoji: _getEmojiWidget(_selectedReaction!),
        userId: userId,
      )).toList()..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _getUserNamesWithEmojis();
    final designVariables = DesignVariables.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...widget.reactions.aggregated.map((reaction) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildEmojiButton(reaction),
                  )),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) => InkWell(
                onTap: () => Navigator.push(context,
                  ProfilePage.buildRoute(context: context,
                    userId: users[index].userId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        Avatar(
                          size: 36,
                          borderRadius: 4,
                          userId: users[index].userId,
                        ),
                        if (widget.store.users[users[index].userId]?.isActive ?? false)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: designVariables.mainBackground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            users[index].name,
                            style: TextStyle(
                              color: designVariables.textMessage,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return designVariables.contextMenuCancelPressedBg;
                  }
                  return Colors.transparent;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: designVariables.contextMenuCancelBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: designVariables.contextMenuCancelText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnicodeEmoji extends StatelessWidget {
  const _UnicodeEmoji({required this.emojiDisplay});

  final UnicodeEmojiDisplay emojiDisplay;

  @override
  Widget build(BuildContext context) {
    return UnicodeEmojiWidget(
      size: _squareEmojiSize,
      notoColorEmojiTextSize: _notoColorEmojiTextSize,
      textScaler: _squareEmojiScalerClamped(context),
      emojiDisplay: emojiDisplay);
  }
}

class _ImageEmoji extends StatelessWidget {
  const _ImageEmoji({
    required this.emojiDisplay,
    required this.emojiName,
    required this.selected,
  });

  final ImageEmojiDisplay emojiDisplay;
  final String emojiName;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ImageEmojiWidget(
      size: _squareEmojiSize,
      // Unicode and text emoji get scaled; it would look weird if image emoji didn't.
      textScaler: _squareEmojiScalerClamped(context),
      emojiDisplay: emojiDisplay,
      errorBuilder: (context, _, __) => _TextEmoji(
        emojiDisplay: TextEmojiDisplay(emojiName: emojiName), selected: selected),
    );
  }
}

class _TextEmoji extends StatelessWidget {
  const _TextEmoji({required this.emojiDisplay, required this.selected});

  final TextEmojiDisplay emojiDisplay;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final emojiName = emojiDisplay.emojiName;

    // Encourage line breaks before "_" (common in these), but try not
    // to leave a colon alone on a line. See:
    //   <https://github.com/flutter/flutter/issues/61081#issuecomment-1103330522>
    final text = ':\ufeff${emojiName.replaceAll('_', '\u200b_')}\ufeff:';

    final reactionTheme = EmojiReactionTheme.of(context);
    return Text(
      textAlign: TextAlign.end,
      textScaler: _textEmojiScalerClamped(context),
      textWidthBasis: TextWidthBasis.longestLine,
      style: TextStyle(
        fontSize: 14 * 0.8,
        height: 1, // to be denser when we have to wrap
        color: selected ? reactionTheme.textSelected : reactionTheme.textUnselected,
      ).merge(weightVariableTextStyle(context,
          wght: selected ? 600 : null)),
      text);
  }
}

/// The size of a square emoji (Unicode or image).
///
/// This is the exact size we want emojis to be rendered at.
const _squareEmojiSize = 23.0;

/// A font size that, with Noto Color Emoji, renders at exactly our desired size.
/// This matches _squareEmojiSize since we use a height of 1.0 in the text style.
const _notoColorEmojiTextSize = 19.32;

/// A [TextScaler] that maintains accessibility while preventing emojis from getting too large
TextScaler _squareEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

/// A [TextScaler] for text emojis that maintains accessibility while preventing excessive wrapping
TextScaler _textEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

