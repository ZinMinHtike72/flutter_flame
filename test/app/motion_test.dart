import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/press_feedback.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

const _frame = Duration(milliseconds: 34);

/// Opens the app with motion on and the haptics setting as given.
Future<KitchenBloc> _open(WidgetTester tester, {bool haptics = true}) async {
  await getIt.reset();
  configureDependencies(flavor: AppFlavor.development);
  SharedPreferences.setMockInitialValues({
    "yumyum_kitchen.progress.v1": jsonEncode({
      "wallet": 0,
      "unlocked": 1,
      "best": {"1": 100},
      "settled": <String>[],
      "upgrades": <String>[],
      "sound": false,
      "haptics": haptics,
      "quality": 1,
    }),
  });
  useGoldenDevice(tester, padding: notchedPadding);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures();
  await tester.pumpWidget(
    withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
  );
  await waitForWidget(tester, find.byType(MarketEntrance));
  return tester.element(find.byType(MarketEntrance)).read<KitchenBloc>();
}

Future<YumYumKitchenGame> _start(WidgetTester tester, KitchenBloc bloc) async {
  bloc.add(const KitchenAction(ActionType.start, 1));
  await waitForWidget(tester, find.byType(ShiftHud));
  await settleFrames(tester);
  await tester.pump(const Duration(milliseconds: 300));
  return tester
      .widget<GameWidget<YumYumKitchenGame>>(
        find.byType(GameWidget<YumYumKitchenGame>),
      )
      .game!;
}

/// Records HapticFeedback calls.
List<String> _haptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == "HapticFeedback.vibrate") {
        calls.add("${call.arguments}");
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Future<void> _close(WidgetTester tester) async {
  // Let the tap recognizer's long-press timer run out first.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets("a tap shows its press and haptic on the very next frame", (
    tester,
  ) async {
    final bloc = await _open(tester);
    final game = await _start(tester, bloc);
    final calls = _haptics(tester);
    final steps = game.engineSteps;

    await tester.tapAt(game.layout!.pack.center);
    expect(calls, isEmpty, reason: "nothing before the next frame");
    await tester.pump(_frame);

    // Exactly one rendered frame later (34 ms ≤ 100 ms):
    expect(game.engineSteps, steps + 1);
    expect(
      game.press.scale(Station.pack, 0, game.motionMs),
      lessThan(1),
      reason: "the pack is drawn pressed",
    );
    expect(calls, ["HapticFeedbackType.selectionClick"]);
    expect(bloc.run!.pots.first.phase, PotPhase.cooking);

    // The press has eased out within a few frames.
    for (var i = 0; i < 4; i++) {
      await tester.pump(_frame);
    }
    expect(game.press.scale(Station.pack, 0, game.motionMs), 1);
    await _close(tester);
  });

  testWidgets("haptics stay silent when the setting is off", (tester) async {
    final bloc = await _open(tester, haptics: false);
    final game = await _start(tester, bloc);
    final calls = _haptics(tester);
    await tester.tapAt(game.layout!.pack.center);
    await tester.pump(_frame);
    expect(
      game.press.scale(Station.pack, 0, game.motionMs),
      lessThan(1),
      reason: "the visual press still shows",
    );
    expect(calls, isEmpty);
    expect(PressFeedback.pressedScale, lessThan(1));
    await _close(tester);
  });

  testWidgets("the pause overlay cross-fades in and out", (tester) async {
    final bloc = await _open(tester);
    await _start(tester, bloc);
    bloc.add(const KitchenAction(ActionType.pause));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(PauseMenu), findsOneWidget);
    expect(find.byType(ShiftHud), findsOneWidget, reason: "still fading out");
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ShiftHud), findsNothing);
    bloc.add(const KitchenAction(ActionType.resume));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(PauseMenu), findsOneWidget, reason: "fading out");
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(PauseMenu), findsNothing);
    await _close(tester);
  });

  testWidgets("the awning lifts away from the entrance", (tester) async {
    final awning = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName.endsWith("awning.webp"),
    );
    await _open(tester);
    expect(awning, findsOneWidget, reason: "covers the entrance at first");
    await tester.pump(const Duration(milliseconds: 100));
    expect(awning, findsOneWidget, reason: "still lifting");
    if (goldensSupported) {
      await expectGolden(tester, "entrance_awning_lifting");
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(awning, findsNothing, reason: "lifted away after 600 ms");
    await _close(tester);
  });
}
