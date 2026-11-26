import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("gradient action accepts taps and exposes disabled progress", (
    tester,
  ) async {
    int taps = 0;
    Future<void> render({double? progress}) => tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: AppGradientButton(
                onPressed: progress == null ? () => taps++ : null,
                progress: progress,
                child: const Text("Sign in"),
              ),
            ),
          ),
        ),
      ),
    );
    await render();
    await tester.tap(find.text("Sign in"));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(AppGradientButton)).height,
      greaterThanOrEqualTo(48),
    );
    await render(progress: 0.42);
    await tester.tap(find.text("Sign in"));
    expect(taps, 1);
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.42);
    expect(tester.takeException(), isNull);
  });

  testWidgets("narrow content stays centered", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: const AppScaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: AppGradientButton(
                onPressed: null,
                progress: 1,
                child: SizedBox.square(dimension: 20),
              ),
            ),
          ),
        ),
      ),
    );

    final content = find.descendant(
      of: find.byType(AppGradientButton),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 20,
      ),
    );
    expect(
      tester.getCenter(content).dx,
      closeTo(tester.getCenter(find.byType(AppGradientButton)).dx, 0.5),
    );
  });
}
