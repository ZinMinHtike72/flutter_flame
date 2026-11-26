import "dart:ui" show Tristate;

import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host(Widget child, {bool reduceMotion = false, ThemeData? theme}) =>
      MaterialApp(
        theme: theme ?? LightTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: AppScaffold(body: Center(child: child)),
        ),
      );

  String whole(double value) => value.round().toString();

  testWidgets("count up rises from zero to the value", (tester) async {
    await tester.pumpWidget(host(AppCountUp(value: 1000, format: whole)));

    expect(find.text("0"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("0"), findsNothing);
    expect(find.text("1000"), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text("1000"), findsOneWidget);
    expect(find.bySemanticsLabel("1000"), findsOneWidget);
  });

  testWidgets("count up shows the value at once with reduced motion", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(AppCountUp(value: 42, format: whole), reduceMotion: true),
    );
    await tester.pump();

    expect(find.text("42"), findsOneWidget);
  });

  testWidgets("progress ring sweeps to its clamped value", (tester) async {
    await tester.pumpWidget(
      host(const AppProgressRing(value: 1.4, child: Text("99"))),
    );
    await tester.pumpAndSettle();

    final arcs = tester
        .widgetList<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        )
        .map((indicator) => indicator.value)
        .toList();
    expect(arcs, [1, 1]);
    expect(find.text("99"), findsOneWidget);
  });

  testWidgets("bar chart reports taps and labels the selected bar", (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: AppBarChart(
            values: const [2, 5, 3],
            labels: const ["1", "2", "3"],
            valueLabel: (value) => "v$value",
            selectedIndex: 1,
            onSelected: taps.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester.getSemantics(find.bySemanticsLabel("2, v5.0"));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.flagsCollection.isButton, isTrue);

    await tester.tap(find.text("3"));
    expect(taps, [2]);
  });

  testWidgets("bar chart copes with all-zero values", (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 200,
          child: AppBarChart(
            values: const [0, 0],
            labels: const ["a", "b"],
            valueLabel: (value) => "$value",
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets("skeleton shimmers and announces its label", (tester) async {
    await tester.pumpWidget(
      host(
        const AppSkeleton(
          semanticsLabel: "Loading",
          child: AppSkeletonBox(height: 40, width: 120),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.bySemanticsLabel("Loading"), findsOneWidget);
  });

  /// Luminance (0 dark – 1 light) of the middle of the skeleton box.
  Future<double> skeletonLuminance(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      host(
        const RepaintBoundary(
          key: ValueKey("shot"),
          child: AppSkeleton(child: AppSkeletonBox(height: 40, width: 120)),
        ),
        reduceMotion: true,
        theme: theme,
      ),
    );
    // The previous theme eases into this one.
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey("shot")),
    );
    late final double result;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = (await image.toByteData())!;
      final x = image.width ~/ 2;
      final y = image.height ~/ 2;
      final offset = (y * image.width + x) * 4;
      result = Color.fromARGB(
        255,
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      ).computeLuminance();
    });
    return result;
  }

  testWidgets("skeleton boxes are dark in the dark theme, light in the light "
      "theme", (tester) async {
    final dark = await skeletonLuminance(tester, DarkTheme.dark());
    final light = await skeletonLuminance(tester, LightTheme.light());

    expect(dark, lessThan(0.1));
    expect(light, greaterThan(0.7));
  });

  testWidgets("critical status pill uses the error color", (tester) async {
    await tester.pumpWidget(
      host(const AppStatusPill(label: "C", tone: AppStatusTone.critical)),
    );

    final text = tester.widget<Text>(find.text("C"));
    expect(text.style?.color, LightTheme.light().colorScheme.error);
  });
}
