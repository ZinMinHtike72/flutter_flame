import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// Press response for counter targets: the pressed target snaps down to
/// [pressedScale] on the very next rendered frame (≤ 34 ms at 30 fps, well
/// inside the 100 ms budget) and eases back over [releaseMs].
///
/// Time is the game's own motion clock in milliseconds, so the response is
/// deterministic in tests. Holds one press at a time and allocates nothing.
class PressFeedback {
  static const pressedScale = .94;
  static const releaseMs = 120.0;

  Station? _station;
  int _index = 0;
  double _at = double.negativeInfinity;

  /// Records a press of [station] [index] at [nowMs].
  void press(Station station, int index, double nowMs) {
    _station = station;
    _index = index;
    _at = nowMs;
  }

  /// How far through the release [station] [index] is: 0 just pressed,
  /// 1 released (or never pressed).
  double progress(Station station, int index, double nowMs) {
    if (_station != station || _index != index) {
      return 1;
    }
    final t = (nowMs - _at) / releaseMs;
    return t < 0
        ? 0
        : t > 1
        ? 1
        : t;
  }

  /// Scale to draw [station] [index] at: [pressedScale] when just pressed,
  /// easing out (cubic) back to 1.
  double scale(Station station, int index, double nowMs) {
    final t = progress(station, index, nowMs);
    if (t >= 1) {
      return 1;
    }
    final eased = 1 - (1 - t) * (1 - t) * (1 - t);
    return pressedScale + (1 - pressedScale) * eased;
  }
}

/// Haptic strength for each kind of feedback.
enum Haptic { none, selection, light, medium, heavy }

/// Haptics per action: a selection click for every accepted step (pack,
/// transfer, garnish, discard), light on a serve, medium on a streak, heavy
/// on a burnt pot. Missed customers give no buzz: no tap caused them.
Haptic hapticFor(KitchenCue cue) => switch (cue) {
  KitchenCue.pack ||
  KitchenCue.transfer ||
  KitchenCue.garnish ||
  KitchenCue.discarded => Haptic.selection,
  KitchenCue.served => Haptic.light,
  KitchenCue.streak => Haptic.medium,
  KitchenCue.burnt => Haptic.heavy,
  KitchenCue.missed || KitchenCue.none => Haptic.none,
};
