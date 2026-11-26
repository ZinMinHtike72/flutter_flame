import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

const _months = [
  AppSelectOption(
    label: "June 2026",
    shortLabel: "Jun",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "July 2026",
    shortLabel: "Jul",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "August 2026",
    shortLabel: "Aug",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "September 2026",
    shortLabel: "Sep",
    supportingText: "2026",
  ),
  AppSelectOption(
    label: "October 2026",
    shortLabel: "Oct",
    supportingText: "2026",
  ),
];
const _salesTypes = [
  AppSelectOption(
    label: "Direct sales",
    supportingText: "Use the direct sales commission rates.",
    icon: AppIcons.store,
  ),
  AppSelectOption(
    label: "Pre-sales",
    supportingText: "Use the pre-sales commission rates.",
    icon: AppIcons.preSales,
  ),
];

Widget _host(
  Widget child, {
  bool reducedMotion = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: brightness == Brightness.dark ? DarkTheme.dark() : LightTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: AppScaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

AppSelectField _field({
  required ValueChanged<int> onSelected,
  List<AppSelectOption> options = _salesTypes,
  AppSelectLayout layout = AppSelectLayout.list,
  int selectedIndex = 0,
}) => AppSelectField(
  options: options,
  selectedIndex: selectedIndex,
  onSelected: onSelected,
  sheetTitle: "Choose an option",
  sheetSubtitle: "Choose the rates for your sales channel.",
  closeLabel: "Close",
  selectionHint: "Tap a choice to apply instantly.",
  layout: layout,
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(AppSelectField));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("grid uses short labels and speaks the full selected month", (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        _field(
          options: _months,
          selectedIndex: 4,
          layout: AppSelectLayout.grid,
          onSelected: picked.add,
        ),
      ),
    );
    await _open(tester);

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text("Jun"), findsOneWidget);
    expect(find.text("2026"), findsNWidgets(5));
    expect(
      tester.getSemantics(find.bySemanticsLabel("October 2026")),
      matchesSemantics(
        label: "October 2026",
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text("Jun"));
    await tester.pumpAndSettle();
    expect(picked, [0]);
    expect(find.byType(AppSelectSheet), findsNothing);
  });

  testWidgets("row descriptions and the whole padded target are tappable", (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(_host(_field(onSelected: picked.add)));
    await _open(tester);
    expect(find.text(_salesTypes[1].supportingText!), findsOneWidget);
    expect(find.byIcon(AppIcons.preSales), findsOneWidget);

    final second = find.byType(AppSelectOptionTile).last;
    await tester.tapAt(tester.getTopLeft(second) + const Offset(6, 6));
    await tester.pumpAndSettle();
    expect(picked, [1]);
  });

  for (final dismiss in ["close", "barrier", "back", "drag"]) {
    testWidgets("$dismiss dismissal keeps the current selection", (
      tester,
    ) async {
      final picked = <int>[];
      await tester.pumpWidget(_host(_field(onSelected: picked.add)));
      await _open(tester);

      switch (dismiss) {
        case "close":
          await tester.tap(find.byTooltip("Close"));
        case "barrier":
          await tester.tapAt(const Offset(8, 8));
        case "back":
          await tester.binding.handlePopRoute();
        case "drag":
          await tester.dragFrom(
            tester.getTopLeft(find.byType(AppSelectSheet)) +
                const Offset(80, 20),
            const Offset(0, 550),
          );
      }
      await tester.pumpAndSettle();
      expect(find.byType(AppSelectSheet), findsNothing);
      expect(picked, isEmpty);
      expect(find.text("Direct sales"), findsOneWidget);
    });
  }

  testWidgets("keyboard can open the field and select an option", (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(_host(_field(onSelected: picked.add)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AppSelectSheet), findsOneWidget);

    // The close action comes first, followed by the two choices.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, [1]);
  });

  testWidgets(
    "long lists scroll independently while the heading stays visible",
    (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        _host(
          _field(
            options: List.generate(
              40,
              (index) => AppSelectOption(label: "Choice ${index + 1}"),
            ),
            onSelected: picked.add,
          ),
        ),
      );
      await _open(tester);
      expect(find.text("Choice 40"), findsNothing);
      final header = tester.getTopLeft(find.text("Choose an option"));
      await tester.scrollUntilVisible(
        find.text("Choice 40"),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.getTopLeft(find.text("Choose an option")), header);
      await tester.tap(find.text("Choice 40"));
      await tester.pumpAndSettle();
      expect(picked, [39]);
    },
  );

  testWidgets("large text on a small phone changes the month grid to rows", (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        _field(
          options: _months,
          layout: AppSelectLayout.grid,
          onSelected: (_) {},
        ),
        textScale: 2,
      ),
    );
    await _open(tester);
    expect(find.byType(GridView), findsNothing);
    expect(find.text("June 2026").last, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("reduced motion leaves choices immediately visible", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_field(onSelected: (_) {}), reducedMotion: true),
    );
    await _open(tester);
    expect(find.text("Pre-sales"), findsOneWidget);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(AppSelectOptionTile).first,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .duration,
      Duration.zero,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets("entrance and dismissal render safely throughout their motion", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_field(onSelected: (_) {}), brightness: Brightness.dark),
    );
    await tester.tap(find.byType(AppSelectField));
    await tester.pump();
    for (final milliseconds in [50, 130, 250, 400]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text("Pre-sales"));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
