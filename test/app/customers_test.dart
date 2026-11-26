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
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

class _Scene {
  _Scene(this.tester, this.bloc, this.game);
  final WidgetTester tester;
  final KitchenBloc bloc;
  final YumYumKitchenGame game;

  KitchenRun get run => bloc.run!;

  /// Real 30 fps frames (34 ms pumps) through the game loop.
  Future<void> frames(int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 34));
    }
  }

  /// Jumps the rules forward, then lets the game step and draw.
  Future<void> skip(int ms) async {
    bloc.tick(ms);
    await frames(2);
  }

  CustomerPose pose(CustomerActor actor) {
    final out = CustomerPose();
    CustomerCast.pose(
      actor,
      run.now,
      out,
      reducedMotion: game.reducedMotion,
      guided: false,
    );
    return out;
  }

  CustomerActor actorFor(int customerId) =>
      game.cast.actors.firstWhere((a) => a.active && a.id == customerId);
}

/// Shift 12 (four customers) with seeded randomness.
Future<_Scene> _open(
  WidgetTester tester, {
  bool motion = true,
  Locale locale = const Locale("en"),
}) async {
  await getIt.reset();
  configureDependencies(flavor: AppFlavor.development);
  SharedPreferences.setMockInitialValues({
    "yumyum_kitchen.progress.v1": jsonEncode({
      "wallet": 0,
      "unlocked": 12,
      "best": {"1": 100},
      "settled": <String>[],
      "upgrades": <String>[],
      "sound": false,
      "haptics": false,
      "quality": 1,
    }),
  });
  useGoldenDevice(tester, padding: notchedPadding, locale: locale);
  if (motion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
  }
  await tester.pumpWidget(
    withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
  );
  await waitForWidget(tester, find.byType(MarketEntrance));
  final bloc = tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
    ..add(const KitchenAction(ActionType.start, 12));
  await waitForWidget(tester, find.byType(ShiftHud));
  await settleFrames(tester);
  final game = tester
      .widget<GameWidget<YumYumKitchenGame>>(
        find.byType(GameWidget<YumYumKitchenGame>),
      )
      .game!;
  return _Scene(tester, bloc, game);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets("customers walk in, wait, react and walk out at 30 fps", (
    tester,
  ) async {
    final scene = await _open(tester);
    final first = scene.run.customers.nonNulls.first;
    final actor = scene.actorFor(first.id);

    // Walking in, mid-stride, from the nearer side.
    await scene.frames(17);
    var pose = scene.pose(actor);
    expect(pose.clip, CustomerClip.walk);
    expect(pose.depth, inExclusiveRange(0, 1));
    if (goldensSupported) {
      await expectGolden(tester, "customers_walk_in");
    }

    // Four customers waiting at the counter.
    await scene.skip(11500);
    await scene.frames(10);
    expect(scene.run.customers.nonNulls, hasLength(4));
    for (final c in scene.run.customers.nonNulls) {
      expect(scene.game.cast.actors.where((a) => a.id == c.id), hasLength(1));
    }
    if (goldensSupported) {
      await expectGolden(tester, "customers_four_waiting");
    }

    // The first one is now impatient (under 30 % patience).
    pose = scene.pose(actor);
    expect(pose.clip, CustomerClip.impatient);

    // Serve them: happy with the bowl, then walk away and disappear.
    scene.run.bowls[0] = {...first.toppings};
    scene.bloc.tap(Station.bowl, 0);
    await scene.frames(6);
    expect(actor.served, isTrue);
    expect(scene.pose(actor).clip, CustomerClip.happy);
    if (goldensSupported) {
      await expectGolden(tester, "customers_happy");
    }
    await scene.frames(30);
    expect(scene.pose(actor).clip, CustomerClip.away);
    await scene.frames(30);
    expect(scene.game.cast.actors.where((a) => a.id == first.id), isEmpty);

    // Let the next customer run out of patience: annoyed, then gone.
    final next = scene.run.customers.nonNulls.reduce(
      (a, b) => a.expires < b.expires ? a : b,
    );
    await scene.skip(next.expires - scene.run.now);
    final missed = scene.actorFor(next.id);
    expect(missed.leftAt, isNotNull);
    expect(missed.served, isFalse);
    await scene.frames(4);
    expect(scene.pose(missed).clip, CustomerClip.annoyed);
    if (goldensSupported) {
      await expectGolden(tester, "customers_annoyed");
    }
    await _close(tester);
  });

  testWidgets("reduced motion: customers fade in place, states stay visible", (
    tester,
  ) async {
    final scene = await _open(tester, motion: false);
    final first = scene.run.customers.nonNulls.first;
    final actor = scene.actorFor(first.id);
    await scene.frames(2);
    final pose = scene.pose(actor);
    expect(pose.x, 0);
    expect(pose.depth, 0);
    // Past 70 % of the first customer's 17.5 s patience.
    await scene.skip(12500);
    await scene.frames(10);
    expect(scene.pose(actor).clip, CustomerClip.impatient);
    if (goldensSupported) {
      await expectGolden(tester, "customers_four_waiting_reduced");
    }
    await _close(tester);
  });

  testWidgets("four customers in Myanmar", (tester) async {
    final scene = await _open(tester, locale: const Locale("my"));
    await scene.skip(11500);
    await scene.frames(10);
    if (goldensSupported) {
      await expectGolden(tester, "customers_four_waiting_myanmar");
    }
    await _close(tester);
  });
}
