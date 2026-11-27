import "dart:convert";

import "package:flame/game.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/upgrade_shop.dart";

import "../helpers/golden.dart";

class _Mode {
  const _Mode(this.name, this.size, this.locale, this.brightness, this.padding);
  final String name;
  final Size size;
  final Locale locale;
  final Brightness brightness;
  final FakeViewPadding padding;
}

const _modes = [
  _Mode("light", goldenPhone, Locale("en"), Brightness.light, notchedPadding),
  _Mode("dark", goldenPhone, Locale("en"), Brightness.dark, notchedPadding),
  _Mode("myanmar", goldenPhone, Locale("my"), Brightness.light, notchedPadding),
  _Mode(
    "myanmar_small",
    goldenSmallPhone,
    Locale("my"),
    Brightness.light,
    FakeViewPadding.zero,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  for (final mode in _modes) {
    testWidgets("landscape kitchen screen flow ${mode.name}", (tester) async {
      await getIt.reset();
      configureDependencies(flavor: AppFlavor.development);
      // A fresh save with the graphics tier pinned to medium, so the
      // machine-dependent startup benchmark cannot change any golden.
      SharedPreferences.setMockInitialValues({
        "yumyum_kitchen.progress.v1": jsonEncode({
          "wallet": 0,
          "unlocked": 1,
          "best": <String, int>{},
          "settled": <String>[],
          "upgrades": <String>[],
          "sound": true,
          "haptics": true,
          "quality": 1,
        }),
      });
      useGoldenDevice(
        tester,
        size: mode.size,
        locale: mode.locale,
        brightness: mode.brightness,
        padding: mode.padding,
      );
      await tester.pumpWidget(
        withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
      );
      await waitForWidget(tester, find.byType(MarketEntrance));

      Future<void> snap(String name) async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await settleFrames(tester);
        await expectGolden(tester, "${name}_${mode.name}");
      }

      await snap("entrance");
      final bloc = tester
          .element(find.byType(MarketEntrance))
          .read<KitchenBloc>();
      Future<void> action(ActionType type, Type widget, [int index = 0]) async {
        bloc.add(KitchenAction(type, index));
        await waitForWidget(tester, find.byType(widget));
      }

      await action(ActionType.tickets, MarketTickets);
      await snap("tickets");
      await action(ActionType.brief, MarketBrief, 1);
      await snap("brief");
      // Day 1 is the step-by-step restaurant.
      await action(ActionType.start, ShiftHud, 1);
      await snap("day1");

      final game = tester
          .widget<GameWidget<YumYumKitchenGame>>(
            find.byType(GameWidget<YumYumKitchenGame>),
          )
          .game!;
      final run = bloc.restaurant!;
      Future<void> step(RestaurantSpot spot, [int index = 0]) async {
        bloc.tapRestaurant(spot, index);
        await tester.pump();
      }

      await settleFrames(tester);
      await step(RestaurantSpot.pot); // water
      bloc.tick(2600); // boiling; the first guest is seated
      await step(RestaurantSpot.pack); // noodles in
      bloc.tick(3100); // cooked
      await step(RestaurantSpot.pot); // into the bowl
      await step(RestaurantSpot.stockpot); // chicken broth
      await step(RestaurantSpot.bowl, run.rack.selected); // serve
      expect(run.served, 1);
      await snap("live");
      await action(ActionType.pause, PauseMenu);
      await snap("pause");
      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await settleFrames(tester);
      expect(bloc.state.profile.qualityTier, 2);
      expect(game.quality.index, 2);
      await action(ActionType.resume, ShiftHud);
      bloc.tick(200000);
      await waitForWidget(tester, find.byType(ShiftReceipt));
      await snap("receipt");
      await action(ActionType.shop, UpgradeShop);
      await snap("upgrades");
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, skip: !goldensSupported);
  }
}
