import "dart:convert";
import "dart:math";

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
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/boil_sync.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

/// Records boil audio calls with the pot phase at that moment.
class _RecordingAudio extends SilentTestAudio {
  KitchenBloc? bloc;
  final loop = <(bool on, PotPhase phase)>[];
  final chimes = <PotPhase>[];

  PotPhase get _phase => bloc?.run?.pots.first.phase ?? PotPhase.empty;

  @override
  void boilLoop({required bool on, required bool sound}) {
    if (loop.isEmpty || loop.last.$1 != (on && sound)) {
      loop.add((on && sound, _phase));
    }
  }

  @override
  void ready({required bool sound}) => chimes.add(_phase);
}

void main() {
  setUpAll(loadAppFonts);
  testWidgets("boil loop and ready chime follow the pot on its rules step", (
    tester,
  ) async {
    await getIt.reset();
    configureDependencies(flavor: AppFlavor.development);
    SharedPreferences.setMockInitialValues({
      "yumyum_kitchen.progress.v1": jsonEncode({
        "wallet": 0,
        "unlocked": 2,
        "best": {"1": 100},
        "settled": <String>[],
        "upgrades": <String>[],
        "sound": true,
        "haptics": false,
        "quality": 1,
      }),
    });
    useGoldenDevice(tester, padding: notchedPadding);
    // Motion on: bubbles and lid rattle are drawn.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    final audio = _RecordingAudio();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<KitchenAudio>(create: (_) => audio),
          RepositoryProvider<Random>(create: (_) => Random(7)),
        ],
        child: const RepaintBoundary(key: goldenKey, child: App()),
      ),
    );
    await waitForWidget(tester, find.byType(MarketEntrance));
    final bloc = audio.bloc =
        tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
          ..add(const KitchenAction(ActionType.start, 2));
    await waitForWidget(tester, find.byType(ShiftHud));
    await settleFrames(tester);
    final game = tester
        .widget<GameWidget<YumYumKitchenGame>>(
          find.byType(GameWidget<YumYumKitchenGame>),
        )
        .game!;
    Future<void> frames(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 34));
      }
    }

    final pack = game.layout!.pack.center;
    await tester.tapAt(pack);
    await frames(2);
    expect(game.boil.stage(0), BoilStage.simmer);
    expect(audio.loop.last, (true, PotPhase.cooking));

    await frames(45);
    expect(game.boil.stage(0), BoilStage.rolling);
    expect(audio.loop.last.$1, isTrue, reason: "loop peaks while rolling");
    if (goldensSupported) {
      await expectGolden(tester, "boil_rolling");
    }

    await frames(46);
    expect(bloc.run!.pots.first.phase, PotPhase.ready);
    expect(audio.chimes, [PotPhase.ready], reason: "one chime, at ready");
    expect(audio.loop.last, (false, PotPhase.ready), reason: "stops at ready");

    // Cook again, then pause: the loop stops with the shift.
    await tester.tapAt(game.layout!.pots.first.center); // ready → bowl
    await tester.tapAt(pack);
    await frames(2);
    expect(audio.loop.last.$1, isTrue);
    bloc.add(const KitchenAction(ActionType.pause));
    await waitForWidget(tester, find.byType(PauseMenu));
    await frames(2);
    expect(audio.loop.last.$1, isFalse, reason: "paused shift is silent");

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
