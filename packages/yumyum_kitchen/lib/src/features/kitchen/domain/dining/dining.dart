import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/pricing.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/ticket.dart";

/// Someone who walks in: their order and how long they wait once seated.
class Guest {
  const Guest(this.id, this.recipe, this.patienceMs);

  final int id;
  final Recipe recipe;
  final int patienceMs;
}

/// A table's life: [free] → [booked] (the waiter is bringing a guest) →
/// [waiting] (seated, order on the rail, patience running) → [served] (the
/// bowl is on its way, patience frozen) → [eating] → [dirty] (coins and
/// bowls left) → cleared → [free]. A guest who runs out of patience while
/// [waiting] leaves the table [free].
enum TablePhase { free, booked, waiting, served, eating, dirty }

class DiningTable {
  DiningTable(this.position);

  /// Where it stands along the waiter's aisle (0 door … 1000 shelf).
  final int position;
  TablePhase phase = TablePhase.free;
  Guest? guest;
  bool hadTea = false;
  bool teaQueued = false;
  bool clearQueued = false;

  /// The bill for the bowl on its way, left on the table after eating.
  int bill = 0;

  /// Coins waiting on a [TablePhase.dirty] table.
  int coins = 0;
  int eatsUntil = 0;
}

enum WaiterJob { seat, carry, tea, clear }

/// What the waiter is doing now; [walking] between stops, the rest at one.
enum WaiterAction {
  idle,
  walking,
  greeting,
  seating,
  picking,
  placing,
  pouring,
  wiping,
  dropping,
}

/// What the waiter has in hand (picks the sprite).
enum WaiterLoad { none, guest, bowl, teapot, dirtyBowls }

/// One errand. [bill] travels with a bowl.
class WaiterTask {
  WaiterTask(this.job, this.table, {this.bill = 0});

  final WaiterJob job;
  final int table;
  final int bill;
}

class Waiter {
  Waiter(this.position);

  /// Where the waiter is when not walking, and where the last walk began.
  int position;
  int walkTo = 0;
  int walkStart = 0;
  int walkEnd = 0;
  WaiterAction action = WaiterAction.idle;
  int actionEnds = 0;
  WaiterTask? task;

  /// Which stop of [task] the waiter is heading to or working at.
  int stop = 0;

  bool get idle => task == null;

  /// Aisle position at [now], moving smoothly along a walk.
  int positionAt(int now) {
    if (action != WaiterAction.walking) {
      return position;
    }
    final t = now <= walkStart
        ? 0
        : now >= walkEnd
        ? 1000
        : (now - walkStart) * 1000 ~/ (walkEnd - walkStart);
    return position + (walkTo - position) * t ~/ 1000;
  }

  /// +1 walking towards the shelf, -1 towards the door, 0 standing.
  int get facing => action != WaiterAction.walking || walkTo == position
      ? 0
      : walkTo > position
      ? 1
      : -1;

  WaiterLoad get load {
    final job = task?.job;
    return switch (job) {
      WaiterJob.seat when stop == 1 => WaiterLoad.guest,
      WaiterJob.carry when stop == 1 => WaiterLoad.bowl,
      WaiterJob.tea => WaiterLoad.teapot,
      WaiterJob.clear when stop == 1 => WaiterLoad.dirtyBowls,
      _ => WaiterLoad.none,
    };
  }
}

/// What a tap on a table did.
enum TableTap { none, tea, clear }

/// The dining room: guests at the door, tables, the ticket rail and the
/// waiter(s) running a first-in, first-out task queue.
///
/// Like the cookers it keeps absolute deadlines and [advanceTo] handles
/// every event at its exact time, in a fixed order on ties, so slow frames
/// and pauses never change the outcome. Advancing allocates nothing; a
/// ticket is created when a guest sits down.
class Dining {
  Dining({
    required int tables,
    int waiters = 1,
    List<int>? tablePositions,
    this.walkMsPerAisle = 2000,
    this.doorPatienceMs = 12000,
  }) : tables = [
         for (var i = 0; i < tables; i++)
           DiningTable(tablePositions?[i] ?? (i + 1) * 1000 ~/ (tables + 1)),
       ],
       tickets = List<Ticket?>.filled(tables, null),
       waiters = [for (var i = 0; i < waiters; i++) Waiter(pass)],
       _door = List<Guest?>.filled(doorCapacity, null),
       _doorSince = List<int>.filled(doorCapacity, 0),
       _queue = List<WaiterTask?>.filled(queueCapacity, null);

  static const door = 0;
  static const pass = 500;
  static const doorCapacity = 6;
  static const queueCapacity = 16;
  static const greetMs = 300;
  static const seatMs = 300;
  static const pickMs = 200;
  static const placeMs = 300;
  static const pourMs = 600;
  static const wipeMs = 800;
  static const dropMs = 200;
  static const eatMs = 4000;

  /// Free green tea gives back this share of a guest's full patience.
  static const teaPermille = 250;

  /// Time to walk the whole aisle; the faster-waiter upgrade lowers it.
  final int walkMsPerAisle;

  /// How long a guest waits at the door for a table before leaving.
  final int doorPatienceMs;
  final List<DiningTable> tables;

  /// The rail: the open order of each table, by table index; null when it
  /// has none (or its bowl is already on the way).
  final List<Ticket?> tickets;
  final List<Waiter> waiters;
  final streak = ServiceStreak();

  final List<Guest?> _door;
  final List<int> _doorSince;
  int _doorHead = 0;
  int _doorCount = 0;
  final List<WaiterTask?> _queue;
  int _queueHead = 0;
  int _queueCount = 0;

  /// Coins collected from cleared tables.
  int coins = 0;
  int served = 0;
  int lost = 0;

  int get waitingAtDoor => _doorCount;
  int get queuedTasks => _queueCount;

  /// A guest walks in at [now]; false when the doorway is full (they turn
  /// away, which counts as a lost guest).
  bool arrive(Guest guest, int now) {
    if (_doorCount == doorCapacity) {
      _lose();
      return false;
    }
    final slot = (_doorHead + _doorCount) % doorCapacity;
    _door[slot] = guest;
    _doorSince[slot] = now;
    _doorCount++;
    _seatNext(now);
    return true;
  }

  /// A tap on table [index]: free green tea for a waiting guest who has not
  /// had any, or clearing a dirty table. Each is queued once.
  TableTap tapTable(int index, int now) {
    if (index < 0 || index >= tables.length) {
      return TableTap.none;
    }
    final table = tables[index];
    if (table.phase == TablePhase.waiting &&
        !table.hadTea &&
        !table.teaQueued &&
        _enqueue(WaiterTask(WaiterJob.tea, index), now)) {
      table.teaQueued = true;
      return TableTap.tea;
    }
    if (table.phase == TablePhase.dirty &&
        !table.clearQueued &&
        _enqueue(WaiterTask(WaiterJob.clear, index), now)) {
      table.clearQueued = true;
      return TableTap.clear;
    }
    return TableTap.none;
  }

  /// Sends a finished [bowl] to the most urgent order it matches. The bill
  /// is set now (patience left, perfect and cold items, streak), the order
  /// leaves the rail, the guest stops losing patience, and the bowl is
  /// cleared for the next order. Returns the table, or -1 when no order
  /// matches (or the waiter's queue is full) and nothing changes.
  int serve(Bowl bowl, int now) {
    final index = ticketFor(bowl, tickets);
    if (index < 0 || _queueCount == queueCapacity) {
      return -1;
    }
    final ticket = tickets[index]!;
    final bill = Bill.of(
      ticket.recipe,
      patiencePermille: ticket.patiencePermille(now),
      perfectItems: bowl.perfectItems,
      coldItems: bowl.coldItems,
      streakTenths: streak.serve(),
    );
    _enqueue(WaiterTask(WaiterJob.carry, index, bill: bill.total), now);
    tables[index]
      ..phase = TablePhase.served
      ..bill = bill.total;
    tickets[index] = null;
    served++;
    bowl.clear();
    return index;
  }

  /// Runs every event due up to [now], each at its own time.
  void advanceTo(int now) {
    for (var due = _nextDeadline(); due >= 0 && due <= now;) {
      _runEvents(due);
      due = _nextDeadline();
    }
  }

  int walkMs(int from, int to) =>
      (from > to ? from - to : to - from) * walkMsPerAisle ~/ 1000;

  static int _earlier(int next, int at) => next < 0 || at < next ? at : next;

  int _nextDeadline() {
    var next = -1;
    for (var i = 0; i < waiters.length; i++) {
      final waiter = waiters[i];
      if (waiter.action == WaiterAction.walking) {
        next = _earlier(next, waiter.walkEnd);
      } else if (!waiter.idle) {
        next = _earlier(next, waiter.actionEnds);
      }
    }
    for (var i = 0; i < tables.length; i++) {
      final table = tables[i];
      if (table.phase == TablePhase.eating) {
        next = _earlier(next, table.eatsUntil);
      } else if (table.phase == TablePhase.waiting) {
        next = _earlier(next, tickets[i]!.expiresAt);
      }
    }
    if (_doorCount > 0) {
      next = _earlier(next, _doorSince[_doorHead] + doorPatienceMs);
    }
    return next;
  }

  /// Ties run in a fixed order: waiters, eating, impatient tables, door.
  /// Then guests at the door get any table freed by these events.
  void _runEvents(int at) {
    for (var i = 0; i < waiters.length; i++) {
      final waiter = waiters[i];
      if (waiter.action == WaiterAction.walking && waiter.walkEnd == at) {
        waiter.position = waiter.walkTo;
        _startAction(waiter, at);
      } else if (!waiter.idle &&
          waiter.action != WaiterAction.walking &&
          waiter.actionEnds == at) {
        _finishAction(waiter, at);
      }
    }
    for (var i = 0; i < tables.length; i++) {
      final table = tables[i];
      if (table.phase == TablePhase.eating && table.eatsUntil == at) {
        table
          ..phase = TablePhase.dirty
          ..coins = table.bill
          ..bill = 0;
      } else if (table.phase == TablePhase.waiting &&
          tickets[i]!.expiresAt == at) {
        tickets[i] = null;
        table
          ..phase = TablePhase.free
          ..guest = null;
        _lose();
      }
    }
    while (_doorCount > 0 && _doorSince[_doorHead] + doorPatienceMs == at) {
      _door[_doorHead] = null;
      _doorHead = (_doorHead + 1) % doorCapacity;
      _doorCount--;
      _lose();
    }
    _seatNext(at);
    _dispatch(at);
  }

  void _lose() {
    lost++;
    streak.lose();
  }

  /// Books free tables for guests at the door, oldest guest first.
  void _seatNext(int now) {
    for (var i = 0; i < tables.length && _doorCount > 0; i++) {
      final table = tables[i];
      if (table.phase != TablePhase.free || _queueCount == queueCapacity) {
        continue;
      }
      table
        ..phase = TablePhase.booked
        ..guest = _door[_doorHead]
        ..hadTea = false;
      _door[_doorHead] = null;
      _doorHead = (_doorHead + 1) % doorCapacity;
      _doorCount--;
      _enqueue(WaiterTask(WaiterJob.seat, i), now);
    }
  }

  bool _enqueue(WaiterTask task, int now) {
    if (_queueCount == queueCapacity) {
      return false;
    }
    _queue[(_queueHead + _queueCount) % queueCapacity] = task;
    _queueCount++;
    _dispatch(now);
    return true;
  }

  /// Gives queued tasks to idle waiters, in order.
  void _dispatch(int now) {
    for (var i = 0; i < waiters.length && _queueCount > 0; i++) {
      final waiter = waiters[i];
      if (!waiter.idle) {
        continue;
      }
      final task = _queue[_queueHead]!;
      _queue[_queueHead] = null;
      _queueHead = (_queueHead + 1) % queueCapacity;
      _queueCount--;
      waiter
        ..task = task
        ..stop = 0;
      _walkToStop(waiter, now);
    }
  }

  int _stopPosition(WaiterTask task, int stop) {
    if (stop == 0 && task.job == WaiterJob.seat) {
      return door;
    }
    if ((stop == 0 && task.job == WaiterJob.carry) ||
        (stop == 1 && task.job == WaiterJob.clear)) {
      return pass;
    }
    return tables[task.table].position;
  }

  static int _stopCount(WaiterJob job) => job == WaiterJob.tea ? 1 : 2;

  void _walkToStop(Waiter waiter, int now) {
    final target = _stopPosition(waiter.task!, waiter.stop);
    final duration = walkMs(waiter.position, target);
    if (duration == 0) {
      waiter.position = target;
      _startAction(waiter, now);
      return;
    }
    waiter
      ..action = WaiterAction.walking
      ..walkTo = target
      ..walkStart = now
      ..walkEnd = now + duration;
  }

  void _startAction(Waiter waiter, int now) {
    final first = waiter.stop == 0;
    final WaiterAction action;
    final int ms;
    switch (waiter.task!.job) {
      case WaiterJob.seat:
        action = first ? WaiterAction.greeting : WaiterAction.seating;
        ms = first ? greetMs : seatMs;
      case WaiterJob.carry:
        action = first ? WaiterAction.picking : WaiterAction.placing;
        ms = first ? pickMs : placeMs;
      case WaiterJob.tea:
        action = WaiterAction.pouring;
        ms = pourMs;
      case WaiterJob.clear:
        action = first ? WaiterAction.wiping : WaiterAction.dropping;
        ms = first ? wipeMs : dropMs;
    }
    waiter
      ..action = action
      ..actionEnds = now + ms;
  }

  void _finishAction(Waiter waiter, int now) {
    final task = waiter.task!;
    final table = tables[task.table];
    final last = waiter.stop + 1 == _stopCount(task.job);
    switch (task.job) {
      case WaiterJob.seat when last:
        final guest = table.guest!;
        table.phase = TablePhase.waiting;
        tickets[task.table] = Ticket(
          guest.id,
          guest.recipe,
          now,
          now + guest.patienceMs,
        );
      case WaiterJob.carry when last:
        table
          ..phase = TablePhase.eating
          ..eatsUntil = now + eatMs;
      case WaiterJob.tea:
        table.teaQueued = false;
        final ticket = tickets[task.table];
        if (table.phase == TablePhase.waiting && ticket != null) {
          table.hadTea = true;
          _refreshPatience(task.table, ticket, now);
        }
      case WaiterJob.clear when !last:
        coins += table.coins;
        table
          ..coins = 0
          ..phase = TablePhase.free
          ..guest = null
          ..clearQueued = false;
      case WaiterJob.seat:
      case WaiterJob.carry:
      case WaiterJob.clear:
    }
    if (!last) {
      waiter.stop++;
      _walkToStop(waiter, now);
      return;
    }
    waiter
      ..task = null
      ..stop = 0
      ..action = WaiterAction.idle;
    _dispatch(now);
  }

  /// Gives back [teaPermille] of the full patience, never above full.
  void _refreshPatience(int index, Ticket ticket, int now) {
    final full = ticket.expiresAt - ticket.arrivedAt;
    final room = now + full - ticket.expiresAt;
    final bonus = full * teaPermille ~/ 1000;
    final shift = bonus < room ? bonus : room;
    if (shift <= 0) {
      return;
    }
    tickets[index] = Ticket(
      ticket.id,
      ticket.recipe,
      ticket.arrivedAt + shift,
      ticket.expiresAt + shift,
    );
  }
}
