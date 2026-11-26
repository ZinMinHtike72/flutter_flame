import "dart:math";
import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

KitchenRun shift(
  int level, {
  bool guided = false,
  Set<Upgrade> upgrades = const {},
}) => KitchenRun(
  shift: campaign[level - 1],
  id: "shift-$level",
  random: Random(42),
  tutorial: guided,
  upgrades: upgrades,
);

void main() {
  test(
    "guided sale freezes patience and clock until the first plain order",
    () {
      final run = shift(1, guided: true);
      run.tap(Station.pot);
      run.tap(Station.pack);
      run.tap(Station.pack);
      run.advance(2999);
      expect(run.pots.first.phase, PotPhase.cooking);
      run.advance(1);
      expect(run.guide, Guide.pot);
      run.advance(120000);
      expect(run.elapsed, 0);
      run.tap(Station.pot);
      expect(run.guide, Guide.serve);
      run.tap(Station.bowl);
      expect(run.guide, Guide.done);
      expect(run.coins, 80);
      run.advance(1000);
      expect(run.secondsLeft, 44);
    },
  );
  test("burn boundary, full bowls, first free pot, pause and discard", () {
    final run = shift(5, upgrades: {Upgrade.extraPot, Upgrade.fastBoil});
    run.tap(Station.pack);
    run.tap(Station.pack);
    run.advance(2100);
    expect(run.pots.every((p) => p.phase == PotPhase.ready), isTrue);
    run.tap(Station.pot, 1);
    run.tap(Station.pot);
    run.tap(Station.pack);
    run.advance(2100);
    run.tap(Station.pot);
    expect(run.pots[0].phase, PotPhase.ready);
    run.paused = true;
    run.advance(9000);
    run.tap(Station.bowl);
    expect(run.now, 4200);
    run.paused = false;
    run.advance(5999);
    expect(run.pots[0].phase, PotPhase.ready);
    run.advance(1);
    expect(run.pots[0].phase, PotPhase.burnt);
    run.chain = 4;
    run.tap(Station.pot);
    expect(run.chain, 0);
    expect(run.pots[0].phase, PotPhase.empty);
  });
  test("exact matching, topping priority, ties, rejection and recovery", () {
    final run = shift(8);
    run.bowls[0] = {};
    run.bowls[1] = {};
    run.tap(Station.garnish);
    run.tap(Station.garnish);
    run.tap(Station.garnish, 1);
    expect(run.bowls, [
      {Garnish.onion, Garnish.egg},
      {Garnish.onion},
    ]);
    run.customers[0] = const Customer(
      0,
      0,
      {Garnish.egg, Garnish.onion},
      0,
      20000,
    );
    run.customers[1] = const Customer(
      1,
      1,
      {Garnish.onion, Garnish.egg},
      0,
      15000,
    );
    run.customers[2] = const Customer(
      2,
      2,
      {Garnish.egg, Garnish.onion},
      0,
      15000,
    );
    run.tap(Station.bowl);
    expect(run.servedSlot, 1);
    expect(run.coins, 120);
    run.tap(Station.bowl, 1);
    expect(run.discardBowl, 1);
    run.tap(Station.discard, 1);
    expect(run.bowls[1], isNull);
  });
  test(
    "streak cap, five-second boundary, half-patience speed boundary and expiry",
    () {
      final run = shift(12, upgrades: {Upgrade.premiumBowl});
      void serve({int age = 0}) {
        run.customers[0] = Customer(0, 0, {}, run.now - age, run.now + 20000);
        run.bowls[0] = {};
        run.tap(Station.bowl);
      }

      for (var i = 0; i < 6; i++) {
        serve();
      }
      expect(run.chain, 6);
      expect(run.lastReward, 210);
      run.advance(5000);
      serve();
      expect(run.chain, 7);
      run.advance(5001);
      serve();
      expect(run.chain, 1);
      serve(age: run.shift.patienceMs ~/ 2);
      expect(run.chain, 0);
      expect(run.lastReward, 85);
      run.advance(30000);
      expect(run.missed, greaterThan(0));
    },
  );
  for (final level in campaign) {
    test(
      "starting equipment can clear shift ${level.number} with legal taps",
      () {
        final run = shift(level.number, guided: level.number == 1);
        while (!run.ended) {
          run.tap(Station.pack);
          final waiting = run.customers.nonNulls.toList()
            ..sort((a, b) => a.expires.compareTo(b.expires));
          if (waiting.isNotEmpty && run.pots.first.phase == PotPhase.ready) {
            run.tap(Station.pot);
            for (final topping in waiting.first.toppings) {
              run.tap(Station.garnish, topping.index);
            }
            run.tap(Station.bowl);
          }
          run.advance(100);
        }
        expect(run.won, isTrue, reason: "${run.progress} / ${level.target}");
        expect(run.elapsed, level.seconds * 1000);
        final total = run.coins;
        run.tap(Station.bowl);
        run.advance(100);
        expect(run.coins, total);
      },
    );
  }
  test("a missed customer resets the streak and the lanterns", () {
    final run = shift(12);
    run.chain = 3;
    final first = run.customers.nonNulls.first;
    run.advance(first.expires - run.now);
    expect(run.missed, 1);
    expect(run.cue, KitchenCue.missed);
    expect(run.chain, 0);
  });

  test("campaign: three products, up to four customers, 1500 in 90 s", () {
    expect(campaign, hasLength(12));
    expect({for (final s in campaign) s.product}, NoodleProduct.values.toSet());
    for (final s in campaign) {
      expect(s.product, NoodleProduct.values[(s.number - 1) ~/ 4]);
      expect(s.slots, inInclusiveRange(2, 4));
    }
    expect(campaign.map((s) => s.slots).reduce(max), 4);
    final finale = campaign.last;
    expect(finale.goal, Goal.coins);
    expect(finale.target, 1500);
    expect(finale.seconds, 90);
  });
}
