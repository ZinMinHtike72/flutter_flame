import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";

/// The wooden board where fresh toppings are chopped.
///
/// Place one vegetable, chop it [cutsNeeded] times, then [collect] the pile:
/// it yields [Topping.chopPortions] portions for that topping's tray.
class CuttingBoard {
  static const cutsNeeded = 3;

  /// What lies on the board, chopped or not.
  Topping? item;

  /// Cuts made so far (each tap draws one more cut).
  int cuts = 0;

  bool get isEmpty => item == null;

  bool get chopped => item != null && cuts >= cutsNeeded;

  /// Puts a whole [vegetable] on an empty board.
  bool place(Topping vegetable) {
    if (item != null || !vegetable.choppable) {
      return false;
    }
    item = vegetable;
    cuts = 0;
    return true;
  }

  /// One cut; refused when there is nothing to cut or it is done.
  bool chop() {
    if (item == null || chopped) {
      return false;
    }
    cuts++;
    return true;
  }

  /// Clears the chopped pile and returns its topping; null when it is not
  /// chopped yet. Portions are the topping's [Topping.chopPortions].
  Topping? collect() {
    if (!chopped) {
      return null;
    }
    final pile = item;
    item = null;
    cuts = 0;
    return pile;
  }
}
