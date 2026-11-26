import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const items = [
    AppNavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: "Home",
    ),
    AppNavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: "Profile",
    ),
  ];

  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? LightTheme.light(),
    home: AppScaffold(body: Center(child: child)),
  );

  testWidgets("glass bar reports taps and marks the selected destination", (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      host(
        AppGlassNavigationBar(
          items: items,
          selectedIndex: 0,
          onSelected: taps.add,
        ),
      ),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel("Home")),
      matchesSemantics(
        label: "Home",
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
      ),
    );

    await tester.tap(find.text("Profile"));
    await tester.tap(find.text("Home"));
    expect(taps, [1, 0]);
  });

  testWidgets("glass bar colours the selected label primary, others faint", (
    tester,
  ) async {
    final theme = LightTheme.light();
    await tester.pumpWidget(
      host(
        AppGlassNavigationBar(
          items: items,
          selectedIndex: 1,
          onSelected: (_) {},
        ),
        theme: theme,
      ),
    );
    await tester.pumpAndSettle();

    Text label(String text) => tester.widget<Text>(find.text(text));
    expect(label("Profile").style?.color, theme.colorScheme.primary);
    expect(label("Profile").style?.fontWeight, FontWeight.w600);
    expect(label("Home").style?.color, AppColorsExtension.light.textFaint);
  });

  testWidgets("fade through replays only when its trigger changes", (
    tester,
  ) async {
    Future<void> show(int trigger) => tester.pumpWidget(
      host(AppFadeThrough(trigger: trigger, child: const Text("tab"))),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: find.text("tab"), matching: find.byType(Opacity)),
        )
        .opacity;

    await show(0);
    expect(opacity(), 1);

    await show(1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(opacity(), lessThan(1));

    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  test("avatar initials are Unicode-safe and capped at two", () {
    expect(AppAvatar.initialsOf("Zin Min Htike"), "ZM");
    expect(AppAvatar.initialsOf("  aung  "), "A");
    expect(AppAvatar.initialsOf(""), "");
    expect(AppAvatar.initialsOf("မောင် မောင်"), "မေမေ");
  });

  testWidgets("avatar shows initials and settles with reduced motion", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: AppAvatar(name: "Aung Kyaw", showRing: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("AK"), findsOneWidget);
  });

  testWidgets("success snackbar shows its message", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  AppSnackBar.showSuccess(context, message: "Copied"),
              child: const Text("copy"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("copy"));
    await tester.pump();

    expect(find.text("Copied"), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets("bottom sheet surface follows a live theme change", (
    tester,
  ) async {
    final mode = ValueNotifier(ThemeMode.light);
    addTearDown(mode.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (context, value, _) => MaterialApp(
          theme: LightTheme.light(),
          darkTheme: DarkTheme.dark(),
          themeMode: value,
          home: AppScaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppBottomSheet.show<void>(
                  context: context,
                  builder: (_) => const Text("sheet"),
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    Color sheetColor() => tester
        .widget<Material>(
          find
              .ancestor(of: find.text("sheet"), matching: find.byType(Material))
              .first,
        )
        .color!;

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(sheetColor(), LightTheme.light().colorScheme.surface);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(sheetColor(), DarkTheme.dark().colorScheme.surface);
  });
}
