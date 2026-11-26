import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: LightTheme.light(),
    home: AppScaffold(
      body: Center(child: SizedBox(width: 300, child: child)),
    ),
  );

  double scaleOf(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(AppPressable),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets("pressable dips while held and springs back on release", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppPressable(
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(height: 60, child: Text("press")),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("press")),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets("disabled pressable stays still", (tester) async {
    await tester.pumpWidget(
      host(
        const AppPressable(
          enabled: false,
          child: SizedBox(height: 60, child: Text("press")),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("press")),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), 1);
    await gesture.up();
  });

  testWidgets("primary and secondary buttons share one height", (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            AppGradientButton(onPressed: () {}, child: const Text("Primary")),
            AppOutlinedButton(onPressed: () {}, child: const Text("Second")),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AppGradientButton)).height,
      tester.getSize(find.byType(OutlinedButton)).height,
    );
    expect(tester.getSize(find.byType(OutlinedButton)).height, appButtonHeight);
  });

  testWidgets("destructive tone paints with the error colour", (tester) async {
    await tester.pumpWidget(
      host(
        AppGradientButton(
          tone: AppButtonTone.destructive,
          onPressed: () {},
          child: const Text("Sign out"),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AppGradientButton),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, LightTheme.light().colorScheme.error);
  });
}
