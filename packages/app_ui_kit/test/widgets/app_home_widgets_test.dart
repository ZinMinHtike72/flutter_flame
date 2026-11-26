import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host(Widget child, {bool reduceMotion = true}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: LightTheme.light(),
      home: AppScaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    ),
  );

  testWidgets("stat tile shows its value and label as one label", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AppStatTile(
          icon: AppIcons.flag,
          label: "Remaining",
          value: "31.4 M",
          color: Colors.green,
        ),
      ),
    );

    expect(find.text("31.4 M"), findsOneWidget);
    expect(find.text("Remaining"), findsOneWidget);
    expect(find.bySemanticsLabel("Remaining, 31.4 M"), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.flag)).color, Colors.green);
  });

  testWidgets("error card shows the given icon", (tester) async {
    await tester.pumpWidget(
      host(
        AppErrorCard(
          icon: AppIcons.offline,
          title: "You're offline",
          body: "Check your connection.",
          retryLabel: "Try again",
          onRetry: () {},
        ),
      ),
    );

    expect(find.byIcon(AppIcons.offline), findsOneWidget);
    expect(find.byIcon(AppIcons.error), findsNothing);
  });
}
