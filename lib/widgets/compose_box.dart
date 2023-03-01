import 'package:flutter/material.dart';
import 'dialog.dart';

import 'app.dart';
import '../api/route/messages.dart';

const double _inputVerticalPadding = 8;
const double _sendButtonSize = 35;

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
  tooLong;

  // Later: upload in progress; quote-and-reply in progress

  String message() {
    switch (this) {
      case ContentValidationError.tooLong:
        return "Message length shouldn't be greater than 10000 characters.";
      case ContentValidationError.empty:
        return 'You have nothing to send!';
    }
  }
}

class ContentTextEditingController extends TextEditingController {
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
    ];
  }
}

/// The content input for StreamComposeBox.
class _StreamContentInput extends StatefulWidget {
  const _StreamContentInput({required this.controller, required this.topicController});

  final ContentTextEditingController controller;
  final TopicTextEditingController topicController;

  @override
  State<_StreamContentInput> createState() => _StreamContentInputState();
}

class _StreamContentInputState extends State<_StreamContentInput> {
  late String _topicTextNormalized;

  _topicValueChanged() {
    setState(() {
      _topicTextNormalized = widget.topicController.textNormalized();
    });
  }

  @override
  void initState() {
    super.initState();
    _topicTextNormalized = widget.topicController.textNormalized();
    widget.topicController.addListener(_topicValueChanged);
  }

  @override
  void dispose() {
    widget.topicController.removeListener(_topicValueChanged);
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

  _topicValueChanged() {
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

  _contentValueChanged() {
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
    widget.topicController.addListener(_topicValueChanged);
    widget.contentController.addListener(_contentValueChanged);
  }

  @override
  void dispose() {
    widget.topicController.removeListener(_topicValueChanged);
    widget.contentController.removeListener(_contentValueChanged);
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

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
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
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Theme(
                    data: inputThemeData,
                    child: Column(
                        children: [
                          topicInput,
                          const SizedBox(height: 8),
                          _StreamContentInput(topicController: _topicController, controller: _contentController),
                        ]))),
              const SizedBox(width: 8),
              _StreamSendButton(topicController: _topicController, contentController: _contentController),
            ]))));
  }
}
