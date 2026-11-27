import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/run_clock.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

// Two tables stand at 333 and 666 on the 0–1000 aisle; the waiter starts at
// the pass (500) and walks the whole aisle in 2 s, so 1 unit = 2 ms.
const _chicken = Recipe(Soup.chicken);

Guest _guest(int id, {int patience = 20000, Recipe recipe = _chicken}) =>
    Guest(id, recipe, patience);

Bowl _chickenBowl() => Bowl()
  ..addNoodles(Doneness.ready)
  ..addSoup(Soup.chicken);

/// One guest seated at table 0 at 2266 (door at 1000, greet until 1300,
/// walk 666 ms to the table, seat until 2266).
Dining _seated({int tables = 2, int patience = 20000}) =>
    Dining(tables: tables, tablePositions: const [333, 666])
      ..arrive(_guest(1, patience: patience), 0)
      ..advanceTo(2266);

/// Everything that should come out the same however time is stepped.
List<Object?> _snapshot(Dining d, int now) => [
  for (final t in d.tables) (t.phase, t.coins, t.hadTea),
  for (final t in d.tickets) (t?.id, t?.arrivedAt, t?.expiresAt),
  for (final w in d.waiters) (w.positionAt(now), w.action, w.stop, w.load),
  d.coins,
  d.served,
  d.lost,
  d.waitingAtDoor,
  d.queuedTasks,
];

void main() {
  group("table life cycle", () {
    test("free → booked → waiting, with the waiter fetching the guest", () {
      final dining = Dining(tables: 2);
      expect(dining.tables.map((t) => t.position), [333, 666]);
      expect(dining.arrive(_guest(1), 0), isTrue);
      final table = dining.tables[0];
      final waiter = dining.waiters.single;
      expect(table.phase, TablePhase.booked);
      expect(dining.waitingAtDoor, 0, reason: "booked at once");
      expect(waiter.action, WaiterAction.walking);
      expect(waiter.positionAt(500), 250, reason: "halfway to the door");
      expect(waiter.facing, -1);

      dining.advanceTo(999);
      expect(waiter.action, WaiterAction.walking);
      dining.advanceTo(1000);
      expect(waiter.action, WaiterAction.greeting);
      expect(waiter.positionAt(1000), Dining.door);
      dining.advanceTo(1300);
      expect(waiter.action, WaiterAction.walking);
      expect(waiter.load, WaiterLoad.guest, reason: "leading the guest");
      expect(waiter.facing, 1);
      dining.advanceTo(1966);
      expect(waiter.action, WaiterAction.seating);
      dining.advanceTo(2265);
      expect(table.phase, TablePhase.booked);
      expect(dining.tickets[0], isNull);
      dining.advanceTo(2266);
      expect(table.phase, TablePhase.waiting);
      expect(waiter.idle, isTrue);
      expect(waiter.facing, 0);
      final ticket = dining.tickets[0]!;
      expect((ticket.arrivedAt, ticket.expiresAt), (2266, 22266));
      expect(ticket.recipe, _chicken);
    });

    test("served → eating → dirty → cleared, coins collected once", () {
      final dining = _seated();
      final table = dining.tables[0];
      final waiter = dining.waiters.single;
      final bowl = _chickenBowl();
      expect(dining.serve(bowl, 3000), 0);
      expect(bowl.isEmpty, isTrue, reason: "the bowl slot is free again");
      expect(table.phase, TablePhase.served);
      expect(dining.tickets[0], isNull, reason: "off the rail");
      // 963 ‰ patience → 38 % speed tip on 40 coins.
      expect(table.bill, 40 + 15);
      expect(dining.served, 1);

      dining.advanceTo(3334);
      expect(waiter.action, WaiterAction.picking);
      dining.advanceTo(3534);
      expect(waiter.load, WaiterLoad.bowl);
      dining.advanceTo(3868);
      expect(waiter.action, WaiterAction.placing);
      dining.advanceTo(4168);
      expect(table.phase, TablePhase.eating);
      dining.advanceTo(30000);
      expect(table.phase, TablePhase.dirty, reason: "no patience after food");
      expect(table.coins, 55);
      expect(dining.coins, 0, reason: "still on the table");

      expect(dining.tapTable(0, 30000), TableTap.clear);
      expect(dining.tapTable(0, 30000), TableTap.none, reason: "queued once");
      expect(waiter.action, WaiterAction.wiping, reason: "already there");
      dining.advanceTo(30800);
      expect(table.phase, TablePhase.free);
      expect(dining.coins, 55);
      expect(waiter.load, WaiterLoad.dirtyBowls);
      dining.advanceTo(31134);
      expect(waiter.action, WaiterAction.dropping);
      dining.advanceTo(31333);
      expect(waiter.idle, isFalse);
      dining.advanceTo(31334);
      expect(waiter.idle, isTrue);
      expect(waiter.positionAt(31334), Dining.pass);
      expect(dining.coins, 55);
    });

    test("only a matching bowl is served", () {
      final dining = _seated();
      final wrong = Bowl()
        ..addNoodles(Doneness.ready)
        ..addSoup(Soup.tomYum);
      expect(dining.serve(wrong, 3000), -1);
      expect(wrong.soup, Soup.tomYum, reason: "untouched");
      expect(dining.tables[0].phase, TablePhase.waiting);
      expect(dining.served, 0);
      expect(dining.streak.serves, 0);
    });

    test("taps only act on waiting and dirty tables", () {
      final dining = Dining(tables: 2)..arrive(_guest(1), 0);
      expect(dining.tapTable(0, 0), TableTap.none, reason: "booked");
      expect(dining.tapTable(1, 0), TableTap.none, reason: "free");
      expect(dining.tapTable(2, 0), TableTap.none, reason: "no such table");
      expect(dining.tapTable(-1, 0), TableTap.none);
      dining
        ..advanceTo(2266)
        ..serve(_chickenBowl(), 2266);
      expect(dining.tapTable(0, 2266), TableTap.none, reason: "served");
      dining.advanceTo(5000);
      expect(dining.tables[0].phase, TablePhase.eating);
      expect(dining.tapTable(0, 5000), TableTap.none, reason: "eating");
    });
  });

  group("losing guests", () {
    test("a waiting guest leaves when patience runs out", () {
      final dining = _seated(patience: 5000);
      dining.streak.serve();
      dining.advanceTo(7265);
      expect(dining.tables[0].phase, TablePhase.waiting);
      dining.advanceTo(7266);
      expect(dining.tables[0].phase, TablePhase.free);
      expect(dining.tables[0].guest, isNull);
      expect(dining.tickets[0], isNull);
      expect(dining.lost, 1);
      expect(dining.streak.serves, 0, reason: "a lost guest ends the streak");
    });

    test("a guest at the door leaves when no table frees up", () {
      final dining = Dining(tables: 1)
        ..arrive(_guest(1), 0)
        ..arrive(_guest(2), 0);
      expect(dining.waitingAtDoor, 1);
      dining.advanceTo(11999);
      expect(dining.waitingAtDoor, 1);
      dining.advanceTo(12000);
      expect(dining.waitingAtDoor, 0);
      expect(dining.lost, 1);
    });

    test("a guest at the door gets the next cleared table", () {
      final dining = Dining(tables: 1, tablePositions: const [333])
        ..arrive(_guest(1), 0)
        ..arrive(_guest(2), 0)
        ..advanceTo(2266)
        ..serve(_chickenBowl(), 2266)
        ..advanceTo(8000);
      expect(dining.tables[0].phase, TablePhase.dirty);
      dining.tapTable(0, 8000);
      dining.advanceTo(8800);
      expect(dining.tables[0].phase, TablePhase.booked, reason: "guest 2");
      expect(dining.tables[0].guest!.id, 2);
      expect(dining.waitingAtDoor, 0);
      expect(dining.lost, 0, reason: "seated before the door timeout");
    });

    test("a full doorway turns guests away", () {
      final dining = Dining(tables: 1);
      for (var id = 0; id <= Dining.doorCapacity; id++) {
        expect(dining.arrive(_guest(id), 0), isTrue);
      }
      expect(dining.waitingAtDoor, Dining.doorCapacity);
      expect(dining.arrive(_guest(99), 0), isFalse);
      expect(dining.lost, 1);
    });
  });

  group("waiter queue", () {
    test("runs tasks first in, first out, each in its own time", () {
      final dining = Dining(tables: 2)
        ..arrive(_guest(1), 0)
        ..arrive(_guest(2), 0);
      final waiter = dining.waiters.single;
      expect(dining.queuedTasks, 1, reason: "second seating waits");
      dining.advanceTo(2266);
      expect(dining.tables[0].phase, TablePhase.waiting);
      expect(waiter.task!.job, WaiterJob.seat);
      expect(waiter.task!.table, 1);
      // Tea for table 0 queues behind the second seating.
      expect(dining.tapTable(0, 3000), TableTap.tea);
      expect(dining.tapTable(0, 3000), TableTap.none, reason: "queued once");
      dining.advanceTo(4863);
      expect(dining.tables[1].phase, TablePhase.booked);
      dining.advanceTo(4864);
      expect(dining.tables[1].phase, TablePhase.waiting);
      expect(dining.tickets[1]!.arrivedAt, 4864);
      expect(waiter.task!.job, WaiterJob.tea);
      dining.advanceTo(5530);
      expect(waiter.action, WaiterAction.pouring);
      expect(waiter.load, WaiterLoad.teapot);
      dining.advanceTo(6130);
      expect(dining.tables[0].hadTea, isTrue);
      expect(waiter.idle, isTrue);
    });

    test("queued seatings run in arrival order", () {
      final dining = Dining(tables: 3, tablePositions: const [333, 666, 900])
        ..arrive(_guest(1), 0)
        ..arrive(_guest(2), 0)
        ..arrive(_guest(3), 0);
      expect(dining.queuedTasks, 2);
      dining.advanceTo(2266);
      expect(dining.waiters.single.task!.table, 1, reason: "guest 2 next");
      dining.advanceTo(4864);
      expect(dining.tables[1].phase, TablePhase.waiting);
      expect(dining.waiters.single.task!.table, 2, reason: "then guest 3");
      expect(dining.tickets.map((t) => t?.id), [1, 2, null]);
    });

    test("two waiters share the queue", () {
      final dining = Dining(tables: 2, waiters: 2)
        ..arrive(_guest(1), 0)
        ..arrive(_guest(2), 0);
      expect(dining.queuedTasks, 0);
      dining.advanceTo(2266);
      expect(dining.tables[0].phase, TablePhase.waiting);
      expect(dining.tables[1].phase, TablePhase.booked);
      dining.advanceTo(2932);
      expect(dining.tables[1].phase, TablePhase.waiting);
    });

    test("a faster waiter walks the aisle in less time", () {
      final dining = Dining(tables: 2, walkMsPerAisle: 1000)
        ..arrive(_guest(1), 0)
        ..advanceTo(1633);
      expect(dining.tables[0].phase, TablePhase.waiting);
      expect(dining.walkMs(0, 1000), 1000);
    });
  });

  group("free green tea", () {
    test("gives back a quarter of full patience, once", () {
      final dining = _seated(tables: 1)..advanceTo(12266);
      expect(dining.tickets[0]!.patiencePermille(12266), 500);
      expect(dining.tapTable(0, 12266), TableTap.tea);
      expect(dining.waiters.single.action, WaiterAction.pouring);
      dining.advanceTo(12866);
      final ticket = dining.tickets[0]!;
      expect(ticket.patiencePermille(12866), 470 + 250);
      expect(ticket.expiresAt - ticket.arrivedAt, 20000, reason: "same full");
      expect(dining.tables[0].hadTea, isTrue);
      expect(dining.tapTable(0, 13000), TableTap.none, reason: "only once");
    });

    test("never above full patience", () {
      final dining = _seated(tables: 1)..tapTable(0, 2266);
      dining.advanceTo(2866);
      expect(dining.tickets[0]!.patiencePermille(2866), 1000);
      expect(dining.tickets[0]!.expiresAt, 2866 + 20000);
    });

    test("tea for a guest who already left does nothing", () {
      final dining = Dining(tables: 2)
        ..arrive(_guest(1, patience: 1500), 0)
        ..arrive(_guest(2), 0)
        ..advanceTo(2266);
      expect(dining.tapTable(0, 2266), TableTap.tea);
      dining.advanceTo(3766);
      expect(dining.lost, 1, reason: "left before the waiter came");
      dining.advanceTo(6130);
      expect(dining.tables[0].hadTea, isFalse);
      expect(dining.tables[0].teaQueued, isFalse);
      expect(dining.waiters.single.idle, isTrue);
    });
  });

  group("time", () {
    /// Guest 1 arrives at 0 and is served at 3000; guest 2 arrives at 2000
    /// and gets tea at 5000; table 0 is cleared at 11000 (after eating).
    Dining script(void Function(Dining d, int to) advance) {
      final d = Dining(tables: 2)..arrive(_guest(1), 0);
      advance(d, 2000);
      d.arrive(_guest(2, patience: 8000), 2000);
      advance(d, 3000);
      d.serve(_chickenBowl(), 3000);
      advance(d, 5000);
      d.tapTable(1, 5000);
      advance(d, 11000);
      d.tapTable(0, 11000);
      advance(d, 25000);
      return d;
    }

    test("30 Hz steps and one slow frame end in the same state", () {
      final clock = FixedStepClock();
      var now = 0;
      final stepped = script((d, to) {
        while (now < to) {
          clock.advance(1000 / 30, (ms) {
            now += ms;
            d.advanceTo(now < to ? now : to);
          });
        }
        now = to;
      });
      final jumped = script((d, to) => d.advanceTo(to));
      expect(_snapshot(stepped, 25000), _snapshot(jumped, 25000));
      expect(jumped.coins, greaterThan(0));
      expect(jumped.lost, 1, reason: "guest 2 ran out despite the tea");
    });

    test("a paused clock freezes guests, the waiter and every timer", () {
      List<Object?> run({required bool withPause}) {
        final clock = RunClock();
        final dining = Dining(tables: 2)..arrive(_guest(1, patience: 9000), 0);
        final pot = Cooker(CookerKind.pot)..fill(0);
        final seen = <Object?>[];
        for (var frame = 0; frame < 900; frame++) {
          if (withPause) {
            clock.paused = frame >= 100 && frame < 400;
          }
          final before = [..._snapshot(dining, clock.now), pot.phase];
          final now = clock.advance(33);
          dining.advanceTo(now);
          pot.advanceTo(now);
          if (clock.paused) {
            expect(
              [..._snapshot(dining, now), pot.phase],
              before,
              reason: "nothing moves while paused",
            );
            continue;
          }
          seen.add([now, ..._snapshot(dining, now), pot.phase, pot.deadline]);
        }
        return seen;
      }

      final reference = run(withPause: false);
      final paused = run(withPause: true);
      expect(paused.length, 600);
      expect(
        paused,
        reference.take(600).toList(),
        reason: "after resuming, everything is exactly where it was",
      );
    });

    test("the clock ignores time while paused or negative", () {
      final clock = RunClock();
      expect(clock.advance(34), 34);
      expect(clock.advance(-5), 34);
      clock.paused = true;
      expect(clock.advance(1000), 34);
      clock.paused = false;
      expect(clock.advance(33), 67);
    });
  });
}
