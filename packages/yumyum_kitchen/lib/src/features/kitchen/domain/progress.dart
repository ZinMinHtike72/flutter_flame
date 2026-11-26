import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

class KitchenProgress {
  const KitchenProgress({
    this.wallet = 0,
    this.unlocked = 1,
    this.best = const {},
    this.upgrades = const {},
    this.settled = const {},
    this.sound = true,
    this.haptics = true,
  });
  final int wallet;
  final int unlocked;
  final Map<int, int> best;
  final Set<Upgrade> upgrades;
  final Set<String> settled;
  final bool sound;
  final bool haptics;
  KitchenProgress settle(KitchenRun run) {
    if (!run.ended || settled.contains(run.id)) {
      return this;
    }
    final level = run.shift.number;
    return KitchenProgress(
      wallet: wallet + run.coins,
      unlocked: run.won && level == unlocked && unlocked < campaign.length
          ? unlocked + 1
          : unlocked,
      best: {
        ...best,
        level: run.coins > (best[level] ?? 0) ? run.coins : best[level] ?? 0,
      },
      upgrades: upgrades,
      settled: {...settled, run.id},
      sound: sound,
      haptics: haptics,
    );
  }

  KitchenProgress buy(Upgrade item) {
    if (wallet < item.price || upgrades.contains(item)) {
      return this;
    }
    return KitchenProgress(
      wallet: wallet - item.price,
      unlocked: unlocked,
      best: best,
      upgrades: {...upgrades, item},
      settled: settled,
      sound: sound,
      haptics: haptics,
    );
  }

  KitchenProgress preferences({bool? soundOn, bool? hapticsOn}) =>
      KitchenProgress(
        wallet: wallet,
        unlocked: unlocked,
        best: best,
        upgrades: upgrades,
        settled: settled,
        sound: soundOn ?? sound,
        haptics: hapticsOn ?? haptics,
      );
}

abstract interface class ProgressRepository {
  Future<KitchenProgress> read();
  Future<KitchenProgress> update(
    KitchenProgress Function(KitchenProgress current) change,
  );
}
