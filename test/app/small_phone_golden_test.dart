import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";

import "../helpers/golden.dart";

/// Food and appliance art at the smallest supported size: egg, lime and
/// onion bins and toppings, an empty, a cooking and a ready pot.
void main() {
  setUpAll(loadAppFonts);

  testWidgets("food, toppings and pot states read on a small phone", (
    tester,
  ) async {
    await getIt.reset();
    configureDependencies(flavor: AppFlavor.development);
    SharedPreferences.setMockInitialValues({
      "yumyum_kitchen.progress.v1": jsonEncode({
        "wallet": 0,
        "unlocked": 12,
        "best": {"1": 100},
        "settled": <String>[],
        "upgrades": ["extraPot"],
        "sound": false,
        "haptics": false,
        "quality": 1,
      }),
    });
    useGoldenDevice(tester, size: goldenSmallPhone, locale: const Locale("my"));
    await tester.pumpWidget(
      withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
    );
    await waitForWidget(tester, find.byType(MarketEntrance));
    final bloc = tester.element(find.byType(MarketEntrance)).read<KitchenBloc>()
      ..add(const KitchenAction(ActionType.start, 12));
    await waitForWidget(tester, find.byType(ShiftHud));
    bloc.tick(11500);
    final run = bloc.run!;
    run.pots[0]
      ..phase = PotPhase.cooking
      ..deadline = run.now + 2000;
    run.pots[1]
      ..phase = PotPhase.ready
      ..deadline = run.now + 5000;
    run.bowls[0] = {Garnish.egg, Garnish.lime};
    run.bowls[1] = {};
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 34));
    }
    expect(run.shift.garnishCount, 3);
    if (goldensSupported) {
      await expectGolden(tester, "small_phone_food_and_pots");
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
