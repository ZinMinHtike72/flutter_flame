enum NoodleProduct {
  originalChicken("bag_original_chicken", "yum-yum-chicken-flavour"),
  xciteTomYumChicken(
    "bag_xcite_tom_yum_chicken",
    "yum-yum-xcite-tom-yum-chicken-flavour",
  ),
  ultraMalaXiangGuo(
    "bag_ultra_mala_xiang_guo",
    "yum-yum-ultra-mala-xiang-guo-flavour",
  );

  const NoodleProduct(this.key, this.slug);
  final String key;
  final String slug;
  Uri get officialPage => Uri.https("yumyummyanmar.com", "/$slug/");
}

enum Garnish { onion, egg, lime }

enum Upgrade {
  extraPot(350),
  fastBoil(550),
  premiumBowl(750);

  const Upgrade(this.price);
  final int price;
}

enum Goal { customers, coins }

class Shift {
  const Shift(
    this.number,
    this.goal,
    this.target,
    this.seconds,
    this.slots,
    this.arrivalMs,
    this.patienceMs,
  );
  final int number;
  final Goal goal;
  final int target;
  final int seconds;
  final int slots;
  final int arrivalMs;
  final int patienceMs;
  NoodleProduct get product => NoodleProduct.values[(number - 1) ~/ 4];
  int get garnishCount => number == 1
      ? 0
      : number < 3
      ? 1
      : number < 5
      ? 2
      : 3;
  int get maxToppings => number < 5 ? 1 : 2;
}

const campaign = [
  Shift(1, Goal.customers, 4, 45, 2, 6500, 24000),
  Shift(2, Goal.coins, 480, 50, 2, 6200, 23000),
  Shift(3, Goal.customers, 7, 55, 2, 5900, 22000),
  Shift(4, Goal.coins, 800, 60, 2, 5500, 22000),
  Shift(5, Goal.customers, 9, 65, 3, 5100, 21000),
  Shift(6, Goal.coins, 950, 65, 3, 4900, 20500),
  Shift(7, Goal.customers, 11, 70, 3, 4700, 20000),
  Shift(8, Goal.coins, 1200, 75, 3, 4500, 19500),
  Shift(9, Goal.customers, 13, 80, 4, 4300, 19000),
  Shift(10, Goal.coins, 1350, 80, 4, 4100, 18500),
  Shift(11, Goal.customers, 15, 85, 4, 3900, 18000),
  Shift(12, Goal.coins, 1500, 90, 4, 3700, 17500),
];
