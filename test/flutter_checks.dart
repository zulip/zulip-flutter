/// `package:checks`-related extensions for the Flutter framework.
library;


import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Subject<RouteSettings> get settings => has((r) => r.settings, 'settings');
}

extension RouteSettingsChecks<T> on Subject<RouteSettings> {
  Subject<String?> get name => has((s) => s.name, 'name');
  Subject<Object?> get arguments => has((s) => s.arguments, 'arguments');
}

extension ValueNotifierChecks<T> on Subject<ValueNotifier<T>> {
  Subject<T> get value => has((c) => c.value, 'value');
}

extension TextChecks on Subject<Text> {
  Subject<String?> get data => has((t) => t.data, 'data');
}

extension TextFieldChecks on Subject<TextField> {
  Subject<TextCapitalization?> get textCapitalization => has((t) => t.textCapitalization, 'textCapitalization');
}

extension TextStyleChecks on Subject<TextStyle> {
  Subject<bool> get inherit => has((t) => t.inherit, 'inherit');
  Subject<FontWeight?> get fontWeight => has((t) => t.fontWeight, 'fontWeight');
  Subject<List<FontVariation>?> get fontVariations => has((t) => t.fontVariations, 'fontVariations');
  Subject<String?> get fontFamily => has((t) => t.fontFamily, 'fontFamily');
  Subject<List<String>?> get fontFamilyFallback => has((t) => t.fontFamilyFallback, 'fontFamilyFallback');

  // TODO others
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
