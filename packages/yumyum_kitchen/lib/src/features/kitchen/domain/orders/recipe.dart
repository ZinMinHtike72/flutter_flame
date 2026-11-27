import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";

/// What goes over the noodles: a broth ladled from a stockpot, or the dry
/// Mala sauce from its bottle.
enum Soup {
  chicken,
  tomYum,
  mala(dry: true);

  const Soup({this.dry = false});

  final bool dry;
}

/// A drink served with the order.
enum Drink { milkTea, lemonTea }

/// One order: noodles, a [soup], any [toppings], an optional [drink], eaten
/// in or taken away.
///
/// Toppings are a bit mask (bit `Topping.index`), so comparing two sets is
/// one integer comparison and order never matters.
class Recipe {
  const Recipe(
    this.soup, {
    this.toppings = 0,
    this.drink,
    this.takeaway = false,
  });

  /// Builds a recipe from a list of toppings (at spawn time, not per frame).
  factory Recipe.of(
    Soup soup, {
    List<Topping> toppings = const [],
    Drink? drink,
    bool takeaway = false,
  }) => Recipe(
    soup,
    toppings: maskOf(toppings),
    drink: drink,
    takeaway: takeaway,
  );

  final Soup soup;
  final int toppings;
  final Drink? drink;
  final bool takeaway;

  static int bit(Topping topping) => 1 << topping.index;

  static int maskOf(List<Topping> toppings) {
    var mask = 0;
    for (var i = 0; i < toppings.length; i++) {
      mask |= bit(toppings[i]);
    }
    return mask;
  }

  /// Set bits in [mask].
  static int countOf(int mask) {
    var count = 0;
    for (var rest = mask; rest != 0; rest &= rest - 1) {
      count++;
    }
    return count;
  }

  bool has(Topping topping) => toppings & bit(topping) != 0;

  int get toppingCount => countOf(toppings);

  /// Bowl steps: noodles, soup, then one per topping.
  int get steps => 2 + toppingCount;

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.soup == soup &&
      other.toppings == toppings &&
      other.drink == drink &&
      other.takeaway == takeaway;

  @override
  int get hashCode => Object.hash(soup, toppings, drink, takeaway);

  @override
  String toString() =>
      "Recipe($soup, ${[for (final t in Topping.values)
        if (has(t)) t.name]}"
      "${drink == null ? "" : ", $drink"}${takeaway ? ", takeaway" : ""})";
}
