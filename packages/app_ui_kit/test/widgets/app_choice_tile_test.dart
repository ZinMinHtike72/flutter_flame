import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("preference choice shows its icon, detail and selection", (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: AppChoiceTile(
            label: "Light theme",
            subtitle: "Use a light appearance",
            icon: AppIcons.sun,
            selected: true,
            onPressed: () => taps.add("light"),
          ),
        ),
      ),
    );
    expect(find.byIcon(AppIcons.sun), findsOneWidget);
    expect(find.text("Use a light appearance"), findsOneWidget);
    await tester.tap(find.text("Light theme"));
    expect(taps, ["light"]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("disabled preference choice respects reduced motion", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DarkTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const AppScaffold(
          body: AppChoiceTile(
            label: "Unavailable theme",
            selected: false,
            onPressed: null,
          ),
        ),
      ),
    );
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });
}
