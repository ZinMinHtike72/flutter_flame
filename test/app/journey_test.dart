import "dart:convert";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";
import "package:yumyum_kitchen/yumyum_kitchen.dart";

import "../helpers/golden.dart";

void _save({
  int unlocked = 1,
  Map<String, int> best = const {},
  List<String> settled = const [],
}) => SharedPreferences.setMockInitialValues({
  "yumyum_kitchen.progress.v1": jsonEncode({
    "wallet": 0,
    "unlocked": unlocked,
    "best": best,
    "settled": settled,
    "upgrades": <String>[],
    "sound": false,
    "haptics": false,
    "quality": 1,
  }),
});

KitchenBloc _bloc(WidgetTester tester) =>
    tester.element(find.byType(MarketEntrance)).read<KitchenBloc>();

/// Records SystemChrome calls and url_launcher launches.
class _Platform {
  _Platform(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == "SystemChrome.setPreferredOrientations") {
          final list = (call.arguments as List).cast<String>();
          orientations.add(
            list.any((o) => o.contains("portrait")) ? "portrait" : "landscape",
          );
        } else if (call.method == "SystemChrome.setEnabledSystemUIMode") {
          uiModes.add("${call.arguments}");
        }
        return null;
      })
      ..setMockMethodCallHandler(_launcher, (call) async {
        if (call.method == "launch") {
          launched.add("${(call.arguments as Map)["url"]}");
        }
        return true;
      });
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(SystemChannels.platform, null)
        ..setMockMethodCallHandler(_launcher, null);
    });
  }

  static const _launcher = MethodChannel("plugins.flutter.io/url_launcher");
  final orientations = <String>[];
  final uiModes = <String>[];
  final launched = <String>[];
}

Future<void> _close(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// The package screen as a host app would push it.
Widget _host({
  required Future<bool> Function(NoodleProduct product) onOpenProduct,
  required VoidCallback onExit,
}) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<KitchenAudio>(create: (_) => SilentTestAudio()),
    RepositoryProvider<Random>(create: (_) => Random(7)),
  ],
  child: MaterialApp(
    home: YumYumKitchenScreen(onOpenProduct: onOpenProduct, onExit: onExit),
  ),
);

Future<void> _toReceipt(WidgetTester tester, KitchenBloc bloc) async {
  bloc.add(const KitchenAction(ActionType.start, 1));
  await waitForWidget(tester, find.byType(ShiftHud));
  await settleFrames(tester);
  bloc.tick(200000);
  await waitForWidget(tester, find.byType(ShiftReceipt));
}

void main() {
  group("entrance and tickets (#12)", () {
    setUp(() async {
      await getIt.reset();
      configureDependencies(flavor: AppFlavor.development);
    });

    testWidgets("first play goes straight into restaurant day 1", (
      tester,
    ) async {
      _save();
      useGoldenDevice(tester);
      await tester.pumpWidget(withTestAudio(const App()));
      await waitForWidget(tester, find.byType(MarketEntrance));
      expect(find.text("Play"), findsOneWidget);
      expect(find.text("Continue"), findsNothing);
      final bloc = _bloc(tester);
      await tester.tap(find.text("Play"));
      await waitForWidget(tester, find.byType(ShiftHud));
      expect(bloc.restaurant!.number, 1);
      expect(bloc.run, isNull, reason: "not the stall");
      await _close(tester);
    });

    testWidgets("returning players continue to twelve tickets with locks", (
      tester,
    ) async {
      _save(unlocked: 3, best: {"1": 520, "2": 610}, settled: ["a", "b"]);
      useGoldenDevice(tester);
      await tester.pumpWidget(withTestAudio(const App()));
      await waitForWidget(tester, find.byType(MarketEntrance));
      expect(find.text("Continue"), findsOneWidget);
      await tester.tap(find.text("Continue"));
      await waitForWidget(tester, find.byType(MarketTickets));
      for (var level = 1; level <= 12; level++) {
        expect(find.text("$level"), findsOneWidget, reason: "ticket $level");
      }
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(9));
      // A locked ticket does nothing; an unlocked one opens its brief.
      await tester.tap(find.text("7"));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MarketBrief), findsNothing);
      await tester.tap(find.text("2"));
      await waitForWidget(tester, find.byType(MarketBrief));
      expect(find.textContaining("Goal ·"), findsOneWidget);
      expect(find.text("Personal best · 610"), findsOneWidget);
      await _close(tester);
    });
  });

  testWidgets("backgrounding freezes the whole shift until resumed (#18)", (
    tester,
  ) async {
    await getIt.reset();
    configureDependencies(flavor: AppFlavor.development);
    _save(best: {"1": 100});
    useGoldenDevice(tester);
    await tester.pumpWidget(withTestAudio(const App()));
    await waitForWidget(tester, find.byType(MarketEntrance));
    final bloc = _bloc(tester)..add(const KitchenAction(ActionType.start, 1));
    await waitForWidget(tester, find.byType(ShiftHud));
    await settleFrames(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final run = bloc.restaurant!;
    expect(run.now, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await waitForWidget(tester, find.byType(PauseMenu));
    final frozenAt = run.now;
    expect(run.paused, isTrue);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(run.now, frozenAt, reason: "no time passes while away");
    expect(find.byType(PauseMenu), findsOneWidget, reason: "waits for player");

    bloc.add(const KitchenAction(ActionType.resume));
    await waitForWidget(tester, find.byType(ShiftHud));
    await tester.pump(const Duration(milliseconds: 500));
    expect(run.now, greaterThan(frozenAt));
    await _close(tester);
  });

  group("embedded in a host app (#19, #21)", () {
    setUp(() async {
      await getIt.reset();
      configureDependencies(flavor: AppFlavor.development);
    });

    testWidgets("product cards go to the host in portrait, then back", (
      tester,
    ) async {
      _save(best: {"1": 100});
      useGoldenDevice(tester);
      final platform = _Platform(tester);
      final opened = <NoodleProduct>[];
      final orientationAtHandoff = <String>[];
      await tester.pumpWidget(
        _host(
          onOpenProduct: (product) async {
            opened.add(product);
            orientationAtHandoff.add(platform.orientations.last);
            return true;
          },
          onExit: () {},
        ),
      );
      await waitForWidget(tester, find.byType(MarketEntrance));
      expect(platform.orientations.first, "landscape");
      expect(platform.uiModes.first, contains("immersiveSticky"));

      await _toReceipt(tester, _bloc(tester));
      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opened, [NoodleProduct.originalChicken], reason: "stable key");
      expect(orientationAtHandoff, ["portrait"], reason: "host policy");
      expect(platform.orientations.last, "landscape", reason: "restored");
      expect(platform.launched, isEmpty, reason: "the host handled it");
      await _close(tester);
    });

    testWidgets("without a host match the official page opens", (tester) async {
      _save(best: {"1": 100});
      useGoldenDevice(tester);
      final platform = _Platform(tester);
      await tester.pumpWidget(
        _host(onOpenProduct: (_) async => false, onExit: () {}),
      );
      await waitForWidget(tester, find.byType(MarketEntrance));
      await _toReceipt(tester, _bloc(tester));
      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(platform.launched, [
        NoodleProduct.originalChicken.officialPage.toString(),
      ]);
      expect(
        NoodleProduct.originalChicken.officialPage.host,
        "yumyummyanmar.com",
      );
      await _close(tester);
    });

    testWidgets("back pauses the shift; exit restores the host", (
      tester,
    ) async {
      _save(best: {"1": 100});
      useGoldenDevice(tester);
      final platform = _Platform(tester);
      var exits = 0;
      await tester.pumpWidget(
        _host(onOpenProduct: (_) async => true, onExit: () => exits++),
      );
      await waitForWidget(tester, find.byType(MarketEntrance));
      final bloc = _bloc(tester)..add(const KitchenAction(ActionType.start, 1));
      await waitForWidget(tester, find.byType(ShiftHud));
      await settleFrames(tester);

      // System back during a shift pauses instead of leaving.
      await tester.binding.handlePopRoute();
      await waitForWidget(tester, find.byType(PauseMenu));
      expect(bloc.current!.paused, isTrue);
      expect(exits, 0);

      // Leave from the pause menu: portrait and system bars come back first.
      platform.orientations.clear();
      platform.uiModes.clear();
      await tester.tap(find.text("Leave kitchen"));
      await tester.pump(const Duration(milliseconds: 200));
      expect(exits, 1);
      expect(platform.orientations, ["portrait"]);
      expect(platform.uiModes.single, contains("edgeToEdge"));
      await _close(tester);
    });
  });
}
