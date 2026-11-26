import "dart:math";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/data/local_progress_repository.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    "reopening and concurrent settlement pay one reward and buy once",
    () async {
      final repo = LocalProgressRepository();
      final other = LocalProgressRepository();
      final run = KitchenRun(shift: campaign.first, id: "1", random: Random(1))
        ..served = 8
        ..coins = 800;
      expect((await repo.update((p) => p.settle(run))).wallet, 0);
      run.advance(45000);
      await Future.wait([
        repo.update((p) => p.settle(run)),
        other.update((p) => p.settle(run)),
      ]);
      await Future.wait([
        repo.update((p) => p.buy(Upgrade.extraPot)),
        other.update((p) => p.buy(Upgrade.extraPot)),
      ]);
      await repo.update((p) => p.preferences(soundOn: false, hapticsOn: false));
      final saved = await other.read();
      expect(saved.wallet, 450);
      expect(saved.best[1], 800);
      expect(saved.unlocked, 2);
      expect(saved.sound, isFalse);
      expect(saved.haptics, isFalse);
      expect(saved.upgrades, {Upgrade.extraPot});
      expect(saved.buy(Upgrade.premiumBowl), same(saved));
    },
  );
  test("invalid saves fail explicitly", () async {
    SharedPreferences.setMockInitialValues({
      "yumyum_kitchen.progress.v1": "{}",
    });
    await expectLater(LocalProgressRepository().read(), throwsFormatException);
  });
  test("failed shifts bank earnings and keep the higher score", () {
    final run =
        KitchenRun(shift: campaign.first, id: "replay", random: Random(3))
          ..ended = true
          ..coins = 5;
    final p = const KitchenProgress(best: {1: 50}).settle(run);
    expect(p.best[1], 50);
    expect(p.wallet, 5);
    expect(p.unlocked, 1);
  });
}
