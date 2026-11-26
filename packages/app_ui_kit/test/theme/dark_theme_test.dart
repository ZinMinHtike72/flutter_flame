import "package:app_ui_kit/theme/dark_theme.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("dark theme uses a readable tint of the brand primary", () {
    final theme = DarkTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xff8FA2FF));
    expect(theme.primaryColor, theme.colorScheme.primary);
    expect(theme.scaffoldBackgroundColor, const Color(0xff151519));
    expect(theme.textTheme.bodyMedium?.fontFamily, "Poppins");
  });

  test("dark buttons and progress indicator follow the primary color", () {
    final theme = DarkTheme.dark();
    final elevated = theme.elevatedButtonTheme.style!;

    expect(
      elevated.backgroundColor?.resolve(<WidgetState>{}),
      theme.colorScheme.primary,
    );
    expect(
      elevated.foregroundColor?.resolve(<WidgetState>{}),
      theme.colorScheme.onPrimary,
    );
    expect(theme.progressIndicatorTheme.color, theme.colorScheme.primary);
  });
}
