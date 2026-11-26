import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: LightTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: AppScaffold(body: Center(child: child)),
    ),
  );

  double dx(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(AppShake),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getTranslation()
      .x;

  testWidgets("shake moves its child only after the trigger changes", (
    tester,
  ) async {
    await tester.pumpWidget(host(const AppShake(trigger: 0, child: Text("x"))));
    expect(dx(tester), 0);

    await tester.pumpWidget(host(const AppShake(trigger: 1, child: Text("x"))));
    await tester.pump(const Duration(milliseconds: 40));
    expect(dx(tester), isNot(0));

    await tester.pumpAndSettle();
    expect(dx(tester), closeTo(0, 0.001));
  });

  testWidgets("shake stays still with reduced motion", (tester) async {
    await tester.pumpWidget(
      host(const AppShake(trigger: 0, child: Text("x")), reduceMotion: true),
    );
    await tester.pumpWidget(
      host(const AppShake(trigger: 1, child: Text("x")), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(dx(tester), 0);
  });

  testWidgets("aurora, float and glass render their child and settle with "
      "reduced motion", (tester) async {
    await tester.pumpWidget(
      host(
        const AppAuroraBackground(
          child: AppFloat(child: AppGlassSurface(child: Text("content"))),
        ),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("content"), findsOneWidget);
  });

  testWidgets("aurora and float keep animating with motion enabled", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppAuroraBackground(child: AppFloat(child: Text("content")))),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.hasRunningAnimations, isTrue);
    expect(find.text("content"), findsOneWidget);
  });

  testWidgets("glass surface renders in dark mode", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DarkTheme.dark(),
        home: const AppScaffold(body: AppGlassSurface(child: Text("dark"))),
      ),
    );

    expect(find.text("dark"), findsOneWidget);
  });
}
