import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../icons.dart';
import '../../theme.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key, required this.onSubmitted});

  final void Function(KeywordSearchNarrow) onSubmitted;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;

  static KeywordSearchNarrow _valueToNarrow(String value) =>
      KeywordSearchNarrow(value.trim());

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted(_valueToNarrow(value));
  }

  void _clearInput() {
    _controller.clear();
    _handleSubmitted('');
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return TextField(
      controller: _controller,
      autocorrect: false,

      // Servers as of 2025-07 seem to require straight quotes for the
      // "exact match"- style query. (N.B. the doc says this param is iOS-only.)
      smartQuotesType: SmartQuotesType.disabled,

      autofocus: true,
      onSubmitted: _handleSubmitted,
      cursorColor: designVariables.textInput,
      style: TextStyle(
        color: designVariables.textInput,
        fontSize: 19,
        height: 28 / 19,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: zulipLocalizations.searchMessagesHintText,
        hintStyle: TextStyle(color: designVariables.labelSearchPrompt),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 0, 8),
          child: Icon(size: 24, ZulipIcons.search),
        ),
        prefixIconColor: designVariables.labelSearchPrompt,
        prefixIconConstraints: BoxConstraints(),
        suffixIcon: IconButton(
          tooltip: zulipLocalizations.searchMessagesClearButtonTooltip,
          onPressed: _clearInput,
          // This and `suffixIconConstraints` allow 42px square touch target.
          visualDensity: VisualDensity.compact,
          highlightColor: Colors.transparent,
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            splashFactory: NoSplash.splashFactory,
          ),
          iconSize: 24,
          icon: Icon(ZulipIcons.remove),
        ),
        suffixIconColor: designVariables.textMessageMuted,
        suffixIconConstraints: BoxConstraints(minWidth: 42, minHeight: 42),
        contentPadding: const EdgeInsetsDirectional.symmetric(vertical: 7),
        filled: true,
        fillColor: designVariables.bgSearchInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
