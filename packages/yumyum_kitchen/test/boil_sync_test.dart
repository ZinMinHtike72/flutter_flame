import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/boil_sync.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

/// A run driven exactly like the game: fixed 30 Hz rules steps, with the
/// boil synced inside each step.
class _Harness {
  _Harness()
    : run = KitchenRun(
        shift: campaign[1],
        id: "boil",
        random: Random(3),
        upgrades: const {Upgrade.extraPot},
      );

  final KitchenRun run;
  final sync = BoilSync();
  final clock = FixedStepClock();
  final changes = <(int step, BoilChange change)>[];
  final loopFlips = <(int step, bool on)>[];
  final phaseChanges = <(int step, int pot, PotPhase phase)>[];
  int stepCount = 0;
  late final List<PotPhase> _phases = [for (final p in run.pots) p.phase];

  void step(int ms) {
    stepCount++;
    run.advance(ms);
    for (var i = 0; i < run.pots.length; i++) {
      if (run.pots[i].phase != _phases[i]) {
        _phases[i] = run.pots[i].phase;
        phaseChanges.add((stepCount, i, _phases[i]));
      }
    }
    if (sync.step(run, (c) => changes.add((stepCount, c)))) {
      loopFlips.add((stepCount, sync.loopOn));
    }
  }

  void seconds(double s) {
    for (var i = 0; i < (s * 30).round(); i++) {
      clock.advance(1000 / 30, step);
    }
  }

  void tap(Station station, [int index = 0]) {
    run.tap(station, index);
    for (var i = 0; i < run.pots.length; i++) {
      _phases[i] = run.pots[i].phase;
    }
    // A tap lands between steps; the next step picks it up.
    clock.advance(1000 / 30, step);
  }
}

void main() {
  test("stage follows the pot phase and the half-way cooking mark", () {
    final pot = Pot();
    expect(BoilSync.stageOf(pot, 0, 3000), BoilStage.off);
    pot
      ..phase = PotPhase.cooking
      ..deadline = 3000;
    expect(BoilSync.stageOf(pot, 0, 3000), BoilStage.simmer);
    expect(BoilSync.stageOf(pot, 1499, 3000), BoilStage.simmer);
    expect(BoilSync.stageOf(pot, 1500, 3000), BoilStage.rolling);
    pot.phase = PotPhase.ready;
    expect(BoilSync.stageOf(pot, 0, 3000), BoilStage.ready);
    pot.phase = PotPhase.burnt;
    expect(BoilSync.stageOf(pot, 0, 3000), BoilStage.burnt);
  });

  test("boil starts, peaks and stops on the rules step that changes", () {
    final h = _Harness()..tap(Station.pack);
    // The loop starts on the very step that saw the pot start cooking.
    expect(h.loopFlips.first, (1, true));
    expect(h.changes.first.$2.to, BoilStage.simmer);
    expect(h.changes.first.$1, 1);

    h.seconds(3.2);
    final ready = h.phaseChanges.firstWhere((c) => c.$3 == PotPhase.ready);
    final readyChange = h.changes.firstWhere((c) => c.$2.to == BoilStage.ready);
    final rolling = h.changes.firstWhere((c) => c.$2.to == BoilStage.rolling);
    expect(readyChange.$1, ready.$1, reason: "ready stage on the ready step");
    expect(h.loopFlips.last, (ready.$1, false), reason: "loop stops there");
    expect(rolling.$1, lessThan(ready.$1));
    // Rolling starts at the half-way mark: within one step of 1.5 s.
    expect(rolling.$1, inInclusiveRange(45, 47));
  });

  test("burning and pausing silence the loop", () {
    final h = _Harness()
      ..tap(Station.pack)
      ..seconds(10);
    final burnt = h.phaseChanges.firstWhere((c) => c.$3 == PotPhase.burnt);
    expect(
      h.changes.any((c) => c.$1 == burnt.$1 && c.$2.to == BoilStage.burnt),
      isTrue,
    );
    expect(h.sync.loopOn, isFalse);

    h
      ..tap(Station.pot) // clear the burnt pot
      ..tap(Station.pack);
    expect(h.sync.loopOn, isTrue);
    h.run.paused = true;
    h.seconds(.1);
    expect(h.sync.loopOn, isFalse, reason: "paused shift is silent");
    h.run.paused = false;
    h.seconds(.1);
    expect(h.sync.loopOn, isTrue);
  });

  test("lid rattles only at the rolling boil, within its amplitude", () {
    final h = _Harness()..tap(Station.pack);
    for (var now = h.run.now; now < h.run.now + 600; now += 10) {
      expect(h.sync.rattle(0, now), 0, reason: "simmer is quiet");
    }
    h.seconds(1.7);
    expect(h.sync.stage(0), BoilStage.rolling);
    var peak = 0.0;
    for (var now = 0; now < BoilSync.rattlePeriodMs * 3; now += 5) {
      final r = h.sync.rattle(0, now);
      expect(r, inInclusiveRange(0, BoilSync.rattleAmplitude));
      peak = max(peak, r);
    }
    expect(peak, closeTo(BoilSync.rattleAmplitude, .002));
    expect(h.sync.boilFrame(0, 0), 0);
    expect(h.sync.boilFrame(0, 250), 2);
    expect(h.sync.boilFrame(0, 450), 0);
    expect(h.sync.tilt(0, 45), closeTo(h.sync.rattle(0, 45) * 2.2, 1e-9));
  });

  test("the ready lid wobbles, then settles", () {
    final h = _Harness()..tap(Station.pack);
    while (h.sync.stage(0) != BoilStage.ready) {
      h.seconds(1 / 30);
    }
    final readyAt = h.run.now;
    final wobble = [
      for (var t = 0; t < BoilSync.settleMs; t += 10)
        h.sync.rattle(0, readyAt + t).abs(),
    ].reduce(max);
    expect(wobble, greaterThan(BoilSync.rattleAmplitude * .3));
    expect(h.sync.rattle(0, readyAt + BoilSync.settleMs), 0);
    expect(h.sync.boilFrame(0, readyAt), -1);
  });

  test("reset clears every pot", () {
    final h = _Harness()..tap(Station.pack);
    h.sync.reset();
    expect(h.sync.stage(0), BoilStage.off);
    expect(h.sync.loopOn, isFalse);
  });
}
