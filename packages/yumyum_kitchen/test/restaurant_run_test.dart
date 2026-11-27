import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

RestaurantRun _day1() => RestaurantRun(day: restaurantDays.first, id: "d1");

/// One human-paced decision: the most useful single tap, if any.
bool _chefTap(RestaurantRun run) {
  for (var i = 0; i < run.dining.tables.length; i++) {
    if (run.dining.tables[i].phase == TablePhase.dirty &&
        !run.dining.tables[i].clearQueued) {
      return run.tap(RestaurantSpot.table, i);
    }
  }
  for (var i = 0; i < run.rack.bowls.length; i++) {
    final bowl = run.rack.bowls[i];
    if (bowl.soup != null) {
      return run.tap(RestaurantSpot.bowl, i);
    }
  }
  final bowl = run.rack.current;
  if (bowl.noodles && bowl.soup == null) {
    return run.tap(RestaurantSpot.stockpot);
  }
  for (var i = 0; i < run.pots.length; i++) {
    final phase = run.pots[i].phase;
    if (phase == CookPhase.perfect || phase == CookPhase.empty) {
      return run.tap(RestaurantSpot.pot, i);
    }
  }
  final waiting = run.dining.tickets.where((t) => t != null).length;
  final cooking = run.pots.where((p) => p.busy).length;
  if (waiting > cooking && run.pots.any((p) => p.phase == CookPhase.hot)) {
    return run.tap(RestaurantSpot.pack);
  }
  return false;
}

void main() {
  test("day 1 is winnable by a chef tapping every 300 ms", () {
    final run = _day1();
    final clock = FixedStepClock();
    var nextTap = 0;
    while (!run.ended) {
      clock.advance(1000 / 30, (ms) {
        run.advance(ms);
        if (run.now >= nextTap && _chefTap(run)) {
          nextTap = run.now + 300;
        }
      });
    }
    expect(run.won, isTrue);
    expect(run.served, greaterThanOrEqualTo(run.target));
    expect(run.missed, 0);
    expect(run.coins, greaterThan(run.served * 40), reason: "tips paid");
    expect(run.bestChain, run.served);
    expect(run.guestsLeft, 0);
    expect(run.secondsLeft, 0);
    final saved = const KitchenProgress().settle(run);
    expect(saved.unlocked, 2, reason: "winning day 1 opens day 2");
    expect(saved.best[1], run.coins);
    expect(saved.settle(run), same(saved), reason: "banked once");
  });

  group("a day 1 bowl, step by step", () {
    test("water, boil, noodles, bowl, broth, serve", () {
      final run = _day1();
      expect(run.tap(RestaurantSpot.pack), isFalse, reason: "no water yet");
      expect(run.cue, RestaurantCue.rejected);
      expect(run.tap(RestaurantSpot.pot), isTrue);
      expect(run.cue, RestaurantCue.water);
      expect(run.pots[0].phase, CookPhase.heating);
      expect(run.tap(RestaurantSpot.pack), isFalse, reason: "not boiling");
      expect(run.tap(RestaurantSpot.pot), isFalse, reason: "still heating");
      run.advance(2500);
      expect(run.pots[0].phase, CookPhase.hot);
      expect(run.dining.tables[0].phase, TablePhase.booked, reason: "1.5 s");
      expect(run.tap(RestaurantSpot.pack), isTrue);
      expect(run.cue, RestaurantCue.noodles);
      expect(run.tap(RestaurantSpot.stockpot), isFalse, reason: "no noodles");
      run.advance(3000);
      expect(run.pots[0].phase, CookPhase.perfect);
      expect(run.tap(RestaurantSpot.pot), isTrue);
      expect(run.cue, RestaurantCue.bowlFilled);
      expect(run.rack.current.noodles, isTrue);
      expect(run.rack.current.perfectItems, 1);
      expect(run.pots[0].phase, CookPhase.empty, reason: "needs water again");
      expect(run.tap(RestaurantSpot.stockpot), isTrue);
      expect(run.cue, RestaurantCue.ladle);
      expect(run.tap(RestaurantSpot.stockpot), isFalse, reason: "one broth");
      final full = run.rack.selected;
      // The guest walked in at 1.5 s and has been seated since.
      expect(run.dining.tickets[0], isNotNull);
      expect(run.tap(RestaurantSpot.bowl, full), isTrue);
      expect(run.cue, RestaurantCue.served);
      expect(run.served, 1);
      expect(run.rack.bowls[full].isEmpty, isTrue);
      expect(run.dining.tables[0].phase, TablePhase.served);
    });

    test("an unfinished bowl is selected, not served; the bin empties it", () {
      final run = _day1();
      expect(run.tap(RestaurantSpot.bowl, 2), isTrue);
      expect(run.cue, RestaurantCue.selected);
      expect(run.rack.selected, 2);
      expect(run.tap(RestaurantSpot.bowl, 3), isFalse, reason: "no bowl 3");
      expect(run.tap(RestaurantSpot.bin), isFalse, reason: "already empty");
      run.rack.current.usePaperBowl();
      expect(run.tap(RestaurantSpot.bin), isTrue);
      expect(run.cue, RestaurantCue.binned);
      expect(run.rack.bowls[2].isEmpty, isTrue);
      expect(run.tap(RestaurantSpot.stockpot, 1), isFalse, reason: "one pot");
      expect(run.tap(RestaurantSpot.pot, 5), isFalse);
      expect(run.tap(RestaurantSpot.table), isFalse, reason: "table 0 is free");
    });

    test("soggy noodles go in the bin", () {
      final run = _day1()..tap(RestaurantSpot.pot);
      run.advance(2500);
      run.tap(RestaurantSpot.pack);
      run.advance(10000);
      expect(run.pots[0].phase, CookPhase.ruined);
      expect(run.tap(RestaurantSpot.pot), isTrue);
      expect(run.cue, RestaurantCue.binned);
      expect(run.pots[0].phase, CookPhase.empty);
    });
  });

  group("the day", () {
    test("guests arrive at their times, even across a slow frame", () {
      final run = _day1()..advance(30000);
      expect(run.guestsLeft, 3, reason: "1.5 s, 12 s and 26 s");
      expect(run.dining.tables.map((t) => t.phase), [
        TablePhase.waiting,
        TablePhase.waiting,
      ]);
      expect(run.dining.waitingAtDoor, 1);
      final d = run.dining;
      final seated =
          1500 +
          d.walkMs(Dining.pass, Dining.door) +
          Dining.greetMs +
          d.walkMs(Dining.door, RestaurantDay.tableSpots[0]) +
          Dining.seatMs;
      expect(d.tickets[0]!.arrivedAt, seated);
    });

    test("ends after its time; taps and time stop", () {
      final run = _day1()..advance(119000);
      expect(run.secondsLeft, 1);
      expect(run.ended, isFalse);
      final sequence = run.feedbackSequence;
      run.advance(5000);
      expect(run.ended, isTrue);
      expect(run.elapsed, 120000, reason: "clamped to the day");
      expect(run.feedbackSequence, greaterThan(sequence));
      expect(run.tap(RestaurantSpot.pot), isFalse);
      run.advance(1000);
      expect(run.now, 120000);
      expect(run.won, isFalse);
      expect(run.missed, greaterThan(0), reason: "nobody was served");
    });

    test("pausing freezes the clock and refuses taps", () {
      final run = _day1()..paused = true;
      run.advance(5000);
      expect(run.now, 0);
      expect(run.tap(RestaurantSpot.pot), isFalse);
      run.paused = false;
      run.advance(5000);
      expect(run.now, 5000);
    });

    test("reports itself like any day", () {
      final run = _day1();
      expect(run.number, 1);
      expect(run.goal, Goal.customers);
      expect(run.target, 4);
      expect(run.product, NoodleProduct.originalChicken);
      expect(run.guide, Guide.done);
      expect(run.multiplierPercent, 100);
      expect(run.progress, 0);
      expect(run.secondsLeft, 120);
      expect(
        run.guests.map((g) => g.recipe),
        everyElement(const Recipe(Soup.chicken)),
      );
    });
  });
}
