import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'autocomplete.dart';
import 'color.dart';
import 'dialog.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

const double _composeButtonSize = 44;

/// A [TextEditingController] for use in the compose box.
///
/// Subclasses must ensure that [_update] is called in all exposed constructors.
abstract class ComposeController<ErrorT> extends TextEditingController {
  String get textNormalized => _textNormalized;
  late String _textNormalized;
  String _computeTextNormalized();

  List<ErrorT> get validationErrors => _validationErrors;
  late List<ErrorT> _validationErrors;
  List<ErrorT> _computeValidationErrors();

  ValueNotifier<bool> hasValidationErrors = ValueNotifier(false);

  void _update() {
    _textNormalized = _computeTextNormalized();
    _validationErrors = _computeValidationErrors();
    hasValidationErrors.value = _validationErrors.isNotEmpty;
  }

  @override
  void notifyListeners() {
    _update();
    super.notifyListeners();
  }
}

enum TopicValidationError {
  mandatoryButEmpty,
  tooLong;

  String message(ZulipLocalizations zulipLocalizations) {
    switch (this) {
      case tooLong:
        return zulipLocalizations.topicValidationErrorTooLong;
      case mandatoryButEmpty:
        return zulipLocalizations.topicValidationErrorMandatoryButEmpty;
    }
  }
}

class ComposeTopicController extends ComposeController<TopicValidationError> {
  ComposeTopicController() {
    _update();
  }

  // TODO: subscribe to this value:
  //   https://zulip.com/help/require-topics
  final mandatory = true;

  @override
  String _computeTextNormalized() {
    String trimmed = text.trim();
    return trimmed.isEmpty ? kNoTopicTopic : trimmed;
  }

  @override
  List<TopicValidationError> _computeValidationErrors() {
    return [
      if (mandatory && textNormalized == kNoTopicTopic)
        TopicValidationError.mandatoryButEmpty,
      if (textNormalized.length > kMaxTopicLength)
        TopicValidationError.tooLong,
    ];
  }

  void setTopic(TopicName newTopic) {
    value = TextEditingValue(text: newTopic.displayName);
  }
}

enum ContentValidationError {
  empty,
  tooLong,
  quoteAndReplyInProgress,
  uploadInProgress;

  String message(ZulipLocalizations zulipLocalizations) {
    switch (this) {
      case ContentValidationError.tooLong:
        return zulipLocalizations.contentValidationErrorTooLong;
      case ContentValidationError.empty:
        return zulipLocalizations.contentValidationErrorEmpty;
      case ContentValidationError.quoteAndReplyInProgress:
        return zulipLocalizations.contentValidationErrorQuoteAndReplyInProgress;
      case ContentValidationError.uploadInProgress:
        return zulipLocalizations.contentValidationErrorUploadInProgress;
    }
  }
}

class ComposeContentController extends ComposeController<ContentValidationError> {
  ComposeContentController() {
    _update();
  }

  int _nextQuoteAndReplyTag = 0;
  int _nextUploadTag = 0;

  final Map<int, ({int messageId, String placeholder})> _quoteAndReplies = {};
  final Map<int, ({String filename, String placeholder})> _uploads = {};

  /// A probably-reasonable place to insert Markdown, such as for a file upload.
  ///
  /// Gives the cursor position,
  /// or if text is selected, the end of the selection range.
  ///
  /// If there isn't a cursor position or a text selection
  /// (e.g., when the input has never been focused),
  /// gives the end of the whole text.
  ///
  /// Expressed as a collapsed `TextRange` at the index.
  TextRange insertionIndex() {
    final TextRange selection = value.selection;
    final String text = value.text;
    return selection.isValid
      ? (selection.isCollapsed
        ? selection
        : TextRange.collapsed(selection.end))
      : TextRange.collapsed(text.length);
  }

  /// Inserts [newText] in [text], setting off with an empty line before and after.
  ///
  /// Assumes [newText] is not empty and consists entirely of complete lines
  /// (each line ends with a newline).
  ///
  /// Inserts at [insertionIndex]. If that's zero, no empty line is added before.
  ///
  /// If there is already an empty line before or after, does not add another.
  void insertPadded(String newText) {
    assert(newText.isNotEmpty);
    assert(newText.endsWith('\n'));
    final i = insertionIndex();
    final textBefore = text.substring(0, i.start);
    final String paddingBefore;
    if (textBefore.isEmpty || textBefore == '\n' || textBefore.endsWith('\n\n')) {
      paddingBefore = ''; // At start of input, or just after an empty line.
    } else if (textBefore.endsWith('\n')) {
      paddingBefore = '\n'; // After a complete but non-empty line.
    } else {
      paddingBefore = '\n\n'; // After an incomplete line.
    }
    if (text.substring(i.start).startsWith('\n')) {
      final partial = value.replaced(i, paddingBefore + newText);
      value = partial.copyWith(selection: TextSelection.collapsed(offset: partial.selection.start + 1));
    } else {
      value = value.replaced(i, '$paddingBefore$newText\n');
    }
  }

  /// Tells the controller that a quote-and-reply has started.
  ///
  /// Returns an int "tag" that should be passed to registerQuoteAndReplyEnd on
  /// success or failure
  int registerQuoteAndReplyStart(PerAccountStore store, {required Message message}) {
    final tag = _nextQuoteAndReplyTag;
    _nextQuoteAndReplyTag += 1;
    final placeholder = quoteAndReplyPlaceholder(store, message: message);
    _quoteAndReplies[tag] = (messageId: message.id, placeholder: placeholder);
    notifyListeners(); // _quoteAndReplies change could affect validationErrors
    insertPadded(placeholder);
    return tag;
  }

  /// Tells the controller that a quote-and-reply has ended, with success or error.
  ///
  /// To indicate success, pass [rawContent].
  /// If that is null, failure is assumed.
  void registerQuoteAndReplyEnd(PerAccountStore store, int tag, {
    required Message message,
    String? rawContent,
  }) {
    final val = _quoteAndReplies[tag];
    assert(val != null, 'registerQuoteAndReplyEnd called twice for same tag');
    final int startIndex = text.indexOf(val!.placeholder);
    final replacementText = rawContent == null
      ? ''
      : quoteAndReply(store, message: message, rawContent: rawContent);
    if (startIndex >= 0) {
      value = value.replaced(
        TextRange(start: startIndex, end: startIndex + val.placeholder.length),
        replacementText,
      );
    } else if (replacementText != '') { // insertPadded requires non-empty string
      insertPadded(replacementText);
    }
    _quoteAndReplies.remove(tag);
    notifyListeners(); // _quoteAndReplies change could affect validationErrors
  }

  /// Tells the controller that a file upload has started.
  ///
  /// Returns an int "tag" that should be passed to registerUploadEnd on the
  /// upload's success or failure.
  int registerUploadStart(String filename, ZulipLocalizations zulipLocalizations) {
    final tag = _nextUploadTag;
    _nextUploadTag += 1;
    final linkText = zulipLocalizations.composeBoxUploadingFilename(filename);
    final placeholder = inlineLink(linkText, null);
    _uploads[tag] = (filename: filename, placeholder: placeholder);
    notifyListeners(); // _uploads change could affect validationErrors
    value = value.replaced(insertionIndex(), '$placeholder\n\n');
    return tag;
  }

  /// Tells the controller that a file upload has ended, with success or error.
  ///
  /// To indicate success, pass the URL to be used for the Markdown link.
  /// If `url` is null, failure is assumed.
  void registerUploadEnd(int tag, Uri? url) {
    final val = _uploads[tag];
    assert(val != null, 'registerUploadEnd called twice for same tag');
    final (:filename, :placeholder) = val!;
    final int startIndex = text.indexOf(placeholder);
    final replacementRange = startIndex >= 0
      ? TextRange(start: startIndex, end: startIndex + placeholder.length)
      : insertionIndex();

    value = value.replaced(
      replacementRange,
      url == null ? '' : inlineLink(filename, url));
    _uploads.remove(tag);
    notifyListeners(); // _uploads change could affect validationErrors
  }

  @override
  String _computeTextNormalized() {
    return text.trim();
  }

  @override
  List<ContentValidationError> _computeValidationErrors() {
    return [
      if (textNormalized.isEmpty)
        ContentValidationError.empty,

      // normalized.length is the number of UTF-16 code units, while the server
      // API expresses the max in Unicode code points. So this comparison will
      // be conservative and may cut the user off shorter than necessary.
      if (textNormalized.length > kMaxMessageLengthCodePoints)
        ContentValidationError.tooLong,

      if (_quoteAndReplies.isNotEmpty)
        ContentValidationError.quoteAndReplyInProgress,

      if (_uploads.isNotEmpty)
        ContentValidationError.uploadInProgress,
    ];
  }
}

class _ContentInput extends StatefulWidget {
  const _ContentInput({
    required this.narrow,
    required this.destination,
    required this.controller,
    required this.hintText,
  });

  final Narrow narrow;
  final SendableNarrow destination;
  final ComposeBoxController controller;
  final String hintText;

  @override
  State<_ContentInput> createState() => _ContentInputState();
}

class _ContentInputState extends State<_ContentInput> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller.content.addListener(_contentChanged);
    widget.controller.contentFocusNode.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _ContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.content.removeListener(_contentChanged);
      widget.controller.content.addListener(_contentChanged);
      oldWidget.controller.contentFocusNode.removeListener(_focusChanged);
      widget.controller.contentFocusNode.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.content.removeListener(_contentChanged);
    widget.controller.contentFocusNode.removeListener(_focusChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _contentChanged() {
    final store = PerAccountStoreWidget.of(context);
    (widget.controller.content.text.isEmpty)
      ? store.typingNotifier.stoppedComposing()
      : store.typingNotifier.keystroke(widget.destination);
  }

  void _focusChanged() {
    if (widget.controller.contentFocusNode.hasFocus) {
      // Content input getting focus doesn't necessarily mean that
      // the user started typing, so do nothing.
      return;
    }
    final store = PerAccountStoreWidget.of(context);
    store.typingNotifier.stoppedComposing();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Transition to either [hidden] or [paused] signals that
        // > [the] application is not currently visible to the user, and not
        // > responding to user input.
        //
        // When transitioning to [detached], the compose box can't exist:
        // > The application defaults to this state before it initializes, and
        // > can be in this state (applicable on Android, iOS, and web) after
        // > all views have been detached.
        //
        // For all these states, we can conclude that the user is not
        // composing a message.
        final store = PerAccountStoreWidget.of(context);
        store.typingNotifier.stoppedComposing();
      case AppLifecycleState.inactive:
        // > At least one view of the application is visible, but none have
        // > input focus. The application is otherwise running normally.
        // For example, we expect this state when the user is selecting a file
        // to upload.
      case AppLifecycleState.resumed:
    }
  }

  static double maxHeight(BuildContext context) {
    final clampingTextScaler = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: 1.5);
    final scaledLineHeight = clampingTextScaler.scale(_fontSize) * _lineHeightRatio;

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
      narrow: widget.narrow,
      controller: widget.controller.content,
      focusNode: widget.controller.contentFocusNode,
      fieldViewBuilder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight(context)),
        // This [ClipRect] replaces the [TextField] clipping we disable below.
        child: ClipRect(
          child: InsetShadowBox(
            top: _verticalPadding, bottom: _verticalPadding,
            color: designVariables.composeBoxBg,
            child: TextField(
              controller: widget.controller.content,
              focusNode: widget.controller.contentFocusNode,
              // Let the content show through the `contentPadding` so that
              // our [InsetShadowBox] can fade it smoothly there.
              clipBehavior: Clip.none,
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeightRatio,
                color: designVariables.textInput),
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
                contentPadding: const EdgeInsets.symmetric(vertical: _verticalPadding),
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: designVariables.textInput.withFadedAlpha(0.5))))))));
  }
}

/// The content input for _StreamComposeBox.
class _StreamContentInput extends StatefulWidget {
  const _StreamContentInput({required this.narrow, required this.controller});

  final ChannelNarrow narrow;
  final StreamComposeBoxController controller;

  @override
  State<_StreamContentInput> createState() => _StreamContentInputState();
}

class _StreamContentInputState extends State<_StreamContentInput> {
  late String _topicTextNormalized;

  void _topicChanged() {
    setState(() {
      _topicTextNormalized = widget.controller.topic.textNormalized;
    });
  }

  @override
  void initState() {
    super.initState();
    _topicTextNormalized = widget.controller.topic.textNormalized;
    widget.controller.topic.addListener(_topicChanged);
  }

  @override
  void didUpdateWidget(covariant _StreamContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.topic != oldWidget.controller.topic) {
      oldWidget.controller.topic.removeListener(_topicChanged);
      widget.controller.topic.addListener(_topicChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.topic.removeListener(_topicChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final streamName = store.streams[widget.narrow.streamId]?.name
      ?? zulipLocalizations.composeBoxUnknownChannelName;
    return _ContentInput(
      narrow: widget.narrow,
      destination: TopicNarrow(widget.narrow.streamId, TopicName(_topicTextNormalized)),
      controller: widget.controller,
      hintText: zulipLocalizations.composeBoxChannelContentHint(streamName, _topicTextNormalized));
  }
}

class _TopicInput extends StatelessWidget {
  const _TopicInput({required this.streamId, required this.controller});

  final int streamId;
  final StreamComposeBoxController controller;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    TextStyle topicTextStyle = TextStyle(
      fontSize: 20,
      height: 22 / 20,
      color: designVariables.textInput.withFadedAlpha(0.9),
    ).merge(weightVariableTextStyle(context, wght: 600));

    return TopicAutocomplete(
      streamId: streamId,
      controller: controller.topic,
      focusNode: controller.topicFocusNode,
      contentFocusNode: controller.contentFocusNode,
      fieldViewBuilder: (context) => Container(
        padding: const EdgeInsets.only(top: 10, bottom: 9),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(
          width: 1,
          color: designVariables.foreground.withFadedAlpha(0.2)))),
        child: TextField(
          controller: controller.topic,
          focusNode: controller.topicFocusNode,
          textInputAction: TextInputAction.next,
          style: topicTextStyle,
          decoration: InputDecoration(
            hintText: zulipLocalizations.composeBoxTopicHintText,
            hintStyle: topicTextStyle.copyWith(
              color: designVariables.textInput.withFadedAlpha(0.5))))));
  }
}

class _FixedDestinationContentInput extends StatelessWidget {
  const _FixedDestinationContentInput({
    required this.narrow,
    required this.controller,
  });

  final SendableNarrow narrow;
  final FixedDestinationComposeBoxController controller;

  String _hintText(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (narrow) {
      case TopicNarrow(:final streamId, :final topic):
        final store = PerAccountStoreWidget.of(context);
        final streamName = store.streams[streamId]?.name
          ?? zulipLocalizations.composeBoxUnknownChannelName;
        return zulipLocalizations.composeBoxChannelContentHint(
          streamName, topic.displayName);

      case DmNarrow(otherRecipientIds: []): // The self-1:1 thread.
        return zulipLocalizations.composeBoxSelfDmContentHint;

      case DmNarrow(otherRecipientIds: [final otherUserId]):
        final store = PerAccountStoreWidget.of(context);
        final fullName = store.users[otherUserId]?.fullName;
        if (fullName == null) return zulipLocalizations.composeBoxGenericContentHint;
        return zulipLocalizations.composeBoxDmContentHint(fullName);

      case DmNarrow(): // A group DM thread.
        return zulipLocalizations.composeBoxGroupDmContentHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ContentInput(
      narrow: narrow,
      destination: narrow,
      controller: controller,
      hintText: _hintText(context));
  }
}

/// Data on a file to be uploaded, from any source.
///
/// A convenience class to represent data from the generic file picker,
/// the media library, and the camera, in a single form.
class _File {
  _File({
    required this.content,
    required this.length,
    required this.filename,
    required this.mimeType,
  });

  final Stream<List<int>> content;
  final int length;
  final String filename;
  final String? mimeType;
}

Future<void> _uploadFiles({
  required BuildContext context,
  required ComposeContentController contentController,
  required FocusNode contentFocusNode,
  required Iterable<_File> files,
}) async {
  assert(context.mounted);
  final store = PerAccountStoreWidget.of(context);
  final zulipLocalizations = ZulipLocalizations.of(context);

  final List<_File> tooLargeFiles = [];
  final List<_File> rightSizeFiles = [];
  for (final file in files) {
    if ((file.length / (1 << 20)) > store.maxFileUploadSizeMib) {
      tooLargeFiles.add(file);
    } else {
      rightSizeFiles.add(file);
    }
  }

  if (tooLargeFiles.isNotEmpty) {
    final listMessage = tooLargeFiles
      .map((file) => '${file.filename}: ${(file.length / (1 << 20)).toStringAsFixed(1)} MiB')
      .join('\n');
    showErrorDialog(
      context: context,
      title: zulipLocalizations.errorFilesTooLargeTitle(tooLargeFiles.length),
      message: zulipLocalizations.errorFilesTooLarge(
        tooLargeFiles.length,
        store.maxFileUploadSizeMib,
        listMessage));
  }

  final List<(int, _File)> uploadsInProgress = [];
  for (final file in rightSizeFiles) {
    final tag = contentController.registerUploadStart(file.filename,
      zulipLocalizations);
    uploadsInProgress.add((tag, file));
  }
  if (!contentFocusNode.hasFocus) {
    contentFocusNode.requestFocus();
  }

  for (final (tag, file) in uploadsInProgress) {
    final _File(:content, :length, :filename, :mimeType) = file;
    Uri? url;
    try {
      final result = await uploadFile(store.connection,
        content: content,
        length: length,
        filename: filename,
        contentType: mimeType,
      );
      url = Uri.parse(result.uri);
    } catch (e) {
      if (!context.mounted) return;
      // TODO(#741): Specifically handle `413 Payload Too Large`
      // TODO(#741): On API errors, quote `msg` from server, with "The server said:"
      showErrorDialog(context: context,
        title: zulipLocalizations.errorFailedToUploadFileTitle(filename),
        message: e.toString());
    } finally {
      contentController.registerUploadEnd(tag, url);
    }
  }
}

abstract class _AttachUploadsButton extends StatelessWidget {
  const _AttachUploadsButton({required this.controller});

  final ComposeBoxController controller;

  IconData get icon;
  String tooltip(ZulipLocalizations zulipLocalizations);

  /// Request files from the user, in the way specific to this upload type.
  ///
  /// Subclasses should manage the interaction completely, e.g., by catching and
  /// handling any permissions-related exceptions.
  ///
  /// To signal exiting the interaction with no files chosen,
  /// return an empty [Iterable] after showing user feedback as appropriate.
  Future<Iterable<_File>> getFiles(BuildContext context);

  void _handlePress(BuildContext context) async {
    final files = await getFiles(context);
    if (files.isEmpty) {
      return; // Nothing to do (getFiles handles user feedback)
    }

    // https://github.com/dart-lang/linter/issues/4007
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    await _uploadFiles(
      context: context,
      contentController: controller.content,
      contentFocusNode: controller.contentFocusNode,
      files: files);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return SizedBox(
      width: _composeButtonSize,
      child: IconButton(
        icon: Icon(icon, color: designVariables.foreground.withFadedAlpha(0.5)),
        tooltip: tooltip(zulipLocalizations),
        onPressed: () => _handlePress(context)));
  }
}

Future<Iterable<_File>> _getFilePickerFiles(BuildContext context, FileType type) async {
  FilePickerResult? result;
  try {
    result = await ZulipBinding.instance
      .pickFiles(allowMultiple: true, withReadStream: true, type: type);
  } catch (e) {
    if (!context.mounted) return [];
    final zulipLocalizations = ZulipLocalizations.of(context);
    if (e is PlatformException && e.code == 'read_external_storage_denied') {
      // Observed on Android. If Android's error message tells us whether the
      // user has checked "Don't ask again", it seems the library doesn't pass
      // that on to us. So just always prompt to check permissions in settings.
      // If the user hasn't checked "Don't ask again", they can always dismiss
      // our prompt and retry, and the permissions request will reappear,
      // letting them grant permissions and complete the upload.
      showSuggestedActionDialog(context: context,
        title: zulipLocalizations.permissionsNeededTitle,
        message: zulipLocalizations.permissionsDeniedReadExternalStorage,
        actionButtonText: zulipLocalizations.permissionsNeededOpenSettings,
        onActionButtonPress: () {
          AppSettings.openAppSettings();
        });
    } else {
      showErrorDialog(context: context,
        title: zulipLocalizations.errorDialogTitle,
        message: e.toString());
    }
    return [];
  }
  if (result == null) {
    return []; // User cancelled; do nothing
  }

  return result.files.map((f) {
    assert(f.readStream != null);  // We passed `withReadStream: true` to pickFiles.
    final mimeType = lookupMimeType(
      // Seems like the path shouldn't be required; we still want to look for
      // matches on `headerBytes`. Thankfully we can still do that, by calling
      // lookupMimeType with the empty string as the path. That's a value that
      // doesn't map to any particular type, so the path will be effectively
      // ignored, as desired. Upstream comment:
      //   https://github.com/dart-lang/mime/issues/11#issuecomment-2246824452
      f.path ?? '',
      headerBytes: f.bytes?.take(defaultMagicNumbersMaxLength).toList(),
    );
    return _File(
      content: f.readStream!,
      length: f.size,
      filename: f.name,
      mimeType: mimeType,
    );
  });
}

class _AttachFileButton extends _AttachUploadsButton {
  const _AttachFileButton({required super.controller});

  @override
  IconData get icon => ZulipIcons.attach_file;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.composeBoxAttachFilesTooltip;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    return _getFilePickerFiles(context, FileType.any);
  }
}

class _AttachMediaButton extends _AttachUploadsButton {
  const _AttachMediaButton({required super.controller});

  @override
  IconData get icon => ZulipIcons.image;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.composeBoxAttachMediaTooltip;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    // TODO(#114): This doesn't give quite the right UI on Android.
    return _getFilePickerFiles(context, FileType.media);
  }
}

class _AttachFromCameraButton extends _AttachUploadsButton {
  const _AttachFromCameraButton({required super.controller});

  @override
  IconData get icon => ZulipIcons.camera;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
      zulipLocalizations.composeBoxAttachFromCameraTooltip;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final XFile? result;
    try {
      // Ideally we'd open a platform interface that lets you choose between
      // taking a photo and a video. `image_picker` doesn't yet have that
      // option: https://github.com/flutter/flutter/issues/89159
      // so just stick with images for now. We could add another button for
      // videos, but we don't want too many buttons.
      result = await ZulipBinding.instance.pickImage(
        source: ImageSource.camera, requestFullMetadata: false);
    } catch (e) {
      if (!context.mounted) return [];
      if (e is PlatformException && e.code == 'camera_access_denied') {
        // iOS has a quirk where it will only request the native
        // permission-request alert once, the first time the app wants to
        // use a protected resource. After that, the only way the user can
        // grant it is in Settings.
        showSuggestedActionDialog(context: context,
          title: zulipLocalizations.permissionsNeededTitle,
          message: zulipLocalizations.permissionsDeniedCameraAccess,
          actionButtonText: zulipLocalizations.permissionsNeededOpenSettings,
          onActionButtonPress: () {
            AppSettings.openAppSettings();
          });
      } else {
        showErrorDialog(context: context,
          title: zulipLocalizations.errorDialogTitle,
          message: e.toString());
      }
      return [];
    }
    if (result == null) {
      return []; // User cancelled; do nothing
    }
    final length = await result.length();

    List<int>? headerBytes;
    try {
      headerBytes = await result.openRead(
        0,
        // Despite its dartdoc, [XFile.openRead] can throw if `end` is greater
        // than the file's length. We can *probably* trust our `length` to be
        // accurate, but it's nontrivial to verify. If it's inaccurate, we'd
        // rather sacrifice this part of the MIME lookup than throw the whole
        // upload. So, the try/catch.
        min(defaultMagicNumbersMaxLength, length)
      ).expand((l) => l).toList();
    } catch (e) {
      // TODO(log)
    }
    return [_File(
      content: result.openRead(),
      length: length,
      filename: result.name,
      mimeType: result.mimeType
        ?? lookupMimeType(result.path, headerBytes: headerBytes),
    )];
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.controller, required this.getDestination});

  final ComposeBoxController controller;
  final MessageDestination Function() getDestination;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  void _hasErrorsChanged() {
    setState(() {
      // Update disabled/non-disabled state
    });
  }

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    if (controller is StreamComposeBoxController) {
      controller.topic.hasValidationErrors.addListener(_hasErrorsChanged);
    }
    controller.content.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void didUpdateWidget(covariant _SendButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = widget.controller;
    final oldController = oldWidget.controller;
    if (controller == oldController) return;

    if (oldController is StreamComposeBoxController) {
      oldController.topic.hasValidationErrors.removeListener(_hasErrorsChanged);
    }
    if (controller is StreamComposeBoxController) {
      controller.topic.hasValidationErrors.addListener(_hasErrorsChanged);
    }
    oldController.content.hasValidationErrors.removeListener(_hasErrorsChanged);
    controller.content.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void dispose() {
    final controller = widget.controller;
    if (controller is StreamComposeBoxController) {
      controller.topic.hasValidationErrors.removeListener(_hasErrorsChanged);
    }
    controller.content.hasValidationErrors.removeListener(_hasErrorsChanged);
    super.dispose();
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
      List<String> validationErrorMessages = [
        for (final error in (controller is StreamComposeBoxController
                              ? controller.topic.validationErrors
                              : const <TopicValidationError>[]))
          error.message(zulipLocalizations),
        for (final error in controller.content.validationErrors)
          error.message(zulipLocalizations),
      ];
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: validationErrorMessages.join('\n\n'));
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    final content = controller.content.textNormalized;

    controller.content.clear();
    // The following `stoppedComposing` call is currently redundant,
    // because clearing input sends a "typing stopped" notice.
    // It will be necessary once we resolve #720.
    store.typingNotifier.stoppedComposing();

    try {
      // TODO(#720) clear content input only on success response;
      //   while waiting, put input(s) and send button into a disabled
      //   "working on it" state (letting input text be selected for copying).
      await store.sendMessage(destination: widget.getDestination(), content: content);
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.message,
      };
      showErrorDialog(context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: message);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final iconColor = _hasValidationErrors
      ? designVariables.icon.withFadedAlpha(0.5)
      : designVariables.icon;

    return SizedBox(
      width: _composeButtonSize,
      child: IconButton(
        tooltip: zulipLocalizations.composeBoxSendTooltip,
        icon: Icon(ZulipIcons.send,
          // We set [Icon.color] instead of [IconButton.color] because the
          // latter implicitly uses colors derived from it to override the
          // ambient [ButtonStyle.overlayColor], where we set the color for
          // the highlight state to match the Figma design.
          color: iconColor),
        onPressed: _send));
  }
}

class _ComposeBoxContainer extends StatelessWidget {
  const _ComposeBoxContainer({
    required this.body,
    this.errorBanner,
  }) : assert(body != null || errorBanner != null);

  /// The text inputs, compose-button row, and send button.
  ///
  /// This widget does not need a [SafeArea] to consume any device insets.
  ///
  /// Can be null, but only if [errorBanner] is non-null.
  final Widget? body;

  /// An error bar that goes at the top.
  ///
  /// This may be present on its own or with a [body].
  /// If [body] is null this must be present.
  ///
  /// This widget should use a [SafeArea] to pad the left, right,
  /// and bottom device insets.
  /// (A bottom inset may occur if [body] is null.)
  final Widget? errorBanner;

  Widget _paddedBody() {
    assert(body != null);
    return SafeArea(minimum: const EdgeInsets.symmetric(horizontal: 8),
      child: body!);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final List<Widget> children = switch ((errorBanner, body)) {
      (Widget(), Widget()) => [
        // _paddedBody() already pads the bottom inset,
        // so make sure the error banner doesn't double-pad it.
        MediaQuery.removePadding(context: context, removeBottom: true,
          child: errorBanner!),
        _paddedBody(),
      ],
      (Widget(),     null) => [errorBanner!],
      (null,     Widget()) => [_paddedBody()],
      (null,         null) => throw UnimplementedError(), // not allowed, see dartdoc
    };

    // TODO(design): Maybe put a max width on the compose box, like we do on
    //   the message list itself
    return Container(width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: designVariables.borderBar))),
      // TODO(#720) try a Stack for the overlaid linear progress indicator
      child: Material(
        color: designVariables.composeBoxBg,
        child: Column(
          children: children)));
  }
}

/// The text inputs, compose-button row, and send button for the compose box.
abstract class _ComposeBoxBody extends StatelessWidget {
  /// The narrow on view in the message list.
  Narrow get narrow;

  ComposeBoxController get controller;

  Widget? buildTopicInput();
  Widget buildContentInput();
  Widget buildSendButton();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final designVariables = DesignVariables.of(context);

    final inputThemeData = themeData.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        // Both [contentPadding] and [isDense] combine to make the layout compact.
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none));

    // TODO(#417): Disable splash effects for all buttons globally.
    final iconButtonThemeData = IconButtonThemeData(
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        // TODO(#417): The Figma design specifies a different icon color on
        //   pressed, but `IconButton` currently does not have support for
        //   that.  See also:
        //     https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3707-41711&node-type=frame&t=sSYomsJzGCt34D8N-0
        highlightColor: designVariables.editorButtonPressedBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)))));

    final composeButtons = [
      _AttachFileButton(controller: controller),
      _AttachMediaButton(controller: controller),
      _AttachFromCameraButton(controller: controller),
    ];

    final topicInput = buildTopicInput();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Theme(
          data: inputThemeData,
          child: Column(children: [
            if (topicInput != null) topicInput,
            buildContentInput(),
          ]))),
      SizedBox(
        height: _composeButtonSize,
        child: IconButtonTheme(
          data: iconButtonThemeData,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: composeButtons),
              buildSendButton(),
            ]))),
    ]);
  }
}

/// A compose box for use in a channel narrow.
///
/// This offers a text input for the topic to send to,
/// in addition to a text input for the message content.
class _StreamComposeBoxBody extends _ComposeBoxBody {
  _StreamComposeBoxBody({required this.narrow, required this.controller});

  @override
  final ChannelNarrow narrow;

  @override
  final StreamComposeBoxController controller;

  @override Widget buildTopicInput() => _TopicInput(
    streamId: narrow.streamId,
    controller: controller,
  );

  @override Widget buildContentInput() => _StreamContentInput(
    narrow: narrow,
    controller: controller,
  );

  @override Widget buildSendButton() => _SendButton(
    controller: controller,
    getDestination: () => StreamDestination(
      narrow.streamId, TopicName(controller.topic.textNormalized)),
  );
}

class _FixedDestinationComposeBoxBody extends _ComposeBoxBody {
  _FixedDestinationComposeBoxBody({required this.narrow, required this.controller});

  @override
  final SendableNarrow narrow;

  @override
  final FixedDestinationComposeBoxController controller;

  @override Widget? buildTopicInput() => null;

  @override Widget buildContentInput() => _FixedDestinationContentInput(
    narrow: narrow,
    controller: controller,
  );

  @override Widget buildSendButton() => _SendButton(
    controller: controller,
    getDestination: () => narrow.destination,
  );
}

sealed class ComposeBoxController {
  final content = ComposeContentController();
  final contentFocusNode = FocusNode();

  @mustCallSuper
  void dispose() {
    content.dispose();
    contentFocusNode.dispose();
  }
}

class StreamComposeBoxController extends ComposeBoxController {
  final topic = ComposeTopicController();
  final topicFocusNode = FocusNode();

  @override
  void dispose() {
    topic.dispose();
    topicFocusNode.dispose();
    super.dispose();
  }
}

class FixedDestinationComposeBoxController extends ComposeBoxController {}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final labelTextStyle = TextStyle(
      fontSize: 17,
      height: 22 / 17,
      color: designVariables.btnLabelAttMediumIntDanger,
    ).merge(weightVariableTextStyle(context, wght: 600));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: designVariables.bannerBgIntDanger),
      child: SafeArea(
        minimum: const EdgeInsetsDirectional.only(start: 8)
          // (SafeArea.minimum doesn't take an EdgeInsetsDirectional)
          .resolve(Directionality.of(context)),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 0, 9),
                child: Text(style: labelTextStyle,
                  label))),
            const SizedBox(width: 8),
            // TODO(#720) "x" button goes here.
            //   24px square with 8px touchable padding in all directions?
          ])));
  }
}

class ComposeBox extends StatefulWidget {
  ComposeBox({super.key, required this.narrow})
    : assert(ComposeBox.hasComposeBox(narrow));

  final Narrow narrow;

  static bool hasComposeBox(Narrow narrow) {
    switch (narrow) {
      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return true;

      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return false;
    }
  }

  @override
  State<ComposeBox> createState() => _ComposeBoxState();
}

/// The interface for the state of a [ComposeBox].
abstract class ComposeBoxState extends State<ComposeBox> {
  ComposeBoxController get controller;
}

class _ComposeBoxState extends State<ComposeBox> implements ComposeBoxState {
  @override ComposeBoxController get controller => _controller;
  late final ComposeBoxController _controller;

  @override
  void initState() {
    super.initState();
    switch (widget.narrow) {
      case ChannelNarrow():
        _controller = StreamComposeBoxController();
      case TopicNarrow():
      case DmNarrow():
        _controller = FixedDestinationComposeBoxController();
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        assert(false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget? _errorBanner(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final selfUser = store.users[store.selfUserId]!;
    switch (widget.narrow) {
      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final channel = store.streams[streamId];
        if (channel == null || !store.hasPostingPermission(inChannel: channel,
            user: selfUser, byDate: DateTime.now())) {
          return _ErrorBanner(label:
            ZulipLocalizations.of(context).errorBannerCannotPostInChannelLabel);
        }
      case DmNarrow(:final otherRecipientIds):
        final hasDeactivatedUser = otherRecipientIds.any((id) =>
          !(store.users[id]?.isActive ?? true));
        if (hasDeactivatedUser) {
          return _ErrorBanner(label:
            ZulipLocalizations.of(context).errorBannerDeactivatedDmLabel);
        }
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget? body;

    final errorBanner = _errorBanner(context);
    if (errorBanner != null) {
      return _ComposeBoxContainer(body: null, errorBanner: errorBanner);
    }

    final narrow = widget.narrow;
    switch (_controller) {
      case StreamComposeBoxController(): {
        narrow as ChannelNarrow;
        body = _StreamComposeBoxBody(controller: _controller, narrow: narrow);
      }
      case FixedDestinationComposeBoxController(): {
        narrow as SendableNarrow;
        body = _FixedDestinationComposeBoxBody(controller: _controller, narrow: narrow);
      }
    }

    // TODO(#720) dismissable message-send error, maybe something like:
    //     if (controller.sendMessageError.value != null) {
    //       errorBanner = _ErrorBanner(label:
    //         ZulipLocalizations.of(context).errorSendMessageTimeout);
    //     }
    return _ComposeBoxContainer(body: body, errorBanner: null);
  }
}
