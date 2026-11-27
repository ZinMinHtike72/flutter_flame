import "dart:math";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/shift_run.dart";

enum PotPhase { empty, cooking, ready, burnt }

enum Station { pack, pot, bowl, garnish, discard }

enum KitchenCue {
  none,
  pack,
  transfer,
  garnish,
  served,
  streak,
  burnt,
  discarded,
  missed,
}

enum Guide { pack, wait, pot, serve, done }

class Pot {
  PotPhase phase = PotPhase.empty;
  int deadline = 0;
}

class Customer {
  const Customer(this.id, this.slot, this.toppings, this.arrived, this.expires);
  final int id;
  final int slot;
  final Set<Garnish> toppings;
  final int arrived;
  final int expires;
  bool matches(Set<Garnish> bowl) =>
      bowl.length == toppings.length && bowl.containsAll(toppings);
}

/// The original one-tap noodle stall, still used for days 2–12 until the
/// restaurant campaign (#42) replaces them.
class KitchenRun implements ShiftRun {
  KitchenRun({
    required this.shift,
    required this.id,
    required this.random,
    this.upgrades = const {},
    bool tutorial = false,
  }) : pots = List.generate(
         upgrades.contains(Upgrade.extraPot) ? 2 : 1,
         (_) => Pot(),
       ),
       guide = tutorial ? Guide.pack : Guide.done,
       customers = List.filled(shift.slots, null) {
    _spawn(plain: tutorial);
    _nextArrival = shift.arrivalMs;
  }
  final Shift shift;
  @override
  final String id;
  final Random random;
  final Set<Upgrade> upgrades;
  final List<Pot> pots;
  final bowls = <Set<Garnish>?>[null, null];
  final List<Customer?> customers;
  @override
  Guide guide;
  int now = 0;
  int elapsed = 0;
  @override
  int coins = 0;
  @override
  int served = 0;
  @override
  int missed = 0;
  int chain = 0;
  @override
  int bestChain = 0;
  int? discardBowl;
  int? servedSlot;
  int? servedBowl;
  int? servedCustomerId;
  int lastReward = 0;
  @override
  int feedbackSequence = 0;
  KitchenCue cue = KitchenCue.none;
  @override
  bool paused = false;
  @override
  bool ended = false;
  int _nextArrival = 0;
  int _serial = 0;
  int? _lastFast;
  int get cookMs => upgrades.contains(Upgrade.fastBoil) ? 2100 : 3000;
  @override
  int get secondsLeft => ((shift.seconds * 1000 - elapsed) / 1000).ceil();
  int get quarterMultiplier => 4 + (chain - 1).clamp(0, 4);
  @override
  int get multiplierPercent => quarterMultiplier * 25;
  @override
  int get number => shift.number;
  @override
  Goal get goal => shift.goal;
  @override
  int get target => shift.target;
  @override
  NoodleProduct get product => shift.product;
  @override
  int get progress => shift.goal == Goal.coins ? coins : served;
  @override
  bool get won => progress >= shift.target;
  void _signal(KitchenCue value) {
    cue = value;
    feedbackSequence++;
  }

  void _resetChain() {
    chain = 0;
    _lastFast = null;
  }

  void _spawn({bool plain = false}) {
    final slot = customers.indexOf(null);
    if (slot < 0) {
      return;
    }
    final options = Garnish.values.take(shift.garnishCount).toList()
      ..shuffle(random);
    final count = plain
        ? 0
        : random.nextInt(min(shift.maxToppings, options.length) + 1);
    customers[slot] = Customer(
      _serial++,
      slot,
      options.take(count).toSet(),
      now,
      now + shift.patienceMs,
    );
  }

  /// Advances the simulation clock to each boundary, including on slow frames.
  ///
  /// Runs every rules step, so it uses index loops and allocates nothing.
  @override
  void advance(int milliseconds) {
    if (paused || ended || milliseconds <= 0) {
      return;
    }
    final guided = guide != Guide.done;
    final duration = guided
        ? milliseconds
        : min(milliseconds, shift.seconds * 1000 - elapsed);
    final end = now + duration;
    while (now < end) {
      var boundary = end;
      for (var i = 0; i < pots.length; i++) {
        final pot = pots[i];
        if (pot.phase == PotPhase.cooking ||
            (!guided && pot.phase == PotPhase.ready)) {
          boundary = min(boundary, pot.deadline);
        }
      }
      if (!guided) {
        boundary = min(boundary, _nextArrival);
        for (var i = 0; i < customers.length; i++) {
          final customer = customers[i];
          if (customer != null) {
            boundary = min(boundary, customer.expires);
          }
        }
        elapsed += boundary - now;
      }
      now = boundary;
      for (var i = 0; i < pots.length; i++) {
        final pot = pots[i];
        if (pot.deadline != now) {
          continue;
        }
        if (pot.phase == PotPhase.cooking) {
          pot.phase = PotPhase.ready;
          pot.deadline = now + 6000;
          if (guide == Guide.wait) {
            guide = Guide.pot;
          }
        } else if (!guided && pot.phase == PotPhase.ready) {
          pot.phase = PotPhase.burnt;
          _signal(KitchenCue.burnt);
        }
      }
      if (guided) {
        continue;
      }
      for (var i = 0; i < customers.length; i++) {
        final customer = customers[i];
        if (customer != null && customer.expires == now) {
          customers[i] = null;
          missed++;
          _resetChain();
          _signal(KitchenCue.missed);
        }
      }
      if (elapsed == shift.seconds * 1000) {
        ended = true;
        return;
      }
      if (_nextArrival == now) {
        _spawn();
        _nextArrival += shift.arrivalMs;
      }
    }
  }

  void tap(Station station, [int index = 0]) {
    if (paused || ended || index < 0) {
      return;
    }
    switch (station) {
      case Station.pack:
        final next = pots.where((p) => p.phase == PotPhase.empty).firstOrNull;
        if (next == null || (guide != Guide.done && guide != Guide.pack)) {
          return;
        }
        next.phase = PotPhase.cooking;
        next.deadline = now + cookMs;
        if (guide == Guide.pack) {
          guide = Guide.wait;
        }
        _signal(KitchenCue.pack);
      case Station.pot:
        if (index >= pots.length) {
          return;
        }
        final pot = pots[index];
        if (pot.phase == PotPhase.burnt) {
          pot.phase = PotPhase.empty;
          _resetChain();
          _signal(KitchenCue.discarded);
        } else if (pot.phase == PotPhase.ready) {
          final empty = bowls.indexOf(null);
          if (empty < 0) {
            return;
          }
          bowls[empty] = {};
          pot.phase = PotPhase.empty;
          if (guide == Guide.pot) {
            guide = Guide.serve;
          }
          _signal(KitchenCue.transfer);
        }
      case Station.garnish:
        if (index >= shift.garnishCount || guide != Guide.done) {
          return;
        }
        final topping = Garnish.values[index];
        for (var i = 0; i < bowls.length; i++) {
          final bowl = bowls[i];
          if (bowl != null && bowl.length < 2 && bowl.add(topping)) {
            if (discardBowl == i) {
              discardBowl = null;
            }
            _signal(KitchenCue.garnish);
            return;
          }
        }
      case Station.bowl:
        if (index >= bowls.length) {
          return;
        }
        final bowl = bowls[index];
        if (bowl == null) {
          return;
        }
        final matches =
            customers.nonNulls.where((c) => c.matches(bowl)).toList()..sort(
              (a, b) => a.expires == b.expires
                  ? a.slot.compareTo(b.slot)
                  : a.expires.compareTo(b.expires),
            );
        if (matches.isEmpty) {
          discardBowl = index;
          return;
        }
        _serve(matches.first, index);
      case Station.discard:
        if (discardBowl != index || bowls[index] == null) {
          return;
        }
        bowls[index] = null;
        discardBowl = null;
        _signal(KitchenCue.discarded);
    }
  }

  void _serve(Customer customer, int index) {
    final guided = guide != Guide.done;
    final fast = guided || (now - customer.arrived) * 2 < shift.patienceMs;
    if (fast) {
      chain = _lastFast != null && now - _lastFast! <= 5000 ? chain + 1 : 1;
      _lastFast = now;
      bestChain = max(bestChain, chain);
    } else {
      _resetChain();
    }
    final value =
        60 +
        customer.toppings.length * 20 +
        (fast ? 20 : 0) +
        (upgrades.contains(Upgrade.premiumBowl) ? 25 : 0);
    lastReward = value * quarterMultiplier ~/ 4;
    coins += lastReward;
    served++;
    servedSlot = customer.slot;
    servedCustomerId = customer.id;
    servedBowl = index;
    customers[customer.slot] = null;
    bowls[index] = null;
    if (discardBowl == index) {
      discardBowl = null;
    }
    _signal(chain == 5 ? KitchenCue.streak : KitchenCue.served);
    if (guided) {
      guide = Guide.done;
      _spawn();
      _nextArrival = now + shift.arrivalMs;
    }
  }
}
