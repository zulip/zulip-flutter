/// `package:checks`-related extensions for the Flutter framework.
library;

import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

extension TextStyleChecks on Subject<TextStyle> {
  Subject<bool> get inherit => has((t) => t.inherit, 'inherit');
  Subject<List<FontVariation>?> get fontVariations => has((t) => t.fontVariations, 'fontVariations');
  Subject<FontWeight?> get fontWeight => has((t) => t.fontWeight, 'fontWeight');

  // TODO others
}
