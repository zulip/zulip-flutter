import 'package:flutter/material.dart';

import 'content.dart';
import 'store.dart';
import '../model/autocomplete.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import 'compose_box.dart';

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

  AutocompleteView<QueryT, ResultT> initViewModel(BuildContext context);

  @override
  State<AutocompleteField<QueryT, ResultT>> createState() => _AutocompleteFieldState<QueryT, ResultT>();
}

class _AutocompleteFieldState<QueryT extends AutocompleteQuery, ResultT extends AutocompleteResult> extends State<AutocompleteField<QueryT, ResultT>> with PerAccountStoreAwareStateMixin<AutocompleteField<QueryT, ResultT>> {
  AutocompleteView<QueryT, ResultT>? _viewModel;

  void _initViewModel() {
    _viewModel = widget.initViewModel(context)
      ..addListener(_viewModelChanged);
  }

  void _handleControllerChange() {
    final newAutocompleteIntent = widget.autocompleteIntent();
    if (newAutocompleteIntent != null) {
      if (_viewModel == null) {
        _initViewModel();
      }
      _viewModel!.query = newAutocompleteIntent.query;
    } else {
      if (_viewModel != null) {
        _viewModel!.dispose(); // removes our listener
        _viewModel = null;
        _resultsToDisplay = [];
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
      _initViewModel();
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
      optionsViewBuilder: (context, _, __) {
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
      fieldViewBuilder: (context, _, __, ___) => widget.fieldViewBuilder(context),
    );
  }
}

class ComposeAutocomplete extends AutocompleteField<MentionAutocompleteQuery, MentionAutocompleteResult> {
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
  AutocompleteIntent<MentionAutocompleteQuery>? autocompleteIntent() => controller.autocompleteIntent();

  @override
  MentionAutocompleteView initViewModel(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return MentionAutocompleteView.init(store: store, narrow: narrow);
  }

  void _onTapOption(BuildContext context, MentionAutocompleteResult option) {
    // Probably the same intent that brought up the option that was tapped.
    // If not, it still shouldn't be off by more than the time it takes
    // to compute the autocomplete results, which we do asynchronously.
    final intent = autocompleteIntent();
    if (intent == null) {
      return; // Shrug.
    }

    final store = PerAccountStoreWidget.of(context);
    final String replacementString;
    switch (option) {
      case UserMentionAutocompleteResult(:var userId):
        // TODO(i18n) language-appropriate space character; check active keyboard?
        //   (maybe handle centrally in `controller`)
        replacementString = '${mention(store.users[userId]!, silent: intent.query.silent, users: store.users)} ';
    }

    controller.value = intent.textEditingValue.replaced(
      TextRange(
        start: intent.syntaxStart,
        end: intent.textEditingValue.selection.end),
      replacementString,
    );
  }

  @override
  Widget buildItem(BuildContext context, int index, MentionAutocompleteResult option) {
    Widget avatar;
    String label;
    switch (option) {
      case UserMentionAutocompleteResult(:var userId):
        avatar = Avatar(userId: userId, size: 32, borderRadius: 3);
        label = PerAccountStoreWidget.of(context).users[userId]!.fullName;
    }
    return InkWell(
      onTap: () {
        _onTapOption(context, option);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 8),
            Text(label),
          ])));
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
  TopicAutocompleteView initViewModel(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return TopicAutocompleteView.init(store: store, streamId: streamId);
  }

  void _onTapOption(BuildContext context, TopicAutocompleteResult option) {
    final intent = autocompleteIntent();
    if (intent == null) return;
    final replacementString = option.topic;
    controller.value = intent.textEditingValue.replaced(
      TextRange(
        start: intent.syntaxStart,
        end: intent.textEditingValue.text.length),
      replacementString,
    );
    contentFocusNode.requestFocus();
  }

  @override
  Widget buildItem(BuildContext context, int index, TopicAutocompleteResult option) {
    return InkWell(
      onTap: () {
        _onTapOption(context, option);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(option.topic)));
  }
}
