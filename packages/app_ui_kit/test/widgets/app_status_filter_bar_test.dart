import "dart:ui" show SemanticsAction, Tristate;
import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets("counted filters remain reachable at ${scale}x, dark $dark", (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(320, 600);
        addTearDown(tester.view.reset);
        int? selected;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? DarkTheme.dark() : LightTheme.light(),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: AppStatusFilterBar(
                  labels: const ["အားလုံး", "စောင့်ဆိုင်းဆဲ", "ပြီးစီး"],
                  counts: const ["၁၀၀၀", "၉၉၉", "၁"],
                  selectedIndex: 0,
                  onSelected: (index) => selected = index,
                ),
              ),
            ),
          ),
        );
        final all = find.bySemanticsLabel("အားလုံး, ၁၀၀၀");
        expect(
          tester
              .getSemantics(all)
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(all)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        final completed = find.bySemanticsLabel("ပြီးစီး, ၁");
        await tester.ensureVisible(completed);
        await tester.pumpAndSettle();
        await tester.tap(completed);
        expect(selected, 2);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
