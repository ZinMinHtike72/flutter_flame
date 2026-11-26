import "package:app_ui_kit/theme/light_theme.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("light theme uses the requested brand, typography and background", () {
    final theme = LightTheme.light();

    expect(theme.primaryColor, const Color(0xff2F54E9));
    expect(theme.colorScheme.primary, const Color(0xff2F54E9));
    expect(theme.textTheme.bodyMedium?.fontFamily, "Poppins");
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.textTheme.bodyMedium?.fontSize, 13);
    expect(theme.inputDecorationTheme.errorMaxLines, 2);
  });

  test("input outlines are neutral grey and error outlines stay red", () {
    final theme = LightTheme.light();
    final decoration = theme.inputDecorationTheme;
    const grey = Color(0xff999999);
    final normalBorders = [
      (border: decoration.enabledBorder, width: 1.6),
      (border: decoration.focusedBorder, width: 2.0),
      (border: decoration.disabledBorder, width: 1.6),
    ];

    expect(theme.colorScheme.secondary, grey);
    for (final configuration in normalBorders) {
      expect(configuration.border, isA<OutlineInputBorder>());
      final border = configuration.border! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(10));
      expect(border.borderSide.color, grey);
      expect(border.borderSide.color, theme.colorScheme.secondary);
      expect(border.borderSide.width, configuration.width);
    }
    for (final inputBorder in [
      decoration.errorBorder,
      decoration.focusedErrorBorder,
    ]) {
      expect(inputBorder, isA<OutlineInputBorder>());
      final border = inputBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(10));
      expect(border.borderSide.color, Colors.redAccent);
      expect(border.borderSide.width, 1.6);
    }
  });
}
