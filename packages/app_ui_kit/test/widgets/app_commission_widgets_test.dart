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

  testWidgets("card shows its header and reports taps", (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppCard(
          title: "Sales vs target",
          action: "42%",
          onTap: () => taps++,
          child: const Text("body"),
        ),
      ),
    );

    expect(find.text("Sales vs target"), findsOneWidget);
    expect(find.text("42%"), findsOneWidget);
    await tester.tap(find.text("body"));
    expect(taps, 1);
  });

  testWidgets("pill tones use the design colours", (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            AppPill(label: "good", tone: AppPillTone.good),
            AppPill(label: "bad", tone: AppPillTone.bad),
          ],
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text("good")).style?.color,
      AppColorsExtension.light.good,
    );
    expect(
      tester.widget<Text>(find.text("bad")).style?.color,
      AppColorsExtension.light.bad,
    );
  });

  testWidgets("meter fills to its value and draws the marker", (tester) async {
    await tester.pumpWidget(host(const AppMeter(value: 0.5, marker: 0.25)));
    await tester.pumpAndSettle();

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.5);
    expect(
      tester.widget<Positioned>(find.byType(Positioned).last).left,
      closeTo(80, 0.01),
    );
  });

  testWidgets("date chip reports taps and its selected state", (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppDateChip(
          weekday: "Fri",
          day: "13",
          selected: true,
          semanticsLabel: "Friday 13",
          onTap: () => taps++,
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.bySemanticsLabel("Friday 13"))
          .flagsCollection
          .isButton,
      isTrue,
    );
    await tester.tap(find.text("13"));
    expect(taps, 1);
  });

  testWidgets("date chip centres its text when the chip is tall", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 120,
          child: Row(
            children: [
              AppDateChip(
                weekday: "Fri",
                day: "13",
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final chip = tester.getRect(find.byType(AnimatedContainer));
    final text = tester
        .getRect(find.text("Fri"))
        .expandToInclude(tester.getRect(find.text("13")));
    expect(text.center.dy, closeTo(chip.center.dy, 1));
    expect(text.center.dx, closeTo(chip.center.dx, 1));
  });

  testWidgets("calc line bolds the total", (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            AppCalcLine(label: "Sales", value: "1,000 Ks"),
            AppCalcLine(label: "Total", value: "40 Ks", total: true),
          ],
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text("40 Ks")).style?.fontWeight,
      FontWeight.w600,
    );
    expect(
      tester.widget<Text>(find.text("1,000 Ks")).style?.fontWeight,
      FontWeight.w400,
    );
  });
}
