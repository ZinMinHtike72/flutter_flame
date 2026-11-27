import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/topping_tray.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/ticket.dart";

/// The answer to an assembly step; anything but [added] shakes the bowl and
/// says why.
enum Assembly {
  added,

  /// Broth or a topping before the noodles.
  needsNoodles,
  alreadyHasNoodles,

  /// A bowl takes one broth or sauce only.
  alreadyHasSoup,
  alreadyHasTopping,

  /// A paper bowl can only replace an empty bowl.
  notEmpty,
}

/// One bowl slot on the assembly counter.
///
/// Noodles go in first, then one soup and any toppings in any order. The
/// bowl remembers how many items were perfect (tip bonus) or cold (tip
/// penalty). Reused for every order: [clear] empties it.
class Bowl {
  bool takeaway = false;
  bool noodles = false;
  Soup? soup;

  /// Bit mask of toppings, as in [Recipe.toppings].
  int toppings = 0;
  int perfectItems = 0;
  int coldItems = 0;

  bool get isEmpty => !noodles && !takeaway;

  /// Swaps the empty enamel bowl for a paper takeaway bowl.
  Assembly usePaperBowl() {
    if (!isEmpty) {
      return Assembly.notEmpty;
    }
    takeaway = true;
    return Assembly.added;
  }

  Assembly checkNoodles() =>
      noodles ? Assembly.alreadyHasNoodles : Assembly.added;

  Assembly checkSoup() => !noodles
      ? Assembly.needsNoodles
      : soup != null
      ? Assembly.alreadyHasSoup
      : Assembly.added;

  Assembly checkTopping(Topping topping) => !noodles
      ? Assembly.needsNoodles
      : toppings & Recipe.bit(topping) != 0
      ? Assembly.alreadyHasTopping
      : Assembly.added;

  /// Noodles from a pot, taken out [doneness].
  Assembly addNoodles(Doneness doneness) {
    final result = checkNoodles();
    if (result == Assembly.added) {
      noodles = true;
      if (doneness == Doneness.perfect) {
        perfectItems++;
      }
    }
    return result;
  }

  Assembly addSoup(Soup ladled) {
    final result = checkSoup();
    if (result == Assembly.added) {
      soup = ladled;
    }
    return result;
  }

  /// Check with [checkTopping] before taking the [portion] from its tray.
  Assembly addTopping(Topping topping, Portion portion) {
    final result = checkTopping(topping);
    if (result == Assembly.added) {
      toppings |= Recipe.bit(topping);
      if (portion == Portion.perfect) {
        perfectItems++;
      } else if (portion == Portion.cold) {
        coldItems++;
      }
    }
    return result;
  }

  void clear() {
    takeaway = false;
    noodles = false;
    soup = null;
    toppings = 0;
    perfectItems = 0;
    coldItems = 0;
  }

  /// How many of [recipe]'s bowl steps this bowl already has, or -1 when it
  /// holds something the recipe does not (wrong soup, extra topping, wrong
  /// kind of bowl). Equal to [Recipe.steps] when it is complete.
  int score(Recipe recipe) {
    if (takeaway != recipe.takeaway ||
        (soup != null && soup != recipe.soup) ||
        toppings & ~recipe.toppings != 0) {
      return -1;
    }
    if (!noodles) {
      return 0;
    }
    return 1 + (soup == null ? 0 : 1) + Recipe.countOf(toppings);
  }

  bool matches(Recipe recipe) => score(recipe) == recipe.steps;
}

/// The bowl slots on the counter and which one is selected.
///
/// Noodles, soup and toppings go to the [selected] bowl. After every step
/// [autoSelect] moves the selection to the bowl that best fits the most
/// urgent ticket, so one-handed play needs no extra taps.
class BowlRack {
  BowlRack(int slots) : bowls = List.generate(slots, (_) => Bowl());

  final List<Bowl> bowls;
  int selected = 0;

  Bowl get current => bowls[selected];

  bool select(int index) {
    if (index < 0 || index >= bowls.length) {
      return false;
    }
    selected = index;
    return true;
  }

  /// Walks [tickets] from the least patience left. A ticket that a finished
  /// bowl already matches is covered (that bowl is claimed). The first
  /// ticket that is not covered selects its best-scoring free bowl, keeping
  /// the current bowl on a tie. Leaves the selection alone when no bowl
  /// fits any ticket. Allocates nothing.
  void autoSelect(List<Ticket?> tickets) {
    var visited = 0;
    var claimed = 0;
    for (var round = 0; round < tickets.length; round++) {
      final urgent = mostUrgent(tickets, skip: visited);
      if (urgent < 0) {
        return;
      }
      visited |= 1 << urgent;
      final recipe = tickets[urgent]!.recipe;
      var best = -1;
      var bestScore = -1;
      var covered = false;
      for (var b = 0; b < bowls.length; b++) {
        if (claimed & (1 << b) != 0) {
          continue;
        }
        final score = bowls[b].score(recipe);
        if (score == recipe.steps) {
          claimed |= 1 << b;
          covered = true;
          break;
        }
        if (score > bestScore || (score == bestScore && b == selected)) {
          bestScore = score;
          best = b;
        }
      }
      if (!covered && best >= 0 && bestScore >= 0) {
        selected = best;
        return;
      }
    }
  }
}
