import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../../autocomplete.dart';
import '../../../color.dart';
import '../../../compose_box.dart';
import '../../../dialog.dart';
import '../../../inset_shadow.dart';
import '../../../theme.dart';

class ContentInput extends StatelessWidget {
  const ContentInput({
    super.key,
    required this.narrow,
    required this.controller,
    this.hintText,
    this.enabled = true,
  });

  final Narrow narrow;
  final ComposeBoxController controller;
  final String? hintText;
  final bool enabled;

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

    await controller.uploadFiles(
      context: context,
      files: [file],
      shouldRequestFocus: true,
    );
  }

  // Высчитать максимальную высоту инпута
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
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return ComposeAutocomplete(
      narrow: narrow,
      controller: controller.content,
      focusNode: controller.contentFocusNode,
      fieldViewBuilder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight(context)),
        // This [ClipRect] replaces the [TextField] clipping we disable below.
        child: ClipRect(
          child: InsetShadowBox(
            top: _verticalPadding,
            bottom: _verticalPadding,
            color: designVariables.composeBoxBg,
            child: TextField(
              enabled: enabled,
              controller: controller.content,
              focusNode: controller.contentFocusNode,
              contentInsertionConfiguration: ContentInsertionConfiguration(
                onContentInserted: (content) =>
                    _handleContentInserted(context, content),
              ),
              // Let the content show through the `contentPadding` so that
              // our [InsetShadowBox] can fade it smoothly there.
              clipBehavior: Clip.none,
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeightRatio,
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
                  vertical: _verticalPadding,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: designVariables.textInput.withFadedAlpha(0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
