// ПРОВЕЛ ДЕКОМПОЗИЦИЮ ВСЕГО ГОВНА!
// ТУТ ОСТАЛОСЬ ВСЕ ТО, ЧТО Я ПОКА НЕ ПОНЯЛ, КУДА ЗАСУНУТЬ

import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/model/model.dart';
import '../../api/route/messages.dart';
import '../../generated/l10n/zulip_localizations.dart';
import '../../model/compose.dart';
import '../../model/store.dart';
import 'compose_box_block.dart';
import '../widgets/dialog.dart';
import '../utils/store.dart';
import '../values/theme.dart';

/// Compose-box styles that differ between light and dark theme.
///
/// These styles will animate on theme changes (with help from [lerp]).
class ComposeBoxTheme extends ThemeExtension<ComposeBoxTheme> {
  static final light = ComposeBoxTheme._(boxShadow: null);

  static final dark = ComposeBoxTheme._(
    boxShadow: [
      BoxShadow(
        color: DesignVariables.dark.bgTopBar,
        offset: const Offset(0, -4),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ],
  );

  ComposeBoxTheme._({required this.boxShadow});

  /// The [ComposeBoxTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [ComposeBoxTheme] in [ThemeData.extensions].
  static ComposeBoxTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ComposeBoxTheme>();
    assert(extension != null);
    return extension!;
  }

  final List<BoxShadow>? boxShadow;

  @override
  ComposeBoxTheme copyWith({List<BoxShadow>? boxShadow}) {
    return ComposeBoxTheme._(boxShadow: boxShadow ?? this.boxShadow);
  }

  @override
  ComposeBoxTheme lerp(ComposeBoxTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return ComposeBoxTheme._(
      boxShadow: BoxShadow.lerpList(boxShadow, other.boxShadow, t)!,
    );
  }
}

/// A [TextEditingController] for use in the compose box.
///
/// Subclasses must ensure that [_update] is called in all exposed constructors.
abstract class ComposeController<ErrorT> extends TextEditingController {
  ComposeController({super.text, required this.store});

  PerAccountStore store;

  int get maxLengthUnicodeCodePoints;

  String get textNormalized => _textNormalized;
  late String _textNormalized;
  String _computeTextNormalized();

  /// Length of [textNormalized] in Unicode code points
  /// if it might exceed [maxLengthUnicodeCodePoints], else null.
  ///
  /// Use this instead of [String.length]
  /// to enforce a max length expressed in code points.
  /// [String.length] is conservative and may cut the user off too short.
  ///
  /// Counting code points ([String.runes])
  /// is more expensive than getting the number of UTF-16 code units
  /// ([String.length]), so we avoid it when the result definitely won't exceed
  /// [maxLengthUnicodeCodePoints].
  late int? _lengthUnicodeCodePointsIfLong;
  @visibleForTesting
  int? get debugLengthUnicodeCodePointsIfLong => _lengthUnicodeCodePointsIfLong;
  int? _computeLengthUnicodeCodePointsIfLong() =>
      _textNormalized.length > maxLengthUnicodeCodePoints
      ? _textNormalized.runes.length
      : null;

  List<ErrorT> get validationErrors => _validationErrors;
  late List<ErrorT> _validationErrors;
  List<ErrorT> _computeValidationErrors();

  ValueNotifier<bool> hasValidationErrors = ValueNotifier(false);

  void _update() {
    _textNormalized = _computeTextNormalized();
    // uses _textNormalized, so comes after _computeTextNormalized()
    _lengthUnicodeCodePointsIfLong = _computeLengthUnicodeCodePointsIfLong();
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

  String message(
    ZulipLocalizations zulipLocalizations, {
    required int maxLength,
  }) {
    switch (this) {
      case tooLong:
        return zulipLocalizations.topicValidationErrorTooLong(maxLength);
      case mandatoryButEmpty:
        return zulipLocalizations.topicValidationErrorMandatoryButEmpty;
    }
  }
}

class ComposeTopicController extends ComposeController<TopicValidationError> {
  ComposeTopicController({super.text, required super.store}) {
    _update();
  }

  // TODO(#668): listen to [PerAccountStore] once we subscribe to this value
  bool get mandatory => store.realmMandatoryTopics;

  @override
  int get maxLengthUnicodeCodePoints => store.maxTopicLength;

  @override
  String _computeTextNormalized() {
    String trimmed = text.trim();
    // TODO(server-10): simplify
    if (store.zulipFeatureLevel < 334) {
      return trimmed.isEmpty ? kNoTopicTopic : trimmed;
    }

    return trimmed;
  }

  /// Whether [textNormalized] would fail a mandatory-topics check
  /// (see [mandatory]).
  ///
  /// The term "Vacuous" draws distinction from [String.isEmpty], in the sense
  /// that certain strings are not empty but also indicate the absence of a topic.
  ///
  /// See also: https://zulip.com/api/send-message#parameter-topic
  bool get isTopicVacuous {
    if (textNormalized.isEmpty) return true;

    if (textNormalized == kNoTopicTopic) return true;

    // TODO(server-10): simplify
    if (store.zulipFeatureLevel >= 334) {
      return textNormalized == store.realmEmptyTopicDisplayName;
    }

    return false;
  }

  @override
  List<TopicValidationError> _computeValidationErrors() {
    return [
      if (mandatory && isTopicVacuous) TopicValidationError.mandatoryButEmpty,

      if (_lengthUnicodeCodePointsIfLong != null &&
          _lengthUnicodeCodePointsIfLong! > maxLengthUnicodeCodePoints)
        TopicValidationError.tooLong,
    ];
  }

  void setTopic(TopicName newTopic) {
    value = TextEditingValue(text: newTopic.displayName ?? '');
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

class ComposeContentController
    extends ComposeController<ContentValidationError> {
  ComposeContentController({
    super.text,
    required super.store,
    this.requireNotEmpty = true,
  }) {
    _update();
  }

  /// Whether to produce [ContentValidationError.empty].
  final bool requireNotEmpty;

  // TODO(#1237) use `max_message_length` instead of hardcoded limit
  @override
  final maxLengthUnicodeCodePoints = kMaxMessageLengthCodePoints;

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
    if (textBefore.isEmpty ||
        textBefore == '\n' ||
        textBefore.endsWith('\n\n')) {
      paddingBefore = ''; // At start of input, or just after an empty line.
    } else if (textBefore.endsWith('\n')) {
      paddingBefore = '\n'; // After a complete but non-empty line.
    } else {
      paddingBefore = '\n\n'; // After an incomplete line.
    }
    if (text.substring(i.start).startsWith('\n')) {
      final partial = value.replaced(i, paddingBefore + newText);
      value = partial.copyWith(
        selection: TextSelection.collapsed(offset: partial.selection.start + 1),
      );
    } else {
      value = value.replaced(i, '$paddingBefore$newText\n');
    }
  }

  /// Tells the controller that a quote-and-reply has started.
  ///
  /// Returns an int "tag" that should be passed to registerQuoteAndReplyEnd on
  /// success or failure
  int registerQuoteAndReplyStart(
    ZulipLocalizations zulipLocalizations,
    PerAccountStore store, {
    required Message message,
  }) {
    final tag = _nextQuoteAndReplyTag;
    _nextQuoteAndReplyTag += 1;
    final placeholder = quoteAndReplyPlaceholder(
      zulipLocalizations,
      store,
      message: message,
    );
    _quoteAndReplies[tag] = (messageId: message.id, placeholder: placeholder);
    notifyListeners(); // _quoteAndReplies change could affect validationErrors
    insertPadded(placeholder);
    return tag;
  }

  /// Tells the controller that a quote-and-reply has ended, with success or error.
  ///
  /// To indicate success, pass [rawContent].
  /// If that is null, failure is assumed.
  void registerQuoteAndReplyEnd(
    PerAccountStore store,
    int tag, {
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
    } else if (replacementText != '') {
      // insertPadded requires non-empty string
      insertPadded(replacementText);
    }
    _quoteAndReplies.remove(tag);
    notifyListeners(); // _quoteAndReplies change could affect validationErrors
  }

  /// Tells the controller that a file upload has started.
  ///
  /// Returns an int "tag" that should be passed to registerUploadEnd on the
  /// upload's success or failure.
  int registerUploadStart(
    String filename,
    ZulipLocalizations zulipLocalizations,
  ) {
    final tag = _nextUploadTag;
    _nextUploadTag += 1;
    final linkText = zulipLocalizations.composeBoxUploadingFilename(filename);
    final placeholder = inlineLink(linkText, '');
    _uploads[tag] = (filename: filename, placeholder: placeholder);
    notifyListeners(); // _uploads change could affect validationErrors
    value = value.replaced(insertionIndex(), '$placeholder\n\n');
    return tag;
  }

  /// Tells the controller that a file upload has ended, with success or error.
  ///
  /// To indicate success, pass the URL string to be used for the Markdown link.
  /// If `url` is null, failure is assumed.
  void registerUploadEnd(int tag, String? url) {
    final val = _uploads[tag];
    assert(val != null, 'registerUploadEnd called twice for same tag');
    final (:filename, :placeholder) = val!;
    final int startIndex = text.indexOf(placeholder);
    final replacementRange = startIndex >= 0
        ? TextRange(start: startIndex, end: startIndex + placeholder.length)
        : insertionIndex();

    value = value.replaced(
      replacementRange,
      url == null ? '' : inlineLink(filename, url),
    );
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
      if (requireNotEmpty && textNormalized.isEmpty)
        ContentValidationError.empty,

      if (_lengthUnicodeCodePointsIfLong != null &&
          _lengthUnicodeCodePointsIfLong! > maxLengthUnicodeCodePoints)
        ContentValidationError.tooLong,

      if (_quoteAndReplies.isNotEmpty)
        ContentValidationError.quoteAndReplyInProgress,

      if (_uploads.isNotEmpty) ContentValidationError.uploadInProgress,
    ];
  }
}

/// The content input for _StreamComposeBox.

/// Data on a file to be uploaded, from any source.
///
/// A convenience class to represent data from the generic file picker,
/// the media library, and the camera, in a single form.
class FileToUpload {
  FileToUpload({
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
  bool shouldRequestFocus = true,
  required Iterable<FileToUpload> files,
}) async {
  assert(context.mounted);
  final store = PerAccountStoreWidget.of(context);
  final zulipLocalizations = ZulipLocalizations.of(context);

  final List<FileToUpload> tooLargeFiles = [];
  final List<FileToUpload> rightSizeFiles = [];
  for (final file in files) {
    if ((file.length / (1 << 20)) > store.maxFileUploadSizeMib) {
      tooLargeFiles.add(file);
    } else {
      rightSizeFiles.add(file);
    }
  }

  if (tooLargeFiles.isNotEmpty) {
    final listMessage = tooLargeFiles
        .map(
          (file) => zulipLocalizations.filenameAndSizeInMiB(
            file.filename,
            (file.length / (1 << 20)).toStringAsFixed(1),
          ),
        )
        .join('\n');
    showErrorDialog(
      context: context,
      title: zulipLocalizations.errorFilesTooLargeTitle(tooLargeFiles.length),
      message: zulipLocalizations.errorFilesTooLarge(
        tooLargeFiles.length,
        store.maxFileUploadSizeMib,
        listMessage,
      ),
    );
  }

  final List<(int, FileToUpload)> uploadsInProgress = [];
  for (final file in rightSizeFiles) {
    final tag = contentController.registerUploadStart(
      file.filename,
      zulipLocalizations,
    );
    uploadsInProgress.add((tag, file));
  }
  if (shouldRequestFocus && !contentFocusNode.hasFocus) {
    contentFocusNode.requestFocus();
  }

  for (final (tag, file) in uploadsInProgress) {
    final FileToUpload(:content, :length, :filename, :mimeType) = file;
    String? url;
    try {
      final result = await uploadFile(
        store.connection,
        content: content,
        length: length,
        filename: filename,
        contentType: mimeType,
      );
      url = result.url;
    } catch (e) {
      if (!context.mounted) return;
      // TODO(#741): Specifically handle `413 Payload Too Large`
      // TODO(#741): On API errors, quote `msg` from server, with "The server said:"
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorFailedToUploadFileTitle(filename),
        message: e.toString(),
      );
    } finally {
      contentController.registerUploadEnd(tag, url);
    }
  }
}

sealed class ComposeBoxController {
  ComposeBoxController({required PerAccountStore store})
    : content = ComposeContentController(store: store);

  final ComposeContentController content;
  final contentFocusNode = FocusNode();

  /// If no input is focused, requests focus on the appropriate input.
  ///
  /// This encapsulates choosing the topic or content input
  /// when both exist (see [StreamComposeBoxController.requestFocusIfUnfocused]).
  void requestFocusIfUnfocused() {
    if (contentFocusNode.hasFocus) return;
    contentFocusNode.requestFocus();
  }

  /// Uploads the provided files, populating the content input with their links.
  ///
  /// If any of the files are larger than maximum file size allowed by the
  /// server, an error dialog is shown mentioning their names and actual
  /// file sizes.
  ///
  /// While uploading, a placeholder link is inserted in the content input and
  /// if [shouldRequestFocus] is true it will be focused. And then after
  /// uploading completes successfully the placeholder link will be replaced
  /// with an actual link.
  ///
  /// If there is an error while uploading a file, then an error dialog is
  /// shown mentioning the corresponding file name.
  Future<void> uploadFiles({
    required BuildContext context,
    required Iterable<FileToUpload> files,
    required bool shouldRequestFocus,
  }) async {
    await _uploadFiles(
      context: context,
      contentController: content,
      contentFocusNode: contentFocusNode,
      shouldRequestFocus: shouldRequestFocus,
      files: files,
    );
  }

  @mustCallSuper
  void dispose() {
    content.dispose();
    contentFocusNode.dispose();
  }
}

/// Represent how a user has interacted with topic and content inputs.
///
/// State-transition diagram:
///
/// ```
///                       (default)
///    Topic input            │          Content input
///    lost focus.            ▼          gained focus.
///   ┌────────────► notEditingNotChosen ────────────┐
///   │                                 │            │
///   │         Topic input             │            │
///   │         gained focus.           │            │
///   │       ◄─────────────────────────┘            ▼
/// isEditing ◄───────────────────────────── hasChosen
///   │         Focus moved from             ▲ │     ▲
///   │         content to topic.            │ │     │
///   │                                      │ │     │
///   └──────────────────────────────────────┘ └─────┘
///    Focus moved from                        Content input loses focus
///    topic to content.                       without topic input gaining it.
/// ```
///
/// This state machine offers the following invariants:
/// - When topic input has focus, the status must be [isEditing].
/// - When content input has focus, the status must be [hasChosen].
/// - When neither input has focus, and content input was the last
///   input among the two to be focused, the status must be [hasChosen].
/// - Otherwise, the status must be [notEditingNotChosen].
enum ComposeTopicInteractionStatus {
  /// The topic has likely not been chosen if left empty,
  /// and is not being actively edited.
  ///
  /// When in this status neither the topic input nor the content input has focus.
  notEditingNotChosen,

  /// The topic is being actively edited.
  ///
  /// When in this status, the topic input must have focus.
  isEditing,

  /// The topic has likely been chosen, even if it is left empty.
  ///
  /// When in this status, the topic input must have no focus;
  /// the content input might have focus.
  hasChosen,
}

class StreamComposeBoxController extends ComposeBoxController {
  StreamComposeBoxController({required super.store})
    : topic = ComposeTopicController(store: store);

  final ComposeTopicController topic;
  final topicFocusNode = FocusNode();
  final ValueNotifier<ComposeTopicInteractionStatus> topicInteractionStatus =
      ValueNotifier(ComposeTopicInteractionStatus.notEditingNotChosen);

  @override
  void requestFocusIfUnfocused() {
    if (topicFocusNode.hasFocus || contentFocusNode.hasFocus) return;
    switch (topicInteractionStatus.value) {
      case ComposeTopicInteractionStatus.notEditingNotChosen:
        topicFocusNode.requestFocus();
      case ComposeTopicInteractionStatus.isEditing:
        // (should be impossible given early-return on topicFocusNode.hasFocus)
        break;
      case ComposeTopicInteractionStatus.hasChosen:
        contentFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    topic.dispose();
    topicFocusNode.dispose();
    topicInteractionStatus.dispose();
    super.dispose();
  }
}

class FixedDestinationComposeBoxController extends ComposeBoxController {
  FixedDestinationComposeBoxController({required super.store});
}

class EditMessageComposeBoxController extends ComposeBoxController {
  EditMessageComposeBoxController({
    required super.store,
    required this.messageId,
    required this.originalRawContent,
    required String? initialText,
  }) : _content = ComposeContentController(
         text: initialText,
         store: store,
         // Editing to delete the content is a supported form of
         // deletion: https://zulip.com/help/delete-a-message#delete-message-content
         requireNotEmpty: false,
       );

  factory EditMessageComposeBoxController.empty(
    PerAccountStore store,
    int messageId,
  ) => EditMessageComposeBoxController(
    store: store,
    messageId: messageId,
    originalRawContent: null,
    initialText: null,
  );

  @override
  ComposeContentController get content => _content;
  final ComposeContentController _content;

  final int messageId;
  String? originalRawContent;
}

/// An [InheritedWidget] to provide data to leafward [StatelessWidget]s,
/// such as flags that should cause the upload buttons to be disabled.
class ComposeBoxInheritedWidget extends InheritedWidget {
  factory ComposeBoxInheritedWidget.fromComposeBoxState(
    ComposeBoxBlockState state, {
    required Widget child,
  }) {
    final controller = state.controller;
    return ComposeBoxInheritedWidget._(
      awaitingRawMessageContentForEdit:
          controller is EditMessageComposeBoxController &&
          controller.originalRawContent == null,
      child: child,
    );
  }

  const ComposeBoxInheritedWidget._({
    required this.awaitingRawMessageContentForEdit,
    required super.child,
  });

  final bool awaitingRawMessageContentForEdit;

  @override
  bool updateShouldNotify(covariant ComposeBoxInheritedWidget oldWidget) =>
      awaitingRawMessageContentForEdit !=
      oldWidget.awaitingRawMessageContentForEdit;

  static ComposeBoxInheritedWidget of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ComposeBoxInheritedWidget>();
    assert(widget != null, 'No ComposeBoxInheritedWidget ancestor');
    return widget!;
  }
}
