import 'package:flutter/material.dart';

import 'store.dart';
import '../model/autocomplete.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import 'compose_box.dart';

class ComposeAutocomplete extends StatefulWidget {
  const ComposeAutocomplete({
    super.key,
    required this.narrow,
    required this.controller,
    required this.focusNode,
    required this.fieldViewBuilder,
  });

  /// The message list's narrow.
  final Narrow narrow;

  final ComposeContentController controller;
  final FocusNode focusNode;
  final WidgetBuilder fieldViewBuilder;

  @override
  State<ComposeAutocomplete> createState() => _ComposeAutocompleteState();
}

class _ComposeAutocompleteState extends State<ComposeAutocomplete> {
  MentionAutocompleteView? _viewModel; // TODO different autocomplete view types

  void _composeContentChanged() {
    final newAutocompleteIntent = widget.controller.autocompleteIntent();
    if (newAutocompleteIntent != null) {
      final store = PerAccountStoreWidget.of(context);
      _viewModel ??= MentionAutocompleteView.init(store: store, narrow: widget.narrow)
        ..addListener(_viewModelChanged);
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
    widget.controller.addListener(_composeContentChanged);
  }

  @override
  void didUpdateWidget(covariant ComposeAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_composeContentChanged);
      widget.controller.addListener(_composeContentChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_composeContentChanged);
    _viewModel?.dispose(); // removes our listener
    super.dispose();
  }

  List<MentionAutocompleteResult> _resultsToDisplay = [];

  void _viewModelChanged() {
    setState(() {
      _resultsToDisplay = _viewModel!.results.toList();
    });
  }

  void _onTapOption(MentionAutocompleteResult option) {
    // Probably the same intent that brought up the option that was tapped.
    // If not, it still shouldn't be off by more than the time it takes
    // to compute the autocomplete results, which we do asynchronously.
    final intent = widget.controller.autocompleteIntent();
    if (intent == null) {
      return; // Shrug.
    }

    final store = PerAccountStoreWidget.of(context);
    final String replacementString;
    switch (option) {
      case UserMentionAutocompleteResult(:var userId):
        // TODO(i18n) language-appropriate space character; check active keyboard?
        //   (maybe handle centrally in `widget.controller`)
        replacementString = '${mention(store.users[userId]!, silent: intent.query.silent, users: store.users)} ';
      case WildcardMentionAutocompleteResult():
        replacementString = '[unimplemented]'; // TODO
      case UserGroupMentionAutocompleteResult():
        replacementString = '[unimplemented]'; // TODO
    }

    widget.controller.value = intent.textEditingValue.replaced(
      TextRange(
        start: intent.syntaxStart,
        end: intent.textEditingValue.selection.end),
      replacementString,
    );
  }

  Widget _buildItem(BuildContext _, int index) {
    final option = _resultsToDisplay[index];
    String label;
    switch (option) {
      case UserMentionAutocompleteResult(:var userId):
        // TODO avatar
        label = PerAccountStoreWidget.of(context).users[userId]!.fullName;
      case WildcardMentionAutocompleteResult():
        label = '[unimplemented]'; // TODO
      case UserGroupMentionAutocompleteResult():
        label = '[unimplemented]'; // TODO
    }
    return InkWell(
      onTap: () {
        _onTapOption(option);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<MentionAutocompleteResult>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode,
      optionsBuilder: (_) => _resultsToDisplay,
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      // RawAutocomplete passes these when it calls optionsViewBuilder:
      //   AutocompleteOnSelected<T> onSelected,
      //   Iterable<T> options,
      //
      // We ignore them:
      // - `onSelected` would cause some behavior we don't want,
      //   such as moving the cursor to the end of the compose-input text.
      // - `options` would be needed if we were delegating to RawAutocomplete
      //   the work of creating the list of options. We're not; the
      //   `optionsBuilder` we pass is just a function that returns
      //   _resultsToDisplay, which is computed with lots of help from
      //   MentionAutocompleteView.
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
