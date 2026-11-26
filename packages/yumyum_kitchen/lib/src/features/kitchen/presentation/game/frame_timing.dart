/// Decides which display vsyncs run a game step, capping rendering at [fps].
///
/// A vsync runs a step when at least one frame interval has passed since the
/// last step, minus [tolerance] so normal vsync jitter (16.6 ms vs 16.8 ms)
/// does not drop a 60 Hz display to 20 fps. Displays at 60, 90 and 120 Hz all
/// step 30 times a second; a 50 Hz display steps 25 times.
class FrameThrottle {
  FrameThrottle({
    this.fps = 30,
    this.tolerance = const Duration(milliseconds: 4),
  });

  final int fps;
  final Duration tolerance;
  Duration? _last;

  Duration get interval => Duration(microseconds: 1000000 ~/ fps);

  /// Seconds since the last step when [timestamp] should step, else null.
  /// The first vsync only starts the clock.
  double? onVsync(Duration timestamp) {
    final last = _last;
    if (last == null || timestamp < last) {
      _last = timestamp;
      return null;
    }
    final elapsed = timestamp - last;
    if (elapsed + tolerance < interval) {
      return null;
    }
    _last = timestamp;
    return elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  /// Forget the last step, e.g. after the game was detached.
  void reset() => _last = null;
}

/// Turns real elapsed time into fixed rules steps of exactly 1000 / [hertz]
/// milliseconds, as integers that never drift (33, 33, 34 … at 30 Hz).
///
/// At most [maxCatchUp] steps run per call; time beyond that is dropped so a
/// long hitch cannot spiral into ever longer frames.
class FixedStepClock {
  FixedStepClock({this.hertz = 30, this.maxCatchUp = 5});

  final int hertz;
  final int maxCatchUp;
  double _pendingMs = 0;
  int _stepIndex = 0;

  /// Length in ms of the step that runs next.
  int get nextStepMs =>
      ((_stepIndex + 1) * 1000) ~/ hertz - (_stepIndex * 1000) ~/ hertz;

  /// Adds [elapsedMs] and calls [step] once per whole fixed step due.
  /// Returns how many steps ran.
  int advance(double elapsedMs, void Function(int ms) step) {
    if (elapsedMs <= 0) {
      return 0;
    }
    _pendingMs += elapsedMs;
    var ran = 0;
    while (_pendingMs >= nextStepMs) {
      if (ran == maxCatchUp) {
        _pendingMs = 0;
        break;
      }
      final ms = nextStepMs;
      _pendingMs -= ms;
      _stepIndex = (_stepIndex + 1) % hertz;
      step(ms);
      ran++;
    }
    return ran;
  }
}
