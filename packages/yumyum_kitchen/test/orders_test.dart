import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/topping_tray.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/pricing.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/ticket.dart";

final _chicken = Recipe.of(Soup.chicken);
final _beefEgg = Recipe.of(Soup.tomYum, toppings: [Topping.beef, Topping.egg]);

/// A bowl with noodles, [soup] and [toppings] (all fresh, cooked "ready").
Bowl _bowl({Soup? soup, List<Topping> toppings = const []}) {
  final bowl = Bowl()..addNoodles(Doneness.ready);
  if (soup != null) {
    bowl.addSoup(soup);
  }
  for (final t in toppings) {
    bowl.addTopping(t, Portion.fresh);
  }
  return bowl;
}

Ticket _ticket(int id, Recipe recipe, {int arrived = 0, int expires = 20000}) =>
    Ticket(id, recipe, arrived, expires);

void main() {
  group("recipe", () {
    test("toppings are a set: order never matters", () {
      expect(
        Recipe.of(Soup.tomYum, toppings: [Topping.egg, Topping.beef]),
        _beefEgg,
      );
      expect(
        Recipe.of(Soup.tomYum, toppings: [Topping.egg, Topping.beef]).hashCode,
        _beefEgg.hashCode,
      );
      expect(_beefEgg == Recipe.of(Soup.chicken), isFalse);
      expect(_beefEgg.has(Topping.beef), isTrue);
      expect(_beefEgg.has(Topping.lime), isFalse);
      expect(_beefEgg.toppingCount, 2);
      expect(_beefEgg.steps, 4, reason: "noodles, broth, two toppings");
      expect(_chicken.steps, 2);
      expect(Recipe.countOf(0), 0);
      expect(Recipe.countOf(Recipe.maskOf(Topping.values)), 10);
      expect(Soup.values.where((s) => s.dry), [Soup.mala]);
      expect(
        Recipe.of(
          Soup.mala,
          toppings: [Topping.chilli],
          drink: Drink.milkTea,
          takeaway: true,
        ).toString(),
        "Recipe(Soup.mala, [chilli], Drink.milkTea, takeaway)",
      );
    });
  });

  group("bowl assembly", () {
    test("noodles go in first", () {
      final bowl = Bowl();
      expect(bowl.isEmpty, isTrue);
      expect(bowl.addSoup(Soup.chicken), Assembly.needsNoodles);
      expect(
        bowl.addTopping(Topping.onion, Portion.fresh),
        Assembly.needsNoodles,
      );
      expect(bowl.soup, isNull, reason: "refused steps change nothing");
      expect(bowl.toppings, 0);
      expect(bowl.addNoodles(Doneness.ready), Assembly.added);
      expect(bowl.addNoodles(Doneness.ready), Assembly.alreadyHasNoodles);
      expect(bowl.isEmpty, isFalse);
    });

    test("one broth only, and no topping twice", () {
      final bowl = _bowl();
      expect(bowl.checkSoup(), Assembly.added);
      expect(bowl.soup, isNull, reason: "checking does not add");
      expect(bowl.addSoup(Soup.chicken), Assembly.added);
      expect(bowl.addSoup(Soup.tomYum), Assembly.alreadyHasSoup);
      expect(bowl.soup, Soup.chicken);
      expect(bowl.checkTopping(Topping.lime), Assembly.added);
      expect(bowl.addTopping(Topping.lime, Portion.fresh), Assembly.added);
      expect(
        bowl.addTopping(Topping.lime, Portion.fresh),
        Assembly.alreadyHasTopping,
      );
      expect(bowl.checkTopping(Topping.lime), Assembly.alreadyHasTopping);
    });

    test("toppings may go in before the broth", () {
      final bowl = _bowl(toppings: [Topping.egg])..addSoup(Soup.chicken);
      expect(
        bowl.matches(Recipe.of(Soup.chicken, toppings: [Topping.egg])),
        isTrue,
      );
    });

    test("counts perfect and cold items for the tip", () {
      final bowl = Bowl()
        ..addNoodles(Doneness.perfect)
        ..addTopping(Topping.beef, Portion.perfect)
        ..addTopping(Topping.egg, Portion.cold)
        ..addTopping(Topping.onion, Portion.fresh);
      expect(bowl.perfectItems, 2);
      expect(bowl.coldItems, 1);
      bowl
        ..addTopping(Topping.beef, Portion.perfect)
        ..addNoodles(Doneness.perfect);
      expect(bowl.perfectItems, 2, reason: "refused steps never count");
      bowl.clear();
      expect(bowl.isEmpty, isTrue);
      expect([bowl.perfectItems, bowl.coldItems, bowl.toppings], [0, 0, 0]);
      expect(bowl.soup, isNull);
    });

    test("matches a recipe exactly, in any topping order", () {
      final bowl = _bowl(soup: Soup.tomYum, toppings: [Topping.egg]);
      expect(bowl.score(_beefEgg), 3);
      expect(bowl.matches(_beefEgg), isFalse, reason: "beef missing");
      bowl.addTopping(Topping.beef, Portion.fresh);
      expect(bowl.score(_beefEgg), _beefEgg.steps);
      expect(bowl.matches(_beefEgg), isTrue);
      expect(
        bowl.matches(
          Recipe.of(
            Soup.tomYum,
            toppings: [Topping.beef, Topping.egg],
            drink: Drink.lemonTea,
          ),
        ),
        isTrue,
        reason: "the drink is served apart from the bowl",
      );
      expect(bowl.score(Recipe.of(Soup.chicken)), -1, reason: "wrong broth");
      expect(
        bowl.score(Recipe.of(Soup.tomYum, toppings: [Topping.beef])),
        -1,
        reason: "an extra topping",
      );
      expect(Bowl().score(_beefEgg), 0, reason: "empty fits anything");
      expect(_bowl().score(_beefEgg), 1, reason: "noodles only");
    });

    test("takeaway orders need a paper bowl", () {
      final takeaway = Recipe.of(Soup.chicken, takeaway: true);
      expect(Bowl().score(takeaway), -1, reason: "enamel bowl");
      final paper = Bowl();
      expect(paper.usePaperBowl(), Assembly.added);
      expect(paper.usePaperBowl(), Assembly.notEmpty);
      expect(paper.score(_chicken), -1, reason: "dine-in wants enamel");
      paper
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.chicken);
      expect(paper.matches(takeaway), isTrue);
      expect(_bowl().usePaperBowl(), Assembly.notEmpty);
    });
  });

  group("tickets", () {
    test("patience runs from 1000 to 0", () {
      final ticket = _ticket(1, _chicken, arrived: 1000, expires: 21000);
      expect(ticket.patiencePermille(1000), 1000);
      expect(ticket.patiencePermille(11000), 500);
      expect(ticket.patiencePermille(21000), 0);
      expect(ticket.patiencePermille(99000), 0);
      expect(ticket.patiencePermille(0), 1000, reason: "clamped");
    });

    test("the most urgent ticket expires first; ties keep rail order", () {
      final tickets = [
        _ticket(1, _chicken, expires: 30000),
        null,
        _ticket(2, _chicken, expires: 10000),
        _ticket(3, _chicken, expires: 10000),
      ];
      expect(mostUrgent(tickets), 2);
      expect(mostUrgent(tickets, skip: 1 << 2), 3);
      expect(mostUrgent(tickets, skip: 1 << 2 | 1 << 3), 0);
      expect(mostUrgent(tickets, skip: 0xF), -1);
      expect(mostUrgent(const []), -1);
    });

    test("a finished bowl goes to the most urgent matching ticket", () {
      final tickets = [
        _ticket(1, _chicken, expires: 30000),
        _ticket(2, _beefEgg, expires: 5000),
        _ticket(3, _chicken),
      ];
      final chicken = _bowl(soup: Soup.chicken);
      expect(ticketFor(chicken, tickets), 2, reason: "skips the beef order");
      expect(ticketFor(_bowl(), tickets), -1, reason: "no broth yet");
      expect(ticketFor(chicken, [null, null]), -1);
    });
  });

  group("auto-select", () {
    test("picks the bowl closest to the most urgent ticket", () {
      final rack = BowlRack(3);
      rack.bowls[2]
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.tomYum);
      rack.autoSelect([
        _ticket(1, _chicken, expires: 30000),
        _ticket(2, _beefEgg, expires: 9000),
      ]);
      expect(rack.selected, 2, reason: "Tom Yum is already started there");
      expect(rack.current, same(rack.bowls[2]));
    });

    test("skips a bowl that conflicts with the order", () {
      final rack = BowlRack(2);
      rack.bowls[0]
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.tomYum);
      rack.autoSelect([_ticket(1, _chicken)]);
      expect(rack.selected, 1, reason: "bowl 0 has the wrong broth");
    });

    test("keeps the current bowl on a tie", () {
      final rack = BowlRack(3)..select(1);
      rack.autoSelect([_ticket(1, _chicken)]);
      expect(rack.selected, 1);
    });

    test("a finished bowl covers its ticket; the next ticket is chosen", () {
      final rack = BowlRack(3);
      rack.bowls[0]
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.chicken);
      rack.bowls[1].addNoodles(Doneness.ready);
      rack.autoSelect([
        _ticket(1, _chicken, expires: 5000),
        _ticket(2, _beefEgg, expires: 9000),
      ]);
      expect(
        rack.selected,
        1,
        reason: "noodles are waiting for the beef order",
      );
    });

    test("an empty bowl before the finished one is not used for it", () {
      final rack = BowlRack(3);
      rack.bowls[1]
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.chicken);
      rack.bowls[2].addNoodles(Doneness.ready);
      rack.autoSelect([
        _ticket(1, _chicken, expires: 5000),
        _ticket(2, _beefEgg, expires: 9000),
      ]);
      expect(rack.selected, 2, reason: "bowl 1 already serves the chicken");
    });

    test("a covered ticket does not claim a second finished bowl", () {
      final rack = BowlRack(2);
      for (final bowl in rack.bowls) {
        bowl
          ..addNoodles(Doneness.ready)
          ..addSoup(Soup.chicken);
      }
      rack.autoSelect([
        _ticket(1, _chicken, expires: 5000),
        _ticket(2, _chicken, expires: 9000),
      ]);
      expect(rack.selected, 0, reason: "both covered, selection kept");
    });

    test("leaves the selection when nothing fits", () {
      final rack = BowlRack(2)..select(1);
      for (final bowl in rack.bowls) {
        bowl
          ..addNoodles(Doneness.ready)
          ..addSoup(Soup.mala);
      }
      rack
        ..autoSelect([_ticket(1, _chicken)])
        ..autoSelect(const [])
        ..autoSelect([null]);
      expect(rack.selected, 1);
    });

    test("a takeaway ticket goes to the paper bowl", () {
      final rack = BowlRack(3);
      rack.bowls[2].usePaperBowl();
      rack.autoSelect([
        _ticket(1, Recipe.of(Soup.chicken, takeaway: true), expires: 3000),
        _ticket(2, _chicken, expires: 9000),
      ]);
      expect(rack.selected, 2);
    });

    test("select only takes a real slot", () {
      final rack = BowlRack(2);
      expect(rack.select(1), isTrue);
      expect(rack.select(2), isFalse);
      expect(rack.select(-1), isFalse);
      expect(rack.selected, 1);
    });
  });

  group("pricing", () {
    test("prepared toppings pay more than greens and jars", () {
      expect(
        {for (final t in Topping.values) t: toppingPrice(t)},
        {
          Topping.onion: 5,
          Topping.coriander: 5,
          Topping.chilli: 5,
          Topping.lime: 5,
          Topping.egg: 10,
          Topping.beef: 15,
          Topping.shrimp: 15,
          Topping.fishBall: 10,
          Topping.garlic: 5,
          Topping.chilliOil: 5,
        },
      );
      expect(priceOf(_chicken), 40, reason: "noodles 30 + broth 10");
      expect(
        priceOf(
          Recipe.of(
            Soup.tomYum,
            toppings: [Topping.beef, Topping.egg, Topping.onion],
            drink: Drink.milkTea,
          ),
        ),
        40 + 15 + 10 + 5 + 10,
      );
    });

    test("the speed tip runs from 40 % down to 0 %", () {
      expect(Bill.of(_chicken, patiencePermille: 1000).tipPercent, 40);
      expect(Bill.of(_chicken, patiencePermille: 500).tipPercent, 20);
      expect(Bill.of(_chicken, patiencePermille: 0).tipPercent, 0);
      expect(Bill.of(_chicken, patiencePermille: 4000).tipPercent, 40);
      expect(Bill.of(_chicken, patiencePermille: -5).tipPercent, 0);
    });

    test("perfect items add 10 % each, cold toppings take 10 % each", () {
      final bill = Bill.of(
        _beefEgg,
        patiencePermille: 500,
        perfectItems: 3,
        coldItems: 1,
      );
      expect(bill.tipPercent, 20 + 30 - 10);
      expect(bill.price, 65);
      expect(bill.tip, 65 * 40 ~/ 100);
      expect(bill.total, 65 + 26);
      expect(
        Bill.of(_chicken, patiencePermille: 100, coldItems: 2).tipPercent,
        0,
        reason: "never negative",
      );
    });

    test("the streak multiplies price and tip", () {
      final bill = Bill.of(_chicken, patiencePermille: 1000, streakTenths: 15);
      expect(bill.total, (40 + 16) * 15 ~/ 10);
      expect(
        Bill.of(_chicken, patiencePermille: 0, streakTenths: 20).total,
        80,
      );
    });

    test("the service streak climbs by 0.1 to ×2 and resets on a loss", () {
      final streak = ServiceStreak();
      final earned = [for (var i = 0; i < 13; i++) streak.serve()];
      expect(earned, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 20, 20]);
      streak.lose();
      expect(streak.tenths, 10);
      expect(streak.serve(), 10);
      expect(streak.best, 13);
    });
  });

  test("a whole order, step by step, from stove to bill", () {
    const now = 0;
    final pot = Cooker(CookerKind.pot)
      ..fill(now)
      ..advanceTo(2500)
      ..load(Food.noodles, 2500)
      ..advanceTo(5600);
    final grill = Cooker(CookerKind.grill)
      ..load(Food.beef, 0)
      ..advanceTo(2000)
      ..flip(2000)
      ..advanceTo(4100);
    final beef = ToppingTray(Topping.beef)
      ..add(
        Food.beef.portions,
        4100,
        perfect: grill.takeOut(4100) == Doneness.perfect,
      );
    final eggs = ToppingTray(Topping.egg)..add(4, 0);
    final rack = BowlRack(2);
    final tickets = [_ticket(7, _beefEgg)];

    rack.autoSelect(tickets);
    final bowl = rack.current;
    expect(bowl.checkNoodles(), Assembly.added);
    expect(bowl.addNoodles(pot.takeOut(5600)), Assembly.added);
    expect(bowl.addSoup(Soup.tomYum), Assembly.added);
    expect(bowl.checkTopping(Topping.beef), Assembly.added);
    bowl.addTopping(Topping.beef, beef.take(6000));
    // Eggs were boiled long ago: cold.
    bowl.addTopping(Topping.egg, eggs.take(30000));
    expect(beef.count, 1, reason: "one slice gives two portions");

    final served = ticketFor(bowl, tickets);
    expect(served, 0);
    final bill = Bill.of(
      tickets[served].recipe,
      patiencePermille: tickets[served].patiencePermille(10000),
      perfectItems: bowl.perfectItems,
      coldItems: bowl.coldItems,
      streakTenths: ServiceStreak().serve(),
    );
    expect(bowl.perfectItems, 2, reason: "perfect noodles and beef");
    expect(bowl.coldItems, 1);
    expect(bill.tipPercent, 20 + 20 - 10);
    expect(bill.total, 65 + 65 * 30 ~/ 100);
  });
}
