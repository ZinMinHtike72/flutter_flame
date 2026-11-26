import "package:app_ui_kit/theme/light_theme.dart";
import "package:app_ui_kit/widgets/app_text_button.dart";
import "package:app_ui_kit/widgets/app_text_field.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("icons and autofill hints reach the text field", (tester) async {
    const prefix = Icon(Icons.person_outline);
    const suffix = Icon(Icons.visibility_outlined);
    const hints = [AutofillHints.username];
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: const Scaffold(
          body: AppTextField(
            prefixIcon: prefix,
            suffixIcon: suffix,
            autofillHints: hints,
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.prefixIcon, same(prefix));
    expect(field.decoration?.suffixIcon, same(suffix));
    expect(field.autofillHints, hints);
  });
  testWidgets("text field inherits theme decoration in each state", (
    tester,
  ) async {
    final theme = LightTheme.light();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    for (final enabled in [true, false]) {
      for (final errorText in <String?>[null, "Invalid value"]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: AppTextField(
                enabled: enabled,
                errorText: errorText,
                focusNode: focusNode,
              ),
            ),
          ),
        );
        expect(find.byType(TextField), findsOneWidget);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, enabled);
        expect(field.decoration?.errorText, errorText);
        expect(field.decoration?.enabledBorder, isNull);
        expect(field.decoration?.focusedBorder, isNull);
        expect(field.decoration?.contentPadding, isNull);

        if (enabled) {
          focusNode.requestFocus();
          await tester.pump();
          expect(focusNode.hasFocus, isTrue);
        }
        final decoration = tester
            .widget<InputDecorator>(find.byType(InputDecorator))
            .decoration;
        expect(
          decoration.enabledBorder,
          theme.inputDecorationTheme.enabledBorder,
        );
        expect(
          decoration.focusedBorder,
          theme.inputDecorationTheme.focusedBorder,
        );
        expect(decoration.errorBorder, theme.inputDecorationTheme.errorBorder);
        expect(
          decoration.focusedErrorBorder,
          theme.inputDecorationTheme.focusedErrorBorder,
        );
        expect(
          decoration.contentPadding,
          const EdgeInsets.fromLTRB(15, 13, 15, 13),
        );
        expect(decoration.fillColor, Colors.white);
        expect(decoration.filled, isTrue);
        expect(decoration.errorMaxLines, 2);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("reserved error space keeps the field height when an error "
      "appears", (tester) async {
    Future<double> heightWith(String? errorText) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LightTheme.light(),
          home: Scaffold(
            body: AppTextField(
              labelText: "Username",
              errorText: errorText,
              reserveErrorSpace: true,
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(AppTextField)).height;
    }

    final withoutError = await heightWith(null);
    final withError = await heightWith("Please enter your username.");

    expect(withError, withoutError);
  });

  testWidgets("input formatters reach the text field", (tester) async {
    final formatters = [FilteringTextInputFormatter.digitsOnly];
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: Scaffold(body: AppTextField(inputFormatters: formatters)),
      ),
    );

    await tester.enterText(find.byType(TextField), "09a12");

    expect(
      tester.widget<TextField>(find.byType(TextField)).inputFormatters,
      formatters,
    );
    expect(find.text("0912"), findsOneWidget);
  });

  testWidgets("text button calls back and can be disabled", (tester) async {
    var taps = 0;
    Future<void> render({required bool enabled}) => tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: Scaffold(
          body: AppTextButton(
            onPressed: enabled ? () => taps++ : null,
            child: const Text("Resend code"),
          ),
        ),
      ),
    );

    await render(enabled: true);
    await tester.tap(find.text("Resend code"));
    expect(taps, 1);

    await render(enabled: false);
    await tester.tap(find.text("Resend code"));
    expect(taps, 1);
  });
}
