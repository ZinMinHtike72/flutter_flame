import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository();
  static const _key = "yumyum_kitchen.progress.v1";
  Future<void> _tail = Future.value();

  @override
  Future<KitchenProgress> read() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null) {
      return const KitchenProgress();
    }
    final data = jsonDecode(encoded);
    if (data
        case {
          "wallet": final int wallet,
          "unlocked": final int unlocked,
          "best": final Map<String, Object?> scores,
          "settled": final List<Object?> ids,
          "upgrades": final List<Object?> purchases,
          "sound": final bool sound,
          "haptics": final bool haptics,
        }
        when wallet >= 0 &&
            unlocked >= 1 &&
            unlocked <= campaign.length &&
            scores.entries.every(
              (e) => int.tryParse(e.key) != null && e.value is int,
            ) &&
            ids.every((e) => e is String) &&
            purchases.every((e) => Upgrade.values.any((u) => u.name == e))) {
      return KitchenProgress(
        wallet: wallet,
        unlocked: unlocked,
        best: scores.map((k, v) => MapEntry(int.parse(k), v! as int)),
        settled: ids.cast<String>().toSet(),
        upgrades: purchases.cast<String>().map(Upgrade.values.byName).toSet(),
        sound: sound,
        haptics: haptics,
        qualityTier: switch (data["quality"]) {
          final int tier
              when tier >= 0 && tier < KitchenProgress.qualityTiers =>
            tier,
          _ => null,
        },
      );
    }
    throw const FormatException("Invalid kitchen save");
  }

  @override
  Future<KitchenProgress> update(
    KitchenProgress Function(KitchenProgress current) change,
  ) {
    final operation = _tail.then((_) async {
      final current = await read();
      final next = change(current);
      if (identical(current, next)) {
        return current;
      }
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode({
        "wallet": next.wallet,
        "unlocked": next.unlocked,
        "best": next.best.map((k, v) => MapEntry(k.toString(), v)),
        "settled": next.settled.toList(),
        "upgrades": next.upgrades.map((u) => u.name).toList(),
        "sound": next.sound,
        "haptics": next.haptics,
        if (next.qualityTier != null) "quality": next.qualityTier,
      });
      if (!await prefs.setString(_key, encoded)) {
        throw Exception("Could not persist kitchen progress");
      }
      return next;
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}
