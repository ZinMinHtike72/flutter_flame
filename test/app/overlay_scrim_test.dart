import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/stage_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/upgrade_shop.dart";

import "../helpers/golden.dart";

/// True when a pointer at [point] reaches the gesture detector that wraps
/// Flame's render widget (the game's own input), not an overlay.
bool _reachesGame(WidgetTester tester, Offset point) {
  final gameInput = tester.renderObject(
    find
        .ancestor(
          of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == "RenderGameWidget",
          ),
          matching: find.byType(RawGestureDetector),
        )
        .first,
  );
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, point, tester.view.viewId);
  return result.path.any((entry) => identical(entry.target, gameInput));
}

void main() {
  testWidgets("overlay scrims swallow taps meant for the counter", (
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
    useGoldenDevice(tester, padding: notchedPadding);
    await tester.pumpWidget(withTestAudio(const App()));
    await waitForWidget(tester, find.byType(MarketEntrance));
    final bloc = tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
      ..add(const KitchenAction(ActionType.start, 1));
    await waitForWidget(tester, find.byType(ShiftHud));
    await settleFrames(tester);
    final game = tester
        .widget<GameWidget<YumYumKitchenGame>>(
          find.byType(GameWidget<YumYumKitchenGame>),
        )
        .game!;
    final StageLayout layout = game.layout!;
    final targets = layout.allTargets().map((t) => t.bounds.center).toList();

    // Live: the counter is reachable.
    expect(targets.every((p) => _reachesGame(tester, p)), isTrue);

    Future<void> expectBlocked(ActionType open, Type overlay) async {
      bloc.add(KitchenAction(open));
      await waitForWidget(tester, find.byType(overlay));
      for (final point in targets) {
        expect(_reachesGame(tester, point), isFalse, reason: "$overlay $point");
      }
      if (overlay == PauseMenu) {
        // The pack sits on bare scrim here: a real tap must change nothing.
        await tester.tapAt(layout.pack.center);
        await tester.pump();
        expect(bloc.run!.pots.first.phase, PotPhase.empty);
        expect(bloc.state.page, KitchenPage.pause);
      }
    }

    await expectBlocked(ActionType.pause, PauseMenu);
    bloc.add(const KitchenAction(ActionType.resume));
    await waitForWidget(tester, find.byType(ShiftHud));
    bloc.tick(60000);
    await waitForWidget(tester, find.byType(ShiftReceipt));
    await expectBlocked(ActionType.settle, ShiftReceipt);
    await expectBlocked(ActionType.shop, UpgradeShop);

    // The overlay's own controls still work.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await waitForWidget(tester, find.byType(ShiftReceipt));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
