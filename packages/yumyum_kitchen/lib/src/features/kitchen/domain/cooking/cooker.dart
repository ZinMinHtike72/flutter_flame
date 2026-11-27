import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";

/// A heat station on the kitchen line.
///
/// Only the noodle pot needs water: it starts [CookPhase.empty], heats for
/// [heatMs] after it is filled, and is empty again once its food is taken
/// out. Every other station is always hot.
enum CookerKind {
  pot(heatMs: 2500),
  grill,
  eggBoiler,
  fryer,
  teaUrn;

  const CookerKind({this.heatMs = 0});

  final int heatMs;

  bool get needsWater => heatMs > 0;

  bool accepts(Food food) => switch (this) {
    CookerKind.pot => food == Food.noodles || food == Food.fishBalls,
    CookerKind.grill => food == Food.beef,
    CookerKind.eggBoiler => food == Food.eggs,
    CookerKind.fryer => food == Food.shrimp,
    CookerKind.teaUrn => food == Food.tea,
  };
}

/// One station's state, in the order a batch passes through it:
/// - [empty]: a pot without water;
/// - [heating]: water heating (pot only), food is rejected;
/// - [hot]: ready for food (boiling water, hot grill, hot oil);
/// - [cooking]: the food cooks (one side, for beef);
/// - [needsFlip]: beef seared on one side, waiting to be flipped;
/// - [perfect]: done, inside the green window;
/// - [ready]: done, still good;
/// - [ruined]: soggy, charred, cracked or burnt; only the bin clears it.
enum CookPhase {
  empty,
  heating,
  hot,
  cooking,
  needsFlip,
  perfect,
  ready,
  ruined,
}

/// How well a batch was taken out; [none] when there was nothing to take.
enum Doneness { none, perfect, ready }

/// The step-by-step state machine shared by every heat station.
///
/// Time is the run's clock in milliseconds. Each timed phase ends at
/// [deadline]; [advanceTo] moves through every deadline up to `now`, each at
/// its exact time, so a slow frame ends in the same state as many small
/// steps. It allocates nothing, so it can run on every rules step.
class Cooker {
  Cooker(this.kind) : phase = kind.needsWater ? CookPhase.empty : CookPhase.hot;

  /// [deadline] of a phase that waits for the player.
  static const noDeadline = -1;

  final CookerKind kind;
  CookPhase phase;

  /// What is cooking, or was last cooking. Kept through [CookPhase.ruined]
  /// (to draw it burnt) and after [takeOut] (so the caller knows what came
  /// out and how many portions).
  Food? food;

  /// Beef only: whether the second side is cooking.
  bool flipped = false;

  /// When [phase] began.
  int phaseStart = 0;

  /// When [phase] ends by itself, or [noDeadline].
  int deadline = noDeadline;

  bool get busy =>
      phase != CookPhase.empty &&
      phase != CookPhase.hot &&
      phase != CookPhase.ruined;

  /// Pours water into an empty pot.
  bool fill(int now) {
    if (phase != CookPhase.empty) {
      return false;
    }
    _enter(CookPhase.heating, now, kind.heatMs);
    return true;
  }

  /// Puts [item] in. Only a hot station that cooks [item] takes it, so
  /// noodles dropped into cold water are refused.
  bool load(Food item, int now) {
    if (phase != CookPhase.hot || !kind.accepts(item)) {
      return false;
    }
    food = item;
    flipped = false;
    _enter(CookPhase.cooking, now, item.cookMs);
    return true;
  }

  /// Turns seared beef over to cook the second side.
  bool flip(int now) {
    if (phase != CookPhase.needsFlip) {
      return false;
    }
    flipped = true;
    _enter(CookPhase.cooking, now, food!.cookMs);
    return true;
  }

  /// Takes a finished batch out. Returns [Doneness.perfect] inside the green
  /// window (a tip bonus), [Doneness.ready] after it, and [Doneness.none]
  /// when nothing is done (ruined food needs [bin]). [food] still names
  /// what came out.
  Doneness takeOut(int now) {
    final result = switch (phase) {
      CookPhase.perfect => Doneness.perfect,
      CookPhase.ready => Doneness.ready,
      _ => Doneness.none,
    };
    if (result != Doneness.none) {
      _reset(now);
    }
    return result;
  }

  /// Throws ruined food away.
  bool bin(int now) {
    if (phase != CookPhase.ruined) {
      return false;
    }
    _reset(now);
    return true;
  }

  /// Runs every phase change due up to [now].
  void advanceTo(int now) {
    while (deadline != noDeadline && deadline <= now) {
      _expire(deadline);
    }
  }

  /// How far through the current timed phase, in thousandths (0–1000); 0
  /// for an untimed one. An int, so drawing progress rings every frame
  /// allocates nothing (a returned double is boxed).
  int progressPermille(int now) {
    if (deadline == noDeadline) {
      return 0;
    }
    final permille = (now - phaseStart) * 1000 ~/ (deadline - phaseStart);
    return permille < 0
        ? 0
        : permille > 1000
        ? 1000
        : permille;
  }

  void _expire(int at) {
    final item = food;
    switch (phase) {
      case CookPhase.heating:
        _enter(CookPhase.hot, at, 0);
      case CookPhase.cooking when item != null:
        if (item.flips && !flipped) {
          _enter(CookPhase.needsFlip, at, item.flipMs);
        } else {
          _enter(CookPhase.perfect, at, item.perfectMs);
        }
      case CookPhase.perfect when item != null:
        _enter(CookPhase.ready, at, item.readyMs);
      case CookPhase.needsFlip:
      case CookPhase.ready:
        _enter(CookPhase.ruined, at, 0);
      case _:
        deadline = noDeadline;
    }
  }

  void _reset(int now) {
    flipped = false;
    _enter(kind.needsWater ? CookPhase.empty : CookPhase.hot, now, 0);
  }

  void _enter(CookPhase next, int at, int durationMs) {
    phase = next;
    phaseStart = at;
    deadline = durationMs > 0 ? at + durationMs : noDeadline;
  }
}
