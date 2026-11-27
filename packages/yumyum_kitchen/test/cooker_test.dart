import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cutting_board.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/topping_tray.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

/// Expects [cooker] to be in [phase] just before [at] and in [next] at [at].
void expectBoundary(Cooker cooker, int at, CookPhase phase, CookPhase next) {
  cooker.advanceTo(at - 1);
  expect(cooker.phase, phase, reason: "1 ms before $at");
  cooker.advanceTo(at);
  expect(cooker.phase, next, reason: "at $at");
  expect(cooker.phaseStart, at);
}

/// Every phase a cooker enters, with the time it entered it.
List<(CookPhase, int)> _timeline(
  Cooker cooker,
  void Function(void Function(int now) advance) drive,
) {
  final seen = <(CookPhase, int)>[(cooker.phase, cooker.phaseStart)];
  drive((now) {
    cooker.advanceTo(now);
    if (seen.last != (cooker.phase, cooker.phaseStart)) {
      // One change per 30 Hz step is enough: no two deadlines here are
      // closer than a step. The time is the cooker's own exact start.
      seen.add((cooker.phase, cooker.phaseStart));
    }
  });
  return seen;
}

void main() {
  group("noodle pot: water → boil → noodles → ready → soggy", () {
    test("refuses noodles until the water boils", () {
      final pot = Cooker(CookerKind.pot);
      expect(pot.phase, CookPhase.empty);
      expect(pot.load(Food.noodles, 0), isFalse, reason: "no water");
      expect(pot.fill(0), isTrue);
      expect(pot.fill(10), isFalse, reason: "already filled");
      expect(pot.phase, CookPhase.heating);
      expect(pot.load(Food.noodles, 100), isFalse, reason: "cold water");
      expectBoundary(pot, 2500, CookPhase.heating, CookPhase.hot);
      expect(pot.deadline, Cooker.noDeadline, reason: "boils until used");
      pot.advanceTo(60000);
      expect(pot.phase, CookPhase.hot);
    });

    test("cooks, gives a perfect window, then a ready one", () {
      final pot = Cooker(CookerKind.pot)
        ..fill(0)
        ..advanceTo(2500);
      expect(pot.load(Food.beef, 2600), isFalse, reason: "not a pot food");
      expect(pot.load(Food.noodles, 3000), isTrue);
      expect(pot.load(Food.noodles, 3001), isFalse, reason: "already full");
      expect(pot.busy, isTrue);
      expect(pot.takeOut(5999), Doneness.none, reason: "still cooking");
      expectBoundary(pot, 6000, CookPhase.cooking, CookPhase.perfect);
      expectBoundary(pot, 8000, CookPhase.perfect, CookPhase.ready);
      expectBoundary(pot, 12000, CookPhase.ready, CookPhase.ruined);
    });

    test("taking noodles out empties the pot and names the food", () {
      final pot = Cooker(CookerKind.pot)
        ..fill(0)
        ..advanceTo(2500)
        ..load(Food.noodles, 2500)
        ..advanceTo(5500);
      expect(pot.takeOut(5500), Doneness.perfect);
      expect(pot.food, Food.noodles);
      expect(pot.phase, CookPhase.empty, reason: "needs water again");
      expect(pot.takeOut(5600), Doneness.none);

      pot
        ..fill(6000)
        ..advanceTo(8500)
        ..load(Food.noodles, 8500)
        ..advanceTo(8500 + 3000 + 2000);
      expect(pot.takeOut(13500), Doneness.ready, reason: "after the green");
    });

    test("soggy noodles stay until binned", () {
      final pot = Cooker(CookerKind.pot)
        ..fill(0)
        ..advanceTo(2500)
        ..load(Food.noodles, 2500)
        ..advanceTo(20000);
      expect(pot.phase, CookPhase.ruined);
      expect(pot.food, Food.noodles, reason: "drawn soggy");
      expect(pot.busy, isFalse);
      expect(pot.takeOut(20000), Doneness.none);
      expect(pot.load(Food.noodles, 20000), isFalse);
      pot.advanceTo(90000);
      expect(pot.phase, CookPhase.ruined, reason: "never clears itself");
      expect(pot.bin(90000), isTrue);
      expect(pot.phase, CookPhase.empty);
      expect(pot.bin(90001), isFalse, reason: "nothing to bin");
    });

    test("fish balls boil in the same pot", () {
      final pot = Cooker(CookerKind.pot)
        ..fill(0)
        ..advanceTo(2500);
      expect(pot.load(Food.fishBalls, 2500), isTrue);
      expectBoundary(pot, 5000, CookPhase.cooking, CookPhase.perfect);
    });
  });

  group("grill: raw → seared → flip → cooked → charred", () {
    test("the first side waits for a flip, then the second side cooks", () {
      final grill = Cooker(CookerKind.grill);
      expect(grill.phase, CookPhase.hot, reason: "always hot");
      expect(grill.fill(0), isFalse);
      expect(grill.flip(0), isFalse, reason: "nothing to flip");
      expect(grill.load(Food.noodles, 0), isFalse);
      expect(grill.load(Food.beef, 1000), isTrue);
      expectBoundary(grill, 3000, CookPhase.cooking, CookPhase.needsFlip);
      expect(grill.takeOut(3100), Doneness.none, reason: "half raw");
      expect(grill.flip(3200), isTrue);
      expect(grill.flipped, isTrue);
      expect(grill.flip(3201), isFalse);
      expectBoundary(grill, 5200, CookPhase.cooking, CookPhase.perfect);
      expectBoundary(grill, 6700, CookPhase.perfect, CookPhase.ready);
      expectBoundary(grill, 9700, CookPhase.ready, CookPhase.ruined);
    });

    test("an unflipped slice chars", () {
      final grill = Cooker(CookerKind.grill)..load(Food.beef, 0);
      expectBoundary(grill, 2000, CookPhase.cooking, CookPhase.needsFlip);
      expectBoundary(grill, 4500, CookPhase.needsFlip, CookPhase.ruined);
      expect(grill.flip(4500), isFalse, reason: "too late");
      expect(grill.bin(4600), isTrue);
      expect(grill.phase, CookPhase.hot, reason: "grill stays hot");
    });

    test("taking cooked beef out keeps the grill hot for the next slice", () {
      final grill = Cooker(CookerKind.grill)
        ..load(Food.beef, 0)
        ..advanceTo(2000)
        ..flip(2000)
        ..advanceTo(4000);
      expect(grill.takeOut(4000), Doneness.perfect);
      expect(grill.food, Food.beef);
      expect(grill.flipped, isFalse);
      expect(grill.phase, CookPhase.hot);
      expect(grill.load(Food.beef, 4100), isTrue);
    });
  });

  test("each station cooks only its own food, in its own time", () {
    for (final kind in CookerKind.values) {
      for (final food in Food.values) {
        final cooker = Cooker(kind);
        if (kind.needsWater) {
          cooker
            ..fill(0)
            ..advanceTo(kind.heatMs);
        }
        final start = kind.heatMs;
        expect(
          cooker.load(food, start),
          kind.accepts(food),
          reason: "$kind takes $food",
        );
        if (!kind.accepts(food)) {
          continue;
        }
        var done = start + food.cookMs;
        if (food.flips) {
          cooker
            ..advanceTo(done)
            ..flip(done);
          done += food.cookMs;
        }
        expectBoundary(cooker, done, CookPhase.cooking, CookPhase.perfect);
        expect(cooker.takeOut(done), Doneness.perfect);
      }
    }
    expect(
      [for (final k in CookerKind.values) k.needsWater],
      [true, false, false, false, false],
      reason: "only the pot needs water",
    );
  });

  group("timing", () {
    // A whole noodle batch from filling to soggy.
    const expected = [
      (CookPhase.heating, 0),
      (CookPhase.hot, 2500),
      (CookPhase.cooking, 2500),
      (CookPhase.perfect, 5500),
      (CookPhase.ready, 7500),
      (CookPhase.ruined, 11500),
    ];

    Cooker filled() => Cooker(CookerKind.pot)..fill(0);

    test("30 Hz rules steps change phase at the exact deadlines", () {
      final pot = filled();
      final clock = FixedStepClock();
      var now = 0;
      final timeline = _timeline(pot, (advance) {
        for (var frame = 0; frame < 400; frame++) {
          clock.advance(1000 / 30, (ms) {
            now += ms;
            advance(now);
            // The player drops noodles on the first step after the boil.
            if (pot.phase == CookPhase.hot) {
              pot.load(Food.noodles, pot.phaseStart);
            }
          });
        }
      });
      expect(now, greaterThan(11500));
      expect(timeline, expected);
    });

    test("one slow frame lands in the same state as many small steps", () {
      final pot = filled()..advanceTo(2500);
      expect(pot.load(Food.noodles, 2500), isTrue);
      pot.advanceTo(30000);
      expect(pot.phase, CookPhase.ruined);
      expect(pot.phaseStart, 11500, reason: "ruined at its deadline");

      final grill = Cooker(CookerKind.grill)..load(Food.beef, 0);
      grill.advanceTo(10000);
      expect(grill.phase, CookPhase.ruined);
      expect(grill.phaseStart, 4500, reason: "charred, never flipped");
    });

    test("progress runs 0 to 1000 through a timed phase", () {
      final grill = Cooker(CookerKind.grill);
      expect(grill.progressPermille(0), 0, reason: "untimed");
      grill.load(Food.beef, 1000);
      expect(grill.progressPermille(1000), 0);
      expect(grill.progressPermille(2000), 500);
      expect(grill.progressPermille(2999), 999);
      expect(grill.progressPermille(500), 0, reason: "clamped below");
      grill.advanceTo(3000);
      expect(grill.progressPermille(3000), 0, reason: "new phase");
      expect(grill.progressPermille(99999), 1000, reason: "clamped above");
    });
  });

  group("topping tray", () {
    test("hands out the oldest portion; hot ones go cold at 25 s", () {
      final tray = ToppingTray(Topping.beef)..add(2, 1000);
      expect(tray.add(1, 5000), 1);
      expect(tray.count, 3);
      expect(tray.nextIsCold(25999), isFalse);
      expect(tray.nextIsCold(26000), isTrue);
      expect(tray.coldCount(26000), 2);
      expect(tray.coldCount(30000), 3);
      expect(tray.take(25999), Portion.fresh);
      expect(tray.take(26000), Portion.cold);
      expect(tray.take(26000), Portion.fresh, reason: "added at 5 s");
      expect(tray.take(26000), Portion.none);
      expect(tray.isEmpty, isTrue);
      expect(tray.nextIsCold(99999), isFalse);
    });

    test("a perfect batch stays perfect until it goes cold", () {
      final tray = ToppingTray(Topping.beef)
        ..add(1, 0, perfect: true)
        ..add(1, 0)
        ..add(1, 0, perfect: true);
      expect(tray.take(1000), Portion.perfect);
      expect(tray.take(1000), Portion.fresh, reason: "a ready batch");
      expect(tray.take(25000), Portion.cold, reason: "cold loses the bonus");
      final greens = ToppingTray(Topping.onion)..add(1, 0, perfect: true);
      expect(greens.take(900000), Portion.perfect, reason: "never cold");
    });

    test("the heat lamp keeps portions fresh longer", () {
      final tray = ToppingTray(Topping.egg, freshMs: 45000)..add(1, 0);
      expect(tray.take(44999), Portion.fresh);
      tray.add(1, 0);
      expect(tray.take(45000), Portion.cold);
    });

    test("fresh greens never go cold", () {
      final tray = ToppingTray(Topping.onion)..add(5, 0);
      expect(tray.coldCount(600000), 0);
      expect(tray.take(600000), Portion.fresh);
    });

    test("is capped and wraps its ring buffer in order", () {
      final tray = ToppingTray(Topping.shrimp, capacity: 4);
      expect(tray.add(6, 0), 4, reason: "only four fit");
      expect(tray.room, 0);
      expect(tray.add(1, 0), 0);
      for (var i = 0; i < 3; i++) {
        tray.take(0);
      }
      expect(tray.add(3, 30000), 3, reason: "wraps around the end");
      expect(tray.count, 4);
      expect(tray.take(30000), Portion.cold, reason: "the old one first");
      for (var i = 0; i < 3; i++) {
        expect(tray.take(30000), Portion.fresh);
      }
      expect(tray.take(30000), Portion.none);
    });

    test("condiment jars never run out", () {
      final jar = ToppingTray(Topping.chilliOil);
      expect(jar.count, ToppingTray.defaultCapacity);
      expect(jar.room, 0);
      expect(jar.add(3, 0), 0);
      for (var i = 0; i < 50; i++) {
        expect(jar.take(i * 1000000), Portion.fresh);
      }
      expect(jar.isEmpty, isFalse);
    });
  });

  group("cutting board", () {
    test("three cuts turn a vegetable into a pile of portions", () {
      final board = CuttingBoard();
      expect(board.chop(), isFalse, reason: "nothing on the board");
      expect(board.collect(), isNull);
      expect(board.place(Topping.beef), isFalse, reason: "not chopped here");
      expect(board.place(Topping.onion), isTrue);
      expect(board.place(Topping.lime), isFalse, reason: "board is taken");
      expect(board.collect(), isNull, reason: "still whole");
      for (var i = 1; i <= CuttingBoard.cutsNeeded; i++) {
        expect(board.chopped, isFalse);
        expect(board.chop(), isTrue);
        expect(board.cuts, i);
      }
      expect(board.chopped, isTrue);
      expect(board.chop(), isFalse, reason: "already chopped");
      expect(board.collect(), Topping.onion);
      expect(board.isEmpty, isTrue);
      expect(board.cuts, 0);
    });

    test("portions per vegetable", () {
      expect(
        {
          for (final t in Topping.values)
            if (t.choppable) t: t.chopPortions,
        },
        {
          Topping.onion: 5,
          Topping.coriander: 5,
          Topping.chilli: 5,
          Topping.lime: 4,
        },
      );
    });
  });

  test("cooked toppings are hot and land in their tray", () {
    expect(
      {
        for (final f in Food.values)
          if (f.topping != null) f: f.topping,
      },
      {
        Food.fishBalls: Topping.fishBall,
        Food.beef: Topping.beef,
        Food.eggs: Topping.egg,
        Food.shrimp: Topping.shrimp,
      },
    );
    for (final f in Food.values) {
      expect(f.topping?.hot ?? true, isTrue, reason: "$f");
      expect(f.flips, f == Food.beef);
    }
    expect(
      [
        for (final t in Topping.values)
          if (t.unlimited) t,
      ],
      [Topping.garlic, Topping.chilliOil],
    );
  });
}
