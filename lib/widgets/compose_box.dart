import 'package:app_settings/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api/route/messages.dart';
import '../model/autocomplete.dart';
import '../model/narrow.dart';
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

  String message() {
    switch (this) {
      case tooLong:
        return "Topic length shouldn't be greater than 60 characters.";
      case mandatoryButEmpty:
        return 'Topics are required in this organization.';
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
  uploadInProgress;

  // Later: quote-and-reply in progress

  String message() {
    switch (this) {
      case ContentValidationError.tooLong:
        return "Message length shouldn't be greater than 10000 characters.";
      case ContentValidationError.empty:
        return 'You have nothing to send!';
      case ContentValidationError.uploadInProgress:
        return 'Please wait for the upload to complete.';
    }
  }
}

class ComposeContentController extends ComposeController<ContentValidationError> {
  ComposeContentController() {
    _update();
  }

  int _nextUploadTag = 0;

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
  TextRange _insertionIndex() {
    final TextRange selection = value.selection;
    final String text = value.text;
    return selection.isValid
      ? (selection.isCollapsed
        ? selection
        : TextRange.collapsed(selection.end))
      : TextRange.collapsed(text.length);
  }

  /// Tells the controller that a file upload has started.
  ///
  /// Returns an int "tag" that should be passed to registerUploadEnd on the
  /// upload's success or failure.
  int registerUploadStart(String filename) {
    final tag = _nextUploadTag;
    _nextUploadTag += 1;
    final placeholder = '[Uploading $filename...]()'; // TODO(i18n)
    _uploads[tag] = (filename: filename, placeholder: placeholder);
    notifyListeners(); // _uploads change could affect validationErrors
    value = value.replaced(_insertionIndex(), '$placeholder\n\n');
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
      : _insertionIndex();

    value = value.replaced(
      replacementRange,
      url == null
        ? '[Failed to upload file: $filename]()' // TODO(i18n)
        : '[$filename](${url.toString()})');
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

      if (_uploads.isNotEmpty)
        ContentValidationError.uploadInProgress,
    ];
  }
}

class _ContentInput extends StatefulWidget {
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
  State<_ContentInput> createState() => _ContentInputState();
}

class _ContentInputState extends State<_ContentInput> {
  MentionAutocompleteView? _mentionAutocompleteView; // TODO different autocomplete view types

  _changed() {
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
  void didUpdateWidget(covariant _ContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

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
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration.collapsed(hintText: widget.hintText),
          maxLines: null,
        )));
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
    final streamName = store.streams[widget.narrow.streamId]?.name ?? '(unknown stream)';
    return _ContentInput(
      narrow: widget.narrow,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: "Message #$streamName > $_topicTextNormalized");
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
    showErrorDialog( // TODO(i18n)
      context: context,
      title: 'File(s) too large',
      message:
        '${tooLargeFiles.length} file(s) are larger than the server\'s limit'
        ' of ${store.maxFileUploadSizeMib} MiB and will not be uploaded:'
        '\n\n$listMessage');
  }

  final List<(int, _File)> uploadsInProgress = [];
  for (final file in rightSizeFiles) {
    final tag = contentController.registerUploadStart(file.filename);
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
        title: 'Failed to upload file: $filename', message: e.toString());
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
  String get tooltip;

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
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => _handlePress(context));
  }
}

Future<Iterable<_File>> _getFilePickerFiles(BuildContext context, FileType type) async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform
      .pickFiles(allowMultiple: true, withReadStream: true, type: type);
  } catch (e) {
    if (e is PlatformException && e.code == 'read_external_storage_denied') {
      // Observed on Android. If Android's error message tells us whether the
      // user has checked "Don't ask again", it seems the library doesn't pass
      // that on to us. So just always prompt to check permissions in settings.
      // If the user hasn't checked "Don't ask again", they can always dismiss
      // our prompt and retry, and the permissions request will reappear,
      // letting them grant permissions and complete the upload.
      showSuggestedActionDialog(context: context, // TODO(i18n)
        title: 'Permissions needed',
        message: 'To upload files, please grant Zulip additional permissions in Settings.',
        actionButtonText: 'Open settings',
        onActionButtonPress: () {
          AppSettings.openAppSettings();
        });
    } else {
      // TODO(i18n)
      showErrorDialog(context: context, title: 'Error', message: e.toString());
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
  String get tooltip => 'Attach files';

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
  String get tooltip => 'Attach images or videos';

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
  String get tooltip => 'Take a photo';

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
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
      if (e is PlatformException && e.code == 'camera_access_denied') {
        // iOS has a quirk where it will only request the native
        // permission-request alert once, the first time the app wants to
        // use a protected resource. After that, the only way the user can
        // grant it is in Settings.
        showSuggestedActionDialog(context: context, // TODO(i18n)
          title: 'Permissions needed',
          message: 'To upload an image, please grant Zulip additional permissions in Settings.',
          actionButtonText: 'Open settings',
          onActionButtonPress: () {
            AppSettings.openAppSettings();
          });
      } else {
        // TODO(i18n)
        showErrorDialog(context: context, title: 'Error', message: e.toString());
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

/// The send button for _StreamComposeBox.
class _StreamSendButton extends StatefulWidget {
  const _StreamSendButton({
    required this.narrow,
    required this.topicController,
    required this.contentController,
  });

  final StreamNarrow narrow;
  final ComposeTopicController topicController;
  final ComposeContentController contentController;

  @override
  State<_StreamSendButton> createState() => _StreamSendButtonState();
}

class _StreamSendButtonState extends State<_StreamSendButton> {
  _hasErrorsChanged() {
    setState(() {
      // Update disabled/non-disabled state
    });
  }

  @override
  void initState() {
    super.initState();
    widget.topicController.hasValidationErrors.addListener(_hasErrorsChanged);
    widget.contentController.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void didUpdateWidget(covariant _StreamSendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topicController != oldWidget.topicController) {
      oldWidget.topicController.hasValidationErrors.removeListener(_hasErrorsChanged);
      widget.topicController.hasValidationErrors.addListener(_hasErrorsChanged);
    }
    if (widget.contentController != oldWidget.contentController) {
      oldWidget.contentController.hasValidationErrors.removeListener(_hasErrorsChanged);
      widget.contentController.hasValidationErrors.addListener(_hasErrorsChanged);
    }
  }

  @override
  void dispose() {
    widget.topicController.hasValidationErrors.removeListener(_hasErrorsChanged);
    widget.contentController.hasValidationErrors.removeListener(_hasErrorsChanged);
    super.dispose();
  }

  bool get _hasValidationErrors {
    return widget.topicController.hasValidationErrors.value
      || widget.contentController.hasValidationErrors.value;
  }

  void _send() {
    if (_hasValidationErrors) {
      List<String> validationErrorMessages = [
        for (final error in widget.topicController.validationErrors)
          error.message(),
        for (final error in widget.contentController.validationErrors)
          error.message(),
      ];
      showErrorDialog(
        context: context,
        title: 'Message not sent',
        message: validationErrorMessages.join('\n\n'));
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    final destination = StreamDestination(
      widget.narrow.streamId, widget.topicController.textNormalized);
    final content = widget.contentController.textNormalized;
    store.sendMessage(destination: destination, content: content);

    widget.contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _hasValidationErrors;
    final colorScheme = Theme.of(context).colorScheme;

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
        tooltip: 'Send',

        // Match the height of the content input. Zeroing the padding lets the
        // constraints take over.
        constraints: const BoxConstraints(minWidth: _sendButtonSize, minHeight: _sendButtonSize),
        padding: const EdgeInsets.all(0),

        color: foregroundColor,
        icon: const Icon(Icons.send),
        onPressed: _send));
  }
}

/// A compose box for use in a stream narrow.
///
/// This offers a text input for the topic to send to,
/// in addition to a text input for the message content.
class _StreamComposeBox extends StatefulWidget {
  const _StreamComposeBox({required this.narrow});

  /// The narrow on view in the message list.
  final StreamNarrow narrow;

  @override
  State<_StreamComposeBox> createState() => _StreamComposeBoxState();
}

class _StreamComposeBoxState extends State<_StreamComposeBox> {
  final _topicController = ComposeTopicController();
  final _contentController = ComposeContentController();
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

    final topicInput = TextField(
      controller: _topicController,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: const InputDecoration(hintText: 'Topic'),
    );

    return Material(
      color: colorScheme.surfaceVariant,
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
                    topicInput,
                    const SizedBox(height: 8),
                    _StreamContentInput(
                      narrow: widget.narrow,
                      topicController: _topicController,
                      controller: _contentController,
                      focusNode: _contentFocusNode),
                  ]))),
              const SizedBox(width: 8),
              _StreamSendButton(
                narrow: widget.narrow,
                topicController: _topicController,
                contentController: _contentController,
              ),
            ]),
            Theme(
              data: themeData.copyWith(
                iconTheme: themeData.iconTheme.copyWith(color: colorScheme.onSurfaceVariant)),
              child: Row(children: [
                _AttachFileButton(contentController: _contentController, contentFocusNode: _contentFocusNode),
                _AttachMediaButton(contentController: _contentController, contentFocusNode: _contentFocusNode),
                _AttachFromCameraButton(contentController: _contentController, contentFocusNode: _contentFocusNode),
              ])),
          ]))));
  }
}

class ComposeBox extends StatelessWidget {
  const ComposeBox({super.key, required this.narrow});

  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final narrow = this.narrow;
    if (narrow is StreamNarrow) {
      return _StreamComposeBox(narrow: narrow);
    } else if (narrow is TopicNarrow) {
      return const SizedBox.shrink(); // TODO(#144): add a single-topic compose box
    } else if (narrow is DmNarrow) {
      return const SizedBox.shrink(); // TODO(#144): add a DM compose box
    } else if (narrow is AllMessagesNarrow) {
      return const SizedBox.shrink();
    } else {
      throw Exception("impossible narrow"); // TODO(dart-3): show this statically
    }
  }
}
