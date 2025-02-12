/// `package:checks`-related extensions for the Flutter framework.
library;

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension PaintChecks on Subject<Paint> {
  Subject<Shader?> get shader => has((x) => x.shader, 'shader');
}

extension RectChecks on Subject<Rect> {
  Subject<double> get top => has((d) => d.top, 'top');
  Subject<double> get bottom => has((d) => d.bottom, 'bottom');

  // TODO others
}

extension AnimationChecks<T> on Subject<Animation<T>> {
  Subject<AnimationStatus> get status => has((d) => d.status, 'status');
  Subject<T> get value => has((d) => d.value, 'value');
}

extension ClipboardDataChecks on Subject<ClipboardData> {
  Subject<String?> get text => has((d) => d.text, 'text');
}

extension ColoredBoxChecks on Subject<ColoredBox> {
  Subject<Color?> get color => has((d) => d.color, 'color');
}

extension GlobalKeyChecks<T extends State<StatefulWidget>> on Subject<GlobalKey<T>> {
  Subject<BuildContext?> get currentContext => has((k) => k.currentContext, 'currentContext');
  Subject<Widget?> get currentWidget => has((k) => k.currentWidget, 'currentWidget');
  Subject<T?> get currentState => has((k) => k.currentState, 'currentState');
}

extension IconChecks on Subject<Icon> {
  Subject<IconData?> get icon => has((i) => i.icon, 'icon');
  Subject<Color?> get color => has((i) => i.color, 'color');

  // TODO others
}

extension RouteChecks<T> on Subject<Route<T>> {
  Subject<bool> get isFirst => has((r) => r.isFirst, 'isFirst');
  Subject<RouteSettings> get settings => has((r) => r.settings, 'settings');
}

extension PageRouteChecks<T> on Subject<PageRoute<T>> {
  Subject<bool> get fullscreenDialog => has((x) => x.fullscreenDialog, 'fullscreenDialog');
}

extension RouteSettingsChecks<T> on Subject<RouteSettings> {
  Subject<String?> get name => has((s) => s.name, 'name');
  Subject<Object?> get arguments => has((s) => s.arguments, 'arguments');
}

extension ValueListenableChecks<T> on Subject<ValueListenable<T>> {
  Subject<T> get value => has((c) => c.value, 'value');
}

extension TextChecks on Subject<Text> {
  Subject<String?> get data => has((t) => t.data, 'data');
  Subject<TextStyle?> get style => has((t) => t.style, 'style');
}

extension TextEditingValueChecks on Subject<TextEditingValue> {
  Subject<String> get text => has((x) => x.text, 'text');
  Subject<TextSelection> get selection => has((x) => x.selection, 'selection');
  Subject<TextRange> get composing => has((x) => x.composing, 'composing');
}

extension TextEditingControllerChecks on Subject<TextEditingController> {
  Subject<String?> get text => has((t) => t.text, 'text');
}

extension TextFieldChecks on Subject<TextField> {
  Subject<TextCapitalization?> get textCapitalization => has((t) => t.textCapitalization, 'textCapitalization');
  Subject<InputDecoration?> get decoration => has((t) => t.decoration, 'decoration');
  Subject<TextEditingController?> get controller => has((t) => t.controller, 'controller');
}

extension TextStyleChecks on Subject<TextStyle> {
  Subject<bool> get inherit => has((t) => t.inherit, 'inherit');
  Subject<Color?> get color => has((t) => t.color, 'color');
  Subject<double?> get fontSize => has((t) => t.fontSize, 'fontSize');
  Subject<FontWeight?> get fontWeight => has((t) => t.fontWeight, 'fontWeight');
  Subject<double?> get letterSpacing => has((t) => t.letterSpacing, 'letterSpacing');
  Subject<List<FontVariation>?> get fontVariations => has((t) => t.fontVariations, 'fontVariations');
  Subject<String?> get fontFamily => has((t) => t.fontFamily, 'fontFamily');
  Subject<List<String>?> get fontFamilyFallback => has((t) => t.fontFamilyFallback, 'fontFamilyFallback');

  // TODO others
}

extension FontVariationChecks on Subject<FontVariation> {
  Subject<String> get axis => has((x) => x.axis, 'axis');
  Subject<double> get value => has((x) => x.value, 'value');
}

extension TextThemeChecks on Subject<TextTheme> {
  Subject<TextStyle?> get displayLarge => has((t) => t.displayLarge, 'displayLarge');
  Subject<TextStyle?> get displayMedium => has((t) => t.displayMedium, 'displayMedium');
  Subject<TextStyle?> get displaySmall => has((t) => t.displaySmall, 'displaySmall');
  Subject<TextStyle?> get headlineLarge => has((t) => t.headlineLarge, 'headlineLarge');
  Subject<TextStyle?> get headlineMedium => has((t) => t.headlineMedium, 'headlineMedium');
  Subject<TextStyle?> get headlineSmall => has((t) => t.headlineSmall, 'headlineSmall');
  Subject<TextStyle?> get titleLarge => has((t) => t.titleLarge, 'titleLarge');
  Subject<TextStyle?> get titleMedium => has((t) => t.titleMedium, 'titleMedium');
  Subject<TextStyle?> get titleSmall => has((t) => t.titleSmall, 'titleSmall');
  Subject<TextStyle?> get bodyLarge => has((t) => t.bodyLarge, 'bodyLarge');
  Subject<TextStyle?> get bodyMedium => has((t) => t.bodyMedium, 'bodyMedium');
  Subject<TextStyle?> get bodySmall => has((t) => t.bodySmall, 'bodySmall');
  Subject<TextStyle?> get labelLarge => has((t) => t.labelLarge, 'labelLarge');
  Subject<TextStyle?> get labelMedium => has((t) => t.labelMedium, 'labelMedium');
  Subject<TextStyle?> get labelSmall => has((t) => t.labelSmall, 'labelSmall');
}

extension TypographyChecks on Subject<Typography> {
  Subject<TextTheme> get black => has((t) => t.black, 'black');
  Subject<TextTheme> get white => has((t) => t.white, 'white');
  Subject<TextTheme> get englishLike => has((t) => t.englishLike, 'englishLike');
  Subject<TextTheme> get dense => has((t) => t.dense, 'dense');
  Subject<TextTheme> get tall => has((t) => t.tall, 'tall');
}

extension InlineSpanChecks on Subject<InlineSpan> {
  Subject<TextStyle?> get style => has((x) => x.style, 'style');
}

extension SizeChecks on Subject<Size> {
  Subject<double> get width => has((x) => x.width, 'width');
  Subject<double> get height => has((x) => x.height, 'height');
}

extension ElementChecks on Subject<Element> {
  Subject<Size?> get size => has((t) => t.size, 'size');
  // TODO more
}

extension MediaQueryDataChecks on Subject<MediaQueryData> {
  Subject<TextScaler> get textScaler => has((x) => x.textScaler, 'textScaler');
  // TODO more
}

extension MaterialChecks on Subject<Material> {
  Subject<Color?> get color => has((x) => x.color, 'color');
  // TODO more
}

extension InputDecorationChecks on Subject<InputDecoration> {
  Subject<String?> get hintText => has((x) => x.hintText, 'hintText');
}

extension BoxDecorationChecks on Subject<BoxDecoration> {
  Subject<Color?> get color => has((x) => x.color, 'color');
}

extension TableRowChecks on Subject<TableRow> {
  Subject<Decoration?> get decoration => has((x) => x.decoration, 'decoration');
}

extension TableChecks on Subject<Table> {
  Subject<List<TableRow>> get children => has((x) => x.children, 'children');
}

extension IconButtonChecks on Subject<IconButton> {
  Subject<bool?> get isSelected => has((x) => x.isSelected, 'isSelected');
}
