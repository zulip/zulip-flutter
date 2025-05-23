import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../api/route/saved_snippets.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/compose.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'actions.dart';
import 'autocomplete.dart';
import 'button.dart';
import 'color.dart';
import 'dialog.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'saved_snippet.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// Compose-box styles that differ between light and dark theme.
///
/// These styles will animate on theme changes (with help from [lerp]).
class ComposeBoxTheme extends ThemeExtension<ComposeBoxTheme> {
  static final light = ComposeBoxTheme._(
    boxShadow: null,
  );

  static final dark = ComposeBoxTheme._(
    boxShadow: [BoxShadow(
      color: DesignVariables.dark.bgTopBar,
      offset: const Offset(0, -4),
      blurRadius: 16,
      spreadRadius: 0,
    )],
  );

  ComposeBoxTheme._({
    required this.boxShadow,
  });

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
  ComposeBoxTheme copyWith({
    List<BoxShadow>? boxShadow,
  }) {
    return ComposeBoxTheme._(
      boxShadow: boxShadow ?? this.boxShadow,
    );
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

const double _composeButtonSize = 44;

/// A [TextEditingController] for use in the compose box.
///
/// Subclasses must ensure that [_update] is called in all exposed constructors.
abstract class ComposeController<ErrorT> extends TextEditingController {
  ComposeController({super.text});

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
  ComposeTopicController({super.text, required this.store}) {
    _update();
  }

  PerAccountStore store;

  // TODO(#668): listen to [PerAccountStore] once we subscribe to this value
  bool get mandatory => store.realmMandatoryTopics;

  // TODO(#307) use `max_topic_length` instead of hardcoded limit
  @override final maxLengthUnicodeCodePoints = kMaxTopicLengthCodePoints;

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
      if (mandatory && isTopicVacuous)
        TopicValidationError.mandatoryButEmpty,

      if (
        _lengthUnicodeCodePointsIfLong != null
        && _lengthUnicodeCodePointsIfLong! > maxLengthUnicodeCodePoints
      )
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

  /// Convert this into message suitable to use in [SavedSnippetComposeBox].
  String messageForSavedSnippet(ZulipLocalizations zulipLocalizations) {
    switch (this) {
      case ContentValidationError.empty:
        return zulipLocalizations.savedSnippetContentValidationErrorEmpty;
      case ContentValidationError.tooLong:
        return zulipLocalizations.savedSnippetContentValidationErrorTooLong;
      case ContentValidationError.quoteAndReplyInProgress:
      case ContentValidationError.uploadInProgress:
        return message(zulipLocalizations);
    }
  }
}

class ComposeContentController extends ComposeController<ContentValidationError> {
  ComposeContentController({super.text, this.requireNotEmpty = true}) {
    _update();
  }

  /// Whether to produce [ContentValidationError.empty].
  final bool requireNotEmpty;

  // TODO(#1237) use `max_message_length` instead of hardcoded limit
  @override final maxLengthUnicodeCodePoints = kMaxMessageLengthCodePoints;

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
  int registerQuoteAndReplyStart(
    ZulipLocalizations zulipLocalizations,
    PerAccountStore store, {
      required Message message,
    }) {
    final tag = _nextQuoteAndReplyTag;
    _nextQuoteAndReplyTag += 1;
    final placeholder = quoteAndReplyPlaceholder(
      zulipLocalizations, store, message: message);
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
      if (requireNotEmpty && textNormalized.isEmpty)
        ContentValidationError.empty,

      if (
        _lengthUnicodeCodePointsIfLong != null
        && _lengthUnicodeCodePointsIfLong! > maxLengthUnicodeCodePoints
      )
        ContentValidationError.tooLong,

      if (_quoteAndReplies.isNotEmpty)
        ContentValidationError.quoteAndReplyInProgress,

      if (_uploads.isNotEmpty)
        ContentValidationError.uploadInProgress,
    ];
  }
}

enum SavedSnippetTitleValidationError {
  empty,
  tooLong;

  String message(ZulipLocalizations zulipLocalizations) {
    return switch (this) {
      SavedSnippetTitleValidationError.empty => zulipLocalizations.savedSnippetTitleValidationErrorEmpty,
      SavedSnippetTitleValidationError.tooLong => zulipLocalizations.savedSnippetTitleValidationErrorTooLong,
    };
  }
}

class ComposeSavedSnippetTitleController extends ComposeController<SavedSnippetTitleValidationError> {
  ComposeSavedSnippetTitleController() {
    _update();
  }

  // TODO find the right value for this
  @override int get maxLengthUnicodeCodePoints => kMaxTopicLengthCodePoints;

  @override
  String _computeTextNormalized() {
    return text.trim();
  }

  @override
  List<SavedSnippetTitleValidationError> _computeValidationErrors() {
    return [
      if (textNormalized.isEmpty)
        SavedSnippetTitleValidationError.empty,

      if (
        _lengthUnicodeCodePointsIfLong != null
        && _lengthUnicodeCodePointsIfLong! > maxLengthUnicodeCodePoints
      )
        SavedSnippetTitleValidationError.tooLong,
    ];
  }
}

class _TypingNotifier extends StatefulWidget {
  const _TypingNotifier({
    required this.destination,
    required this.controller,
    required this.child,
  });

  final SendableNarrow destination;
  final ComposeBoxController controller;
  final Widget child;

  @override
  State<_TypingNotifier> createState() => _TypingNotifierState();
}

class _TypingNotifierState extends State<_TypingNotifier> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller.content.addListener(_contentChanged);
    widget.controller.contentFocusNode.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _TypingNotifier oldWidget) {
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

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ContentInput extends StatelessWidget {
  const _ContentInput({
    required this.narrow,
    required this.controller,
    this.hintText,
    this.enabled = true,
  });
  /// The narrow used for autocomplete.
  ///
  /// If `null`, autocomplete is disabled.
  // TODO support autocomplete without a narrow
  final Narrow? narrow;

  final ComposeBoxController controller;
  final String? hintText;
  final bool enabled;

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

    final inputWidget = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight(context)),
      // This [ClipRect] replaces the [TextField] clipping we disable below.
      child: ClipRect(
        child: InsetShadowBox(
          top: _verticalPadding, bottom: _verticalPadding,
          color: designVariables.composeBoxBg,
          child: TextField(
            enabled: enabled,
            controller: controller.content,
            focusNode: controller.contentFocusNode,
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
              hintText: hintText,
              hintStyle: TextStyle(
                color: designVariables.textInput.withFadedAlpha(0.5)))))));

    if (narrow == null) {
      return inputWidget;
    }

    return ComposeAutocomplete(
      narrow: narrow!,
      controller: controller.content,
      focusNode: controller.contentFocusNode,
      fieldViewBuilder: (context) => inputWidget);
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
  void _topicChanged() {
    setState(() {
      // The relevant state lives on widget.controller.topic itself.
    });
  }

  void _contentFocusChanged() {
    setState(() {
      // The relevant state lives on widget.controller.contentFocusNode itself.
    });
  }

  void _topicInteractionStatusChanged() {
    setState(() {
      // The relevant state lives on widget.controller.topicInteractionStatus itself.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.topic.addListener(_topicChanged);
    widget.controller.contentFocusNode.addListener(_contentFocusChanged);
    widget.controller.topicInteractionStatus.addListener(_topicInteractionStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _StreamContentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.topic != oldWidget.controller.topic) {
      oldWidget.controller.topic.removeListener(_topicChanged);
      widget.controller.topic.addListener(_topicChanged);
    }
    if (widget.controller.contentFocusNode != oldWidget.controller.contentFocusNode) {
      oldWidget.controller.contentFocusNode.removeListener(_contentFocusChanged);
      widget.controller.contentFocusNode.addListener(_contentFocusChanged);
    }
    if (widget.controller.topicInteractionStatus != oldWidget.controller.topicInteractionStatus) {
      oldWidget.controller.topicInteractionStatus.removeListener(_topicInteractionStatusChanged);
      widget.controller.topicInteractionStatus.addListener(_topicInteractionStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.topic.removeListener(_topicChanged);
    widget.controller.contentFocusNode.removeListener(_contentFocusChanged);
    widget.controller.topicInteractionStatus.removeListener(_topicInteractionStatusChanged);
    super.dispose();
  }

  /// The topic name to show in the hint text, or null to show no topic.
  TopicName? _hintTopic() {
    if (widget.controller.topic.isTopicVacuous) {
      if (widget.controller.topic.mandatory) {
        // The chosen topic can't be sent to, so don't show it.
        return null;
      }
      if (widget.controller.topicInteractionStatus.value !=
            ComposeTopicInteractionStatus.hasChosen) {
        // Do not fall back to a vacuous topic unless the user explicitly
        // chooses to do so, so that the user is not encouraged to use vacuous
        // topic before they have interacted with the inputs at all.
        return null;
      }
    }

    return TopicName(widget.controller.topic.textNormalized);
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final streamName = store.streams[widget.narrow.streamId]?.name
      ?? zulipLocalizations.unknownChannelName;
    final hintTopic = _hintTopic();
    final hintDestination = hintTopic == null
      // No i18n of this use of "#" and ">" string; those are part of how
      // Zulip expresses channels and topics, not any normal English punctuation,
      // so don't make sense to translate. See:
      //   https://github.com/zulip/zulip-flutter/pull/1148#discussion_r1941990585
      ? '#$streamName'
      : '#$streamName > ${hintTopic.displayName ?? store.realmEmptyTopicDisplayName}';

    return _TypingNotifier(
      destination: TopicNarrow(widget.narrow.streamId,
        TopicName(widget.controller.topic.textNormalized)),
      controller: widget.controller,
      child: _ContentInput(
        narrow: widget.narrow,
        controller: widget.controller,
        hintText: zulipLocalizations.composeBoxChannelContentHint(hintDestination)));
  }
}

class _TopicInput extends StatefulWidget {
  const _TopicInput({required this.streamId, required this.controller});

  final int streamId;
  final StreamComposeBoxController controller;

  @override
  State<_TopicInput> createState() => _TopicInputState();
}

class _TopicInputState extends State<_TopicInput> {
  void _topicOrContentFocusChanged() {
    setState(() {
      final status = widget.controller.topicInteractionStatus;
      if (widget.controller.topicFocusNode.hasFocus) {
        // topic input gains focus
        status.value = ComposeTopicInteractionStatus.isEditing;
      } else if (widget.controller.contentFocusNode.hasFocus) {
        // content input gains focus
        status.value = ComposeTopicInteractionStatus.hasChosen;
      } else {
        // neither input has focus, the new value of topicInteractionStatus
        // depends on its previous value
        if (status.value == ComposeTopicInteractionStatus.isEditing) {
          // topic input loses focus
          status.value = ComposeTopicInteractionStatus.notEditingNotChosen;
        } else {
          // content input loses focus; stay in hasChosen
          assert(status.value == ComposeTopicInteractionStatus.hasChosen);
        }
      }
    });
  }

  void _topicInteractionStatusChanged() {
    setState(() {
      // The actual state lives in widget.controller.topicInteractionStatus
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.topicFocusNode.addListener(_topicOrContentFocusChanged);
    widget.controller.contentFocusNode.addListener(_topicOrContentFocusChanged);
    widget.controller.topicInteractionStatus.addListener(_topicInteractionStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _TopicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.topicFocusNode.removeListener(_topicOrContentFocusChanged);
      widget.controller.topicFocusNode.addListener(_topicOrContentFocusChanged);
      oldWidget.controller.contentFocusNode.removeListener(_topicOrContentFocusChanged);
      widget.controller.contentFocusNode.addListener(_topicOrContentFocusChanged);
      oldWidget.controller.topicInteractionStatus.removeListener(_topicInteractionStatusChanged);
      widget.controller.topicInteractionStatus.addListener(_topicInteractionStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.topicFocusNode.removeListener(_topicOrContentFocusChanged);
    widget.controller.contentFocusNode.removeListener(_topicOrContentFocusChanged);
    widget.controller.topicInteractionStatus.removeListener(_topicInteractionStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);

    final topicTextStyle = TextStyle(
      fontSize: 20,
      height: 22 / 20,
      color: designVariables.textInput.withFadedAlpha(0.9),
    ).merge(weightVariableTextStyle(context, wght: 600));

    // TODO(server-10) simplify away
    final emptyTopicsSupported = store.zulipFeatureLevel >= 334;

    final String hintText;
    TextStyle hintStyle = topicTextStyle.copyWith(
      color: designVariables.textInput.withFadedAlpha(0.5));

    if (store.realmMandatoryTopics) {
      // Something short and not distracting.
      hintText = zulipLocalizations.composeBoxTopicHintText;
    } else {
      switch (widget.controller.topicInteractionStatus.value) {
        case ComposeTopicInteractionStatus.notEditingNotChosen:
          // Something short and not distracting.
          hintText = zulipLocalizations.composeBoxTopicHintText;
        case ComposeTopicInteractionStatus.isEditing:
          // The user is actively interacting with the input.  Since topics are
          // not mandatory, show a long hint text mentioning that they can be
          // left empty.
          hintText = zulipLocalizations.composeBoxEnterTopicOrSkipHintText(
            emptyTopicsSupported
              ? store.realmEmptyTopicDisplayName
              : kNoTopicTopic);
        case ComposeTopicInteractionStatus.hasChosen:
          // The topic has likely been chosen.  Since topics are not mandatory,
          // show the default topic display name as if the user has entered that
          // when they left the input empty.
          if (emptyTopicsSupported) {
            hintText = store.realmEmptyTopicDisplayName;
            hintStyle = topicTextStyle.copyWith(fontStyle: FontStyle.italic);
          } else {
            hintText = kNoTopicTopic;
            hintStyle = topicTextStyle;
          }
      }
    }

    final decoration = InputDecoration(hintText: hintText, hintStyle: hintStyle);

    return TopicAutocomplete(
      streamId: widget.streamId,
      controller: widget.controller.topic,
      focusNode: widget.controller.topicFocusNode,
      contentFocusNode: widget.controller.contentFocusNode,
      fieldViewBuilder: (context) => Container(
        padding: const EdgeInsets.only(top: 10, bottom: 9),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(
          width: 1,
          color: designVariables.foreground.withFadedAlpha(0.2)))),
        child: TextField(
          controller: widget.controller.topic,
          focusNode: widget.controller.topicFocusNode,
          textInputAction: TextInputAction.next,
          style: topicTextStyle,
          decoration: decoration)));
  }
}

class _SavedSnippetTitleInput extends StatelessWidget {
  const _SavedSnippetTitleInput({required this.controller});

  final SavedSnippetComposeBoxController controller;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final titleTextStyle = TextStyle(
      fontSize: 20,
      height: 22 / 20,
      color: designVariables.textInput.withFadedAlpha(0.9),
    ).merge(weightVariableTextStyle(context, wght: 600));

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(
        width: 1,
        color: designVariables.foreground.withFadedAlpha(0.2)))),
      child: TextField(
        controller: controller.title,
        focusNode: controller.titleFocusNode,
        textInputAction: TextInputAction.next,
        style: titleTextStyle,
        decoration: InputDecoration(
          hintText: zulipLocalizations.newSavedSnippetTitleHint,
          hintStyle: titleTextStyle.copyWith(
            color: designVariables.textInput.withFadedAlpha(0.5)))));
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
          ?? zulipLocalizations.unknownChannelName;
        return zulipLocalizations.composeBoxChannelContentHint(
          // No i18n of this use of "#" and ">" string; those are part of how
          // Zulip expresses channels and topics, not any normal English punctuation,
          // so don't make sense to translate. See:
          //   https://github.com/zulip/zulip-flutter/pull/1148#discussion_r1941990585
          '#$streamName > ${topic.displayName ?? store.realmEmptyTopicDisplayName}');

      case DmNarrow(otherRecipientIds: []): // The self-1:1 thread.
        return zulipLocalizations.composeBoxSelfDmContentHint;

      case DmNarrow(otherRecipientIds: [final otherUserId]):
        final store = PerAccountStoreWidget.of(context);
        final fullName = store.getUser(otherUserId)?.fullName;
        if (fullName == null) return zulipLocalizations.composeBoxGenericContentHint;
        return zulipLocalizations.composeBoxDmContentHint(fullName);

      case DmNarrow(): // A group DM thread.
        return zulipLocalizations.composeBoxGroupDmContentHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TypingNotifier(
      destination: narrow,
      controller: controller,
      child: _ContentInput(
        narrow: narrow,
        controller: controller,
        hintText: _hintText(context)));
  }
}

class _EditMessageContentInput extends StatelessWidget {
  const _EditMessageContentInput({
    required this.narrow,
    required this.controller,
  });

  final Narrow narrow;
  final EditMessageComposeBoxController controller;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final awaitingRawContent = ComposeBoxInheritedWidget.of(context)
      .awaitingRawMessageContentForEdit;
    return _ContentInput(
      narrow: narrow,
      controller: controller,
      enabled: !awaitingRawContent,
      hintText: awaitingRawContent
        ? zulipLocalizations.preparingEditMessageContentInput
        : null,
    );
  }
}

class _SavedSnippetContentInput extends StatelessWidget {
  const _SavedSnippetContentInput({required this.controller});

  final SavedSnippetComposeBoxController controller;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return _ContentInput(
      narrow: null,
      controller: controller,
      hintText: zulipLocalizations.newSavedSnippetContentHint);
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
      .map((file) => zulipLocalizations.filenameAndSizeInMiB(
        file.filename, (file.length / (1 << 20)).toStringAsFixed(1)))
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

abstract class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.controller, required this.enabled});

  final ComposeBoxController controller;
  final bool enabled;

  IconData get icon;
  String tooltip(ZulipLocalizations zulipLocalizations);

  void handlePress(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    return SizedBox(
      width: _composeButtonSize,
      child: IconButton(
        icon: Icon(icon, color: designVariables.foreground.withFadedAlpha(0.5)),
        tooltip: tooltip(zulipLocalizations),
        onPressed: enabled ? () => handlePress(context) : null));
  }
}

abstract class _AttachUploadsButton extends _ComposeButton {
  const _AttachUploadsButton({required super.controller, required super.enabled});

  /// Request files from the user, in the way specific to this upload type.
  ///
  /// Subclasses should manage the interaction completely, e.g., by catching and
  /// handling any permissions-related exceptions.
  ///
  /// To signal exiting the interaction with no files chosen,
  /// return an empty [Iterable] after showing user feedback as appropriate.
  Future<Iterable<_File>> getFiles(BuildContext context);

  @override
  void handlePress(BuildContext context) async {
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
      final dialog = showSuggestedActionDialog(context: context,
        title: zulipLocalizations.permissionsNeededTitle,
        message: zulipLocalizations.permissionsDeniedReadExternalStorage,
        actionButtonText: zulipLocalizations.permissionsNeededOpenSettings);
      if (await dialog.result == true) {
        unawaited(AppSettings.openAppSettings());
      }
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
  const _AttachFileButton({required super.controller, required super.enabled});

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
  const _AttachMediaButton({required super.controller, required super.enabled});

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
  const _AttachFromCameraButton({required super.controller, required super.enabled});

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
        final dialog = showSuggestedActionDialog(context: context,
          title: zulipLocalizations.permissionsNeededTitle,
          message: zulipLocalizations.permissionsDeniedCameraAccess,
          actionButtonText: zulipLocalizations.permissionsNeededOpenSettings);
        if (await dialog.result == true) {
          unawaited(AppSettings.openAppSettings());
        }
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

class _ShowSavedSnippetsButton extends _ComposeButton {
  const _ShowSavedSnippetsButton({required super.controller, required super.enabled})
    : assert(controller is! SavedSnippetComposeBoxController);

  @override
  void handlePress(BuildContext context) {
    showSavedSnippetPickerSheet(context: context, controller: controller);
  }

  @override
  IconData get icon => ZulipIcons.message_square_text;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.composeBoxShowSavedSnippetsTooltip;
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

class _SavedSnipppetSaveButton extends StatefulWidget {
  const _SavedSnipppetSaveButton({required this.controller});

  final SavedSnippetComposeBoxController controller;

  @override
  State<_SavedSnipppetSaveButton> createState() => _SavedSnipppetSaveButtonState();
}

class _SavedSnipppetSaveButtonState extends State<_SavedSnipppetSaveButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.title.hasValidationErrors.addListener(_hasErrorsChanged);
    widget.controller.content.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void didUpdateWidget(covariant _SavedSnipppetSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = widget.controller;
    final oldController = oldWidget.controller;
    if (controller == oldController) return;

    oldController.title.hasValidationErrors.removeListener(_hasErrorsChanged);
    controller.title.hasValidationErrors.addListener(_hasErrorsChanged);
    oldController.content.hasValidationErrors.removeListener(_hasErrorsChanged);
    controller.content.hasValidationErrors.addListener(_hasErrorsChanged);
  }

  @override
  void dispose() {
    widget.controller.title.hasValidationErrors.removeListener(_hasErrorsChanged);
    widget.controller.content.hasValidationErrors.removeListener(_hasErrorsChanged);
    super.dispose();
  }

  void _hasErrorsChanged() {
   setState(() {
     // The actual state lives in widget.controller.
   });
  }

  void _save() async {
    if (widget.controller.title.hasValidationErrors.value
        || widget.controller.content.hasValidationErrors.value) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      final validationErrorMessages = [
        for (final error in widget.controller.title.validationErrors)
          error.message(zulipLocalizations),
        for (final error in widget.controller.content.validationErrors)
          error.messageForSavedSnippet(zulipLocalizations),
      ];
      showErrorDialog(context: context,
        title: zulipLocalizations.errorFailedToCreateSavedSnippetTitle,
        message: validationErrorMessages.join('\n\n'));
      return;
    }

    final store = PerAccountStoreWidget.of(context);
    try {
      // TODO(#1502) allow saving edits to an existing saved snippet as well
      await createSavedSnippet(store.connection,
        title: widget.controller.title.textNormalized,
        content: widget.controller.content.textNormalized);
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.message,
      };
      showErrorDialog(context: context,
        title: zulipLocalizations.errorFailedToCreateSavedSnippetTitle,
        message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return IconButton(onPressed: _save,
      icon: Icon(ZulipIcons.check, color:
        widget.controller.title.hasValidationErrors.value
        || widget.controller.content.hasValidationErrors.value
          ? designVariables.icon.withFadedAlpha(0.5) : designVariables.icon));
  }
}

class _ComposeBoxContainer extends StatelessWidget {
  const _ComposeBoxContainer({
    required this.body,
    this.banner,
  }) : assert(body != null || banner != null);

  /// The text inputs, compose-button row, and send button.
  ///
  /// This widget does not need a [SafeArea] to consume any device insets.
  ///
  /// Can be null, but only if [banner] is non-null.
  final Widget? body;

  /// A bar that goes at the top.
  ///
  /// This may be present on its own or with a [body].
  /// If [body] is null this must be present.
  ///
  /// This widget should use a [SafeArea] to pad the left, right,
  /// and bottom device insets.
  /// (A bottom inset may occur if [body] is null.)
  final Widget? banner;

  Widget _paddedBody() {
    assert(body != null);
    return SafeArea(minimum: const EdgeInsets.symmetric(horizontal: 8),
      child: body!);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final List<Widget> children = switch ((banner, body)) {
      (Widget(), Widget()) => [
        // _paddedBody() already pads the bottom inset,
        // so make sure the banner doesn't double-pad it.
        MediaQuery.removePadding(context: context, removeBottom: true,
          child: banner!),
        _paddedBody(),
      ],
      (Widget(),     null) => [banner!],
      (null,     Widget()) => [_paddedBody()],
      (null,         null) => throw UnimplementedError(), // not allowed, see dartdoc
    };

    // TODO(design): Maybe put a max width on the compose box, like we do on
    //   the message list itself; if so, remember to update ComposeBox's dartdoc.
    return Container(width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: designVariables.borderBar)),
        boxShadow: ComposeBoxTheme.of(context).boxShadow,
      ),
      // TODO(#720) try a Stack for the overlaid linear progress indicator
      child: Material(
        color: designVariables.composeBoxBg,
        child: Column(
          children: children)));
  }
}

/// The text inputs, compose-button row, and send button for the compose box.
abstract class _ComposeBoxBody extends StatelessWidget {
  ComposeBoxController get controller;

  Widget? buildTopicInput();
  Widget buildContentInput();
  bool getComposeButtonsEnabled(BuildContext context);
  Widget? buildSendButton();

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

    final composeButtonsEnabled = getComposeButtonsEnabled(context);
    final store = PerAccountStoreWidget.of(context);
    final composeButtons = [
      _AttachFileButton(controller: controller, enabled: composeButtonsEnabled),
      _AttachMediaButton(controller: controller, enabled: composeButtonsEnabled),
      _AttachFromCameraButton(controller: controller, enabled: composeButtonsEnabled),
      if (store.zulipFeatureLevel >= 297 // TODO(server-10) simplify
          && controller is! SavedSnippetComposeBoxController)
        _ShowSavedSnippetsButton(controller: controller, enabled: composeButtonsEnabled),
    ];

    final topicInput = buildTopicInput();
    final sendButton = buildSendButton();
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
              if (sendButton != null) sendButton,
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

  @override bool getComposeButtonsEnabled(BuildContext context) => true;

  @override Widget buildSendButton() => _SendButton(
    controller: controller,
    getDestination: () => StreamDestination(
      narrow.streamId, TopicName(controller.topic.textNormalized)),
  );
}

class _FixedDestinationComposeBoxBody extends _ComposeBoxBody {
  _FixedDestinationComposeBoxBody({required this.narrow, required this.controller});

  final SendableNarrow narrow;

  @override
  final FixedDestinationComposeBoxController controller;

  @override Widget? buildTopicInput() => null;

  @override Widget buildContentInput() => _FixedDestinationContentInput(
    narrow: narrow,
    controller: controller,
  );

  @override bool getComposeButtonsEnabled(BuildContext context) => true;

  @override Widget buildSendButton() => _SendButton(
    controller: controller,
    getDestination: () => narrow.destination,
  );
}

/// A compose box for editing an already-sent message.
class _EditMessageComposeBoxBody extends _ComposeBoxBody {
  _EditMessageComposeBoxBody({required this.narrow, required this.controller});

  final Narrow narrow;

  @override
  final EditMessageComposeBoxController controller;

  @override Widget? buildTopicInput() => null;

  @override Widget buildContentInput() => _EditMessageContentInput(
    narrow: narrow,
    controller: controller);

  @override bool getComposeButtonsEnabled(BuildContext context) =>
    !ComposeBoxInheritedWidget.of(context).awaitingRawMessageContentForEdit;

  @override Widget? buildSendButton() => null;
}

class _SavedSnippetComposeBoxBody extends _ComposeBoxBody {
  _SavedSnippetComposeBoxBody({required this.controller});

  @override
  final SavedSnippetComposeBoxController controller;

  @override Widget buildTopicInput() => _SavedSnippetTitleInput(
    controller: controller);

  @override Widget buildContentInput() => _SavedSnippetContentInput(
    controller: controller);

  @override bool getComposeButtonsEnabled(BuildContext context) => true;

  @override Widget? buildSendButton() => _SavedSnipppetSaveButton(
    controller: controller);
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
  StreamComposeBoxController({required PerAccountStore store})
    : topic = ComposeTopicController(store: store);

  final ComposeTopicController topic;
  final topicFocusNode = FocusNode();
  final ValueNotifier<ComposeTopicInteractionStatus> topicInteractionStatus =
    ValueNotifier(ComposeTopicInteractionStatus.notEditingNotChosen);

  @override
  void dispose() {
    topic.dispose();
    topicFocusNode.dispose();
    topicInteractionStatus.dispose();
    super.dispose();
  }
}

class FixedDestinationComposeBoxController extends ComposeBoxController {}

class EditMessageComposeBoxController extends ComposeBoxController {
  EditMessageComposeBoxController({
    required this.messageId,
    required this.originalRawContent,
    required String? initialText,
  }) : _content = ComposeContentController(
                    text: initialText,
                    // Editing to delete the content is a supported form of
                    // deletion: https://zulip.com/help/delete-a-message#delete-message-content
                    requireNotEmpty: false);

  factory EditMessageComposeBoxController.empty(int messageId) =>
    EditMessageComposeBoxController(messageId: messageId,
      originalRawContent: null, initialText: null);

  @override ComposeContentController get content => _content;
  final ComposeContentController _content;

  final int messageId;
  String? originalRawContent;
}

class SavedSnippetComposeBoxController extends ComposeBoxController {
  SavedSnippetComposeBoxController();

  final title = ComposeSavedSnippetTitleController();
  final titleFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    title.dispose();
    titleFocusNode.dispose();
  }
}

abstract class _Banner extends StatelessWidget {
  const _Banner();

  String getLabel(ZulipLocalizations zulipLocalizations);
  Color getLabelColor(DesignVariables designVariables);
  Color getBackgroundColor(DesignVariables designVariables);

  /// A trailing element, with vertical but not horizontal outer padding
  /// for spacing/positioning.
  ///
  /// An interactive element's touchable area should have height at least 44px,
  /// with some of that as "slop" vertical outer padding above and below
  /// what gets painted:
  ///   https://github.com/zulip/zulip-flutter/pull/1432#discussion_r2023907300
  ///
  /// To control the element's distance from the end edge, override [padEnd].
  Widget? buildTrailing(BuildContext context);

  /// Whether to apply `end: 8` in [SafeArea.minimum].
  ///
  /// Subclasses can use `false` when the [buildTrailing] element
  /// is meant to abut the edge of the screen
  /// in the common case that there are no horizontal device insets.
  bool get padEnd => true;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final labelTextStyle = TextStyle(
      fontSize: 17,
      height: 22 / 17,
      color: getLabelColor(designVariables),
    ).merge(weightVariableTextStyle(context, wght: 600));

    final trailing = buildTrailing(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: getBackgroundColor(designVariables)),
      child: SafeArea(
        minimum: EdgeInsetsDirectional.only(start: 8, end: padEnd ? 8 : 0)
          // (SafeArea.minimum doesn't take an EdgeInsetsDirectional)
          .resolve(Directionality.of(context)),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    style: labelTextStyle,
                    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5),
                    getLabel(zulipLocalizations)))),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ]))));
  }
}

class _ErrorBanner extends _Banner {
  const _ErrorBanner({
    required String Function(ZulipLocalizations) getLabel,
  }) : _getLabel = getLabel;

  @override
  String getLabel(ZulipLocalizations zulipLocalizations) =>
    _getLabel(zulipLocalizations);
  final String Function(ZulipLocalizations) _getLabel;

  @override
  Color getLabelColor(DesignVariables designVariables) =>
    designVariables.btnLabelAttMediumIntDanger;

  @override
  Color getBackgroundColor(DesignVariables designVariables) =>
    designVariables.bannerBgIntDanger;

  @override
  Widget? buildTrailing(context) {
    // TODO(#720) "x" button goes here.
    //   24px square with 8px touchable padding in all directions?
    //   and `bool get padEnd => false`; see Figma:
    //     https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=4031-17029&m=dev
    return null;
  }
}

class _EditMessageBanner extends _Banner {
  const _EditMessageBanner({required this.composeBoxState});

  final ComposeBoxState composeBoxState;

  @override
  String getLabel(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.composeBoxBannerLabelEditMessage;

  @override
  Color getLabelColor(DesignVariables designVariables) =>
    designVariables.bannerTextIntInfo;

  @override
  Color getBackgroundColor(DesignVariables designVariables) =>
    designVariables.bannerBgIntInfo;

  void _handleTapSave (BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final controller = composeBoxState.controller;
    if (controller is! EditMessageComposeBoxController) return; // TODO(log)
    final zulipLocalizations = ZulipLocalizations.of(context);

    if (controller.content.hasValidationErrors.value) {
      final validationErrorMessages =
        controller.content.validationErrors.map((error) =>
          error.message(zulipLocalizations));
      showErrorDialog(context: context,
        title: zulipLocalizations.errorMessageEditNotSaved,
        message: validationErrorMessages.join('\n\n'));
      return;
    }

    final originalRawContent = controller.originalRawContent;
    if (originalRawContent == null) {
      // Fetch-raw-content request hasn't finished; try again later.
      // TODO show error dialog?
      return;
    }

    store.editMessage(
      messageId: controller.messageId,
      originalRawContent: originalRawContent,
      newContent: controller.content.textNormalized);
    composeBoxState.endEditInteraction();
  }

  @override
  Widget buildTrailing(context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
      ZulipWebUiKitButton(label: zulipLocalizations.composeBoxBannerButtonCancel,
        onPressed: composeBoxState.endEditInteraction),
      // TODO(#1481) disabled appearance when there are validation errors
      //   or the original raw content hasn't loaded yet
      ZulipWebUiKitButton(label: zulipLocalizations.composeBoxBannerButtonSave,
        attention: ZulipWebUiKitButtonAttention.high,
        onPressed: () => _handleTapSave(context)),
    ]);
  }
}

/// The compose box.
///
/// Takes the full screen width, covering the horizontal insets with its surface.
/// Also covers the bottom inset with its surface.
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

  /// Switch the compose box to editing mode.
  ///
  /// If there is already text in the compose box, gives a confirmation dialog
  /// to confirm that it is OK to discard that text.
  ///
  /// If called from the message action sheet, fetches the raw message content
  /// to fill in the edit-message compose box.
  ///
  /// If called by tapping a message in the message list with 'EDIT NOT SAVED',
  /// fills the edit-message compose box with the content the user wanted
  /// in the edit request that failed.
  void startEditInteraction(int messageId);

  /// Switch the compose box back to regular non-edit mode, with no content.
  void endEditInteraction();
}

class _ComposeBoxState extends State<ComposeBox> with PerAccountStoreAwareStateMixin<ComposeBox> implements ComposeBoxState {
  @override ComposeBoxController get controller => _controller!;
  ComposeBoxController? _controller;

  @override
  void startEditInteraction(int messageId) async {
    if (await _abortBecauseContentInputNotEmpty()) return;
    if (!mounted) return;

    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    switch (store.getEditMessageErrorStatus(messageId)) {
      case null:
        _editFromRawContentFetch(messageId);
      case true:
        _editByRestoringFailedEdit(messageId);
      case false:
        // This can happen if you start an edit interaction on one
        // MessageListPage and then do an edit on a different MessageListPage,
        // and the second edit is still saving when you return to the first.
        //
        // Abort rather than sending a request with a prevContentSha256
        // that the server might not accept, and don't clear the compose
        // box, so the user can try again after the request settles.
        // TODO could write a test for this
        showErrorDialog(context: context,
          title: zulipLocalizations.editAlreadyInProgressTitle,
          message: zulipLocalizations.editAlreadyInProgressMessage);
        return;
    }
  }

  /// If there's text in the compose box, give a confirmation dialog
  /// asking if it can be discarded and await the result.
  Future<bool> _abortBecauseContentInputNotEmpty() async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    if (controller.content.textNormalized.isNotEmpty) {
      final dialog = showSuggestedActionDialog(context: context,
        title: zulipLocalizations.discardDraftConfirmationDialogTitle,
        message: zulipLocalizations.discardDraftConfirmationDialogMessage,
        // TODO(#1032) "destructive" style for action button
        actionButtonText: zulipLocalizations.discardDraftConfirmationDialogConfirmButton);
      if (await dialog.result != true) return true;
    }
    return false;
  }

  void _editByRestoringFailedEdit(int messageId) {
    final store = PerAccountStoreWidget.of(context);
    // Fill the content input with the content the user wanted in the failed
    // edit attempt, not the original content.
    // Side effect: Clears the "EDIT NOT SAVED" text in the message list.
    final failedEdit = store.takeFailedMessageEdit(messageId);
    setState(() {
      controller.dispose();
      _controller = EditMessageComposeBoxController(
        messageId: messageId,
        originalRawContent: failedEdit.originalRawContent,
        initialText: failedEdit.newContent,
      )
        ..contentFocusNode.requestFocus();
    });
  }

  void _editFromRawContentFetch(int messageId) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final emptyEditController = EditMessageComposeBoxController.empty(messageId);
    setState(() {
      controller.dispose();
      _controller = emptyEditController;
    });
    final fetchedRawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: context,
      messageId: messageId,
      errorDialogTitle: zulipLocalizations.errorCouldNotEditMessageTitle,
    );
    // TODO timeout this request?
    if (!mounted) return;
    if (!identical(controller, emptyEditController)) {
      // user tapped Cancel during the fetch-raw-content request
      // TODO in this case we don't want the error dialog caused by
      //   ZulipAction.fetchRawContentWithFeedback; suppress that
      return;
    }
    if (fetchedRawContent == null) {
      // Fetch-raw-content failed; abort the edit session.
      // An error dialog was already shown, by fetchRawContentWithFeedback.
      setState(() {
        controller.dispose();
        _setNewController(PerAccountStoreWidget.of(context));
      });
      return;
    }
    // TODO scroll message list to ensure the message is still in view;
    //   highlight it?
    assert(controller is EditMessageComposeBoxController);
    final editMessageController = controller as EditMessageComposeBoxController;
    setState(() {
      // setState to refresh the input, upload buttons, etc.
      // out of the disabled "Preparing…" state.
      editMessageController.originalRawContent = fetchedRawContent;
    });
    editMessageController.content.value = TextEditingValue(text: fetchedRawContent);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // post-frame callback so this happens after the input is enabled
      editMessageController.contentFocusNode.requestFocus();
    });
  }

  @override
  void endEditInteraction() {
    assert(controller is EditMessageComposeBoxController);
    if (controller is! EditMessageComposeBoxController) return; // TODO(log)

    final store = PerAccountStoreWidget.of(context);
    setState(() {
      controller.dispose();
      _setNewController(store);
    });
  }

  @override
  void onNewStore() {
    final newStore = PerAccountStoreWidget.of(context);

    final controller = _controller;
    if (controller == null) {
      _setNewController(newStore);
      return;
    }

    switch (controller) {
      case StreamComposeBoxController():
        controller.topic.store = newStore;
      case FixedDestinationComposeBoxController():
      case EditMessageComposeBoxController():
        // no reference to the store that needs updating
        break;
      case SavedSnippetComposeBoxController():
        throw StateError('unexpected controller type');
    }
  }

  void _setNewController(PerAccountStore store) {
    switch (widget.narrow) {
      case ChannelNarrow():
        _controller = StreamComposeBoxController(store: store);
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
    controller.dispose();
    super.dispose();
  }

  /// An [_ErrorBanner] that replaces the compose box's text inputs.
  Widget? _errorBannerComposingNotAllowed(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    switch (widget.narrow) {
      case ChannelNarrow(:final streamId):
      case TopicNarrow(:final streamId):
        final channel = store.streams[streamId];
        if (channel == null || !store.hasPostingPermission(inChannel: channel,
            user: store.selfUser, byDate: DateTime.now())) {
          return _ErrorBanner(getLabel: (zulipLocalizations) =>
            zulipLocalizations.errorBannerCannotPostInChannelLabel);
        }

      case DmNarrow(:final otherRecipientIds):
        final hasDeactivatedUser = otherRecipientIds.any((id) =>
          !(store.getUser(id)?.isActive ?? true));
        if (hasDeactivatedUser) {
          return _ErrorBanner(getLabel: (zulipLocalizations) =>
            zulipLocalizations.errorBannerDeactivatedDmLabel);
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
    final errorBanner = _errorBannerComposingNotAllowed(context);
    if (errorBanner != null) {
      return ComposeBoxInheritedWidget.fromComposeBoxState(this,
        child: _ComposeBoxContainer(body: null, banner: errorBanner));
    }

    final Widget? body;
    Widget? banner;

    final controller = this.controller;
    final narrow = widget.narrow;
    switch (controller) {
      case StreamComposeBoxController(): {
        narrow as ChannelNarrow;
        body = _StreamComposeBoxBody(controller: controller, narrow: narrow);
      }
      case FixedDestinationComposeBoxController(): {
        narrow as SendableNarrow;
        body = _FixedDestinationComposeBoxBody(controller: controller, narrow: narrow);
      }
      case EditMessageComposeBoxController(): {
        body = _EditMessageComposeBoxBody(controller: controller, narrow: narrow);
        banner = _EditMessageBanner(composeBoxState: this);
      }
      case SavedSnippetComposeBoxController():
        throw StateError('unexpected controller type');
    }

    // TODO(#720) dismissable message-send error, maybe something like:
    //     if (controller.sendMessageError.value != null) {
    //       errorBanner = _ErrorBanner(label:
    //         ZulipLocalizations.of(context).errorSendMessageTimeout);
    //     }
    return ComposeBoxInheritedWidget.fromComposeBoxState(this,
      child: _ComposeBoxContainer(body: body, banner: banner));
  }
}

/// An [InheritedWidget] to provide data to leafward [StatelessWidget]s,
/// such as flags that should cause the upload buttons to be disabled.
class ComposeBoxInheritedWidget extends InheritedWidget {
  factory ComposeBoxInheritedWidget.fromComposeBoxState(
    ComposeBoxState state, {
    required Widget child,
  }) {
    final controller = state.controller;
    return ComposeBoxInheritedWidget._(
      awaitingRawMessageContentForEdit:
        controller is EditMessageComposeBoxController
        && controller.originalRawContent == null,
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
    awaitingRawMessageContentForEdit != oldWidget.awaitingRawMessageContentForEdit;

  static ComposeBoxInheritedWidget of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ComposeBoxInheritedWidget>();
    assert(widget != null, 'No ComposeBoxInheritedWidget ancestor');
    return widget!;
  }
}

class SavedSnippetComposeBox extends StatefulWidget {
  const SavedSnippetComposeBox({super.key});

  @override
  State<SavedSnippetComposeBox> createState() => _SavedSnippetComposeBoxState();
}

class _SavedSnippetComposeBoxState extends State<SavedSnippetComposeBox> {
  // TODO: preserve the controller independent from this state
  late SavedSnippetComposeBoxController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SavedSnippetComposeBoxController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ComposeBoxContainer(
      body: _SavedSnippetComposeBoxBody(controller: _controller));
  }
}
