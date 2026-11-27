import "dart:async";
import "dart:convert";
import "dart:math";
import "dart:ui";

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
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/allocation_trace.dart";
import "../helpers/golden.dart";

/// Our frame-loop code: an allocation whose stack passes through any of
/// these classes counts against the game.
const _ours = {
  "YumYumKitchenGame",
  "_Counter",
  "MarketArt",
  "ArtSprite",
  "SpriteAtlas",
  "PotSprites",
  "CustomerSprites",
  "CustomerCast",
  "SteamField",
  "BoilSync",
  "FixedStepClock",
  "FrameThrottle",
  "StageLayout",
  "KitchenRun",
  "KitchenBloc",
};

/// Allowed, documented exceptions (`Owner.function`), none of them per-frame
/// frame work:
/// - `Image.debugDisposed`: dart:ui's `assert(!image.debugDisposed)` in
///   `drawImageRect`; asserts are compiled out of profile and release builds.
/// - Flame's component lifecycle processing.
/// - The bloc's once-per-second HUD state update (`Bloc.add` from
///   `KitchenBloc.tick`, event handling, Equatable comparisons).
/// - `KitchenRun._spawn`: a new customer (and their order) every few seconds.
const _allowed = {
  "Image.debugDisposed",
  "ComponentTreeRoot.processLifecycleEvents",
  "Bloc.add",
  "KitchenBloc._handle",
  "KitchenBloc._action",
  "KitchenState.props",
  "KitchenState.copyWith",
  "KitchenRun._spawn",
};

void _progress({int unlocked = 12}) => SharedPreferences.setMockInitialValues({
  "yumyum_kitchen.progress.v1": jsonEncode({
    "wallet": 0,
    "unlocked": unlocked,
    "best": {"1": 100},
    "settled": <String>[],
    "upgrades": ["extraPot"],
    "sound": false,
    "haptics": false,
    "quality": 2,
  }),
});

/// Audio whose preload finishes only when the test says so.
class _SlowAudio extends KitchenAudio {
  final gate = Completer<void>();
  @override
  Future<void> preload() => gate.future;
}

void main() {
  testWidgets("no shift and no clock until every asset is preloaded", (
    tester,
  ) async {
    await getIt.reset();
    configureDependencies(flavor: AppFlavor.development);
    _progress();
    useGoldenDevice(tester);
    final audio = _SlowAudio();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<KitchenAudio>(create: (_) => audio),
          RepositoryProvider<Random>(create: (_) => Random(7)),
        ],
        child: const App(),
      ),
    );
    // Let images and atlases load; audio is still held back.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 34));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    final game = tester
        .widget<GameWidget<YumYumKitchenGame>>(
          find.byType(GameWidget<YumYumKitchenGame>),
        )
        .game!;
    expect(game.preloaded, isFalse);
    expect(find.byType(MarketEntrance), findsNothing, reason: "no menu yet");
    expect(game.engineSteps, 0, reason: "no update, so no rules clock");

    audio.gate.complete();
    await waitForWidget(tester, find.byType(MarketEntrance));
    expect(game.preloaded, isTrue);
    expect(game.potSprites, isNotNull);
    expect(game.customerSprites, isNotNull);
    expect(game.smokeAtlas, isNotNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    "steady 30 fps frames allocate no geometry, closures or iterators",
    (tester) async {
      final uri = await tester.runAsync(vmServiceUri);
      if (uri == null) {
        markTestSkipped(
          "Needs the VM service: run `flutter test --enable-vmservice` "
          "(make test does).",
        );
        return;
      }
      await getIt.reset();
      configureDependencies(flavor: AppFlavor.development);
      _progress();
      useGoldenDevice(tester, padding: notchedPadding);
      // Motion on: steam, boil, walking customers all active.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpWidget(withTestAudio(const App()));
      await waitForWidget(tester, find.byType(MarketEntrance));
      final bloc =
          tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
            ..add(const KitchenAction(ActionType.start, 12));
      await waitForWidget(tester, find.byType(ShiftHud));
      await settleFrames(tester);
      final game = tester
          .widget<GameWidget<YumYumKitchenGame>>(
            find.byType(GameWidget<YumYumKitchenGame>),
          )
          .game!;
      // The four-customer rush: shift 12, both pots busy.
      bloc
        ..tick(11500)
        ..tap(Station.pack, 0)
        ..tap(Station.pack, 0);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 34));
      }
      final run = bloc.run!;
      expect(run.customers.nonNulls, hasLength(4));
      run.pots[1]
        ..phase = PotPhase.ready
        ..deadline = run.now + 600000;
      run.pots[0].deadline = run.now + 600000;

      void frames(int n) {
        for (var i = 0; i < n; i++) {
          game.update(1 / 30);
          final recorder = PictureRecorder();
          game.render(Canvas(recorder));
          recorder.endRecording().dispose();
        }
      }

      const steadyFrames = 300;
      final ours = await tester.runAsync(
        () => traceAllocations(
          uri,
          ours: _ours,
          allowed: _allowed,
          // Warm up so every path is compiled and every cache is built.
          warmUp: () => frames(300),
          measure: () => frames(steadyFrames),
        ),
      );
      final total = ours!.values.fold(0, (a, b) => a + b);
      // ignore: avoid_print
      print(
        "Allocations from game code over 2 × $steadyFrames steady frames: "
        "$total ${ours.isEmpty ? "" : ours}",
      );
      expect(ours, isEmpty, reason: "frame loop allocates: $ours");
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
