import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";

typedef C = CustomerCast;

CustomerActor actor({
  int id = 0,
  int slot = 0,
  int arrived = 1000,
  int patience = 20000,
  int direction = 1,
}) => CustomerActor()
  ..id = id
  ..slot = slot
  ..arrived = arrived
  ..enterAt = arrived
  ..expires = arrived + patience
  ..patience = patience
  ..enterDirection = direction;

CustomerPose at(CustomerActor a, int now, {bool reduced = false}) {
  final out = CustomerPose();
  C.pose(a, now, out, reducedMotion: reduced, guided: false);
  return out;
}

void main() {
  group("walking in", () {
    test("walks from the side and the street to the counter", () {
      final a = actor();
      final start = at(a, 1000);
      expect(start.clip, CustomerClip.walk);
      expect(start.x, closeTo(-C.enterDistance, 1e-9));
      expect(start.depth, 1);
      expect(start.opacity, 0);
      final mid = at(a, 1000 + C.enterMs ~/ 2);
      expect(mid.x, inExclusiveRange(-C.enterDistance, 0));
      expect(mid.depth, inExclusiveRange(0, 1));
      expect(mid.opacity, 1);
      final arrived = at(a, 1000 + C.enterMs);
      expect(arrived.clip, CustomerClip.idle);
      expect(arrived.x, 0);
      expect(arrived.depth, 0);
    });

    test("faces the way they walk", () {
      expect(at(actor(), 1100).flip, isFalse);
      final fromRight = at(actor(direction: -1), 1100);
      expect(fromRight.flip, isTrue);
      expect(fromRight.x, greaterThan(0));
    });

    test("walk frames are locked to distance, so feet never slide", () {
      // Frame changes happen every 1/8 stride cycle of travel, whatever the
      // easing does to speed.
      final a = actor();
      var last = -1;
      var changes = 0;
      double? lastX;
      for (var t = 0; t < C.enterMs; t += 5) {
        final p = at(a, 1000 + t);
        if (p.frame != last) {
          if (lastX != null) {
            changes++;
          }
          last = p.frame;
        }
        lastX = p.x;
      }
      final expected = (C.enterDistance / C.strideCycle * 8).floor();
      expect(changes, inInclusiveRange(expected - 1, expected));
    });
  });

  group("waiting", () {
    test("idles, then turns impatient at 30 % patience", () {
      final a = actor();
      final impatientAt = a.expires - (a.patience * .3).round();
      expect(at(a, impatientAt - 1).clip, CustomerClip.idle);
      expect(at(a, impatientAt).clip, CustomerClip.impatient);
      expect(at(a, impatientAt + 130).frame, 1);
    });

    test("never turns impatient in the guided tutorial", () {
      final a = actor();
      final out = CustomerPose();
      C.pose(a, a.expires - 10, out, reducedMotion: false, guided: true);
      expect(out.clip, CustomerClip.idle);
    });

    test("idle frames loop at 6 fps and breathe gently", () {
      final a = actor();
      final base = 1000 + C.enterMs;
      expect(at(a, base).frame, 0);
      expect(at(a, base + C.idleFrameMs).frame, 1);
      expect(at(a, base + C.idleFrameMs * 4).frame, 0);
      final breaths = [
        for (var t = 0; t < 2000; t += 50) at(a, base + 200 + t).breath,
      ];
      expect(breaths.reduce(max), lessThanOrEqualTo(1.0081));
      expect(breaths.reduce(min), greaterThanOrEqualTo(.9999));
    });

    test("cross-fades for 100 ms into each new clip", () {
      final a = actor();
      final arrive = at(a, 1000 + C.enterMs + 30);
      expect(arrive.fromClip, CustomerClip.walk);
      expect(arrive.fromOpacity, inExclusiveRange(0, 1));
      expect(at(a, 1000 + C.enterMs + C.crossFadeMs).fromClip, isNull);
    });
  });

  group("leaving", () {
    test("served: happy with the bowl, then walks away from behind", () {
      final a = actor()
        ..leftAt = 5000
        ..served = true;
      expect(at(a, 5000).clip, CustomerClip.happy);
      expect(at(a, 5000 + 250).frame, 2);
      expect(at(a, 5000 + 550).frame, 3, reason: "holds the last frame");
      final away = at(a, 5000 + C.reactMs + C.leaveMs ~/ 2);
      expect(away.clip, CustomerClip.away);
      expect(away.depth, inExclusiveRange(0, 1));
      expect(away.x, lessThan(0), reason: "leaves the way it came");
      expect(at(a, 5000 + C.reactMs + C.leaveMs).opacity, 0);
    });

    test("missed: annoyed sigh, then walks off side-on", () {
      final a = actor()
        ..leftAt = 9000
        ..served = false;
      expect(at(a, 9000).clip, CustomerClip.annoyed);
      expect(at(a, 9000 + C.reactMs + 400).clip, CustomerClip.walk);
    });
  });

  group("reduced motion", () {
    test("fades in at the slot and shows each state without moving", () {
      final a = actor();
      final first = at(a, 1000 + 75, reduced: true);
      expect(first.clip, CustomerClip.idle);
      expect(first.opacity, closeTo(.5, .01));
      expect(first.x, 0);
      expect(first.depth, 0);
      final later = at(a, 3000, reduced: true);
      expect(later.frame, 0);
      expect(later.breath, 1);
      expect(later.fromClip, isNull);
      final impatient = at(a, a.expires - 100, reduced: true);
      expect(impatient.clip, CustomerClip.impatient);
      expect(impatient.frame, 0);
    });

    test("leaves with a still reaction and a fade", () {
      final a = actor()
        ..leftAt = 5000
        ..served = true;
      final react = at(a, 5100, reduced: true);
      expect(react.clip, CustomerClip.happy);
      expect(react.frame, 3);
      final fading = at(a, 5000 + C.reactMs + 75, reduced: true);
      expect(fading.opacity, closeTo(.5, .01));
      expect(fading.x, 0);
    });
  });

  test("posing is deterministic for a given time", () {
    final a = actor();
    for (final t in [1000, 1400, 2300, 15000, 20999]) {
      final p = at(a, t);
      final q = at(a, t);
      expect(
        (p.clip, p.frame, p.x, p.depth, p.opacity),
        (q.clip, q.frame, q.x, q.depth, q.opacity),
      );
    }
  });

  group("sync with the rules", () {
    KitchenRun run() =>
        KitchenRun(shift: campaign[11], id: "cast", random: Random(5));

    test("one actor per customer, served ones leave happy", () {
      final r = run();
      final cast = CustomerCast()..sync(r, reducedMotion: false);
      final first = r.customers.nonNulls.first;
      final a = cast.actors.firstWhere((x) => x.id == first.id);
      expect(a.slot, first.slot);
      expect(a.leftAt, isNull);
      // Serve that customer.
      r
        ..bowls[0] = {...first.toppings}
        ..tap(Station.bowl);
      cast.sync(r, reducedMotion: false);
      expect(a.leftAt, r.now);
      expect(a.served, isTrue);
      // Gone once the exit finished.
      r.advance(C.exitMs(reducedMotion: false) + 50);
      cast.sync(r, reducedMotion: false);
      expect(cast.actors.where((x) => x.id == first.id), isEmpty);
    });

    test("missed customers leave annoyed; slots enter from their side", () {
      final r = run();
      final cast = CustomerCast()..sync(r, reducedMotion: false);
      final first = r.customers.nonNulls.first;
      final a = cast.actors.firstWhere((x) => x.id == first.id);
      expect(a.enterDirection, first.slot * 2 < r.shift.slots - 1 ? 1 : -1);
      // Advance past patience in small steps so arrivals keep coming.
      for (var t = 0; t < r.shift.patienceMs + 100; t += 33) {
        r.advance(33);
        cast.sync(r, reducedMotion: false);
        if (a.leftAt != null) {
          break;
        }
      }
      expect(a.leftAt, isNotNull);
      expect(a.served, isFalse);
    });

    test("a new customer waits for the slot to clear before entering", () {
      final r = run();
      final cast = CustomerCast()..sync(r, reducedMotion: false);
      final first = r.customers.nonNulls.first;
      r
        ..bowls[0] = {...first.toppings}
        ..tap(Station.bowl);
      // The rules put a new customer in the same slot straight away.
      r.customers[first.slot] = Customer(
        99,
        first.slot,
        {},
        r.now,
        r.now + 9000,
      );
      cast.sync(r, reducedMotion: false);
      final next = cast.actors.firstWhere((a) => a.id == 99);
      expect(next.arrived, r.now);
      expect(next.enterAt, r.now + C.reactMs);
      expect(
        at(next, r.now + 100).opacity,
        0,
        reason: "hidden while slot busy",
      );
      expect(at(next, next.enterAt + 300).opacity, 1);
    });

    test("a new run clears every actor", () {
      final cast = CustomerCast()..sync(run(), reducedMotion: false);
      expect(cast.actors.where((a) => a.active), isNotEmpty);
      final fresh = KitchenRun(
        shift: campaign.first,
        id: "fresh",
        random: Random(1),
      );
      fresh.customers.fillRange(0, fresh.customers.length);
      cast.sync(fresh, reducedMotion: false);
      expect(cast.actors.where((a) => a.active), isEmpty);
    });

    test("the six looks cycle by customer id", () {
      expect((actor(id: 7)).look, 1);
      expect((actor(id: 12)).look, 0);
    });
  });
}
