import "dart:math" as math;

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// What a pot looks and sounds like right now.
enum BoilStage {
  /// Empty: burner off, silent.
  off,

  /// First half of cooking: small bubbles, quiet lid.
  simmer,

  /// Second half of cooking: rolling boil, lid rattles, boil loop peaks.
  rolling,

  /// Cooked: lid lifted, loop stops, ready chime.
  ready,

  /// Burnt: no boil.
  burnt,
}

/// A stage change of one pot, reported on the rules step it happened.
class BoilChange {
  const BoilChange(this.pot, this.from, this.to);
  final int pot;
  final BoilStage from;
  final BoilStage to;
}

/// Keeps the boil animation and the boil audio locked to the rules.
///
/// [step] runs inside the same fixed 30 Hz rules step that changes pot
/// phases, so bubbles, lid rattle and the boil loop start, peak and stop on
/// exactly the step where the rules say the pot changed — never a rendered
/// frame later.
class BoilSync {
  BoilSync({int pots = 2})
    : _stages = List.filled(pots, BoilStage.off),
      _changedAt = List.filled(pots, 0);

  final List<BoilStage> _stages;
  final List<int> _changedAt;
  bool _loopOn = false;

  /// Rattle amplitude at the rolling boil, as a fraction of the pot height.
  static const rattleAmplitude = .018;

  /// One lid knock every this many milliseconds at the rolling boil.
  static const rattlePeriodMs = 180;

  /// How long the ready lid wobbles after it pops up.
  static const settleMs = 420;

  BoilStage stage(int pot) => _stages[pot];

  /// Whether the boil loop should be playing.
  bool get loopOn => _loopOn;

  /// Stage for [pot] at [now] in a run whose cooking lasts [cookMs].
  static BoilStage stageOf(Pot pot, int now, int cookMs) {
    switch (pot.phase) {
      case PotPhase.empty:
        return BoilStage.off;
      case PotPhase.ready:
        return BoilStage.ready;
      case PotPhase.burnt:
        return BoilStage.burnt;
      case PotPhase.cooking:
        final left = (pot.deadline - now) / cookMs;
        return left > .5 ? BoilStage.simmer : BoilStage.rolling;
    }
  }

  /// Re-reads every pot after a rules step and reports each change through
  /// [onChange]. Returns whether the boil loop flipped on or off this step.
  bool step(KitchenRun run, void Function(BoilChange change) onChange) {
    final count = math.min(_stages.length, run.pots.length);
    for (var i = 0; i < count; i++) {
      final next = stageOf(run.pots[i], run.now, run.cookMs);
      final previous = _stages[i];
      if (next != previous) {
        _stages[i] = next;
        _changedAt[i] = run.now;
        onChange(BoilChange(i, previous, next));
      }
    }
    var boiling = false;
    if (!run.paused && !run.ended) {
      for (var i = 0; i < count; i++) {
        final s = _stages[i];
        if (s == BoilStage.simmer || s == BoilStage.rolling) {
          boiling = true;
        }
      }
    }
    final flipped = boiling != _loopOn;
    _loopOn = boiling;
    return flipped;
  }

  /// Forget every pot (new shift).
  void reset() {
    _stages.fillRange(0, _stages.length, BoilStage.off);
    _changedAt.fillRange(0, _changedAt.length, 0);
    _loopOn = false;
  }

  /// Lid lift for [pot] at [now], as a fraction of the pot height: knocks at
  /// the rolling boil, a decaying wobble just after the lid pops up.
  double rattle(int pot, int now) {
    switch (_stages[pot]) {
      case BoilStage.rolling:
        final t = (now % rattlePeriodMs) / rattlePeriodMs;
        // A quick knock up, then the lid falls back: |sin| over half a period.
        return t < .5 ? math.sin(t * 2 * math.pi) * rattleAmplitude : 0;
      case BoilStage.ready:
        final age = now - _changedAt[pot];
        if (age < 0 || age >= settleMs) {
          return 0;
        }
        final decay = 1 - age / settleMs;
        return math.sin(age / 35) * rattleAmplitude * .8 * decay;
      case BoilStage.off || BoilStage.simmer || BoilStage.burnt:
        return 0;
    }
  }

  /// Lid tilt in radians that goes with [rattle].
  double tilt(int pot, int now) => rattle(pot, now) * 2.2;

  /// Bubbles visible in the pot mouth for the current stage.
  int bubbles(int pot) => switch (_stages[pot]) {
    BoilStage.simmer => 3,
    BoilStage.rolling => 7,
    BoilStage.off || BoilStage.ready || BoilStage.burnt => 0,
  };
}
