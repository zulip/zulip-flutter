/// `package:checks`-related extensions for the Flutter framework.
import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

extension ClipboardDataChecks on Subject<ClipboardData> {
  Subject<String?> get text => has((d) => d.text, 'text');
}

extension GlobalKeyChecks<T extends State<StatefulWidget>> on Subject<GlobalKey<T>> {
  Subject<BuildContext?> get currentContext => has((k) => k.currentContext, 'currentContext');
  Subject<Widget?> get currentWidget => has((k) => k.currentWidget, 'currentWidget');
  Subject<T?> get currentState => has((k) => k.currentState, 'currentState');
}

extension ValueNotifierChecks<T> on Subject<ValueNotifier<T>> {
  Subject<T> get value => has((c) => c.value, 'value');
}

extension TextStyleChecks on Subject<TextStyle> {
  Subject<bool> get inherit => has((t) => t.inherit, 'inherit');
  Subject<List<FontVariation>?> get fontVariations => has((t) => t.fontVariations, 'fontVariations');
  Subject<FontWeight?> get fontWeight => has((t) => t.fontWeight, 'fontWeight');

  // TODO others
}
