import "dart:async";

import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? LightTheme.light(),
  home: AppScaffold(
    body: SingleChildScrollView(child: Column(children: [child])),
  ),
);

void main() {
  testWidgets("tiles and rows report presses and show their text", (
    tester,
  ) async {
    final presses = <String>[];
    final toggles = <bool>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppActionTile(
              icon: AppIcons.store,
              title: "Visit",
              subtitle: "Today",
              highlighted: true,
              onPressed: () => presses.add("action"),
            ),
            AppSettingsRow(
              title: "Language",
              subtitle: "System",
              icon: AppIcons.language,
              selected: true,
              trailing: const Text("›"),
              onPressed: () => presses.add("settings"),
            ),
            AppSettingsRow(
              title: "Sign out",
              icon: AppIcons.logout,
              destructive: true,
              onPressed: () => presses.add("signOut"),
            ),
            AppSwitchTile(
              title: "Dark",
              subtitle: "Theme",
              icon: AppIcons.moon,
              value: false,
              onChanged: toggles.add,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text("Visit"));
    await tester.tap(find.text("Language"));
    await tester.tap(find.text("Sign out"));
    await tester.tap(find.byType(Switch));
    expect(presses, ["action", "settings", "signOut"]);
    expect(toggles, [true]);
    expect(find.text("Today"), findsOneWidget);
  });

  testWidgets("small buttons and headers report taps", (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: CustomScrollView(
            slivers: [
              const AppPinnedHeader(child: Text("Pinned")),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppChevronBackButton(
                      tooltip: "Back",
                      onPressed: () => taps.add("back"),
                    ),
                    AppImageCloseButton(
                      tooltip: "Close",
                      onPressed: () => taps.add("close"),
                    ),
                    const AppProgressLine(value: 0.5),
                    const AppProgressLine(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip("Back"));
    await tester.tap(find.byTooltip("Close"));
    expect(taps, ["back", "close"]);
    expect(find.text("Pinned"), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets("note field reports edits", (tester) async {
    final notes = <String>[];
    await tester.pumpWidget(
      _host(
        AppNoteField(
          initialValue: "",
          labelText: "Note",
          maxLength: 20,
          onChanged: notes.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), "Hello");
    expect(notes.last, "Hello");
  });

  testWidgets("bottom navigation selects destinations", (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: const SizedBox(),
          bottomNavigationBar: AppBottomNavigation(
            items: const [
              AppNavigationItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: "Home",
              ),
              AppNavigationItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: "Profile",
              ),
            ],
            selectedIndex: 0,
            onSelected: picked.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text("Profile"));
    expect(picked, [1]);
  });

  testWidgets("view tabs switch and timelines lay out", (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppViewTabs(
              labels: const ["List", "Map"],
              icons: const [AppIcons.list, AppIcons.map],
              selectedIndex: 0,
              onSelected: picked.add,
            ),
            const AppTimelineEntry(
              color: Colors.blue,
              icon: AppIcons.check,
              isLast: false,
              child: Text("Calculated"),
            ),
            const AppTimelineEntry(
              color: Colors.green,
              icon: AppIcons.check,
              isLast: true,
              child: Text("Paid"),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Map"));
    expect(picked, [1]);
    expect(find.text("Paid"), findsOneWidget);
  });

  testWidgets("entrance and success mark animate to the end", (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            AppEntrance(delay: 0.2, child: Text("Card")),
            AppSuccessMark(color: Colors.green, size: 80),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text("Card"), findsOneWidget);
    expect(find.byType(AppSuccessMark), findsOneWidget);
  });

  testWidgets("status and filter pills render every tone", (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            for (final tone in AppStatusTone.values)
              AppStatusPill(label: tone.name, tone: tone),
            const AppStatusPill(label: "emphasized", emphasized: true),
            AppFilterPill(
              label: "Open",
              detail: "3",
              trailingIcon: AppIcons.expandMore,
              tooltip: "Filter",
              selected: true,
              onSelected: () => picked.add("open"),
            ),
            AppSurface(
              accent: true,
              onTap: () => picked.add("surface"),
              child: const Text("Surface"),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.tap(find.text("Surface"));
    expect(picked, ["open", "surface"]);
    expect(find.text("critical"), findsOneWidget);
  });

  testWidgets("protected route reports a blocked back", (tester) async {
    var attempts = 0;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: LightTheme.light(),
        home: const AppScaffold(body: Text("Root")),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => AppProtectedRoute(
            canPop: false,
            onBackAttempted: () => attempts++,
            child: const AppScaffold(body: Text("Saving")),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text("Saving"), findsOneWidget);
  });

  testWidgets("modal and date picker open and close", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightTheme.light(),
        home: AppScaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => AppModal.show<void>(
                    context: context,
                    builder: (_) => const Text("Working"),
                  ),
                  child: const Text("modal"),
                ),
                TextButton(
                  onPressed: () => AppDatePicker.show(
                    context: context,
                    initialDate: DateTime(2026, 11, 13),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                    title: "Pick a day",
                  ),
                  child: const Text("date"),
                ),
                TextButton(
                  onPressed: () =>
                      AppSnackBar.showInfo(context, message: "Heads up"),
                  child: const Text("info"),
                ),
                TextButton(
                  onPressed: () =>
                      AppSnackBar.showError(context, message: "Oops"),
                  child: const Text("error"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("info"));
    await tester.pump();
    expect(find.text("Heads up"), findsOneWidget);
    await tester.tap(find.text("error"));
    await tester.pump();
    expect(find.text("Oops"), findsOneWidget);

    await tester.tap(find.text("modal"));
    await tester.pumpAndSettle();
    expect(find.text("Working"), findsOneWidget);
    Navigator.of(tester.element(find.text("Working"))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text("date"));
    await tester.pumpAndSettle();
    expect(find.text("Pick a day"), findsOneWidget);
  });

  test("colour extension copies and blends every token", () {
    const light = AppColorsExtension.light;
    const dark = AppColorsExtension.dark;
    final copy = light.copyWith(card: Colors.red, heroEnd: Colors.blue);
    expect(copy.card, Colors.red);
    expect(copy.heroEnd, Colors.blue);
    expect(copy.canvas, light.canvas);
    expect(light.lerp(dark, 1).canvas, dark.canvas);
    expect(light.lerp(dark, 0).good, light.good);
    expect(light.lerp(null, 0.5), same(light));
  });
}
