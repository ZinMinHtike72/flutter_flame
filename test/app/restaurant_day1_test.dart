import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/restaurant_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

const _frame = Duration(milliseconds: 34);

/// Plays [ms] of game time at 30 fps.
Future<void> _play(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 34) {
    await tester.pump(_frame);
  }
}

Future<(KitchenBloc, YumYumKitchenGame)> _openDay1(
  WidgetTester tester, {
  Locale locale = const Locale("en"),
}) async {
  await getIt.reset();
  configureDependencies(flavor: AppFlavor.development);
  SharedPreferences.setMockInitialValues({
    "yumyum_kitchen.progress.v1": jsonEncode({
      "wallet": 0,
      "unlocked": 1,
      "best": <String, int>{},
      "settled": <String>[],
      "upgrades": <String>[],
      "sound": false,
      "haptics": false,
      "quality": 1,
    }),
  });
  useGoldenDevice(tester, padding: notchedPadding, locale: locale);
  await tester.pumpWidget(
    withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
  );
  await waitForWidget(tester, find.byType(MarketEntrance));
  final bloc = tester.element(find.byType(MarketEntrance)).read<KitchenBloc>();
  final game = tester
      .widget<GameWidget<YumYumKitchenGame>>(
        find.byType(GameWidget<YumYumKitchenGame>),
      )
      .game!;
  return (bloc, game);
}

Future<void> _tap(
  WidgetTester tester,
  RestaurantLayout layout,
  RestaurantSpot spot, [
  int index = 0,
]) async {
  final target = layout.allTargets().firstWhere(
    (t) => t.spot == spot && t.index == index,
  );
  await tester.tapAt(target.bounds.center);
  await tester.pump(_frame);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets("Play opens restaurant day 1 and a bowl is cooked step by step", (
    tester,
  ) async {
    final (bloc, game) = await _openDay1(tester);
    await tester.tap(find.text("Play"));
    await waitForWidget(tester, find.byType(ShiftHud));
    final run = bloc.restaurant!;
    expect(bloc.run, isNull, reason: "the stall is not running");
    expect(bloc.current, same(run));
    await settleFrames(tester);
    final layout = game.restaurantLayout!;

    // Every target is a real 48 dp tap area that does not overlap another.
    final targets = layout.allTargets();
    for (final t in targets) {
      expect(t.bounds.width, greaterThanOrEqualTo(48), reason: "${t.spot}");
      expect(t.bounds.height, greaterThanOrEqualTo(48), reason: "${t.spot}");
      expect(
        layout.safe.expandToInclude(t.bounds),
        layout.safe,
        reason: "${t.spot} ${t.index} inside the safe stage",
      );
      for (final other in targets) {
        if (!identical(t, other)) {
          expect(
            t.bounds.intersect(other.bounds).isEmpty ||
                t.bounds.intersect(other.bounds).width <= 0 ||
                t.bounds.intersect(other.bounds).height <= 0,
            isTrue,
            reason: "${t.spot} ${t.index} overlaps ${other.spot}",
          );
        }
      }
    }

    // 1. Pour water, 2. wait for the boil.
    await _tap(tester, layout, RestaurantSpot.pack);
    expect(game.lastRestaurantTapRefused, isTrue, reason: "no water yet");
    await _tap(tester, layout, RestaurantSpot.pot);
    expect(run.pots[0].phase, CookPhase.heating);
    await _play(tester, 2600);
    expect(run.pots[0].phase, CookPhase.hot);
    // 3. Drop the noodles, 4. cook them.
    await _tap(tester, layout, RestaurantSpot.pack);
    expect(run.pots[0].phase, CookPhase.cooking);
    await _play(tester, 3100);
    expect(run.pots[0].phase, CookPhase.perfect);
    expect(run.dining.tables[0].phase, TablePhase.waiting, reason: "seated");
    if (goldensSupported) {
      await expectGolden(tester, "restaurant_day1_1_cooking");
    }
    // 5. Noodles into the bowl, 6. ladle the broth.
    await _tap(tester, layout, RestaurantSpot.pot);
    final bowl = run.rack.current;
    expect(bowl.noodles, isTrue);
    await _tap(tester, layout, RestaurantSpot.stockpot);
    expect(bowl.soup, isNotNull);
    // 7. Serve: the waiter carries it, the guest eats and pays.
    await _tap(tester, layout, RestaurantSpot.bowl, run.rack.selected);
    expect(run.served, 1);
    expect(find.text("1/4"), findsOneWidget, reason: "HUD goal");
    // The waiter carries it over, then the guest eats for 4 s.
    for (
      var i = 0;
      i < 300 && run.dining.tables[0].phase != TablePhase.dirty;
      i++
    ) {
      await tester.pump(_frame);
    }
    expect(run.dining.tables[0].phase, TablePhase.dirty);
    if (goldensSupported) {
      await expectGolden(tester, "restaurant_day1_2_dirty_table");
    }
    // 8. Clear the table and collect the coins.
    await _tap(tester, layout, RestaurantSpot.table);
    expect(run.dining.tables[0].clearQueued, isTrue);
    // The waiter may seat guest 2 (in at 12 s) first, then clears.
    for (
      var i = 0;
      i < 300 && run.dining.tables[0].phase == TablePhase.dirty;
      i++
    ) {
      await tester.pump(_frame);
    }
    expect(run.dining.tables[0].phase, isNot(TablePhase.dirty));
    expect(run.dining.coins, greaterThan(40));
    await _close(tester);
  });

  testWidgets(
    "pausing day 1 freezes the restaurant; the day ends in a receipt",
    (tester) async {
      final (bloc, _) = await _openDay1(tester);
      bloc.add(const KitchenAction(ActionType.start, 1));
      await waitForWidget(tester, find.byType(ShiftHud));
      await settleFrames(tester);
      final run = bloc.restaurant!;
      await _play(tester, 500);
      bloc.add(const KitchenAction(ActionType.pause));
      await waitForWidget(tester, find.byType(PauseMenu));
      final frozen = run.now;
      await _play(tester, 2000);
      expect(run.now, frozen);
      bloc.add(const KitchenAction(ActionType.resume));
      await waitForWidget(tester, find.byType(ShiftHud));
      await _play(tester, 500);
      expect(run.now, greaterThan(frozen));

      bloc.tick(200000);
      await waitForWidget(tester, find.byType(ShiftReceipt));
      expect(run.ended, isTrue);
      expect(bloc.state.profile.settled, contains(run.id));
      expect(bloc.state.profile.unlocked, 1, reason: "nobody was served");
      await _close(tester);
    },
  );
}
