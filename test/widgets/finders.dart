import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Like `find.text` from flutter_test upstream, but with
/// the `includePlaceholders` option.
///
/// When `includePlaceholders` is true, any [PlaceholderSpan] (for example,
/// any [WidgetSpan]) in the tree will be represented as
/// an "object replacement character", U+FFFC.
/// When `includePlaceholders` is false, such spans will be omitted.
///
/// TODO(upstream): get `find.text` to accept includePlaceholders
Finder findText(String text, {
  bool findRichText = false,
  bool includePlaceholders = true,
  bool skipOffstage = true,
}) {
  return _TextWidgetFinder(text,
    findRichText: findRichText,
    includePlaceholders: includePlaceholders,
    skipOffstage: skipOffstage);
}

// (Compare the implementation in `package:flutter_test/src/finders.dart`.)
abstract class _MatchTextFinder extends MatchFinder {
  _MatchTextFinder({this.findRichText = false, this.includePlaceholders = true,
    super.skipOffstage});

  /// Whether standalone [RichText] widgets should be found or not.
  ///
  /// Defaults to `false`.
  ///
  /// If disabled, only [Text] widgets will be matched. [RichText] widgets
  /// *without* a [Text] ancestor will be ignored.
  /// If enabled, only [RichText] widgets will be matched. This *implicitly*
  /// matches [Text] widgets as well since they always insert a [RichText]
  /// child.
  ///
  /// In either case, [EditableText] widgets will also be matched.
  final bool findRichText;

  final bool includePlaceholders;

  bool matchesText(String textToMatch);

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    if (widget is EditableText) {
      return _matchesEditableText(widget);
    }

    if (!findRichText) {
      return _matchesNonRichText(widget);
    }
    // It would be sufficient to always use _matchesRichText if we wanted to
    // match both standalone RichText widgets as well as Text widgets. However,
    // the find.text() finder used to always ignore standalone RichText widgets,
    // which is why we need the _matchesNonRichText method in order to not be
    // backwards-compatible and not break existing tests.
    return _matchesRichText(widget);
  }

  bool _matchesRichText(Widget widget) {
    if (widget is RichText) {
      return matchesText(widget.text.toPlainText(
        includePlaceholders: includePlaceholders));
    }
    return false;
  }

  bool _matchesNonRichText(Widget widget) {
    if (widget is Text) {
      if (widget.data != null) {
        return matchesText(widget.data!);
      }
      assert(widget.textSpan != null);
      return matchesText(widget.textSpan!.toPlainText(
        includePlaceholders: includePlaceholders));
    }
    return false;
  }

  bool _matchesEditableText(EditableText widget) {
    return matchesText(widget.controller.text);
  }
}

class _TextWidgetFinder extends _MatchTextFinder {
  _TextWidgetFinder(this.text, {super.findRichText, super.includePlaceholders,
    super.skipOffstage});

  final String text;

  @override
  String get description => 'text "$text"';

  @override
  bool matchesText(String textToMatch) {
    return textToMatch == text;
  }
}
