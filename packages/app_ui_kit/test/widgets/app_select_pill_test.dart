import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

const _months = [
  AppSelectOption(
    label: "November 2026",
    shortLabel: "Nov",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "October 2026",
    shortLabel: "Oct",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "September 2026",
    shortLabel: "Sep",
    supportingText: "2026",
  ),
];

Widget _host(Widget child) => MaterialApp(
  theme: LightTheme.light(),
  home: AppScaffold(body: Center(child: child)),
);

void main() {
  testWidgets("shows its label and a tap target of at least 44", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AppSelectPill(
          label: "Nov · to date",
          options: _months,
          selectedIndex: 0,
          onSelected: (_) {},
          sheetTitle: "Pick a month",
          closeLabel: "Close",
        ),
      ),
    );

    expect(find.text("Nov · to date"), findsOneWidget);
    expect(find.byIcon(AppIcons.expandMore), findsOneWidget);
    final size = tester.getSize(find.byType(AppSelectPill));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel("Pick a month"), findsOneWidget);
  });

  testWidgets("opens the sheet and reports the picked option", (tester) async {
    int? picked;
    await tester.pumpWidget(
      _host(
        AppSelectPill(
          label: "Nov · to date",
          options: _months,
          selectedIndex: 0,
          onSelected: (index) => picked = index,
          sheetTitle: "Pick a month",
          sheetSubtitle: "Choose a month.",
          selectionHint: "Tap to apply.",
          sheetIcon: AppIcons.calendar,
          layout: AppSelectLayout.grid,
          closeLabel: "Close",
        ),
      ),
    );

    await tester.tap(find.text("Nov · to date"));
    await tester.pumpAndSettle();
    expect(find.text("Pick a month"), findsOneWidget);
    expect(find.text("Choose a month."), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp("^September 2026")).last);
    await tester.pumpAndSettle();
    expect(picked, 2);
    expect(find.text("Pick a month"), findsNothing);
  });

  testWidgets("closing the sheet picks nothing", (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        AppSelectPill(
          label: "Nov · to date",
          options: _months,
          selectedIndex: 0,
          onSelected: (_) => calls++,
          sheetTitle: "Pick a month",
          closeLabel: "Close",
        ),
      ),
    );

    await tester.tap(find.text("Nov · to date"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Close"));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text("Pick a month"), findsNothing);
  });
}
