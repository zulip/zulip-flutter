import 'dart:async';

import 'package:collection/collection.dart';
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
  unawaited(showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return PerAccountStoreWidget(
        accountId: store.accountId,
        child: _SavedSnippetPicker(controller: controller));
    }));
}

class _SavedSnippetPicker extends StatelessWidget {
  const _SavedSnippetPicker({required this.controller});

  final ComposeBoxController controller;

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
    final store = PerAccountStoreWidget.of(context);
    // Usually a user shouldn't have that many saved snippets, so it is
    // tolerable to re-sort during builds.
    final savedSnippets = store.savedSnippets.values.sortedBy((x) => x.title); // TODO(#1399)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SavedSnippetPickerHeader(),
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
                  if (store.savedSnippets.isEmpty)
                    // TODO(design)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(zulipLocalizations.noSavedSnippets,
                        textAlign: TextAlign.center)),
                ])))),
      ]);
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
      color: designVariables.icon);
    final overlayColor = WidgetStateColor.fromMap({
      // TODO(design) check if these are the right colors
      WidgetState.hovered: designVariables.pressedTint,
      WidgetState.pressed: designVariables.pressedTint,
      WidgetState.any: Colors.transparent,
    });

    return Material(
      color: designVariables.bgContextMenu,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            splashFactory: NoSplash.splashFactory,
            overlayColor: overlayColor,
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 10, 8, 6),
              child: Text(zulipLocalizations.dialogClose,
                style: textStyle.merge(
                  weightVariableTextStyle(context, wght: 400))))),

          // TODO(#1501) support search box
          Expanded(child: Padding(
            padding: EdgeInsets.only(top: 10, bottom: 6),
            child: Text(zulipLocalizations.savedSnippetsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: designVariables.title,
                fontSize: 20,
                height: 30 / 20,
              ).merge(weightVariableTextStyle(context, wght: 600))))),

          InkWell(
            splashFactory: NoSplash.splashFactory,
            overlayColor: overlayColor,
            onTap: () => showNewSavedSnippetComposeBox(context: context),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(3, 10, 10, 6),
              child: Row(
                spacing: 4,
                children: [
                  Icon(ZulipIcons.plus, size: 24, color: designVariables.icon),
                  Text(zulipLocalizations.newSavedSnippetButton,
                    style: textStyle.merge(
                      weightVariableTextStyle(context, wght: 600))),
                ]))),
        ]),
    );
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

class _NewSavedSnippetHeader extends StatelessWidget {
  const _NewSavedSnippetHeader();

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Material(
      color: designVariables.bgContextMenu,
      child: Stack(
        children: [
          Center(child: Padding(
            padding: EdgeInsets.only(top: 10, bottom: 6),
            child: Text(zulipLocalizations.newSavedSnippetTitle,
              style: TextStyle(
                color: designVariables.title,
                fontSize: 20,
                height: 30 / 20,
              ).merge(weightVariableTextStyle(context, wght: 600))))),
          PositionedDirectional(
            end: 0,
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.fromMap({
                // TODO(design) check if these are the right colors
                WidgetState.pressed: designVariables.pressedTint,
                WidgetState.hovered: designVariables.pressedTint,
                WidgetState.any: Colors.transparent,
              }),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, 10, 16, 6),
                child: Text(zulipLocalizations.dialogCancel,
                  style: TextStyle(
                    color: designVariables.icon,
                    fontSize: 20,
                    height: 30 / 20,
                  ).merge(weightVariableTextStyle(context, wght: 400)))))),
        ]));
  }
}

void showNewSavedSnippetComposeBox({
  required BuildContext context,
}) {
  final store = PerAccountStoreWidget.of(context);
  showModalBottomSheet<void>(context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return PerAccountStoreWidget(
        accountId: store.accountId,
        child: Padding(
          padding: EdgeInsets.only(
            // When there is bottom viewInset, part of the bottom sheet would
            // be completely obstructed by certain system UI, typically the
            // keyboard.  For the compose box on message-list page, this is
            // handled by [Scaffold]; modal bottom sheet doesn't have that.
            // TODO(upstream) https://github.com/flutter/flutter/issues/71418
            bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _NewSavedSnippetHeader(),
                const SavedSnippetComposeBox(),
              ]))));
    });
}
