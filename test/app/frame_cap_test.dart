import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

void main() {
  testWidgets("one second of 60 Hz frames runs 30 engine steps", (
    tester,
  ) async {
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
        "haptics": false,
      }),
    });
    useGoldenDevice(tester);
    await tester.pumpWidget(withTestAudio(const App()));
    await waitForWidget(tester, find.byType(MarketEntrance));
    final bloc = tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
      ..add(const KitchenAction(ActionType.start, 1));
    await waitForWidget(tester, find.byType(ShiftHud));
    final game = tester
        .widget<GameWidget<YumYumKitchenGame>>(
          find.byType(GameWidget<YumYumKitchenGame>),
        )
        .game!;
    expect(game.paused, isTrue, reason: "Flame's own loop stays stopped");

    // Align to a step, then measure one second of 60 Hz vsyncs.
    const vsync = Duration(microseconds: 16667);
    for (var i = 0; i < 4; i++) {
      await tester.pump(vsync);
    }
    final steps = game.engineSteps;
    final rulesMs = bloc.run!.elapsed;
    for (var i = 0; i < 60; i++) {
      await tester.pump(vsync);
    }
    expect(game.engineSteps - steps, inInclusiveRange(29, 31));
    expect(bloc.run!.elapsed - rulesMs, inInclusiveRange(966, 1034));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
