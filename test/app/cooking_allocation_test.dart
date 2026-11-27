import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cutting_board.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/topping_tray.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

import "../helpers/allocation_trace.dart";

/// A full day-12 kitchen line run by a scripted chef: two pots, three grill
/// places, egg boiler, fryer, tea urn, every tray, the cutting board, and
/// three bowls assembled and served to a four-table dining room with one
/// waiter seating, carrying, pouring tea and clearing.
class _Kitchen {
  final cookers = [
    Cooker(CookerKind.pot),
    Cooker(CookerKind.pot),
    Cooker(CookerKind.grill),
    Cooker(CookerKind.grill),
    Cooker(CookerKind.grill),
    Cooker(CookerKind.eggBoiler),
    Cooker(CookerKind.fryer),
    Cooker(CookerKind.teaUrn),
  ];
  final trays = [for (final t in Topping.values) ToppingTray(t)];
  final board = CuttingBoard();
  final rack = BowlRack(3);
  final dining = Dining(tables: 4);

  /// Built once; guests walk in again and again.
  final guests = [
    const Guest(1, Recipe(Soup.chicken), 40000),
    Guest(2, Recipe.of(Soup.tomYum, toppings: [Topping.beef]), 40000),
    Guest(3, Recipe.of(Soup.mala, toppings: [Topping.onion]), 9000),
  ];
  int waiterAt = 0;
  int served = 0;
  final clock = FixedStepClock();
  int now = 0;
  int steps = 0;
  int perfect = 0;
  int progress = 0;
  late final void Function(int ms) _step = _rulesStep;

  void frame() => clock.advance(1000 / 30, _step);

  void _rulesStep(int ms) {
    now += ms;
    steps++;
    for (var i = 0; i < cookers.length; i++) {
      final cooker = cookers[i]..advanceTo(now);
      progress += cooker.progressPermille(now);
      _chef(cooker, i);
    }
    // Chop greens and use a few portions now and then.
    if (steps % 7 == 0) {
      if (board.isEmpty) {
        board.place(Topping.values[steps % 4]);
      } else if (!board.chop()) {
        final pile = board.collect()!;
        trays[pile.index].add(pile.chopPortions, now);
      }
    }
    if (steps % 13 == 0) {
      _assemble();
    }
    dining.advanceTo(now);
    waiterAt += dining.waiters[0].positionAt(now);
    if (steps % 90 == 0) {
      dining.arrive(guests[(steps ~/ 90) % guests.length], now);
    }
    if (steps % 17 == 0) {
      for (var t = 0; t < dining.tables.length; t++) {
        dining.tapTable(t, now);
      }
    }
    if (steps % 11 == 0) {
      for (var t = 0; t < trays.length; t++) {
        trays[t]
          ..take(now)
          ..coldCount(now)
          ..nextIsCold(now);
      }
    }
  }

  /// Broth, a topping, then serve to the matching ticket or bin the bowl.
  void _assemble() {
    final bowl = rack.current;
    if (!bowl.noodles) {
      return;
    }
    if (bowl.addSoup(Soup.values[steps % 3]) != Assembly.added) {
      final topping = steps.isEven ? Topping.beef : Topping.onion;
      if (bowl.checkTopping(topping) == Assembly.added) {
        bowl.addTopping(topping, trays[topping.index].take(now));
      }
    }
    if (dining.serve(bowl, now) >= 0) {
      served++;
    } else if (Recipe.countOf(bowl.toppings) > 0 && bowl.soup != null) {
      bowl.clear();
    }
    rack.autoSelect(dining.tickets);
  }

  /// Fills, loads, flips, takes out and bins, staggered by station.
  void _chef(Cooker cooker, int i) {
    if ((steps + i) % 5 != 0) {
      return;
    }
    switch (cooker.phase) {
      case CookPhase.empty:
        cooker.fill(now);
      case CookPhase.hot:
        cooker.load(_foods[i], now);
      case CookPhase.needsFlip:
        cooker.flip(now);
      case CookPhase.perfect:
      case CookPhase.ready:
        // Leave every third batch to ruin, so binning runs too.
        if ((steps ~/ 5) % 3 != 0) {
          final food = cooker.food!;
          if (food == Food.noodles &&
              rack.current.checkNoodles() != Assembly.added) {
            return;
          }
          final doneness = cooker.takeOut(now);
          if (doneness == Doneness.perfect) {
            perfect++;
          }
          final topping = food.topping;
          if (topping != null) {
            trays[topping.index].add(
              food.portions,
              now,
              perfect: doneness == Doneness.perfect,
            );
          } else if (food == Food.noodles) {
            rack.current.addNoodles(doneness);
            rack.autoSelect(dining.tickets);
          }
        }
      case CookPhase.ruined:
        cooker.bin(now);
      case CookPhase.heating:
      case CookPhase.cooking:
    }
  }

  static const _foods = [
    Food.noodles,
    Food.fishBalls,
    Food.beef,
    Food.beef,
    Food.beef,
    Food.eggs,
    Food.shrimp,
    Food.tea,
  ];
}

void main() {
  test("cooking and assembly rules steps allocate nothing", () async {
    final uri = await vmServiceUri();
    if (uri == null) {
      markTestSkipped(
        "Needs the VM service: run `flutter test --enable-vmservice` "
        "(make test does).",
      );
      return;
    }
    final kitchen = _Kitchen();
    void frames(int n) {
      for (var i = 0; i < n; i++) {
        kitchen.frame();
      }
    }

    const steadyFrames = 3000;
    final found = await traceAllocations(
      uri,
      ours: const {
        "Cooker",
        "ToppingTray",
        "CuttingBoard",
        "Bowl",
        "BowlRack",
        "ticketFor",
        "mostUrgent",
        "Dining",
        "Waiter",
      },
      traced: {...guardedClasses, "_Double", "_Mint"},
      warmUp: () => frames(1000),
      measure: () => frames(steadyFrames),
    );
    // The script really exercised every phase.
    expect(kitchen.steps, greaterThan(3500));
    expect(kitchen.perfect, greaterThan(50));
    expect(kitchen.progress, greaterThan(0));
    expect(kitchen.served, greaterThan(5));
    expect(kitchen.dining.coins, greaterThan(0), reason: "tables cleared");
    expect(kitchen.waiterAt, greaterThan(0));
    expect(
      kitchen.trays.where((t) => t.topping.choppable).any((t) => t.count > 0),
      isTrue,
    );
    expect(found, isEmpty, reason: "cooking rules allocate: $found");
  });
}
