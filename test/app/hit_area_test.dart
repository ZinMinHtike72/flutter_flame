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

const _devices = <String, (Size, FakeViewPadding)>{
  "notched phone": (goldenPhone, notchedPadding),
  "small phone": (goldenSmallPhone, FakeViewPadding.zero),
  "tall phone with cutout": (
    Size(915, 412),
    FakeViewPadding(left: 32, bottom: 16),
  ),
  "foldable inner": (Size(884, 841), FakeViewPadding(top: 24, bottom: 16)),
  "tablet": (Size(1024, 768), FakeViewPadding(top: 24, bottom: 20)),
};

/// Every shift's widest layout: shift 12 with the extra pot.
final _savedProgress = jsonEncode({
  "wallet": 0,
  "unlocked": 12,
  "best": {"1": 100},
  "settled": <String>[],
  "upgrades": ["extraPot"],
  "sound": false,
  "haptics": false,
});

bool _encloses(Rect outer, Rect inner) =>
    inner.left >= outer.left - 1e-6 &&
    inner.top >= outer.top - 1e-6 &&
    inner.right <= outer.right + 1e-6 &&
    inner.bottom <= outer.bottom + 1e-6;

void main() {
  setUpAll(loadAppFonts);
  for (final MapEntry(key: name, value: (size, padding)) in _devices.entries) {
    testWidgets("hit boxes stay in the safe stage, ≥ 48×48, apart: $name", (
      tester,
    ) async {
      await getIt.reset();
      configureDependencies(flavor: AppFlavor.development);
      SharedPreferences.setMockInitialValues({
        "yumyum_kitchen.progress.v1": _savedProgress,
      });
      useGoldenDevice(tester, size: size, padding: padding);
      await tester.pumpWidget(
        withTestAudio(const RepaintBoundary(key: goldenKey, child: App())),
      );
      await waitForWidget(tester, find.byType(MarketEntrance));
      tester
          .element(find.byType(MarketEntrance))
          .read<KitchenBloc>()
          .add(const KitchenAction(ActionType.start, 12));
      await waitForWidget(tester, find.byType(ShiftHud));

      final game = tester
          .widget<GameWidget<YumYumKitchenGame>>(
            find.byType(GameWidget<YumYumKitchenGame>),
          )
          .game!;
      final layout = game.layout!;
      expect(layout.pots, hasLength(2));
      expect(layout.garnishes, hasLength(3));

      final boxes = <String, Rect>{
        for (final target in layout.allTargets())
          "${target.station.name} ${target.index}": target.bounds,
        "hud pause": tester.getRect(
          find
              .ancestor(
                of: find.byIcon(Icons.pause_rounded),
                matching: find.byType(GestureDetector),
              )
              .first,
        ),
      };
      final entries = boxes.entries.toList();
      for (final (i, MapEntry(key: label, value: box)) in entries.indexed) {
        expect(
          _encloses(layout.safe, box),
          isTrue,
          reason: "$label $box leaves safe stage ${layout.safe}",
        );
        expect(
          box.width,
          greaterThanOrEqualTo(48 - 1e-6),
          reason: "$label width",
        );
        expect(
          box.height,
          greaterThanOrEqualTo(48 - 1e-6),
          reason: "$label height",
        );
        for (final other in entries.skip(i + 1)) {
          final overlap = box.intersect(other.value);
          expect(
            overlap.width <= 0 || overlap.height <= 0,
            isTrue,
            reason: "$label overlaps ${other.key}",
          );
        }
      }
      if (name == "notched phone" && goldensSupported) {
        game.showHitBoxes = true;
        await tester.pump(const Duration(milliseconds: 40));
        await expectGolden(tester, "hit_boxes_notched_phone");
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
