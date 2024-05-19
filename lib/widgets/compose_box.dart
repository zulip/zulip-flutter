import 'package:app_settings/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'autocomplete.dart';
import 'dialog.dart';
import 'store.dart';

const double _inputVerticalPadding = 8;
const double _sendButtonSize = 36;

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

class _ContentInput extends StatelessWidget {
  const _ContentInput({
    required this.narrow,
    required this.controller,
    required this.focusNode,
    required this.hintText,
  });

  final Narrow narrow;
  final ComposeContentController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: const InputDecoration(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _sendButtonSize - 2 * _inputVerticalPadding,

          // TODO constrain this adaptively (i.e. not hard-coded 200)
          maxHeight: 200,
        ),
        child: ComposeAutocomplete(
          narrow: narrow,
          controller: controller,
          focusNode: focusNode,
          fieldViewBuilder: (context) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration.collapsed(hintText: hintText),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            );
          }),
        ));
  }
}

/// The content input for _StreamComposeBox.
class _StreamContentInput extends StatefulWidget {
  const _StreamContentInput({
    required this.narrow,
    required this.controller,
    required this.topicController,
    required this.focusNode,
  });

  final StreamNarrow narrow;
  final ComposeContentController controller;
  final ComposeTopicController topicController;
  final FocusNode focusNode;

  @override
  State<_StreamContentInput> createState() => _StreamContentInputState();
}

class _StreamContentInputState extends State<_StreamContentInput> {
  late String _topicTextNormalized;

  _topicChanged() {
    setState(() {
      _topicTextNormalized = widget.topicController.textNormalized;
    });
  }

  @override
  void initState() {
    super.initState();
    _topicTextNormalized = widget.topicController.textNormalized;
    widget.topicController.addListener(_topicChanged);
  }

  @override
  void didUpdateWidget(covariant _StreamContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topicController != oldWidget.topicController) {
      oldWidget.topicController.removeListener(_topicChanged);
      widget.topicController.addListener(_topicChanged);
    }
  }

  @override
  void dispose() {
    widget.topicController.removeListener(_topicChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final streamName = store.streams[widget.narrow.streamId]?.name
      ?? zulipLocalizations.composeBoxUnknownStreamName;
    return _ContentInput(
      narrow: widget.narrow,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: zulipLocalizations.composeBoxStreamContentHint(streamName, _topicTextNormalized));
  }
}

class _FixedDestinationContentInput extends StatelessWidget {
  const _FixedDestinationContentInput({
    required this.narrow,
    required this.controller,
    required this.focusNode,
  });

  final SendableNarrow narrow;
  final ComposeContentController controller;
  final FocusNode focusNode;

  String _hintText(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (narrow) {
      case TopicNarrow(:final streamId, :final topic):
        final store = PerAccountStoreWidget.of(context);
        final streamName = store.streams[streamId]?.name
          ?? zulipLocalizations.composeBoxUnknownStreamName;
        return zulipLocalizations.composeBoxStreamContentHint(streamName, topic);

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
      controller: controller,
      focusNode: focusNode,
      hintText: _hintText(context));
  }
}

/// Data on a file to be uploaded, from any source.
///
/// A convenience class to represent data from the generic file picker,
/// the media library, and the camera, in a single form.
class _File {
  _File({required this.content, required this.length, required this.filename});

  final Stream<List<int>> content;
  final int length;
  final String filename;
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
    final _File(:content, :length, :filename) = file;
    Uri? url;
    try {
      final result = await uploadFile(store.connection,
        content: content, length: length, filename: filename);
      url = Uri.parse(result.uri);
    } catch (e) {
      if (!context.mounted) return;
      // TODO(#37): Specifically handle `413 Payload Too Large`
      // TODO(#37): On API errors, quote `msg` from server, with "The server said:"
      showErrorDialog(context: context,
        title: zulipLocalizations.errorFailedToUploadFileTitle(filename),
        message: e.toString());
    } finally {
      contentController.registerUploadEnd(tag, url);
    }
  }
}

abstract class _AttachUploadsButton extends StatelessWidget {
  const _AttachUploadsButton({required this.contentController, required this.contentFocusNode});

  final ComposeContentController contentController;
  final FocusNode contentFocusNode;

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
      contentController: contentController,
      contentFocusNode: contentFocusNode,
      files: files);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip(zulipLocalizations),
      onPressed: () => _handlePress(context));
  }
}

Future<Iterable<_File>> _getFilePickerFiles(BuildContext context, FileType type) async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform
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
    return _File(content: f.readStream!, length: f.size, filename: f.name);
  });
}

class _AttachFileButton extends _AttachUploadsButton {
  const _AttachFileButton({required super.contentController, required super.contentFocusNode});

  @override
  IconData get icon => Icons.attach_file;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.composeBoxAttachFilesTooltip;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    return _getFilePickerFiles(context, FileType.any);
  }
}

class _AttachMediaButton extends _AttachUploadsButton {
  const _AttachMediaButton({required super.contentController, required super.contentFocusNode});

  @override
  IconData get icon => Icons.image;

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
  const _AttachFromCameraButton({required super.contentController, required super.contentFocusNode});

  @override
  IconData get icon => Icons.camera_alt;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
      zulipLocalizations.composeBoxAttachFromCameraTooltip;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final picker = ImagePicker();
    final XFile? result;
    try {
      // Ideally we'd open a platform interface that lets you choose between
      // taking a photo and a video. `image_picker` doesn't yet have that
      // option: https://github.com/flutter/flutter/issues/89159
      // so just stick with images for now. We could add another button for
      // videos, but we don't want too many buttons.
      result = await picker.pickImage(source: ImageSource.camera, requestFullMetadata: false);
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

    return [_File(content: result.openRead(), length: length, filename: result.name)];
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.topicController,
    required this.contentController,
    required this.getDestination,
  });

  final ComposeTopicController? topicController;
  final ComposeContentController contentController;
  final MessageDestination Function() getDestination;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  _hasErrorsChanged() {
    setState(() {
      // Update disabled/non-disabled state
    });
  }

  @override
  void initState() {
    super.initState();
    widget.topicController?.hasValidationErrors.addListener(_hasErrorsChanged);
    widget.contentController.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void didUpdateWidget(covariant _SendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topicController != oldWidget.topicController) {
      oldWidget.topicController?.hasValidationErrors.removeListener(_hasErrorsChanged);
      widget.topicController?.hasValidationErrors.addListener(_hasErrorsChanged);
    }
    if (widget.contentController != oldWidget.contentController) {
      oldWidget.contentController.hasValidationErrors.removeListener(_hasErrorsChanged);
      widget.contentController.hasValidationErrors.addListener(_hasErrorsChanged);
    }
  }

  @override
  void dispose() {
    widget.topicController?.hasValidationErrors.removeListener(_hasErrorsChanged);
    widget.contentController.hasValidationErrors.removeListener(_hasErrorsChanged);
    super.dispose();
  }

  bool get _hasValidationErrors {
    return (widget.topicController?.hasValidationErrors.value ?? false)
      || widget.contentController.hasValidationErrors.value;
  }

  void _send() {
    if (_hasValidationErrors) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      List<String> validationErrorMessages = [
        for (final error in widget.topicController?.validationErrors ?? const [])
          error.message(zulipLocalizations),
        for (final error in widget.contentController.validationErrors)
          error.message(zulipLocalizations),
      ];
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorMessageNotSent,
        message: validationErrorMessages.join('\n\n'));
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    final content = widget.contentController.textNormalized;
    store.sendMessage(destination: widget.getDestination(), content: content);

    widget.contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _hasValidationErrors;
    final colorScheme = Theme.of(context).colorScheme;
    final zulipLocalizations = ZulipLocalizations.of(context);

    // Copy FilledButton defaults (_FilledButtonDefaultsM3.backgroundColor)
    final backgroundColor = disabled
      ? colorScheme.onSurface.withOpacity(0.12)
      : colorScheme.primary;

    // Copy FilledButton defaults (_FilledButtonDefaultsM3.foregroundColor)
    final foregroundColor = disabled
      ? colorScheme.onSurface.withOpacity(0.38)
      : colorScheme.onPrimary;

    return Ink(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: backgroundColor,
      ),
      child: IconButton(
        tooltip: zulipLocalizations.composeBoxSendTooltip,
        style: const ButtonStyle(
          // Match the height of the content input.
          minimumSize: WidgetStatePropertyAll(Size.square(_sendButtonSize)),
          // With the default of [MaterialTapTargetSize.padded], not just the
          // tap target but the visual button would get padded to 48px square.
          // It would be nice if the tap target extended invisibly out from the
          // button, to make a 48px square, but that's not the behavior we get.
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        color: foregroundColor,
        icon: const Icon(Icons.send),
        onPressed: _send));
  }
}

class _ComposeBoxLayout extends StatelessWidget {
  const _ComposeBoxLayout({
    required this.topicInput,
    required this.contentInput,
    required this.sendButton,
    required this.contentController,
    required this.contentFocusNode,
  });

  final Widget? topicInput;
  final Widget contentInput;
  final Widget sendButton;
  final ComposeContentController contentController;
  final FocusNode contentFocusNode;

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ColorScheme colorScheme = themeData.colorScheme;

    final inputThemeData = themeData.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        // Both [contentPadding] and [isDense] combine to make the layout compact.
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0, vertical: _inputVerticalPadding),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          borderSide: BorderSide.none),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Theme(
                  data: inputThemeData,
                  child: Column(children: [
                    if (topicInput != null) topicInput!,
                    if (topicInput != null) const SizedBox(height: 8),
                    contentInput,
                  ]))),
              const SizedBox(width: 8),
              sendButton,
            ]),
            Theme(
              data: themeData.copyWith(
                iconTheme: themeData.iconTheme.copyWith(color: colorScheme.onSurfaceVariant)),
              child: Row(children: [
                _AttachFileButton(contentController: contentController, contentFocusNode: contentFocusNode),
                _AttachMediaButton(contentController: contentController, contentFocusNode: contentFocusNode),
                _AttachFromCameraButton(contentController: contentController, contentFocusNode: contentFocusNode),
              ])),
          ]))));  }
}

abstract class ComposeBoxController<T extends StatefulWidget> extends State<T> {
  ComposeTopicController? get topicController;
  ComposeContentController get contentController;
  FocusNode get contentFocusNode;
}

/// A compose box for use in a stream narrow.
///
/// This offers a text input for the topic to send to,
/// in addition to a text input for the message content.
class _StreamComposeBox extends StatefulWidget {
  const _StreamComposeBox({super.key, required this.narrow});

  /// The narrow on view in the message list.
  final StreamNarrow narrow;

  @override
  State<_StreamComposeBox> createState() => _StreamComposeBoxState();
}

class _StreamComposeBoxState extends State<_StreamComposeBox> implements ComposeBoxController<_StreamComposeBox> {
  @override ComposeTopicController get topicController => _topicController;
  final _topicController = ComposeTopicController();

  @override ComposeContentController get contentController => _contentController;
  final _contentController = ComposeContentController();

  @override FocusNode get contentFocusNode => _contentFocusNode;
  final _contentFocusNode = FocusNode();

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final zulipLocalizations = ZulipLocalizations.of(context);

    return _ComposeBoxLayout(
      contentController: _contentController,
      contentFocusNode: _contentFocusNode,
      topicInput: TextField(
        controller: _topicController,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(hintText: zulipLocalizations.composeBoxTopicHintText),
      ),
      contentInput: _StreamContentInput(
        narrow: widget.narrow,
        topicController: _topicController,
        controller: _contentController,
        focusNode: _contentFocusNode,
      ),
      sendButton: _SendButton(
        topicController: _topicController,
        contentController: _contentController,
        getDestination: () => StreamDestination(
          widget.narrow.streamId, _topicController.textNormalized),
      ));
  }
}

class _FixedDestinationComposeBox extends StatefulWidget {
  const _FixedDestinationComposeBox({super.key, required this.narrow});

  final SendableNarrow narrow;

  @override
  State<_FixedDestinationComposeBox> createState() => _FixedDestinationComposeBoxState();
}

class _FixedDestinationComposeBoxState extends State<_FixedDestinationComposeBox> implements ComposeBoxController<_FixedDestinationComposeBox>  {
  @override ComposeTopicController? get topicController => null;

  @override ComposeContentController get contentController => _contentController;
  final _contentController = ComposeContentController();

  @override FocusNode get contentFocusNode => _contentFocusNode;
  final _contentFocusNode = FocusNode();

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ComposeBoxLayout(
      contentController: _contentController,
      contentFocusNode: _contentFocusNode,
      topicInput: null,
      contentInput: _FixedDestinationContentInput(
        narrow: widget.narrow,
        controller: _contentController,
        focusNode: _contentFocusNode,
      ),
      sendButton: _SendButton(
        topicController: null,
        contentController: _contentController,
        getDestination: () => widget.narrow.destination,
      ));
  }
}

class ComposeBox extends StatelessWidget {
  const ComposeBox({super.key, this.controllerKey, required this.narrow});

  final GlobalKey<ComposeBoxController>? controllerKey;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final narrow = this.narrow;
    if (narrow is StreamNarrow) {
      return _StreamComposeBox(key: controllerKey, narrow: narrow);
    } else if (narrow is TopicNarrow) {
      return _FixedDestinationComposeBox(key: controllerKey, narrow: narrow);
    } else if (narrow is DmNarrow) {
      return _FixedDestinationComposeBox(key: controllerKey, narrow: narrow);
    } else if (narrow is CombinedFeedNarrow) {
      return const SizedBox.shrink();
    } else {
      throw Exception("impossible narrow"); // TODO(dart-3): show this statically
    }
  }
}
