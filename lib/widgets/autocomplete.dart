import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/emoji.dart';
import '../model/store.dart';
import 'emoji.dart';
import 'icons.dart';
import 'store.dart';
import '../model/autocomplete.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import 'compose_box.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

abstract class AutocompleteField<QueryT extends AutocompleteQuery, ResultT extends AutocompleteResult> extends StatefulWidget {
  const AutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldViewBuilder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final WidgetBuilder fieldViewBuilder;

  AutocompleteIntent<QueryT>? autocompleteIntent();

  Widget buildItem(BuildContext context, int index, ResultT option);

  AutocompleteView<QueryT, ResultT> initViewModel(BuildContext context, QueryT query);

  @override
  State<AutocompleteField<QueryT, ResultT>> createState() => _AutocompleteFieldState<QueryT, ResultT>();
}

class _AutocompleteFieldState<QueryT extends AutocompleteQuery, ResultT extends AutocompleteResult> extends State<AutocompleteField<QueryT, ResultT>> with PerAccountStoreAwareStateMixin<AutocompleteField<QueryT, ResultT>> {
  AutocompleteView<QueryT, ResultT>? _viewModel;

  void _initViewModel(QueryT query) {
    _viewModel = widget.initViewModel(context, query)
      ..addListener(_viewModelChanged);
  }

  void _handleControllerChange() {
    final newQuery = widget.autocompleteIntent()?.query;
    // First, tear down the old view-model if necessary.
    if (_viewModel != null
        && (newQuery == null
            || !_viewModel!.acceptsQuery(newQuery))) {
      // The autocomplete interaction has ended, or has switched to a
      // different kind of autocomplete (e.g. @-mention vs. emoji).
      _viewModel!.dispose(); // removes our listener
      _viewModel = null;
      _resultsToDisplay = [];
    }
    // Then, update the view-model or build a new one.
    if (newQuery != null) {
      if (_viewModel == null) {
        _initViewModel(newQuery);
      } else {
        assert(_viewModel!.acceptsQuery(newQuery));
        _viewModel!.query = newQuery;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void onNewStore() {
    if (_viewModel != null) {
      final query = _viewModel!.query;
      _viewModel!.dispose();
      _initViewModel(query);
      _viewModel!.query = query;
    }
  }

  @override
  void didUpdateWidget(covariant AutocompleteField<QueryT, ResultT> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _viewModel?.dispose(); // removes our listener
    super.dispose();
  }

  List<ResultT> _resultsToDisplay = [];

  void _viewModelChanged() {
    setState(() {
      _resultsToDisplay = _viewModel!.results.toList();
    });
  }

  Widget _buildItem(BuildContext context, int index) {
    return widget.buildItem(context, index, _resultsToDisplay[index]);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<ResultT>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode,
      optionsBuilder: (_) => _resultsToDisplay,
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      // RawAutocomplete passes these when it calls optionsViewBuilder:
      //   AutocompleteOnSelected<ResultT> onSelected,
      //   Iterable<ResultT> options,
      //
      // We ignore them:
      // - `onSelected` would cause some behavior we don't want,
      //   such as moving the cursor to the end of the compose-input text.
      // - `options` would be needed if we were delegating to RawAutocomplete
      //   the work of creating the list of options. We're not; the
      //   `optionsBuilder` we pass is just a function that returns
      //   _resultsToDisplay, which is computed with lots of help from
      //   AutocompleteView.
      optionsViewBuilder: (context, _, _) {
        return Align(
          alignment: Alignment.bottomLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300), // TODO not hard-coded
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _resultsToDisplay.length,
                itemBuilder: _buildItem))));
      },
      // RawAutocomplete passes these when it calls fieldViewBuilder:
      //   TextEditingController textEditingController,
      //   FocusNode focusNode,
      //   VoidCallback onFieldSubmitted,
      //
      // We ignore them. For the first two, we've opted out of having
      // RawAutocomplete create them for us; we create and manage them ourselves.
      // The third isn't helpful; it lets us opt into behavior we don't actually
      // want (see discussion:
      //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/autocomplete.20UI/near/1599994>)
      fieldViewBuilder: (context, _, _, _) => widget.fieldViewBuilder(context),
    );
  }
}

class ComposeAutocomplete extends AutocompleteField<ComposeAutocompleteQuery, ComposeAutocompleteResult> {
  const ComposeAutocomplete({
    super.key,
    required this.narrow,
    required super.focusNode,
    required super.fieldViewBuilder,
    required ComposeContentController super.controller,
  });

  final Narrow narrow;

  @override
  ComposeContentController get controller => super.controller as ComposeContentController;

  @override
  AutocompleteIntent<ComposeAutocompleteQuery>? autocompleteIntent() => controller.autocompleteIntent();

  @override
  ComposeAutocompleteView initViewModel(BuildContext context, ComposeAutocompleteQuery query) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return query.initViewModel(store: store, localizations: zulipLocalizations,
      narrow: narrow);
  }

  void _onTapOption(BuildContext context, ComposeAutocompleteResult option) {
    // Probably the same intent that brought up the option that was tapped.
    // If not, it still shouldn't be off by more than the time it takes
    // to compute the autocomplete results, which we do asynchronously.
    final intent = autocompleteIntent();
    if (intent == null) {
      return; // Shrug.
    }
    final query = intent.query;

    final store = PerAccountStoreWidget.of(context);
    final String replacementString;
    switch (option) {
      case EmojiAutocompleteResult(:var candidate):
        replacementString = ':${candidate.emojiName}:';
      case UserMentionAutocompleteResult(:var userId):
        if (query is! MentionAutocompleteQuery) {
          return; // Shrug; similar to `intent == null` case above.
        }
        final user = store.getUser(userId);
        if (user == null) {
          // Don't crash on theoretical race between async results-filtering
          // and losing data for the user.
          return;
        }
        // TODO(#1805) language-appropriate space character; check active keyboard?
        //   (maybe handle centrally in `controller`)
        replacementString = '${userMention(user, silent: query.silent, users: store)} ';
      case WildcardMentionAutocompleteResult(:var wildcardOption):
        replacementString = '${wildcardMention(wildcardOption, store: store)} ';
      case UserGroupMentionAutocompleteResult(:final groupId):
        if (query is! MentionAutocompleteQuery) {
          return; // Shrug; similar to `intent == null` case above.
        }
        final userGroup = store.getGroup(groupId);
        if (userGroup == null) {
          // Don't crash on theoretical race between async results-filtering
          // and losing data for the group.
          return;
        }
        // TODO(#1805) language-appropriate space character; check active keyboard?
        //   (maybe handle centrally in `controller`)
        replacementString = '${userGroupMention(userGroup.name, silent: query.silent)} ';
      case ChannelLinkAutocompleteResult(:final channelId):
        final channel = store.streams[channelId];
        if (channel == null) {
          // Don't crash on theoretical race between async results-filtering
          // and losing data for the channel.
          return;
        }
        replacementString = '${channelLink(channel, store: store)} ';
    }

    controller.value = intent.textEditingValue.replaced(
      TextRange(
        start: intent.syntaxStart,
        end: intent.textEditingValue.selection.end),
      replacementString,
    );
  }

  @override
  Widget buildItem(BuildContext context, int index, ComposeAutocompleteResult option) {
    final designVariables = DesignVariables.of(context);

    final child = switch (option) {
      MentionAutocompleteResult() => MentionAutocompleteItem(
        option: option, narrow: narrow),
      ChannelLinkAutocompleteResult() => _ChannelLinkAutocompleteItem(option: option),
      EmojiAutocompleteResult() => _EmojiAutocompleteItem(option: option),
    };
    return InkWell(
      onTap: () {
        _onTapOption(context, option);
      },
      highlightColor: designVariables.editorButtonPressedBg,
      splashFactory: NoSplash.splashFactory,
      borderRadius: BorderRadius.circular(5),
      child: child);
  }
}

@visibleForTesting
class MentionAutocompleteItem extends StatelessWidget {
  const MentionAutocompleteItem({
    super.key,
    required this.option,
    required this.narrow,
  });

  final MentionAutocompleteResult option;
  final Narrow narrow;

  String wildcardSublabel(WildcardMentionOption wildcardOption, {
    required BuildContext context,
    required PerAccountStore store,
  }) {
    final isDmNarrow = narrow is DmNarrow;
    final isChannelWildcardAvailable = store.zulipFeatureLevel >= 247; // TODO(server-9)
    final zulipLocalizations = ZulipLocalizations.of(context);
    return switch (wildcardOption) {
      WildcardMentionOption.all || WildcardMentionOption.everyone => isDmNarrow
        ? zulipLocalizations.wildcardMentionAllDmDescription
        : isChannelWildcardAvailable
            ? zulipLocalizations.wildcardMentionChannelDescription
            : zulipLocalizations.wildcardMentionStreamDescription,
      WildcardMentionOption.channel => zulipLocalizations.wildcardMentionChannelDescription,
      WildcardMentionOption.stream => isChannelWildcardAvailable
        ? zulipLocalizations.wildcardMentionChannelDescription
        : zulipLocalizations.wildcardMentionStreamDescription,
      WildcardMentionOption.topic => zulipLocalizations.wildcardMentionTopicDescription,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    Widget avatar;
    String label;
    Widget? emoji;
    String? sublabel;
    switch (option) {
      case UserMentionAutocompleteResult(:var userId):
        avatar = Avatar(userId: userId, size: 36, borderRadius: 4);
        label = store.userDisplayName(userId);
        emoji = UserStatusEmoji(userId: userId, size: 18,
          padding: const EdgeInsetsDirectional.only(start: 5.0));
        sublabel = store.getUser(userId)?.deliveryEmail;
      case UserGroupMentionAutocompleteResult(:final groupId):
        final group = store.getGroup(groupId);
        avatar = SizedBox.square(dimension: 36,
          child: const Icon(ZulipIcons.three_person, size: 24));
        label = group?.name
          // Don't crash on theoretical race between async results-filtering
          // and losing data for the group.
          ?? '';
        emoji = null;
        sublabel = group?.description;
      case WildcardMentionAutocompleteResult(:var wildcardOption):
        avatar = SizedBox.square(dimension: 36,
          child: const Icon(ZulipIcons.three_person, size: 24));
        label = wildcardOption.canonicalString;
        emoji = null;
        sublabel = wildcardSublabel(wildcardOption, context: context, store: store);
    }

    final labelWidget = Row(children: [
      Flexible(child: Text(label,
        style: TextStyle(
          fontSize: 18,
          height: 20 / 18,
          color: designVariables.contextMenuItemLabel,
        ).merge(weightVariableTextStyle(context,
            wght: sublabel == null ? 500 : 600)),
        overflow: TextOverflow.ellipsis,
        maxLines: 1)),
      ?emoji,
    ]);

    final sublabelWidget = sublabel == null ? null : Text(
      sublabel,
      style: TextStyle(
        fontSize: 14,
        height: 16 / 14,
        color: designVariables.contextMenuItemMeta),
      overflow: TextOverflow.ellipsis,
      maxLines: 1);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4),
      child: Row(children: [
        avatar,
        const SizedBox(width: 6),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, ?sublabelWidget])),
      ]));
  }
}

class _ChannelLinkAutocompleteItem extends StatelessWidget {
  const _ChannelLinkAutocompleteItem({required this.option});

  final ChannelLinkAutocompleteResult option;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final channel = store.streams[option.channelId];

    if (channel == null) return SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 44),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(12, 4, 10, 4),
        child: Row(spacing: 10, children: [
          SizedBox.square(dimension: 24, child: Icon(iconDataForStream(channel),
            size: 18, color: colorSwatchFor(context, store.subscriptions[channel.streamId]))),
          Expanded(child: Text(channel.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18, height: 20 / 18,
              color: DesignVariables.of(context).contextMenuItemLabel,
            ).merge(weightVariableTextStyle(context, wght: 600)))),
          // TODO(#1945): show channel description
        ])),
    );
  }
}

class _EmojiAutocompleteItem extends StatelessWidget {
  const _EmojiAutocompleteItem({required this.option});

  final EmojiAutocompleteResult option;

  static const _size = 24.0;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final candidate = option.candidate;

    final emojiDisplay = candidate.emojiDisplay.resolve(store.userSettings);
    final Widget? glyph = switch (emojiDisplay) {
      ImageEmojiDisplay() || UnicodeEmojiDisplay() => EmojiWidget(
        emojiDisplay: emojiDisplay,
        squareDimension: _size,
        imagePlaceholderStyle: EmojiImagePlaceholderStyle.square,
      ),
      TextEmojiDisplay() => null, // The text is already shown separately.
    };

    final label = candidate.aliases.isEmpty
      ? candidate.emojiName
      : [candidate.emojiName, ...candidate.aliases].join(", "); // TODO(#1080)

    // TODO(design): emoji autocomplete results
    // There's no design in Figma for emoji autocomplete results.
    // Instead we adapt the design for the emoji picker to the
    // context of autocomplete results as exemplified by _MentionAutocompleteItem.
    // That means: emoji size, text size, text line-height, and font weight
    // from emoji picker; text color (for contrast with background) and
    // outer padding from _MentionAutocompleteItem; padding around emoji glyph
    // to bring it to same size as avatar in _MentionAutocompleteItem.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(children: [
        if (glyph != null) ...[
          Padding(padding: const EdgeInsets.all(6),
            child: glyph),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            style: TextStyle(fontSize: 17, height: 18 / 17,
              color: designVariables.contextMenuItemLabel),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            label)),
      ]));
  }
}

class TopicAutocomplete extends AutocompleteField<TopicAutocompleteQuery, TopicAutocompleteResult> {
  const TopicAutocomplete({
    super.key,
    required this.streamId,
    required ComposeTopicController super.controller,
    required super.focusNode,
    required this.contentFocusNode,
    required super.fieldViewBuilder,
  });

  final FocusNode contentFocusNode;

  final int streamId;

  @override
  ComposeTopicController get controller => super.controller as ComposeTopicController;

  @override
  AutocompleteIntent<TopicAutocompleteQuery>? autocompleteIntent() => controller.autocompleteIntent();

  @override
  TopicAutocompleteView initViewModel(BuildContext context, TopicAutocompleteQuery query) {
    final store = PerAccountStoreWidget.of(context);
    return TopicAutocompleteView.init(store: store, streamId: streamId, query: query);
  }

  void _onTapOption(BuildContext context, TopicAutocompleteResult option) {
    final intent = autocompleteIntent();
    if (intent == null) return;
    assert(intent.syntaxStart == 0);
    controller.setTopic(option.topic);
    contentFocusNode.requestFocus();
  }

  @override
  Widget buildItem(BuildContext context, int index, TopicAutocompleteResult option) {
    final Widget child;
    if (option.topic.displayName == null) {
      final store = PerAccountStoreWidget.of(context);
      child = Text(store.realmEmptyTopicDisplayName,
        style: const TextStyle(fontStyle: FontStyle.italic));
    } else {
      child = Text(option.topic.displayName!);
    }

    return InkWell(
      onTap: () {
        _onTapOption(context, option);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: child));
  }
}
