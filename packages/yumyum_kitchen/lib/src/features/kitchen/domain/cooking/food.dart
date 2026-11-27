/// What a cooker can cook, with the timing of every step in milliseconds.
///
/// Times follow `.plan/2026-11-27_noodle-house-step-cooking.md`:
/// - [cookMs]: from load to done; for [Food.beef] it is one side.
/// - [flipMs]: beef only, how long the seared slice waits for a flip before
///   it chars. 0 means the food is never flipped.
/// - [perfectMs]: the green window right after it is done (tip bonus).
/// - [readyMs]: the yellow window after that; then it is ruined.
/// - [portions]: how many servings one batch gives.
enum Food {
  noodles(cookMs: 3000, perfectMs: 2000, readyMs: 4000, portions: 1),
  fishBalls(
    cookMs: 2500,
    perfectMs: 2000,
    readyMs: 4000,
    portions: 4,
    topping: Topping.fishBall,
  ),
  beef(
    cookMs: 2000,
    flipMs: 2500,
    perfectMs: 1500,
    readyMs: 3000,
    portions: 2,
    topping: Topping.beef,
  ),
  eggs(
    cookMs: 4000,
    perfectMs: 2000,
    readyMs: 5000,
    portions: 4,
    topping: Topping.egg,
  ),
  shrimp(
    cookMs: 3000,
    perfectMs: 1500,
    readyMs: 3000,
    portions: 3,
    topping: Topping.shrimp,
  ),
  tea(cookMs: 2000, perfectMs: 2000, readyMs: 10000, portions: 1);

  const Food({
    required this.cookMs,
    required this.perfectMs,
    required this.readyMs,
    required this.portions,
    this.flipMs = 0,
    this.topping,
  });

  final int cookMs;
  final int flipMs;
  final int perfectMs;
  final int readyMs;
  final int portions;

  /// The tray a finished batch goes to; null for noodles (a bowl) and tea
  /// (a cup).
  final Topping? topping;

  bool get flips => flipMs > 0;
}

/// Bowl toppings and how they are prepared.
///
/// - [hot]: cooked toppings that go cold in their tray.
/// - [chopPortions]: chopped on the board into this many portions; 0 when
///   not chopped.
/// - [unlimited]: condiment jars that never run out.
enum Topping {
  onion(chopPortions: 5),
  coriander(chopPortions: 5),
  chilli(chopPortions: 5),
  lime(chopPortions: 4),
  egg(hot: true),
  beef(hot: true),
  shrimp(hot: true),
  fishBall(hot: true),
  garlic(unlimited: true),
  chilliOil(unlimited: true);

  const Topping({
    this.hot = false,
    this.chopPortions = 0,
    this.unlimited = false,
  });

  final bool hot;
  final int chopPortions;
  final bool unlimited;

  bool get choppable => chopPortions > 0;
}
