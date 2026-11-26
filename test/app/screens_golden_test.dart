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
      SharedPreferences.setMockInitialValues({});
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
        await tester.pump();
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
      await action(ActionType.start, ShiftHud, 1);
      await snap("tutorial");

      final game = tester
          .widget<GameWidget<YumYumKitchenGame>>(
            find.byType(GameWidget<YumYumKitchenGame>),
          )
          .game!;
      Future<void> tap(Station station, [int index = 0]) async {
        final target = game.layout!.allTargets().firstWhere(
          (t) => t.station == station && t.index == index,
        );
        await tester.tapAt(target.bounds.center);
        await tester.pump();
      }

      await tap(Station.pack);
      bloc.tick(3000);
      await tester.pump();
      await tap(Station.pot);
      await tap(Station.bowl);
      expect(bloc.run!.served, 1);
      await snap("live");
      await action(ActionType.pause, PauseMenu);
      await snap("pause");
      await action(ActionType.resume, ShiftHud);
      bloc.tick(45000);
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
