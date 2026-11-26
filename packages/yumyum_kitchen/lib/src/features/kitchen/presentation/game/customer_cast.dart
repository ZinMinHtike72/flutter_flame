import "dart:math" as math;

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// Animation clips in every customer sheet, with their frame counts.
enum CustomerClip {
  walk(8),
  idle(4),
  impatient(4),
  happy(4),
  annoyed(4),
  away(8);

  const CustomerClip(this.frames);
  final int frames;
}

/// Where and how to draw one customer this frame. Positions are in units of
/// the customer's standing height `H`, relative to their counter slot:
/// [x] sideways (positive = right), [depth] from 0 (at the counter) to 1
/// (back on the street, feet visible, smaller).
class CustomerPose {
  CustomerClip clip = CustomerClip.idle;
  int frame = 0;
  double opacity = 1;

  /// Previous clip fading out during a cross-fade; null when none.
  CustomerClip? fromClip;
  int fromFrame = 0;
  double fromOpacity = 0;

  double x = 0;
  double depth = 0;

  /// Mirror the sprite (sheets face right).
  bool flip = false;

  /// Idle breathing scale.
  double breath = 1;
}

/// One customer on screen, from walking in until they have walked away.
class CustomerActor {
  int id = -1;
  int slot = 0;
  int arrived = 0;

  /// When the entrance starts: the arrival, or later if the previous
  /// customer in this slot is still reacting there. Patience still runs from
  /// [arrived].
  int enterAt = 0;
  int expires = 0;
  int patience = 1;

  /// Walks in from the left (+1, moving right) or the right (-1).
  int enterDirection = 1;

  /// When they left their slot (served or missed), or null while waiting.
  int? leftAt;
  bool served = false;

  /// Which of the six customers to draw.
  int get look => id % CustomerCast.looks;
  bool get active => id >= 0;
}

/// Keeps one animated actor per customer, derived from the rules each step,
/// and poses them as a pure function of `run.now`.
///
/// Because everything is computed from time, the animation is deterministic,
/// frame-rate independent, and freezes with the shift's clock when paused.
class CustomerCast {
  CustomerCast() : actors = List.generate(capacity, (_) => CustomerActor());

  /// Four slots, plus up to four customers still walking away.
  static const capacity = 8;
  static const looks = 6;

  // Timing (ms) and motion (in units of the standing height H).
  static const enterMs = 1200;
  static const enterDistance = 1.4;
  static const enterFadeMs = 250;
  static const reactMs = 600;
  static const reactFrameMs = 100;
  static const leaveMs = 1100;
  static const leaveDistance = 1.0;
  static const leaveFadeMs = 350;
  static const crossFadeMs = 100;
  static const reducedFadeMs = 150;

  /// Distance of one full 8-frame walk cycle (two steps).
  static const strideCycle = .75;
  static const idleFrameMs = 1000 ~/ 6;
  static const impatientFrameMs = 125;

  /// Patience share below which a customer turns impatient.
  static const impatientShare = .3;

  final List<CustomerActor> actors;
  KitchenRun? _run;

  /// Total time an actor stays after leaving the slot.
  static int exitMs({required bool reducedMotion}) =>
      reactMs + (reducedMotion ? reducedFadeMs : leaveMs);

  /// Matches actors to the run's customers. Call once per rules step.
  void sync(KitchenRun run, {required bool reducedMotion}) {
    if (!identical(run, _run)) {
      _run = run;
      for (final actor in actors) {
        actor.id = -1;
      }
    }
    final now = run.now;
    for (var slot = 0; slot < run.customers.length; slot++) {
      final customer = run.customers[slot];
      final waiting = _waitingIn(slot);
      if (waiting != null && waiting.id != customer?.id) {
        waiting
          ..leftAt = now
          ..served = run.servedCustomerId == waiting.id;
      }
      if (customer != null && waiting?.id != customer.id) {
        final clearAt = _slotClearAt(slot);
        final actor = _free(now, reducedMotion);
        if (actor != null) {
          actor
            ..id = customer.id
            ..slot = slot
            ..arrived = customer.arrived
            ..enterAt = math.max(customer.arrived, clearAt)
            ..expires = customer.expires
            ..patience = math.max(1, customer.expires - customer.arrived)
            ..enterDirection = slot * 2 < run.shift.slots - 1
                ? 1
                : slot * 2 > run.shift.slots - 1
                ? -1
                : (customer.id.isEven ? 1 : -1)
            ..leftAt = null
            ..served = false;
        }
      }
    }
    final linger = exitMs(reducedMotion: reducedMotion);
    for (final actor in actors) {
      final left = actor.leftAt;
      if (actor.active && left != null && now - left >= linger) {
        actor.id = -1;
      }
    }
  }

  /// When the last customer to leave [slot] stops reacting there.
  int _slotClearAt(int slot) {
    var clear = 0;
    for (final actor in actors) {
      final left = actor.leftAt;
      if (actor.active && actor.slot == slot && left != null) {
        clear = math.max(clear, left + reactMs);
      }
    }
    return clear;
  }

  CustomerActor? _waitingIn(int slot) {
    for (final actor in actors) {
      if (actor.active && actor.slot == slot && actor.leftAt == null) {
        return actor;
      }
    }
    return null;
  }

  /// A free actor, or the one that has been leaving longest.
  CustomerActor? _free(int now, bool reducedMotion) {
    CustomerActor? oldest;
    for (final actor in actors) {
      if (!actor.active) {
        return actor;
      }
      final left = actor.leftAt;
      if (left != null && (oldest == null || left < oldest.leftAt!)) {
        oldest = actor;
      }
    }
    return oldest;
  }

  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static double _easeIn(double t) => t * t * t;

  static int _strideFrame(double travelled) =>
      ((travelled / strideCycle) * CustomerClip.walk.frames).floor() %
      CustomerClip.walk.frames;

  /// Fills [out] for [actor] at [now]. [guided] freezes patience (tutorial).
  static void pose(
    CustomerActor actor,
    int now,
    CustomerPose out, {
    required bool reducedMotion,
    required bool guided,
  }) {
    out
      ..fromClip = null
      ..x = 0
      ..depth = 0
      ..flip = false
      ..breath = 1
      ..opacity = 1;
    final start = _segment(actor, now, out, reducedMotion, guided);
    if (reducedMotion || now - start >= crossFadeMs || start <= actor.enterAt) {
      return;
    }
    // Cross-fade from the clip that was showing just before this segment.
    final scratch = _scratch
      ..x = out.x
      ..depth = out.depth;
    _segment(actor, start - 1, scratch, reducedMotion, guided);
    final p = (now - start) / crossFadeMs;
    out
      ..fromClip = scratch.clip
      ..fromFrame = scratch.frame
      ..fromOpacity = (1 - p) * scratch.opacity;
  }

  static final _scratch = CustomerPose();

  /// Poses one segment and returns when that segment started.
  static int _segment(
    CustomerActor a,
    int now,
    CustomerPose out,
    bool reducedMotion,
    bool guided,
  ) {
    final left = a.leftAt;
    final t = now - a.enterAt;
    if (left == null || now < left) {
      if (t < 0) {
        // Waiting off stage for the slot to clear.
        out
          ..clip = reducedMotion ? CustomerClip.idle : CustomerClip.walk
          ..frame = 0
          ..x = reducedMotion ? 0 : -a.enterDirection * enterDistance
          ..depth = reducedMotion ? 0 : 1
          ..opacity = 0;
        return a.enterAt;
      }
      // Walking in.
      if (!reducedMotion && t < enterMs) {
        final p = _easeOut((t / enterMs).clamp(0.0, 1.0));
        out
          ..clip = CustomerClip.walk
          ..frame = _strideFrame(enterDistance * p)
          ..x = -a.enterDirection * enterDistance * (1 - p)
          ..depth = 1 - p
          ..flip = a.enterDirection < 0
          ..opacity = math.min(1, t / enterFadeMs);
        return a.enterAt;
      }
      if (reducedMotion && t < reducedFadeMs) {
        out
          ..clip = CustomerClip.idle
          ..frame = 0
          ..opacity = math.max(0, t / reducedFadeMs);
        return a.enterAt;
      }
      // Waiting: idle, then impatient once patience runs low.
      final impatientAt = a.expires - (a.patience * impatientShare).round();
      if (!guided && now >= impatientAt) {
        out
          ..clip = CustomerClip.impatient
          ..frame = reducedMotion
              ? 0
              : ((now - impatientAt) ~/ impatientFrameMs) %
                    CustomerClip.impatient.frames;
        return impatientAt;
      }
      final since = now - (a.enterAt + (reducedMotion ? 0 : enterMs));
      out
        ..clip = CustomerClip.idle
        ..frame = reducedMotion
            ? 0
            : (since ~/ idleFrameMs) % CustomerClip.idle.frames
        ..breath = reducedMotion
            ? 1
            : 1 + math.sin(since / 1000 * math.pi) * .004 + .004;
      return a.enterAt + (reducedMotion ? 0 : enterMs);
    }
    // Reacting at the slot: happy with the bowl, or an annoyed sigh.
    final s = now - left;
    final react = a.served ? CustomerClip.happy : CustomerClip.annoyed;
    if (s < reactMs) {
      out
        ..clip = react
        ..frame = reducedMotion
            ? (a.served ? 3 : 2)
            : math.min(react.frames - 1, s ~/ reactFrameMs);
      return left;
    }
    final exitDirection = -a.enterDirection;
    if (reducedMotion) {
      out
        ..clip = react
        ..frame = a.served ? 3 : 2
        ..opacity = math.max(0, 1 - (s - reactMs) / reducedFadeMs);
      return left;
    }
    // Walking away: back view when happy, side view when annoyed.
    final p = ((s - reactMs) / leaveMs).clamp(0.0, 1.0);
    final e = _easeIn(p);
    final leaveLeft = leaveMs - (s - reactMs);
    out
      ..clip = a.served ? CustomerClip.away : CustomerClip.walk
      ..frame = _strideFrame(leaveDistance * e + .2 * p)
      ..x = exitDirection * leaveDistance * e
      ..depth = e
      ..flip = exitDirection < 0
      ..opacity = math.min(1, math.max(0, leaveLeft / leaveFadeMs));
    return left + reactMs;
  }
}
