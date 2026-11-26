import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/steam_field.dart";

/// Picks the default [SteamQuality] from a short startup benchmark.
///
/// The workload is the heaviest particle case: two ready pots at the high
/// tier, simulated at 30 Hz and recorded into a picture each frame. It runs
/// once during loading (before the shift clock starts) and only when no tier
/// has been saved yet.
abstract final class QualityBenchmark {
  /// Average cost per frame at or under this picks [SteamQuality.high].
  static const highBudget = Duration(microseconds: 250);

  /// Average cost per frame at or under this picks [SteamQuality.medium].
  static const mediumBudget = Duration(microseconds: 700);

  static const _mouths = [
    Rect.fromLTWH(200, 400, 160, 140),
    Rect.fromLTWH(400, 400, 160, 140),
  ];

  /// Maps an average frame cost to a tier.
  static SteamQuality tierFor(Duration perFrame) {
    if (perFrame <= highBudget) {
      return SteamQuality.high;
    }
    if (perFrame <= mediumBudget) {
      return SteamQuality.medium;
    }
    return SteamQuality.low;
  }

  /// Average cost of one simulated frame over [frames], after a warm-up.
  static Duration measure(Image puff, {int frames = 60, int warmUp = 15}) {
    final field = SteamField(emitters: 2);
    final pots = [Pot()..phase = PotPhase.ready, Pot()..phase = PotPhase.ready];
    final paint = Paint();
    void frame() {
      field.update(1 / 30, pots, _mouths, SteamQuality.high, 1);
      final recorder = PictureRecorder();
      field.render(Canvas(recorder), puff, paint);
      recorder.endRecording().dispose();
    }

    for (var i = 0; i < warmUp; i++) {
      frame();
    }
    final watch = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      frame();
    }
    watch.stop();
    return Duration(microseconds: watch.elapsedMicroseconds ~/ frames);
  }
}
