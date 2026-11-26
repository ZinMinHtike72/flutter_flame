import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("shell passes its body, color and keyboard policy", (
    tester,
  ) async {
    const body = Text("content");
    for (final defaults in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: LightTheme.light(),
          home: defaults
              ? const AppScaffold(body: body)
              : const AppScaffold(
                  backgroundColor: Colors.red,
                  resizeToAvoidBottomInset: false,
                  body: body,
                ),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
      final shell = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(shell.body, same(body));
      expect(shell.backgroundColor, defaults ? null : Colors.red);
      expect(shell.resizeToAvoidBottomInset, defaults);
    }
  });
  testWidgets("icon action passes semantics, color and disabled state", (
    tester,
  ) async {
    int taps = 0;
    for (final enabled in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: LightTheme.light(),
          home: AppScaffold(
            body: AppIconButton(
              icon: AppIcons.visibility,
              tooltip: "Show password",
              color: Colors.red,
              onPressed: enabled ? () => taps++ : null,
            ),
          ),
        ),
      );
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, "Show password");
      expect(button.color, Colors.red);
      expect((button.icon as Icon).icon, AppIcons.visibility);
      expect(button.onPressed != null, enabled);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(taps, 1);
    }
  });
  testWidgets("indicator passes size, stroke, color and announcement", (
    tester,
  ) async {
    for (final defaults in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            body: defaults
                ? const AppLoadingIndicator()
                : const AppLoadingIndicator(
                    size: 28,
                    strokeWidth: 3,
                    color: Colors.red,
                    semanticsLabel: "Signing in",
                  ),
          ),
        ),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, defaults ? 20 : 28);
      expect(box.height, defaults ? 20 : 28);
      expect(indicator.strokeWidth, defaults ? 2 : 3);
      expect(indicator.color, defaults ? null : Colors.red);
      expect(indicator.semanticsLabel, defaults ? null : "Signing in");
      await tester.pump();
    }
  });
  test("glyphs and spacing are publicly exported", () {
    expect(AppIcons.person, Icons.person_outline);
    expect(AppIcons.lock, Icons.lock_outline);
    expect(AppIcons.visibility, Icons.visibility_outlined);
    expect(AppIcons.visibilityOff, Icons.visibility_off_outlined);
    expect(AppIcons.error, Icons.error_outline);
    expect(
      [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ],
      [4.0, 8.0, 16.0, 24.0, 32.0],
    );
  });
}
