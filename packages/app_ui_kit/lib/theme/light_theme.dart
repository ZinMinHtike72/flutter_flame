import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

/// The application's shared Poppins-based light theme.
// ignore: avoid_classes_with_only_static_members
class LightTheme {
  /// Creates the theme namespace.
  LightTheme();

  /// Brand primary color shared by the light and dark themes.
  static const Color brandPrimary = Color(0xff2F54E9);

  static const Color _neutralGrey = Color(0xff999999);

  /// Returns the owner's light palette and component styling.
  static ThemeData light() {
    return ThemeData(
      extensions: const [AppColorsExtension.light],
      scaffoldBackgroundColor: Colors.white,
      primaryColor: brandPrimary,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          color: Colors.black,
          height: 1.15,
          letterSpacing: -0.35,
        ),
        displayMedium: TextStyle(
          fontSize: 47,
          color: Colors.black,
          height: 1.15,
          letterSpacing: -0.35,
        ),
        displaySmall: TextStyle(
          fontSize: 46,
          color: Colors.black,
          height: 1.15,
          letterSpacing: -0.35,
        ),
        headlineLarge: TextStyle(
          fontSize: 42,
          color: Colors.black,
          height: 1.2,
          letterSpacing: -0.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 35,
          color: Colors.black,
          height: 1.2,
          letterSpacing: -0.35,
        ),
        headlineSmall: TextStyle(
          fontSize: 29,
          color: Colors.black,
          height: 1.2,
          letterSpacing: -0.35,
        ),
        titleLarge: TextStyle(fontSize: 24, color: Colors.black, height: 1.3),
        titleMedium: TextStyle(fontSize: 20, color: Colors.black, height: 1.3),
        titleSmall: TextStyle(fontSize: 16, color: Colors.black, height: 1.3),
        bodyLarge: TextStyle(fontSize: 14, color: Colors.black, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, color: Colors.black, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: Colors.black, height: 1.5),
        labelLarge: TextStyle(fontSize: 11, color: Colors.black, height: 1.5),
        labelMedium: TextStyle(fontSize: 10, color: Colors.black, height: 1.5),
        labelSmall: TextStyle(fontSize: 9, color: Colors.black, height: 1.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        shadowColor: Colors.black54,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        onPrimary: const Color(0xffF9FAFB),
        secondary: _neutralGrey,
        tertiary: const Color(0xffFFFFFF),
        outline: const Color(0xff819BF4),
        outlineVariant: const Color(0xff3068FA),
        surfaceTint: Colors.transparent,
      ),
      fontFamily: "Poppins",
      fontFamilyFallback: const ["NotoSansMyanmar"],
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _neutralGrey, width: 1.6),
        ),
        errorMaxLines: 2,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _neutralGrey, width: 2.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _neutralGrey, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(130, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          foregroundColor: Colors.white,
          backgroundColor: brandPrimary,
          disabledForegroundColor: const Color(0xffC2CFFB),
          disabledBackgroundColor: const Color(0xffEFF3FF),
          textStyle: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(130, 45),
          textStyle: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
