import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";

/// Steps in one second of vsyncs at [hertz], with optional ±[jitterUs].
int stepsPerSecond(int hertz, {int jitterUs = 0}) {
  final throttle = FrameThrottle();
  var steps = 0;
  // One warm-up vsync plus one second of frames.
  for (var i = 0; i <= hertz; i++) {
    final jitter = i.isEven ? jitterUs : -jitterUs;
    final at = Duration(microseconds: i * 1000000 ~/ hertz + jitter);
    if (throttle.onVsync(at) != null) {
      steps++;
    }
  }
  return steps;
}

void main() {
  group("FrameThrottle", () {
    test("caps 60, 90 and 120 Hz displays at 30 steps a second", () {
      expect(stepsPerSecond(60), 30);
      expect(stepsPerSecond(90), 30);
      expect(stepsPerSecond(120), 30);
    });

    test("tolerates vsync jitter without dropping to 20 fps", () {
      expect(stepsPerSecond(60, jitterUs: 900), 30);
    });

    test("a 50 Hz display steps every other vsync", () {
      expect(stepsPerSecond(50), 25);
    });

    test("first vsync starts the clock; dt is the time since last step", () {
      final throttle = FrameThrottle();
      expect(throttle.onVsync(Duration.zero), isNull);
      expect(throttle.onVsync(const Duration(milliseconds: 16)), isNull);
      expect(
        throttle.onVsync(const Duration(milliseconds: 33)),
        closeTo(.033, 1e-9),
      );
      throttle.reset();
      expect(throttle.onVsync(const Duration(seconds: 5)), isNull);
    });

    test("a timestamp going backwards restarts the clock", () {
      final throttle = FrameThrottle()..onVsync(const Duration(seconds: 2));
      expect(throttle.onVsync(const Duration(seconds: 1)), isNull);
    });
  });

  group("FixedStepClock", () {
    test("steps are 33/33/34 ms and sum to exactly 1000 ms a second", () {
      final clock = FixedStepClock();
      final steps = <int>[];
      for (var i = 0; i < 30; i++) {
        clock.advance(1000 / 30, steps.add);
      }
      expect(steps, hasLength(30));
      expect(steps.reduce((a, b) => a + b), 1000);
      expect(steps.toSet(), {33, 34});
    });

    test("never drifts over ten minutes of uneven frames", () {
      final clock = FixedStepClock();
      var total = 0;
      for (var i = 0; i < 36000; i++) {
        clock.advance(
          i.isEven ? 16.0 : 17.333333333333332,
          (ms) => total += ms,
        );
      }
      expect(total, closeTo(600000, 34));
    });

    test("caps catch-up at five steps and drops the rest", () {
      final clock = FixedStepClock();
      var count = 0;
      expect(clock.advance(1000, (_) => count++), 5);
      expect(count, 5);
      expect(clock.advance(10, (_) => count++), 0);
    });

    test("ignores zero and negative time", () {
      final clock = FixedStepClock();
      expect(clock.advance(0, (_) => fail("no step")), 0);
      expect(clock.advance(-5, (_) => fail("no step")), 0);
    });
  });
}
