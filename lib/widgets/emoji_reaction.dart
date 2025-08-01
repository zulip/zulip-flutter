import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/autocomplete.dart';
import '../model/emoji.dart';
import '../model/store.dart';
import 'color.dart';
import 'dialog.dart';
import 'emoji.dart';
import 'inset_shadow.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// Emoji-reaction styles that differ between light and dark themes.
class EmojiReactionTheme extends ThemeExtension<EmojiReactionTheme> {
  static final light = EmojiReactionTheme._(
    bgSelected: Colors.white,

    // TODO shadow effect, following web, which uses `box-shadow: inset`:
    //   https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow#inset
    //   Needs Flutter support for something like that:
    //     https://github.com/flutter/flutter/issues/18636
    //     https://github.com/flutter/flutter/issues/52999
    //   Until then use a solid color; a much-lightened version of the shadow color.
    //   Also adapt by making [borderUnselected] more transparent, so we'll
    //   want to check that against web when implementing the shadow.
    bgUnselected: const HSLColor.fromAHSL(0.08, 210, 0.50, 0.875).toColor(),

    borderSelected: Colors.black.withValues(alpha: 0.45),

    // TODO see TODO on [bgUnselected] about shadow effect
    borderUnselected: Colors.black.withValues(alpha: 0.05),

    textSelected: const HSLColor.fromAHSL(1, 210, 0.20, 0.20).toColor(),
    textUnselected: const HSLColor.fromAHSL(1, 210, 0.20, 0.25).toColor(),
  );

  static final dark = EmojiReactionTheme._(
    bgSelected: Colors.black.withValues(alpha: 0.8),
    bgUnselected: Colors.black.withValues(alpha: 0.3),
    borderSelected: Colors.white.withValues(alpha: 0.75),
    borderUnselected: Colors.white.withValues(alpha: 0.15),
    textSelected: Colors.white.withValues(alpha: 0.85),
    textUnselected: Colors.white.withValues(alpha: 0.75),
  );

  EmojiReactionTheme._({
    required this.bgSelected,
    required this.bgUnselected,
    required this.borderSelected,
    required this.borderUnselected,
    required this.textSelected,
    required this.textUnselected,
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
  final Color borderSelected;
  final Color borderUnselected;
  final Color textSelected;
  final Color textUnselected;

  @override
  EmojiReactionTheme copyWith({
    Color? bgSelected,
    Color? bgUnselected,
    Color? borderSelected,
    Color? borderUnselected,
    Color? textSelected,
    Color? textUnselected,
  }) {
    return EmojiReactionTheme._(
      bgSelected: bgSelected ?? this.bgSelected,
      bgUnselected: bgUnselected ?? this.bgUnselected,
      borderSelected: borderSelected ?? this.borderSelected,
      borderUnselected: borderUnselected ?? this.borderUnselected,
      textSelected: textSelected ?? this.textSelected,
      textUnselected: textUnselected ?? this.textUnselected,
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
      borderSelected: Color.lerp(borderSelected, other.borderSelected, t)!,
      borderUnselected: Color.lerp(borderUnselected, other.borderUnselected, t)!,
      textSelected: Color.lerp(textSelected, other.textSelected, t)!,
      textUnselected: Color.lerp(textUnselected, other.textUnselected, t)!,
    );
  }
}

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
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final displayEmojiReactionUsers = store.userSettings.displayEmojiReactionUsers ?? false;
    final showNames = displayEmojiReactionUsers && reactions.total <= 3;

    Widget result = Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center,
      children: reactions.aggregated.map((reactionVotes) => ReactionChip(
        showName: showNames,
        messageId: messageId, reactionWithVotes: reactionVotes),
      ).toList());

    return Semantics(
      label: zulipLocalizations.reactionChipsLabel,
      container: true,
      explicitChildNodes: true,
      child: result);
  }
}

class ReactionChip extends StatelessWidget {
  final bool showName;
  final int messageId;
  final ReactionWithVotes reactionWithVotes;

  const ReactionChip({
    super.key,
    required this.showName,
    required this.messageId,
    required this.reactionWithVotes,
  });

  // Linear in the number of voters (of course);
  // best to avoid calling this unless we know there are few voters.
  String _voterNames(PerAccountStore store, ZulipLocalizations zulipLocalizations) {
    final selfUserId = store.selfUserId;
    final userIds = reactionWithVotes.userIds;
    final result = <String>[];
    if (userIds.contains(selfUserId)) {
      // Putting "You" first is helpful when this is used in the semantics label.
      result.add(zulipLocalizations.reactedEmojiSelfUser);
    }
    result.addAll(userIds.whereNot((userId) => userId == selfUserId).map(store.userDisplayName));
    // TODO(i18n): List formatting, like you can do in JavaScript:
    //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Shu'])
    //   // 'Chris、Greg、Alya、Shu'
    return result.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final reactionType = reactionWithVotes.reactionType;
    final emojiCode = reactionWithVotes.emojiCode;
    final emojiName = reactionWithVotes.emojiName;
    final userIds = reactionWithVotes.userIds;

    final selfVoted = userIds.contains(store.selfUserId);
    final String label;
    final String semanticsLabel;
    if (showName) {
      final names = _voterNames(store, zulipLocalizations);
      label = names;
      semanticsLabel = zulipLocalizations.reactionChipLabel(emojiName, names);
    } else {
      final count = userIds.length;
      final countStr = count.toString(); // TODO(i18n) number formatting?
      label = countStr;
      semanticsLabel = zulipLocalizations.reactionChipLabel(emojiName,
        selfVoted
          ? count == 1
            ? zulipLocalizations.reactedEmojiSelfUser
            : zulipLocalizations.reactionChipVotesYouAndOthers(count - 1)
          : countStr);
    }

    final reactionTheme = EmojiReactionTheme.of(context);
    final borderColor =     selfVoted ? reactionTheme.borderSelected : reactionTheme.borderUnselected;
    final labelColor =      selfVoted ? reactionTheme.textSelected   : reactionTheme.textUnselected;
    final backgroundColor = selfVoted ? reactionTheme.bgSelected     : reactionTheme.bgUnselected;
    final splashColor =     selfVoted ? reactionTheme.bgUnselected   : reactionTheme.bgSelected;
    final highlightColor =  splashColor.withFadedAlpha(0.5);

    final borderSide = BorderSide(
      color: borderColor,
      width: selfVoted ? 1.5 : 1.0,
    );
    final shape = StadiumBorder(side: borderSide);

    final emojiDisplay = store.emojiDisplayFor(
      emojiType: reactionType,
      emojiCode: emojiCode,
      emojiName: emojiName,
    ).resolve(store.userSettings);

    final emoji = switch (emojiDisplay) {
      UnicodeEmojiDisplay() => _UnicodeEmoji(
        emojiDisplay: emojiDisplay),
      ImageEmojiDisplay() => _ImageEmoji(
        emojiDisplay: emojiDisplay, emojiName: emojiName, selected: selfVoted),
      TextEmojiDisplay() => _TextEmoji(
        emojiDisplay: emojiDisplay, selected: selfVoted),
    };

    Widget result = Material(
      color: backgroundColor,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        splashColor: splashColor,
        highlightColor: highlightColor,
        onTap: () {
          (selfVoted ? removeReaction : addReaction).call(store.connection,
            messageId: messageId,
            reactionType: reactionType,
            emojiCode: emojiCode,
            emojiName: emojiName,
          );
        },
        child: Padding(
          // 1px of this padding accounts for the border, which Flutter
          // just paints without changing size.
          padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 5, 3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxRowWidth = constraints.maxWidth;
              // To give text emojis some room so they need fewer line breaks
              // when the label is long.
              // TODO(#433) This is a bit overzealous. The shorter width
              //   won't be necessary when the text emoji is very short, or
              //   in the near-universal case of small, square emoji (i.e.
              //   Unicode and image emoji). But it's not simple to recognize
              //   those cases here: we don't know at this point whether we'll
              //   be showing a text emoji, because we use that for various
              //   error conditions (including when an image fails to load,
              //   which we learn about especially late).
              final maxLabelWidth = (maxRowWidth - 6) * 0.75; // 6 is padding

              final labelScaler = _labelTextScalerClamped(context);
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // So text-emoji chips are at least as tall as square-emoji
                  // ones (probably a good thing).
                  SizedBox(height: _squareEmojiScalerClamped(context).scale(_squareEmojiSize)),
                  Flexible( // [Flexible] to let text emojis expand if they can
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: emoji)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxLabelWidth),
                      child: Text(
                        textWidthBasis: TextWidthBasis.longestLine,
                        textScaler: labelScaler,
                        style: TextStyle(
                          fontSize: (14 * 0.90),
                          letterSpacing: proportionalLetterSpacing(context,
                            kButtonTextLetterSpacingProportion,
                            baseFontSize: (14 * 0.90),
                            textScaler: labelScaler),
                          height: 13 / (14 * 0.90),
                          color: labelColor,
                        ).merge(weightVariableTextStyle(context,
                            wght: selfVoted ? 600 : null)),
                        label))),
                ]);
              }))));

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: result));
  }
}

/// The size of a square emoji (Unicode or image).
///
/// Should be scaled by [_emojiTextScalerClamped].
const _squareEmojiSize = 17.0;

/// A [TextScaler] that limits Unicode and image emojis' max scale factor,
/// to leave space for the label.
///
/// This should scale [_squareEmojiSize] for Unicode and image emojis.
// TODO(a11y) clamp higher?
TextScaler _squareEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2);

/// A [TextScaler] that limits text emojis' max scale factor,
/// to minimize the need for line breaks.
// TODO(a11y) clamp higher?
TextScaler _textEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

/// A [TextScaler] that limits the label's max scale factor,
/// to minimize the need for line breaks.
// TODO(a11y) clamp higher?
TextScaler _labelTextScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2);

class _UnicodeEmoji extends StatelessWidget {
  const _UnicodeEmoji({required this.emojiDisplay});

  final UnicodeEmojiDisplay emojiDisplay;

  @override
  Widget build(BuildContext context) {
    return UnicodeEmojiWidget(
      size: _squareEmojiSize,
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
      errorBuilder: (context, _, _) => _TextEmoji(
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

/// Adds or removes a reaction on the message corresponding to
/// the [messageId], showing an error dialog on failure.
/// Returns a Future resolving to true if operation succeeds.
Future<void> doAddOrRemoveReaction({
  required BuildContext context,
  required bool doRemoveReaction,
  required int messageId,
  required EmojiCandidate emoji,
  required String errorDialogTitle,
}) async {
  final store = PerAccountStoreWidget.of(context);
  String? errorMessage;
  try {
    await (doRemoveReaction ? removeReaction : addReaction).call(
      store.connection,
      messageId: messageId,
      reactionType: emoji.emojiType,
      emojiCode: emoji.emojiCode,
      emojiName: emoji.emojiName,
    );
  } catch (e) {
    if (!context.mounted) return;

    switch (e) {
      case ZulipApiException():
        errorMessage = e.message;
        // TODO(#741) specific messages for common errors, like network errors
        //   (support with reusable code)
      default:
        // TODO(log)
    }

    showErrorDialog(context: context,
      title: errorDialogTitle,
      message: errorMessage);
    return;
  }
}

/// Opens a browsable and searchable emoji picker bottom sheet.
Future<EmojiCandidate?> showEmojiPickerSheet({
  required BuildContext pageContext,
}) async {
  final store = PerAccountStoreWidget.of(pageContext);
  return showModalBottomSheet<EmojiCandidate>(
    context: pageContext,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    // The bottom inset is left for [builder] to handle;
    // see [EmojiPicker] and its [CustomScrollView] for how we do that.
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        // By default, when software keyboard is opened, the ListView
        // expands behind the software keyboard — resulting in some
        // list entries being covered by the keyboard. Add explicit
        // bottom padding the size of the keyboard, which fixes this.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        // For _EmojiPickerItem, and RealmContentNetworkImage used in ImageEmojiWidget.
        child: PerAccountStoreWidget(
          accountId: store.accountId,
          child: EmojiPicker(pageContext: pageContext)));
    });
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
      ..addListener(_handleControllerUpdate);
  }

  @override
  void onNewStore() {
    final store = PerAccountStoreWidget.of(context);
    final query = EmojiAutocompleteQuery(_controller.text);
    if (_viewModel != null) {
      assert(_viewModel!.query == query);
      _viewModel!.dispose();
    }
    _viewModel = EmojiAutocompleteView.init(store: store, query: query)
      ..addListener(_handleViewModelUpdate);
  }

  void _handleControllerUpdate() {
    _viewModel!.query = EmojiAutocompleteQuery(_controller.text);
  }

  void _handleViewModelUpdate() {
    setState(() {
      _resultsToDisplay = List.unmodifiable(_viewModel!.results);
    });
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return Column(children: [
      Padding(padding: const EdgeInsetsDirectional.only(start: 8, top: 4),
        child: Row(children: [
          // TODO(design): Make sure if we need a button to clear the textfield.
          Flexible(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: zulipLocalizations.emojiPickerSearchEmoji,
                contentPadding: const EdgeInsetsDirectional.only(start: 10, top: 6),
                filled: true,
                fillColor: designVariables.bgSearchInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                hintStyle: TextStyle(color: designVariables.textMessage)),
              style: const TextStyle(fontSize: 19, height: 26 / 19)))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              splashFactory: NoSplash.splashFactory,
              foregroundColor: designVariables.contextMenuItemText,
            ).copyWith(backgroundColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
                : Colors.transparent)),
            child: Text(zulipLocalizations.dialogCancel,
              style: const TextStyle(fontSize: 20, height: 30 / 20))),
        ])),
      Expanded(child: InsetShadowBox(
        top: 8,
        color: designVariables.bgContextMenu,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: 8),
              sliver: SliverSafeArea(
                minimum: EdgeInsets.only(bottom: 8),
                sliver: SliverList.builder(
                  itemCount: _resultsToDisplay.length,
                  itemBuilder: (context, i) => EmojiPickerListEntry(
                    pageContext: widget.pageContext,
                    emoji: _resultsToDisplay[i].candidate)))),
          ]))),
    ]);
  }
}

@visibleForTesting
class EmojiPickerListEntry extends StatelessWidget {
  const EmojiPickerListEntry({
    super.key,
    required this.pageContext,
    required this.emoji,
  });

  final BuildContext pageContext;
  final EmojiCandidate emoji;

  static const _emojiSize = 24.0;

  void _onPressed() {
    Navigator.pop(pageContext, emoji);
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    // TODO deduplicate this logic with [_EmojiAutocompleteItem]
    final emojiDisplay = emoji.emojiDisplay.resolve(store.userSettings);
    final Widget? glyph = switch (emojiDisplay) {
      ImageEmojiDisplay() =>
        ImageEmojiWidget(size: _emojiSize, emojiDisplay: emojiDisplay),
      UnicodeEmojiDisplay() =>
        UnicodeEmojiWidget(size: _emojiSize, emojiDisplay: emojiDisplay),
      TextEmojiDisplay() => null, // The text is already shown separately.
    };

    final label = emoji.aliases.isEmpty
      ? emoji.emojiName
      : [emoji.emojiName, ...emoji.aliases].join(", "); // TODO(#1080)

    return InkWell(
      onTap: _onPressed,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateColor.resolveWith((states) =>
        states.any((e) => e == WidgetState.pressed)
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(spacing: 4, children: [
          if (glyph != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: glyph),
          Flexible(child: Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              height: 18 / 17,
              color: designVariables.textMessage)))
        ]),
      ));
  }
}
