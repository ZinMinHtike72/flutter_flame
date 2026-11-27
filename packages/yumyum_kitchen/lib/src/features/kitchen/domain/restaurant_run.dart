import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/run_clock.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/shift_run.dart";

/// One restaurant day: how long it lasts, the goal, the equipment and the
/// guests who walk in.
class RestaurantDay {
  const RestaurantDay({
    required this.number,
    required this.seconds,
    required this.target,
    required this.tables,
    required this.pots,
    required this.bowls,
    required this.soups,
    required this.arrivals,
    required this.patienceMs,
    required this.menu,
    this.product = NoodleProduct.originalChicken,
  });

  final int number;
  final int seconds;

  /// Guests to serve to win.
  final int target;
  final int tables;
  final int pots;
  final int bowls;

  /// Stockpots on the line, left to right.
  final List<Soup> soups;

  /// When each guest walks in (ms from the start).
  final List<int> arrivals;

  /// How long a seated guest waits for food.
  final int patienceMs;

  /// Orders handed out in turn.
  final List<Recipe> menu;
  final NoodleProduct product;

  /// Where along the waiter's 0–1000 aisle each of the restaurant's four
  /// tables is served from (just left of the table, as in the keyframe).
  /// A day with fewer tables uses the first ones.
  static const tableSpots = [56, 287, 528, 719];
}

/// The restaurant days built so far. Day 1: chicken noodle soup, step by
/// step, for two tables.
const restaurantDays = [
  RestaurantDay(
    number: 1,
    seconds: 120,
    target: 4,
    tables: 2,
    pots: 2,
    bowls: 3,
    soups: [Soup.chicken],
    arrivals: [1500, 12000, 26000, 40000, 55000, 72000],
    patienceMs: 50000,
    menu: [Recipe(Soup.chicken)],
  ),
];

/// What the player can tap in the restaurant.
enum RestaurantSpot { pack, pot, stockpot, bowl, bin, table }

/// The last thing a tap or the dining room did (sound, haptic, hint).
enum RestaurantCue {
  none,
  water,
  noodles,
  bowlFilled,
  ladle,
  selected,
  served,
  tea,
  clearing,
  cleared,
  binned,
  lost,
  rejected,
}

/// A restaurant day in play: one clock driving the pots, the bowl rack and
/// the dining room.
///
/// Every tap is one cooking step (fill water, drop noodles, noodles into
/// the selected bowl, ladle broth, serve, clear a table), so the day is
/// played step by step. [advance] runs the rules on the fixed 30 Hz step.
class RestaurantRun implements ShiftRun {
  RestaurantRun({required this.day, required this.id})
    : pots = [for (var i = 0; i < day.pots; i++) Cooker(CookerKind.pot)],
      rack = BowlRack(day.bowls),
      dining = Dining(
        tables: day.tables,
        tablePositions: RestaurantDay.tableSpots,
      ),
      guests = [
        for (var i = 0; i < day.arrivals.length; i++)
          Guest(i + 1, day.menu[i % day.menu.length], day.patienceMs),
      ];

  final RestaurantDay day;
  @override
  final String id;
  final clock = RunClock();
  final List<Cooker> pots;
  final BowlRack rack;
  final Dining dining;
  final List<Guest> guests;
  int elapsed = 0;
  int _nextGuest = 0;
  @override
  bool ended = false;
  @override
  int feedbackSequence = 0;
  RestaurantCue cue = RestaurantCue.none;

  int get now => clock.now;

  @override
  bool get paused => clock.paused;
  @override
  set paused(bool value) => clock.paused = value;

  @override
  int get number => day.number;
  @override
  Goal get goal => Goal.customers;
  @override
  int get target => day.target;
  @override
  NoodleProduct get product => day.product;
  @override
  Guide get guide => Guide.done;

  /// Coins collected plus coins still waiting on dirty tables.
  @override
  int get coins {
    var total = dining.coins;
    for (var i = 0; i < dining.tables.length; i++) {
      total += dining.tables[i].coins;
    }
    return total;
  }

  @override
  int get served => dining.served;
  @override
  int get missed => dining.lost;
  @override
  int get bestChain => dining.streak.best;
  @override
  int get progress => served;
  @override
  bool get won => served >= day.target;
  @override
  int get multiplierPercent => dining.streak.tenths * 10;
  @override
  int get secondsLeft => (day.seconds * 1000 - elapsed + 999) ~/ 1000;

  /// Guests still to come.
  int get guestsLeft => guests.length - _nextGuest;

  @override
  void advance(int ms) {
    if (paused || ended || ms <= 0) {
      return;
    }
    final left = day.seconds * 1000 - elapsed;
    final step = ms < left ? ms : left;
    final served = dining.served;
    final lost = dining.lost;
    final collected = dining.coins;
    final to = clock.advance(step);
    elapsed += step;
    while (_nextGuest < guests.length && day.arrivals[_nextGuest] <= to) {
      final at = day.arrivals[_nextGuest];
      _advanceTo(at);
      dining.arrive(guests[_nextGuest], at);
      _nextGuest++;
    }
    _advanceTo(to);
    if (dining.lost != lost) {
      _signal(RestaurantCue.lost);
    } else if (dining.coins != collected) {
      _signal(RestaurantCue.cleared);
    } else if (dining.served != served) {
      feedbackSequence++;
    }
    if (elapsed == day.seconds * 1000) {
      ended = true;
      feedbackSequence++;
    }
  }

  void _advanceTo(int at) {
    for (var i = 0; i < pots.length; i++) {
      pots[i].advanceTo(at);
    }
    dining.advanceTo(at);
  }

  /// One tap; returns whether it did anything. A refused tap sets
  /// [RestaurantCue.rejected] so the station can shake.
  bool tap(RestaurantSpot spot, [int index = 0]) {
    if (paused || ended) {
      return false;
    }
    final done = switch (spot) {
      RestaurantSpot.pack => _dropNoodles(),
      RestaurantSpot.pot => _pot(index),
      RestaurantSpot.stockpot => _ladle(index),
      RestaurantSpot.bowl => _bowl(index),
      RestaurantSpot.bin => _bin(),
      RestaurantSpot.table => _table(index),
    };
    if (done == RestaurantCue.rejected) {
      _signal(done);
      return false;
    }
    rack.autoSelect(dining.tickets);
    _signal(done);
    return true;
  }

  /// Noodles go into the first pot whose water is boiling.
  RestaurantCue _dropNoodles() {
    for (var i = 0; i < pots.length; i++) {
      if (pots[i].load(Food.noodles, now)) {
        return RestaurantCue.noodles;
      }
    }
    return RestaurantCue.rejected;
  }

  /// An empty pot gets water; cooked noodles go into the selected bowl;
  /// soggy noodles go in the bin.
  RestaurantCue _pot(int index) {
    if (index < 0 || index >= pots.length) {
      return RestaurantCue.rejected;
    }
    final pot = pots[index];
    switch (pot.phase) {
      case CookPhase.empty:
        pot.fill(now);
        return RestaurantCue.water;
      case CookPhase.perfect:
      case CookPhase.ready:
        final bowl = rack.current;
        if (bowl.checkNoodles() != Assembly.added) {
          return RestaurantCue.rejected;
        }
        bowl.addNoodles(pot.takeOut(now));
        return RestaurantCue.bowlFilled;
      case CookPhase.ruined:
        pot.bin(now);
        return RestaurantCue.binned;
      case CookPhase.heating:
      case CookPhase.hot:
      case CookPhase.cooking:
      case CookPhase.needsFlip:
        return RestaurantCue.rejected;
    }
  }

  RestaurantCue _ladle(int index) {
    if (index < 0 || index >= day.soups.length) {
      return RestaurantCue.rejected;
    }
    return rack.current.addSoup(day.soups[index]) == Assembly.added
        ? RestaurantCue.ladle
        : RestaurantCue.rejected;
  }

  /// A finished bowl is served to its order; any other bowl is selected.
  RestaurantCue _bowl(int index) {
    if (!rack.select(index)) {
      return RestaurantCue.rejected;
    }
    final bowl = rack.current;
    if (bowl.noodles && dining.serve(bowl, now) >= 0) {
      return RestaurantCue.served;
    }
    return RestaurantCue.selected;
  }

  RestaurantCue _bin() {
    final bowl = rack.current;
    if (bowl.isEmpty) {
      return RestaurantCue.rejected;
    }
    bowl.clear();
    return RestaurantCue.binned;
  }

  RestaurantCue _table(int index) => switch (dining.tapTable(index, now)) {
    TableTap.tea => RestaurantCue.tea,
    TableTap.clear => RestaurantCue.clearing,
    TableTap.none => RestaurantCue.rejected,
  };

  void _signal(RestaurantCue value) {
    cue = value;
    feedbackSequence++;
  }
}
