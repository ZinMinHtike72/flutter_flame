import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: LightTheme.light(),
    home: AppScaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  testWidgets("round icon button reports taps with its label", (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppRoundIconButton(
          icon: AppIcons.share,
          label: "Share",
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byTooltip("Share"));
    expect(taps, 1);
  });

  testWidgets("segmented control reports the tapped option", (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      host(
        AppSegmentedControl(
          labels: const ["This month vs last", "Any two months"],
          selectedIndex: 0,
          onSelected: picked.add,
        ),
      ),
    );

    await tester.tap(find.text("Any two months"));
    expect(picked, [1]);
  });

  testWidgets("select field opens a sheet and returns the pick", (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(
      host(
        AppSelectField(
          options: const [
            AppSelectOption(label: "October 2026"),
            AppSelectOption(label: "September 2026"),
          ],
          selectedIndex: 0,
          sheetTitle: "Pick a month",
          closeLabel: "Close",
          onSelected: picked.add,
        ),
      ),
    );

    await tester.tap(find.text("October 2026"));
    await tester.pumpAndSettle();
    expect(find.text("Pick a month"), findsOneWidget);

    await tester.tap(find.text("September 2026"));
    await tester.pumpAndSettle();
    expect(picked, [1]);
  });

  testWidgets("step timeline shows every step", (tester) async {
    await tester.pumpWidget(
      host(
        const AppStepTimeline(
          steps: [
            AppTimelineStep(title: "Calculated", detail: "1 Nov", done: true),
            AppTimelineStep(title: "Paid", detail: "Expected", done: false),
          ],
        ),
      ),
    );

    expect(find.text("Calculated"), findsOneWidget);
    expect(find.text("Expected"), findsOneWidget);
  });

  testWidgets("hero card shows its chip, tile and legend", (tester) async {
    await tester.pumpWidget(
      host(
        const AppHeroCard(
          child: Column(
            children: [
              AppHeroChip(label: "▲ 18.0% vs Jul"),
              AppHeroTile(label: "Multiplier", value: Text("1.5×")),
              AppLegendDot(color: Colors.blue, label: "Oct"),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("▲ 18.0% vs Jul"), findsOneWidget);
    expect(find.text("1.5×"), findsOneWidget);
    expect(find.text("Oct"), findsOneWidget);
  });

  testWidgets("bar chart draws a pair per label with compare values", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppBarChart(
          values: const [4, 2],
          compareValues: const [3, 5],
          labels: const ["Yum", "Shin"],
          valueLabel: (value) => "$value",
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Yum"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
