import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget host({
    required String value,
    required ValueChanged<String> onChanged,
    bool hasError = false,
  }) => MaterialApp(
    theme: LightTheme.light(),
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: AppScaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: AppOtpField(
              length: 6,
              value: value,
              hasError: hasError,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );

  final input = find.descendant(
    of: find.byType(AppOtpField),
    matching: find.byType(TextField),
  );

  testWidgets("shows each digit in its own box and keeps digits only", (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(host(value: "", onChanged: changes.add));

    await tester.enterText(input, "12a3");
    await tester.pumpAndSettle();

    expect(changes.last, "123");
    for (final digit in ["1", "2", "3"]) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets("never accepts more digits than its length", (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(host(value: "", onChanged: changes.add));

    await tester.enterText(input, "123456789");
    await tester.pump();

    expect(changes.last, "123456");
  });

  testWidgets("clears when the caller resets the value", (tester) async {
    await tester.pumpWidget(host(value: "123", onChanged: (_) {}));
    expect(find.text("1"), findsOneWidget);

    await tester.pumpWidget(host(value: "", onChanged: (_) {}));
    await tester.pump();

    expect(find.text("1"), findsNothing);
    expect(tester.widget<TextField>(input).controller?.text, isEmpty);
  });

  testWidgets("offers SMS code autofill and a number keyboard", (tester) async {
    await tester.pumpWidget(host(value: "", onChanged: (_) {}));

    final field = tester.widget<TextField>(input);
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets("keeps the same height with and without an error", (
    tester,
  ) async {
    await tester.pumpWidget(host(value: "12", onChanged: (_) {}));
    final normal = tester.getSize(find.byType(AppOtpField));

    await tester.pumpWidget(
      host(value: "12", onChanged: (_) {}, hasError: true),
    );

    expect(tester.getSize(find.byType(AppOtpField)), normal);
  });

  testWidgets("hidden input draws no border of its own", (tester) async {
    await tester.pumpWidget(host(value: "", onChanged: (_) {}));

    final decoration = tester.widget<TextField>(input).decoration!;
    for (final border in [
      decoration.border,
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.disabledBorder,
    ]) {
      expect(border, InputBorder.none);
    }
  });

  testWidgets("autofocus returns when the field is re-enabled", (tester) async {
    Widget field({required bool enabled}) => MaterialApp(
      theme: LightTheme.light(),
      home: AppScaffold(
        body: AppOtpField(
          length: 6,
          value: "",
          enabled: enabled,
          autofocus: true,
          onChanged: (_) {},
        ),
      ),
    );
    bool hasFocus() =>
        tester.widget<TextField>(input).focusNode?.hasFocus ?? false;

    await tester.pumpWidget(field(enabled: true));
    await tester.pump();
    expect(hasFocus(), isTrue);

    await tester.pumpWidget(field(enabled: false));
    await tester.pump();
    expect(hasFocus(), isFalse);

    await tester.pumpWidget(field(enabled: true));
    await tester.pump();
    expect(hasFocus(), isTrue);
  });
}
