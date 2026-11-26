import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

Widget _host(Object page, {bool reduce = false, VoidCallback? onTap}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AppFadeSwitcher(
          pageKey: page,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text("page $page"),
          ),
        ),
      ),
    );

double _opacity(WidgetTester tester, String text) => tester
    .widget<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
    )
    .opacity
    .value;

void main() {
  testWidgets("cross-fades from the old page to the new one", (tester) async {
    await tester.pumpWidget(_host("a"));
    await tester.pumpWidget(_host("b"));
    await tester.pump(appFadeSwitchDuration ~/ 2);
    expect(find.text("page a"), findsOneWidget);
    expect(find.text("page b"), findsOneWidget);
    expect(_opacity(tester, "page a"), inExclusiveRange(0, 1));
    expect(_opacity(tester, "page b"), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text("page a"), findsNothing);
    expect(_opacity(tester, "page b"), 1);
  });

  testWidgets("the outgoing page ignores taps while it fades", (tester) async {
    var oldTaps = 0;
    var newTaps = 0;
    await tester.pumpWidget(_host("a", onTap: () => oldTaps++));
    await tester.pumpWidget(_host("b", onTap: () => newTaps++));
    await tester.pump(const Duration(milliseconds: 40));
    final ignoring = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.text("page a"),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignoring.ignoring, isTrue);
    await tester.tapAt(tester.getCenter(find.text("page b")));
    await tester.pumpAndSettle();
    expect(oldTaps, 0);
    expect(newTaps, 1);
  });

  testWidgets("reduced motion switches instantly", (tester) async {
    await tester.pumpWidget(_host("a", reduce: true));
    await tester.pumpWidget(_host("b", reduce: true));
    await tester.pump();
    expect(find.text("page a"), findsNothing);
    expect(find.text("page b"), findsOneWidget);
  });
}
