import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/data/local_progress_repository.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/quality_benchmark.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/steam_field.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group("QualityBenchmark.tierFor", () {
    test("maps frame cost to tiers at the budget boundaries", () {
      expect(QualityBenchmark.tierFor(Duration.zero), SteamQuality.high);
      expect(
        QualityBenchmark.tierFor(QualityBenchmark.highBudget),
        SteamQuality.high,
      );
      expect(
        QualityBenchmark.tierFor(
          QualityBenchmark.highBudget + const Duration(microseconds: 1),
        ),
        SteamQuality.medium,
      );
      expect(
        QualityBenchmark.tierFor(QualityBenchmark.mediumBudget),
        SteamQuality.medium,
      );
      expect(
        QualityBenchmark.tierFor(
          QualityBenchmark.mediumBudget + const Duration(microseconds: 1),
        ),
        SteamQuality.low,
      );
    });

    test("measure times the real workload", () async {
      final puff = await SteamField.bakePuff();
      final cost = QualityBenchmark.measure(puff, frames: 10, warmUp: 2);
      expect(cost, greaterThanOrEqualTo(Duration.zero));
      expect(cost, lessThan(const Duration(milliseconds: 100)));
      puff.dispose();
    });
  });

  group("saved tier", () {
    test("preferences accept 0..2 and ignore anything else", () {
      const progress = KitchenProgress();
      expect(progress.qualityTier, isNull);
      expect(progress.preferences(tier: 2).qualityTier, 2);
      expect(progress.preferences(tier: 3).qualityTier, isNull);
      expect(progress.preferences(tier: -1).qualityTier, isNull);
      expect(
        progress.preferences(tier: 0).preferences(soundOn: false).qualityTier,
        0,
      );
    });

    test(
      "round-trips through local storage; bad values read as null",
      () async {
        final repo = LocalProgressRepository();
        await repo.update((p) => p.preferences(tier: 0));
        expect((await LocalProgressRepository().read()).qualityTier, 0);

        SharedPreferences.setMockInitialValues({
          "yumyum_kitchen.progress.v1":
              '{"wallet":0,"unlocked":1,"best":{},"settled":[],"upgrades":[],'
              '"sound":true,"haptics":true,"quality":9}',
        });
        expect((await LocalProgressRepository().read()).qualityTier, isNull);
      },
    );
  });

  group("KitchenBloc", () {
    KitchenBloc bloc() => KitchenBloc(
      LocalProgressRepository(),
      (shift, profile) => makeKitchenRun(shift, profile, "run", Random(1)),
    );

    test("the benchmark fills an empty tier but never overrides one", () async {
      final first = bloc()..add(const KitchenStarted());
      first.add(const KitchenAction(ActionType.benchmark, 2));
      await expectLater(
        first.stream,
        emitsThrough(
          predicate<KitchenState>((s) => s.profile.qualityTier == 2),
        ),
      );
      first
        ..add(const KitchenAction(ActionType.quality))
        ..add(const KitchenAction(ActionType.benchmark, 2));
      await expectLater(
        first.stream,
        emitsThrough(
          predicate<KitchenState>((s) => s.profile.qualityTier == 0),
        ),
      );
      await first.close();
      final saved = await LocalProgressRepository().read();
      expect(saved.qualityTier, 0);
    });
  });
}
