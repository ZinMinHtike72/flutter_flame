import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget page(List<Widget> slivers) => MaterialApp(
    theme: LightTheme.light(),
    home: AppScaffold(body: CustomScrollView(slivers: slivers)),
  );

  testWidgets("sliver app bar stays pinned with back, actions and bottom", (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(
      page([
        AppSliverAppBar(
          title: "Compare",
          subtitle: "Commission statement",
          onBack: () => backs++,
          backLabel: "Back",
          actions: const [AppPill(label: "FY 2026-27")],
          bottom: const Text("strip"),
          bottomHeight: 40,
        ),
        const AppSliverBody(
          sliver: SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ),
      ]),
    );

    expect(find.text("Compare"), findsOneWidget);
    expect(find.text("Commission statement"), findsOneWidget);
    expect(find.text("FY 2026-27"), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text("Compare"), findsOneWidget);
    expect(find.text("strip"), findsOneWidget);

    await tester.tap(find.byTooltip("Back"));
    expect(backs, 1);
  });

  testWidgets("table shows header, rows and a bold total", (tester) async {
    await tester.pumpWidget(
      page([
        const SliverToBoxAdapter(
          child: AppTable(
            header: ["Brand", "Direct"],
            rows: [
              ["Yum Yum", "0.14%"],
              ["Total", "100"],
            ],
            boldLastRow: true,
          ),
        ),
      ]),
    );

    expect(find.text("Brand"), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("Total")).style?.fontWeight,
      FontWeight.w600,
    );
  });

  testWidgets("an intrinsic column keeps its text on one line", (tester) async {
    await tester.pumpWidget(
      page([
        const SliverToBoxAdapter(
          child: AppTable(
            columnWidths: {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
            rows: [
              ["B Class", "85 ≤ Score < 95"],
            ],
          ),
        ),
      ]),
    );

    final text = tester.getSize(find.text("85 ≤ Score < 95"));
    final line = tester.getSize(find.text("B Class"));
    expect(text.height, line.height);
  });

  testWidgets("slider and checkbox report changes", (tester) async {
    final values = <double>[];
    final ends = <double>[];
    final checks = <bool>[];
    await tester.pumpWidget(
      page([
        SliverToBoxAdapter(
          child: Column(
            children: [
              AppSlider(
                value: 50,
                min: 0,
                max: 100,
                onChanged: values.add,
                onChangeEnd: ends.add,
              ),
              AppCheckboxRow(
                label: "Previous 3 months were A class",
                value: false,
                onChanged: checks.add,
              ),
            ],
          ),
        ),
      ]),
    );

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.tap(find.text("Previous 3 months were A class"));
    expect(values, isNotEmpty);
    expect(ends, hasLength(1));
    expect(checks, [true]);
  });

  testWidgets("error card retries and skeleton cards announce loading", (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      page([
        SliverToBoxAdapter(
          child: AppErrorCard(
            title: "Couldn't load",
            body: "Try again later.",
            retryLabel: "Try again",
            onRetry: () => retries++,
          ),
        ),
        const SliverToBoxAdapter(
          child: AppSkeletonCards(heights: [40, 40], semanticsLabel: "Loading"),
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text("Try again"));
    expect(retries, 1);
    expect(find.bySemanticsLabel("Loading"), findsOneWidget);
    expect(find.byType(AppSkeletonBox), findsNWidgets(2));
  });
}
