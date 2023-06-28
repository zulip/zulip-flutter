import 'package:flutter/material.dart';

import 'store.dart';
import '../model/autocomplete.dart';
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
  MentionAutocompleteView? _mentionAutocompleteView; // TODO different autocomplete view types

  void _changed() {
    final newAutocompleteIntent = widget.controller.autocompleteIntent();
    if (newAutocompleteIntent != null) {
      final store = PerAccountStoreWidget.of(context);
      _mentionAutocompleteView ??= MentionAutocompleteView.init(
        store: store, narrow: widget.narrow);
      _mentionAutocompleteView!.query = newAutocompleteIntent.query;
    } else {
      if (_mentionAutocompleteView != null) {
        _mentionAutocompleteView!.dispose();
        _mentionAutocompleteView = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant ComposeAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _mentionAutocompleteView?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.fieldViewBuilder(context);
  }
}
