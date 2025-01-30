import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'compose_box.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

void showSavedSnippetPickerSheet({
  required BuildContext context,
  required ComposeBoxController controller,
}) async {
  final store = PerAccountStoreWidget.of(context);
  assert(store.zulipFeatureLevel >= 297); // TODO(server-10) remove
  final savedSnippets = store.savedSnippets!;
  unawaited(showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return _SavedSnippetPicker(
        controller: controller,
        savedSnippets: savedSnippets);
    }));
}

class _SavedSnippetPicker extends StatelessWidget {
  const _SavedSnippetPicker({required this.controller, required this.savedSnippets});

  final ComposeBoxController controller;
  final List<SavedSnippet> savedSnippets;

  void _handleSelect(BuildContext context, String content) {
    if (!content.endsWith('\n')) {
      content = '$content\n';
    }
    controller.content.insertPadded(content);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SavedSnippetPickerHeader(),
          Flexible(
            child: InsetShadowBox(
              top: 8,
              color: designVariables.bgContextMenu,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final savedSnippet in savedSnippets)
                      _SavedSnippetItem(
                        savedSnippet: savedSnippet,
                        onPressed:
                          () => _handleSelect(context, savedSnippet.content)),
                    if (savedSnippets.isEmpty)
                      // TODO(design)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(zulipLocalizations.noSavedSnippets,
                          textAlign: TextAlign.center)),
                  ])))),
        ]));
  }
}

class _SavedSnippetPickerHeader extends StatelessWidget {
  const _SavedSnippetPickerHeader();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final textStyle = TextStyle(
      fontSize: 20,
      height: 30 / 20,
      color: designVariables.icon,
    );
    final textButtonStyle = TextButton.styleFrom(
      shape: const ContinuousRectangleBorder(),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(42),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      splashFactory: NoSplash.splashFactory);

    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        children: [
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
              style: textButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8))),
            child: Text(zulipLocalizations.dialogClose,
              style: textStyle.merge(weightVariableTextStyle(context, wght: 400)))),
          Expanded(child: SizedBox.shrink()),
        ]));
  }
}

class _SavedSnippetItem extends StatelessWidget {
  const _SavedSnippetItem({
    required this.savedSnippet,
    required this.onPressed,
  });

  final SavedSnippet savedSnippet;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    // TODO(#xxx): support editing saved snippets
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.fromMap({
        WidgetState.pressed: designVariables.pressedTint,
        WidgetState.hovered: designVariables.pressedTint,
        WidgetState.any: Colors.transparent,
      }),
      child: Padding(
        // The end padding is 14px to account for the lack of edit button,
        // whose visible part would be 14px away from the end of the text.  See:
        //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=7965-76050&t=IxXomdPIZ5bXvJKA-0
        padding: EdgeInsetsDirectional.fromSTEB(16, 8, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            Text(savedSnippet.title,
              style: TextStyle(
                fontSize: 18,
                height: 22 / 18,
                color: designVariables.textMessage,
              ).merge(weightVariableTextStyle(context, wght: 600))),
            Text(savedSnippet.content,
              style: TextStyle(
                fontSize: 17,
                height: 18 / 17,
                color: designVariables.textMessage
              ).merge(weightVariableTextStyle(context, wght: 400))),
          ])));
  }
}
