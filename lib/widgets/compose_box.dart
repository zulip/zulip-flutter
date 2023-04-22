import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dialog.dart';

import '../api/route/messages.dart';
import 'store.dart';

const double _inputVerticalPadding = 8;
const double _sendButtonSize = 36;

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

class TopicTextEditingController extends TextEditingController {
  // TODO: subscribe to this value:
  //   https://zulip.com/help/require-topics
  final mandatory = true;

  String textNormalized() {
    String trimmed = text.trim();
    return trimmed.isEmpty ? kNoTopicTopic : trimmed;
  }

  List<TopicValidationError> validationErrors() {
    final normalized = textNormalized();
    return [
      if (mandatory && normalized == kNoTopicTopic)
        TopicValidationError.mandatoryButEmpty,
      if (normalized.length > kMaxTopicLength)
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

class ContentTextEditingController extends TextEditingController {
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

  String textNormalized() {
    return text.trim();
  }

  List<ContentValidationError> validationErrors() {
    final normalized = textNormalized();
    return [
      if (normalized.isEmpty)
        ContentValidationError.empty,

      // normalized.length is the number of UTF-16 code units, while the server
      // API expresses the max in Unicode code points. So this comparison will
      // be conservative and may cut the user off shorter than necessary.
      if (normalized.length > kMaxMessageLengthCodePoints)
        ContentValidationError.tooLong,

      if (_uploads.isNotEmpty)
        ContentValidationError.uploadInProgress,
    ];
  }
}

/// The content input for StreamComposeBox.
class _StreamContentInput extends StatefulWidget {
  const _StreamContentInput({
    required this.controller,
    required this.topicController,
    required this.focusNode,
  });

  final ContentTextEditingController controller;
  final TopicTextEditingController topicController;
  final FocusNode focusNode;

  @override
  State<_StreamContentInput> createState() => _StreamContentInputState();
}

class _StreamContentInputState extends State<_StreamContentInput> {
  late String _topicTextNormalized;

  _topicChanged() {
    setState(() {
      _topicTextNormalized = widget.topicController.textNormalized();
    });
  }

  @override
  void initState() {
    super.initState();
    _topicTextNormalized = widget.topicController.textNormalized();
    widget.topicController.addListener(_topicChanged);
  }

  @override
  void dispose() {
    widget.topicController.removeListener(_topicChanged);
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
          maxHeight: 200
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration.collapsed(
            hintText: "Message #test here > $_topicTextNormalized",
          ),
          maxLines: null,
        ),
      ),
    );
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
  required ContentTextEditingController contentController,
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
        '${tooLargeFiles.length} file(s) are larger than the server\'s limit of ${store.maxFileUploadSizeMib} MiB and will not be uploaded:\n\n$listMessage');
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

  final ContentTextEditingController contentController;
  final FocusNode contentFocusNode;

  IconData get icon;

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

    if (context.mounted) {} // https://github.com/dart-lang/linter/issues/4007
    else {
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
    return IconButton(icon: Icon(icon), onPressed: () => _handlePress(context));
  }
}

class _AttachFileButton extends _AttachUploadsButton {
  const _AttachFileButton({required super.contentController, required super.contentFocusNode});

  @override
  IconData get icon => Icons.attach_file;

  @override
  Future<Iterable<_File>> getFiles(BuildContext context) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(allowMultiple: true, withReadStream: true);
    } catch (e) {
      // TODO(i18n)
      showErrorDialog(context: context, title: 'Error', message: e.toString());
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
}

/// The send button for StreamComposeBox.
class _StreamSendButton extends StatefulWidget {
  const _StreamSendButton({required this.topicController, required this.contentController});

  final TopicTextEditingController topicController;
  final ContentTextEditingController contentController;

  @override
  State<_StreamSendButton> createState() => _StreamSendButtonState();
}

class _StreamSendButtonState extends State<_StreamSendButton> {
  late List<TopicValidationError> _topicValidationErrors;
  late List<ContentValidationError> _contentValidationErrors;

  _topicChanged() {
    final oldIsEmpty = _topicValidationErrors.isEmpty;
    final newErrors = widget.topicController.validationErrors();
    final newIsEmpty = newErrors.isEmpty;
    _topicValidationErrors = newErrors;
    if (oldIsEmpty != newIsEmpty) {
      setState(() {
        // Update disabled/non-disabled state
      });
    }
  }

  _contentChanged() {
    final oldIsEmpty = _contentValidationErrors.isEmpty;
    final newErrors = widget.contentController.validationErrors();
    final newIsEmpty = newErrors.isEmpty;
    _contentValidationErrors = newErrors;
    if (oldIsEmpty != newIsEmpty) {
      setState(() {
        // Update disabled/non-disabled state
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _topicValidationErrors = widget.topicController.validationErrors();
    _contentValidationErrors = widget.contentController.validationErrors();
    widget.topicController.addListener(_topicChanged);
    widget.contentController.addListener(_contentChanged);
  }

  @override
  void dispose() {
    widget.topicController.removeListener(_topicChanged);
    widget.contentController.removeListener(_contentChanged);
    super.dispose();
  }

  void _showSendFailedDialog(BuildContext context) {
    List<String> validationErrorMessages = [
      for (final error in _topicValidationErrors)
        error.message(),
      for (final error in _contentValidationErrors)
        error.message(),
    ];

    return showErrorDialog(
        context: context,
        title: 'Message not sent',
        message: validationErrorMessages.join('\n\n'));
  }

  void _handleSendPressed(BuildContext context) {
    if (_topicValidationErrors.isNotEmpty || _contentValidationErrors.isNotEmpty) {
      _showSendFailedDialog(context);
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    store.sendStreamMessage(
      topic: widget.topicController.textNormalized(),
      content: widget.contentController.textNormalized(),
    );

    widget.contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    bool disabled = _topicValidationErrors.isNotEmpty || _contentValidationErrors.isNotEmpty;

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
        // Match the height of the content input. Zeroing the padding lets the
        // constraints take over.
        constraints: const BoxConstraints(minWidth: _sendButtonSize, minHeight: _sendButtonSize),
        padding: const EdgeInsets.all(0),

        color: foregroundColor,
        icon: const Icon(Icons.send),
        onPressed: () => _handleSendPressed(context),
      ),
    );
  }
}

/// The compose box for writing a stream message.
class StreamComposeBox extends StatefulWidget {
  const StreamComposeBox({super.key});

  @override
  State<StreamComposeBox> createState() => _StreamComposeBoxState();
}

class _StreamComposeBoxState extends State<StreamComposeBox> {
  final _topicController = TopicTextEditingController();
  final _contentController = ContentTextEditingController();
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
          borderSide: BorderSide.none,
        ),

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
            child: Column(
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Theme(
                        data: inputThemeData,
                        child: Column(
                            children: [
                              topicInput,
                              const SizedBox(height: 8),
                              _StreamContentInput(
                                topicController: _topicController,
                                controller: _contentController,
                                focusNode: _contentFocusNode),
                            ]))),
                  const SizedBox(width: 8),
                  _StreamSendButton(topicController: _topicController, contentController: _contentController),
                ]),
                Theme(
                  data: themeData.copyWith(
                    iconTheme: themeData.iconTheme.copyWith(color: colorScheme.onSurfaceVariant)),
                  child: Row(
                    children: [
                      _AttachFileButton(contentController: _contentController, contentFocusNode: _contentFocusNode),
                    ])),
              ]))));
  }
}
