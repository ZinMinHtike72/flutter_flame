import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/light_theme.dart";
import "package:flutter/material.dart";

/// Dark appearance retaining the shared Poppins scale and brand identity.
abstract final class DarkTheme {
  static ThemeData dark() {
    final light = LightTheme.light();
    final colors = ColorScheme.fromSeed(
      seedColor: LightTheme.brandPrimary,
      brightness: Brightness.dark,
      primary: const Color(0xff8FA2FF),
      surface: const Color(0xff151519),
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      extensions: const [AppColorsExtension.dark],
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      primaryColor: colors.primary,
      fontFamily: "Poppins",
      fontFamilyFallback: const ["NotoSansMyanmar"],
      textTheme: light.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: colors.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: TextStyle(fontSize: 16, color: colors.onPrimary),
          minimumSize: const Size(130, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: TextStyle(fontSize: 16, color: colors.primary),
          minimumSize: const Size(130, 48),
        ),
      ),
    );
  }
}
