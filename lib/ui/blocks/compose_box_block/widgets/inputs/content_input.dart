import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../../../../api/exception.dart';
import '../../../../../api/route/messages.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../model/narrow.dart';
import '../../../../utils/store.dart';
import '../../../../widgets/autocomplete.dart';
import '../../../../extensions/color.dart';
import '../../../message_list_block/message_list_block.dart';
import '../../compose_box.dart';
import '../../../../widgets/dialog.dart';
import '../../../../widgets/inset_shadow.dart';
import '../../../../values/theme.dart';

class ContentInput extends StatefulWidget {
  const ContentInput({
    super.key,
    required this.narrow,
    required this.controller,
    required this.getDestination,
    this.hintText,
    this.enabled = true,
  });

  final Narrow narrow;
  final ComposeBoxController controller;
  final String? hintText;
  final bool enabled;
  final MessageDestination Function() getDestination;

  static double maxHeight(BuildContext context) {
    final clampingTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.5);
    final scaledLineHeight =
        clampingTextScaler.scale(_fontSize) * _lineHeightRatio;

    // Reserve space to fully show the first 7th lines and just partially
    // clip the 8th line, where the height matches the spec at
    //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3960-5147&node-type=text&m=dev
    // > Maximum size of the compose box is suggested to be 178px. Which
    // > has 7 fully visible lines of text
    //
    // The partial line hints that the content input is scrollable.
    //
    // Using the ambient TextScale means this works for different values of the
    // system text-size setting. We clamp to a max scale factor to limit
    // how tall the content input can get; that's to save room for the message
    // list. The user can still scroll the input to see everything.
    return _verticalPadding + 7.727 * scaledLineHeight;
  }

  static const _verticalPadding = 8.0;
  static const _fontSize = 17.0;
  static const _lineHeight = 22.0;
  static const _lineHeightRatio = _lineHeight / _fontSize;

  @override
  State<ContentInput> createState() => _ContentInputState();
}

class _ContentInputState extends State<ContentInput> {
  // Перехват "Вставить" в инпут сообщения
  void _handleContentInserted(
    BuildContext context,
    KeyboardInsertedContent content,
  ) async {
    if (content.data == null || content.data!.isEmpty) {
      // As of writing, the engine implementation never leaves `content.data` as
      // `null`, but ideally it should be when the data cannot be read for
      // errors.
      //
      // When `content.data` is empty, the data is not literally empty — this
      // can also happen when the data can't be read from the input stream
      // provided by the Android SDK because of an IO exception.
      //
      // See Flutter engine implementation that prepares this data:
      //   https://github.com/flutter/flutter/blob/0ffc4ce00/engine/src/flutter/shell/platform/android/io/flutter/plugin/editing/InputConnectionAdaptor.java#L497-L548
      // TODO(upstream): improve the API for this
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorContentNotInsertedTitle,
        message: zulipLocalizations.errorContentToInsertIsEmpty,
      );
      return;
    }

    final file = FileToUpload(
      content: Stream.fromIterable([content.data!]),
      length: content.data!.length,
      filename: path.basename(content.uri),
      mimeType: content.mimeType,
    );

    await widget.controller.uploadFiles(
      context: context,
      files: [file],
      shouldRequestFocus: true,
    );
  }

  bool get _hasValidationErrors {
    bool result = false;
    final controller = widget.controller;
    if (controller is StreamComposeBoxController) {
      result = controller.topic.hasValidationErrors.value;
    }
    result |= controller.content.hasValidationErrors.value;
    return result;
  }

  void _send() async {
    final controller = widget.controller;

    if (_hasValidationErrors) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      final store = PerAccountStoreWidget.of(context);
      List<String> validationErrorMessages = [
        for (final error
            in (controller is StreamComposeBoxController
                ? controller.topic.validationErrors
                : const <TopicValidationError>[]))
          error.message(zulipLocalizations, maxLength: store.maxTopicLength),
        for (final error in controller.content.validationErrors)
          error.message(zulipLocalizations),
      ];
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: validationErrorMessages.join('\n\n'),
      );
      return;
    }

    final destination = widget.getDestination();
    final content = controller.content.textNormalized;

    controller.content.clear();

    try {
      final store = PerAccountStoreWidget.of(context);
      await store.sendMessage(destination: destination, content: content);
      if (!mounted) return;
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.message,
      };
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: message,
      );
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    if (destination is StreamDestination &&
        store.subscriptions[destination.streamId] == null) {
      // The message was sent to an unsubscribed channel.
      // We don't get new-message events for unsubscribed channels,
      // but we can refresh the view when a send-message request succeeds,
      // so the user will at least see their own messages without having to
      // exit and re-enter. See the "first buggy behavior" in
      //   https://github.com/zulip/zulip-flutter/issues/1798 .
      MessageListBlockPage.ancestorOf(context).refresh(AnchorCode.newest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return ComposeAutocomplete(
      narrow: widget.narrow,
      controller: widget.controller.content,
      focusNode: widget.controller.contentFocusNode,
      fieldViewBuilder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: ContentInput.maxHeight(context)),
        // This [ClipRect] replaces the [TextField] clipping we disable below.
        child: ClipRect(
          child: InsetShadowBox(
            top: ContentInput._verticalPadding,
            bottom: ContentInput._verticalPadding,
            color: designVariables.composeBoxBg,
            child:
                // CallbackShortcuts(
                //   bindings: {
                //     const SingleActivator(
                //       LogicalKeyboardKey.enter,
                //       control: true,
                //     ): () {
                //       log('Ctrl+Enter нажат!');
                //     },
                //     const SingleActivator(LogicalKeyboardKey.enter): () {
                //       log('Enter без Ctrl (сейчас добавит новую строку!)');
                //       // Чтобы предотвратить новую строку, нужно здесь тоже вернуть handled,
                //       // но CallbackShortcuts не предоставляет такого механизма.
                //     },
                //   },
                //   child:
                Focus(
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (!(Platform.isAndroid || Platform.isIOS)) {
                      if (event is KeyDownEvent) {
                        final hardwareKeyboard = HardwareKeyboard.instance;
                        if ((hardwareKeyboard.isControlPressed ||
                                hardwareKeyboard.isMetaPressed) &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          widget.controller.content.text += '\n';
                          return KeyEventResult.handled;
                        } else if (event.logicalKey ==
                            LogicalKeyboardKey.enter) {
                          if (widget.controller.content.text.isNotEmpty) {
                            log('Enter нажат!');
                            _send();
                          }

                          return KeyEventResult.handled;
                        }
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    enabled: widget.enabled,
                    controller: widget.controller.content,
                    focusNode: widget.controller.contentFocusNode,
                    contentInsertionConfiguration:
                        ContentInsertionConfiguration(
                          onContentInserted: (content) =>
                              _handleContentInserted(context, content),
                        ),
                    // Let the content show through the `contentPadding` so that
                    // our [InsetShadowBox] can fade it smoothly there.
                    clipBehavior: Clip.none,
                    style: TextStyle(
                      fontSize: ContentInput._fontSize,
                      height: ContentInput._lineHeightRatio,
                      color: designVariables.textInput,
                    ),
                    // From the spec at
                    //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3960-5147&node-type=text&m=dev
                    // > Compose box has the height to fit 2 lines. This is [done] to
                    // > have a bigger hit area for the user to start the input. […]
                    minLines: 2,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      // This padding ensures that the user can always scroll long
                      // content entirely out of the top or bottom shadow if desired.
                      // With this and the `minLines: 2` above, an empty content input
                      // gets 60px vertical distance (with no text-size scaling)
                      // between the top of the top shadow and the bottom of the
                      // bottom shadow. That's a bit more than the 54px given in the
                      // Figma, and we can revisit if needed, but it's tricky to get
                      // that 54px distance while also making the scrolling work like
                      // this and offering two lines of touchable area.
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: ContentInput._verticalPadding,
                      ),
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: designVariables.textInput.withFadedAlpha(0.5),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
      //),
    );
  }
}
