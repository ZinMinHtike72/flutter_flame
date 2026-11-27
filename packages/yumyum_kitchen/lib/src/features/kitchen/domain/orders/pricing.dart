import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";

/// Noodles in a bowl.
const basePrice = 30;

/// Broth or Mala sauce.
const soupPrice = 10;
const drinkPrice = 10;

/// Up to this many percent of the price for serving at full patience.
const speedTipPercent = 40;

/// Tip percent added per perfect item and removed per cold topping.
const itemTipPercent = 10;

/// Prepared toppings pay more than fresh greens and jars.
int toppingPrice(Topping topping) => switch (topping) {
  Topping.beef || Topping.shrimp => 15,
  Topping.egg || Topping.fishBall => 10,
  _ => 5,
};

/// The menu price of [recipe] before the tip.
int priceOf(Recipe recipe) {
  var price = basePrice + soupPrice;
  for (final topping in Topping.values) {
    if (recipe.has(topping)) {
      price += toppingPrice(topping);
    }
  }
  return recipe.drink == null ? price : price + drinkPrice;
}

/// What one served order pays.
class Bill {
  const Bill({
    required this.price,
    required this.tipPercent,
    required this.streakTenths,
  });

  /// Prices the [recipe] served with [patiencePermille] patience left (see
  /// `Ticket.patiencePermille`), [perfectItems] taken out in their perfect
  /// window and [coldItems] cold toppings, under a service streak of
  /// [streakTenths] (10 = ×1.0, 20 = ×2.0).
  factory Bill.of(
    Recipe recipe, {
    required int patiencePermille,
    int perfectItems = 0,
    int coldItems = 0,
    int streakTenths = 10,
  }) {
    final patience = patiencePermille.clamp(0, 1000);
    final percent =
        speedTipPercent * patience ~/ 1000 +
        itemTipPercent * (perfectItems - coldItems);
    return Bill(
      price: priceOf(recipe),
      tipPercent: percent < 0 ? 0 : percent,
      streakTenths: streakTenths,
    );
  }

  final int price;
  final int tipPercent;
  final int streakTenths;

  int get tip => price * tipPercent ~/ 100;

  /// Coins earned: price plus tip, times the streak.
  int get total => (price + tip) * streakTenths ~/ 10;
}

/// Consecutive serves without losing a guest. The first serve pays ×1.0,
/// each one after it 0.1 more, up to ×2.0; losing a guest starts over.
class ServiceStreak {
  static const maxTenths = 20;

  int serves = 0;
  int best = 0;

  /// The multiplier of the next serve, in tenths.
  int get tenths => 10 + serves < maxTenths ? 10 + serves : maxTenths;

  /// Counts a serve and returns the multiplier it earned.
  int serve() {
    final earned = tenths;
    serves++;
    if (serves > best) {
      best = serves;
    }
    return earned;
  }

  void lose() => serves = 0;
}
