import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/steam_field.dart";

const _mouths = [
  Rect.fromLTWH(100, 400, 120, 110),
  Rect.fromLTWH(300, 400, 120, 110),
];

List<Pot> pots(PotPhase a, [PotPhase b = PotPhase.empty]) => [
  Pot()..phase = a,
  Pot()..phase = b,
];

/// Runs [seconds] of 30 Hz steps.
void run(SteamField field, List<Pot> pots, SteamQuality q, double seconds) {
  for (var i = 0; i < (seconds * 30).round(); i++) {
    field.update(1 / 30, pots, _mouths, q, 1);
  }
}

void main() {
  test("empty pots never steam", () {
    final field = SteamField(emitters: 2);
    run(field, pots(PotPhase.empty), SteamQuality.high, 3);
    expect(field.alive, 0);
  });

  test("puffs per pot never exceed the quality tier", () {
    for (final quality in SteamQuality.values) {
      final field = SteamField(emitters: 2);
      final both = pots(PotPhase.ready, PotPhase.ready);
      for (var i = 0; i < 300; i++) {
        field.update(1 / 30, both, _mouths, quality, 1);
        expect(field.aliveAbove(0), lessThanOrEqualTo(quality.perPot));
        expect(field.aliveAbove(1), lessThanOrEqualTo(quality.perPot));
      }
      expect(field.alive, greaterThan(0));
    }
  });

  test("higher tiers show more steam; ready steams more than cooking", () {
    double average(PotPhase phase, SteamQuality q) {
      final field = SteamField(emitters: 2);
      final list = pots(phase);
      var sum = 0;
      for (var i = 0; i < 300; i++) {
        field.update(1 / 30, list, _mouths, q, 1);
        sum += field.alive;
      }
      return sum / 300;
    }

    expect(
      average(PotPhase.ready, SteamQuality.low),
      lessThan(average(PotPhase.ready, SteamQuality.high)),
    );
    expect(
      average(PotPhase.cooking, SteamQuality.high),
      lessThan(average(PotPhase.ready, SteamQuality.high)),
    );
  });

  test("the pool never grows and buffers are reused", () {
    final field = SteamField(emitters: 2);
    final transforms = field.transforms;
    final colors = field.colors;
    run(field, pots(PotPhase.burnt, PotPhase.ready), SteamQuality.high, 10);
    expect(field.alive, lessThanOrEqualTo(field.capacity));
    expect(field.capacity, 2 * SteamQuality.high.perPot);
    expect(identical(field.transforms, transforms), isTrue);
    expect(identical(field.colors, colors), isTrue);
  });

  test("puffs rise above their pot and die when it empties", () {
    final field = SteamField(emitters: 2);
    final list = pots(PotPhase.ready);
    run(field, list, SteamQuality.high, 1);
    expect(field.aliveAbove(0), greaterThan(0));
    expect(field.aliveAbove(1), 0);
    list.first.phase = PotPhase.empty;
    run(field, list, SteamQuality.high, 2);
    expect(field.alive, 0);
  });

  test("clear empties the field; zero dt does nothing", () {
    final field = SteamField(emitters: 2);
    run(field, pots(PotPhase.ready), SteamQuality.high, 1);
    field.clear();
    expect(field.alive, 0);
    field.update(0, pots(PotPhase.ready), _mouths, SteamQuality.high, 1);
    expect(field.alive, 0);
  });

  test("renders live puffs and blanks dead slots", () async {
    final puff = await SteamField.bakePuff();
    final field = SteamField(emitters: 2);
    final list = pots(PotPhase.burnt);
    run(field, list, SteamQuality.high, 1);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    field.render(canvas, puff, Paint());
    final alive = field.alive;
    expect(field.colors.take(alive).every((c) => c != 0), isTrue);
    list.first.phase = PotPhase.empty;
    run(field, list, SteamQuality.high, 2);
    field.render(canvas, puff, Paint());
    expect(field.colors.take(alive).every((c) => c == 0), isTrue);
    recorder.endRecording().dispose();
    puff.dispose();
  });

  test("rate follows the pot phase", () {
    expect(SteamField.rate(PotPhase.empty), 0);
    expect(
      SteamField.rate(PotPhase.ready),
      greaterThan(SteamField.rate(PotPhase.cooking)),
    );
    expect(SteamField.rate(PotPhase.burnt), greaterThan(0));
  });

  group("painted textures", () {
    final steamFrames = [
      for (var i = 0; i < 8; i++) Rect.fromLTWH(i * 100.0, 0, 90, 200),
    ];
    final smokeFrames = [
      for (var i = 0; i < 4; i++) Rect.fromLTWH(i * 100.0, 300, 90, 180),
    ];

    Set<double> lefts(SteamField field) => {
      for (var i = 0; i < field.alive; i++) field.rects[i * 4],
    };

    test("ready pots use the big wisps, cooking pots the small ones", () {
      final ready = SteamField(emitters: 2)
        ..useTextures(steamFrames, smokeFrames);
      expect(ready.textured, isTrue);
      run(ready, pots(PotPhase.ready), SteamQuality.high, 2);
      expect(lefts(ready).every((l) => l >= 400 && l < 800), isTrue);

      final cooking = SteamField(emitters: 2)
        ..useTextures(steamFrames, smokeFrames);
      run(cooking, pots(PotPhase.cooking), SteamQuality.high, 2);
      expect(lefts(cooking).every((l) => l < 400), isTrue);
    });

    test("burnt pots use smoke frames; rects follow swapped particles", () {
      final field = SteamField(emitters: 2)
        ..useTextures(steamFrames, smokeFrames);
      final list = pots(PotPhase.burnt, PotPhase.ready);
      run(field, list, SteamQuality.high, 3);
      for (var i = 0; i < field.alive; i++) {
        final top = field.rects[i * 4 + 1];
        final height = field.rects[i * 4 + 3] - top;
        // Every live slot holds a whole, valid frame from one of the sets.
        expect(
          top == 0 && height == 200 || top == 300 && height == 180,
          isTrue,
        );
      }
      expect(field.aliveAbove(0), greaterThan(0));
    });

    test("textured render draws painted colours untinted", () async {
      final puff = await SteamField.bakePuff();
      final field = SteamField(emitters: 2)
        ..useTextures(steamFrames, smokeFrames);
      run(field, pots(PotPhase.ready), SteamQuality.high, 1);
      final recorder = PictureRecorder();
      field.render(Canvas(recorder), puff, Paint());
      for (var i = 0; i < field.alive; i++) {
        expect(field.colors[i] & 0xFFFFFF, 0xFFFFFF);
      }
      recorder.endRecording().dispose();
      puff.dispose();
    });
  });
}
