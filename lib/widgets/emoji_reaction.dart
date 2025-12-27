import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/autocomplete.dart';
import '../model/emoji.dart';
import '../model/store.dart';
import 'action_sheet.dart';
import 'color.dart';
import 'dialog.dart';
import 'emoji.dart';
import 'inset_shadow.dart';
import 'page.dart';
import 'profile.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

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
    final displayEmojiReactionUsers = store.userSettings.displayEmojiReactionUsers;
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

    final emoji = EmojiWidget(
      emojiDisplay: emojiDisplay,
      squareDimension: _squareEmojiSize,
      squareDimensionScaler: _squareEmojiScalerClamped(context),
      imagePlaceholderStyle: EmojiImagePlaceholderStyle.text,
      buildCustomTextEmoji: () => _TextEmoji(
        emojiName: emojiName, selected: selfVoted),
    );

    Widget result = Material(
      color: backgroundColor,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        splashColor: splashColor,
        highlightColor: highlightColor,
        onLongPress: () {
          showViewReactionsSheet(PageRoot.contextOf(context),
            messageId: messageId,
            initialReactionType: reactionType,
            initialEmojiCode: emojiCode);
        },
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

class _TextEmoji extends StatelessWidget {
  const _TextEmoji({required this.emojiName, required this.selected});

  final String emojiName;
  final bool selected;

  @override
  Widget build(BuildContext context) {
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
      textEmojiForEmojiName(emojiName));
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
              overlayColor: Colors.transparent,
            ),
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

    final emojiDisplay = emoji.emojiDisplay.resolve(store.userSettings);
    final Widget? glyph = switch (emojiDisplay) {
      ImageEmojiDisplay() || UnicodeEmojiDisplay() => EmojiWidget(
        emojiDisplay: emojiDisplay,
        squareDimension: _emojiSize,
        imagePlaceholderStyle: EmojiImagePlaceholderStyle.square,
      ),
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

/// Opens a bottom sheet showing who reacted to the message.
void showViewReactionsSheet(BuildContext pageContext, {
  required int messageId,
  ReactionType? initialReactionType,
  String? initialEmojiCode,
}) {
  final accountId = PerAccountStoreWidget.accountIdOf(pageContext);

  showModalBottomSheet<void>(
    context: pageContext,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) {
      return PerAccountStoreWidget(
        accountId: accountId,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: ViewReactions(
            messageId: messageId,
            initialEmojiCode: initialEmojiCode,
            initialReactionType: initialReactionType)));
    });
}

class ViewReactions extends StatefulWidget {
  const ViewReactions({
    super.key,
    required this.messageId,
    this.initialReactionType,
    this.initialEmojiCode,
  });

  final int messageId;
  final ReactionType? initialReactionType;
  final String? initialEmojiCode;

  @override
  State<ViewReactions> createState() => _ViewReactionsState();
}

class _ViewReactionsState extends State<ViewReactions> with PerAccountStoreAwareStateMixin<ViewReactions> {
  ReactionType? reactionType;
  String? emojiCode;
  String? emojiName;

  PerAccountStore? store;

  void _setSelection(ReactionWithVotes? selection) {
    setState(() {
      reactionType = selection?.reactionType;
      emojiCode = selection?.emojiCode;
      emojiName = selection?.emojiName;
    });
  }

  void _storeChanged() {
    _reconcile();
  }

  /// Check that the given reaction still has votes;
  /// if not, select a different one if possible or clear the selection.
  void _reconcile() {
    // TODO scroll into view
    _setSelection(_findMatchingReaction());
  }

  ReactionWithVotes? _findMatchingReaction() {
    final message = PerAccountStoreWidget.of(context).messages[widget.messageId];

    final reactions = message?.reactions?.aggregated;

    if (reactions == null || reactions.isEmpty) {
      return null;
    }

    return reactions
      .firstWhereOrNull((x) =>
        x.reactionType == reactionType && x.emojiCode == emojiCode)
      // first item will exist; early-return above on reactions.isEmpty
      ?? reactions.first;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialReactionType != null) {
      assert(widget.initialEmojiCode != null);
      reactionType = widget.initialReactionType!;
      emojiCode = widget.initialEmojiCode!;
    }
  }

  @override
  void onNewStore() {
    // TODO(#1747) listen for changes in the message's reactions
    store?.removeListener(_storeChanged);
    store = PerAccountStoreWidget.of(context);
    store!.addListener(_storeChanged);
    _reconcile();
  }

  @override
  void dispose() {
    store?.removeListener(_storeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableModalBottomSheet(
      header: ViewReactionsHeader(
        messageId: widget.messageId,
        reactionType: reactionType,
        emojiCode: emojiCode,
        onRequestSelect: _setSelection,
      ),
      contentSliver: ViewReactionsUserListSliver(
        messageId: widget.messageId,
        reactionType: reactionType,
        emojiCode: emojiCode,
        emojiName: emojiName));
  }
}

class ViewReactionsHeader extends StatelessWidget {
  const ViewReactionsHeader({
    super.key,
    required this.messageId,
    required this.reactionType,
    required this.emojiCode,
    required this.onRequestSelect,
  });

  final int messageId;
  final ReactionType? reactionType;
  final String? emojiCode;
  final void Function(ReactionWithVotes) onRequestSelect;

  /// A [double] between 0.0 and 1.0 for an emoji's position in the list.
  ///
  /// When auto-scrolling an emoji into view,
  /// this is where the scroll position will land
  /// (the min- and max- scroll extent lerped at this value).
  double _emojiItemPosition(int index, int aggregatedLength) {
    if (aggregatedLength == 1) {
      assert(index == 0);
      return 0.5;
    }
    return index / (aggregatedLength - 1);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final message = PerAccountStoreWidget.of(context).messages[messageId];

    final reactions = message?.reactions;

    if (reactions == null || reactions.aggregated.isEmpty) {
      return BottomSheetHeader(
        outerVerticalPadding: true,
        message: zulipLocalizations.seeWhoReactedSheetNoReactions);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: InsetShadowBox(start: 8, end: 8,
        color: designVariables.bgContextMenu,
        child: Center(
          child: SingleChildScrollView(
            // TODO(upstream) we want to pass excludeFromSemantics: true
            //    to the underlying Scrollable to remove an unwanted node
            //    in accessibility focus traversal when there are many items.
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                role: SemanticsRole.tabBar,
                container: true,
                explicitChildNodes: true,
                label: zulipLocalizations.seeWhoReactedSheetHeaderLabel(reactions.total),
                child: Row(
                  children: reactions.aggregated.mapIndexed((i, r) =>
                    _ViewReactionsEmojiItem(
                      reactionWithVotes: r,
                      position: _emojiItemPosition(i, reactions.aggregated.length),
                      selected: r.reactionType == reactionType && r.emojiCode == emojiCode,
                      onRequestSelect: onRequestSelect),
                  ).toList())))))));
  }
}

class _ViewReactionsEmojiItem extends StatelessWidget {
  const _ViewReactionsEmojiItem({
    required this.reactionWithVotes,
    required this.position,
    required this.selected,
    required this.onRequestSelect,
  });

  final ReactionWithVotes reactionWithVotes;
  final double position;
  final bool selected;
  final void Function(ReactionWithVotes) onRequestSelect;

  static const double emojiSize = 24;

  /// Animates the list's scroll position for this item.
  ///
  /// This serves two purposes when the list is longer than the viewport width:
  /// - Ensures the item is in view
  /// - By animating, draws attention to the fact that this is a scrollable list
  ///   and there may be more items in view. (In particular, does this when
  ///   any item is tapped, because each item has a different [position].)
  void _scrollIntoView(BuildContext context) {
    final scrollPosition = Scrollable.of(context, axis: Axis.horizontal).position;
    final destination = lerpDouble(
      scrollPosition.minScrollExtent,
      scrollPosition.maxScrollExtent,
      position)!;

    scrollPosition.animateTo(destination,
      duration: Duration(milliseconds: 200),
      curve: Curves.ease);
  }

  void _handleTap(BuildContext context) {
    _scrollIntoView(context);
    onRequestSelect(reactionWithVotes);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final count = reactionWithVotes.userIds.length;

    final emojiName = reactionWithVotes.emojiName;
    final emojiDisplay = store.emojiDisplayFor(
      emojiType: reactionWithVotes.reactionType,
      emojiCode: reactionWithVotes.emojiCode,
      emojiName: emojiName);
    // (Not calling EmojiDisplay.resolve. For expediency, rather than design a
    // reasonable layout for [Emojiset.text], in this case we just override that
    // setting and show the emoji anyway.)

    final emoji = EmojiWidget(
      emojiDisplay: emojiDisplay,
      squareDimension: emojiSize,
      buildCustomTextEmoji: () =>
        // Invoked when an image emoji's URL didn't parse; see
        // EmojiStore.emojiDisplayFor. Don't show text, just an empty square.
        // TODO(design) refine?; offer a visible touch target with tooltip?
        SizedBox.square(dimension: emojiSize),
    );

    Widget result = Tooltip(
      message: emojiName,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: selected
              ? Border.all(color: designVariables.borderBar)
              : null,
            borderRadius: BorderRadius.circular(10),
            color: selected ? designVariables.background : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 4.5, 14, 4.5),
            child: Center(
              child: Column(
                spacing: 3,
                mainAxisSize: MainAxisSize.min,
                children: [
                  emoji,
                  Text(
                    style: TextStyle(
                      color: designVariables.title,
                      fontSize: 14,
                      height: 14 / 14),
                    count.toString()), // TODO(i18n) number formatting?
                ])),
          ))));

    return Semantics(
      role: SemanticsRole.tab,
      onDidGainAccessibilityFocus: () => _scrollIntoView(context),

      // I *think* we're following the doc with this but it's hard to tell;
      // I've only tested on iOS and I didn't notice a behavior change.
      controlsNodes: {ViewReactionsUserListSliver.semanticsIdentifier},

      selected: selected,
      label: zulipLocalizations.seeWhoReactedSheetEmojiNameWithVoteCount(emojiName, count),
      onTap: () => _handleTap(context),
      child: ExcludeSemantics(
        child: result));
  }
}

@visibleForTesting
class ViewReactionsUserListSliver extends StatelessWidget {
  const ViewReactionsUserListSliver({
    super.key,
    required this.messageId,
    required this.reactionType,
    required this.emojiCode,
    required this.emojiName,
  });

  final int messageId;
  final ReactionType? reactionType;
  final String? emojiCode;
  final String? emojiName;

  static const semanticsIdentifier = 'view-reactions-user-list';

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);

    if (reactionType == null || emojiCode == null) {
      // The emoji selection was cleared,
      // which happens when the message is deleted or loses all its reactions.
      // The sheet's header will have a message like
      // "This message has no reactions."
      return SliverPadding(padding: EdgeInsets.zero);
    }
    assert(emojiName != null);

    final message = store.messages[messageId];

    final userIds = message?.reactions?.aggregated.firstWhereOrNull(
      (x) => x.reactionType == reactionType && x.emojiCode == emojiCode
    )?.userIds.toList();

    // (No filtering of muted or deactivated users.
    //  Muted users will be shown as muted.)

    if (userIds == null) {
      // The selected emoji lost all its votes. This won't show long if at all;
      // a different emoji will be automatically selected if there is one.
      return SliverPadding(padding: EdgeInsets.zero);
    }

    Widget result = SliverList.builder(
      itemCount: userIds.length,
      itemBuilder: (_, index) => ViewReactionsUserItem(userId: userIds[index]));

    return SliverSemantics(
      identifier: semanticsIdentifier, // See note on `controlsNodes` on the tab.
      label: zulipLocalizations.seeWhoReactedSheetUserListLabel(emojiName!, userIds.length),
      role: SemanticsRole.tabPanel,
      container: true,
      explicitChildNodes: true,
      sliver: result);
  }
}

// TODO: deduplicate the code with [ReadReceiptsUserItem]
@visibleForTesting
class ViewReactionsUserItem extends StatelessWidget {
  const ViewReactionsUserItem({
    super.key,
    required this.userId,
  });

  final int userId;

  void _onPressed(BuildContext context) {
    // Dismiss the action sheet.
    Navigator.pop(context);

    Navigator.push(context,
      ProfilePage.buildRoute(context: context, userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    return InkWell(
      onTap: () => _onPressed(context),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateColor.fromMap({
        WidgetState.pressed: designVariables.contextMenuItemBg.withFadedAlpha(0.20),
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(spacing: 8, children: [
          Avatar(
            size: 32,
            borderRadius: 3,
            backgroundColor: designVariables.bgContextMenu,
            userId: userId),
          Flexible(
            child: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                height: 17 / 17,
                color: designVariables.textMessage,
              ).merge(weightVariableTextStyle(context, wght: 500)),
              store.userDisplayName(userId))),
        ])));
  }
}
