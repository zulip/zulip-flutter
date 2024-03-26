import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/app.dart';

void main() {
  test(
    'Test letterSpacing value from ThemeData for button and then returning 0.01',
    () {
      final app = MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            extendedTextStyle: TextStyle(
              letterSpacing: 0.01,
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          menuButtonTheme: MenuButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              textStyle: MaterialStateProperty.all<TextStyle>(
                const TextStyle(
                  letterSpacing: 0.01,
                ),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: const ZulipApp(),
      );

      final themeData = app.theme;

      final letterSpacing =
          extractLetterSpacing(themeData?.elevatedButtonTheme.style);
      expect(letterSpacing, 0.01);

      final letterSpacing2 =
          extractLetterSpacing(themeData?.outlinedButtonTheme.style);
      expect(letterSpacing2, 0.01);

      final letterSpacing3 =
          extractLetterSpacing(themeData?.textButtonTheme.style);
      expect(letterSpacing3, 0.01);

      final letterSpacing4 =
          extractLetterSpacing(themeData?.filledButtonTheme.style);
      expect(letterSpacing4, 0.01);

      final letterSpacing5 =
          themeData?.floatingActionButtonTheme.extendedTextStyle!.letterSpacing;
      expect(letterSpacing5, 0.01);

      final letterSpacing6 =
          extractLetterSpacing(themeData?.iconButtonTheme.style);
      expect(letterSpacing6, 0.01);

      final letterSpacing7 =
          extractLetterSpacing(themeData?.menuButtonTheme.style);
      expect(letterSpacing7, 0.01);

      final letterSpacing8 =
          extractLetterSpacing(themeData?.segmentedButtonTheme.style);
      expect(letterSpacing8, 0.01);
    },
  );
}

double extractLetterSpacing(ButtonStyle? style) {
  return style?.textStyle?.resolve({})?.letterSpacing ?? 0.0;
}
