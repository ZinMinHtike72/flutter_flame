import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

void main() {
  setUpAll(loadAppFonts);
  for (final motion in [true, false]) {
    testWidgets(
      "pot steam golden, motion ${motion ? "on" : "reduced"}",
      (tester) async {
        await getIt.reset();
        configureDependencies(flavor: AppFlavor.development);
        SharedPreferences.setMockInitialValues({
          "yumyum_kitchen.progress.v1": jsonEncode({
            "wallet": 0,
            "unlocked": 1,
            "best": {"1": 100},
            "settled": <String>[],
            "upgrades": ["extraPot"],
            "sound": false,
            "haptics": false,
          }),
        });
        useGoldenDevice(tester, padding: notchedPadding);
        if (motion) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures();
        }
        await tester.pumpWidget(
          withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
        );
        await waitForWidget(tester, find.byType(MarketEntrance));
        final bloc =
            tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
              ..add(const KitchenAction(ActionType.start, 1));
        await waitForWidget(tester, find.byType(ShiftHud));
        await settleFrames(tester);
        final game = tester
            .widget<GameWidget<YumYumKitchenGame>>(
              find.byType(GameWidget<YumYumKitchenGame>),
            )
            .game!;
        final run = bloc.run!;
        // Pot 1 ready, pot 2 burnt, then let the steam build for a second.
        run.pots[0]
          ..phase = PotPhase.ready
          ..deadline = run.now + 60000;
        run.pots[1].phase = PotPhase.burnt;
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 34));
        }
        if (motion) {
          expect(game.steam.aliveAbove(0), greaterThan(0));
          expect(game.steam.aliveAbove(1), greaterThan(0));
        } else {
          expect(game.steam.alive, 0);
        }
        await expectGolden(
          tester,
          "steam_${motion ? "motion" : "reduced_motion"}",
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
      skip: !goldensSupported,
    );
  }
}
