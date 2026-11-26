import "dart:io";
import "dart:ui" as ui;

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/pot_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/sprite_atlas.dart";

Future<SpriteAtlas> loadAtlas(String name) async {
  final bytes = File("assets/images/$name.webp").readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  return SpriteAtlas.fromJson(
    image,
    File("assets/images/$name.json").readAsStringSync(),
  );
}

/// Pots in all four states with their lids, then a rolling boil with the
/// lid rattling and the bubbling surface.
class _Sheet extends CustomPainter {
  _Sheet(this.pots);
  final PotSprites pots;
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF8A3A1C),
    );
    final w = size.width / 5;
    for (final (i, phase) in [
      PotPhase.empty,
      PotPhase.cooking,
      PotPhase.ready,
      PotPhase.burnt,
      PotPhase.cooking,
    ].indexed) {
      final cell = Rect.fromLTWH(i * w + 8, 70, w - 16, w - 16);
      pots.drawBody(canvas, phase, cell, _paint);
      if (i == 4) {
        pots.drawBoil(canvas, 1, cell, _paint);
      }
      pots.drawLid(
        canvas,
        phase,
        cell,
        _paint,
        rattle: i == 4 ? .02 : 0,
        tilt: i == 4 ? .04 : 0,
      );
    }
  }

  @override
  bool shouldRepaint(_Sheet oldDelegate) => false;
}

void main() {
  testWidgets("painted pots, lids and boil surface line up", (tester) async {
    final atlas = (await tester.runAsync(() => loadAtlas("pots")))!;
    final pots = PotSprites(atlas);

    for (final phase in PotPhase.values) {
      expect(atlas.has("pot_${phase.name}"), isTrue);
    }
    for (final name in ["lid_glass", "lid_enamel", "boil_0", "boil_3"]) {
      expect(atlas.has(name), isTrue);
    }
    expect(() => atlas.id("missing"), throwsArgumentError);
    expect(PotSprites.hasLid(PotPhase.cooking), isTrue);
    expect(PotSprites.hasLid(PotPhase.ready), isTrue);
    expect(PotSprites.hasLid(PotPhase.empty), isFalse);
    expect(PotSprites.hasLid(PotPhase.burnt), isFalse);
    expect(PotSprites.poseFor(PotPhase.cooking), (0, 0, 0));
    expect(PotSprites.poseFor(PotPhase.ready).$1, greaterThan(0));

    tester.view
      ..physicalSize = const Size(1500, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(painter: _Sheet(pots), size: const Size(1500, 400)),
      ),
    );
    if (Platform.isMacOS) {
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile("goldens/pot_states.png"),
      );
    }
  });

  testWidgets("a lidless pot draws no lid and keeps the canvas balanced", (
    tester,
  ) async {
    final atlas = (await tester.runAsync(() => loadAtlas("pots")))!;
    final pots = PotSprites(atlas);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const cell = Rect.fromLTWH(0, 0, 100, 100);
    pots
      ..drawLid(canvas, PotPhase.empty, cell, Paint())
      ..drawLid(canvas, PotPhase.burnt, cell, Paint())
      ..drawLid(canvas, PotPhase.ready, cell, Paint(), rattle: .01)
      ..drawBoil(canvas, 7, cell, Paint());
    expect(canvas.getSaveCount(), 1);
    recorder.endRecording().dispose();
  });
}
