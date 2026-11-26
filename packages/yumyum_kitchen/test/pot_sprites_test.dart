import "dart:io";
import "dart:ui" as ui;

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/pot_sprites.dart";

Future<ui.Image> _sheet() async {
  final bytes = File("assets/images/equipment.webp").readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

/// The four states, then the ready lid lifted and tilted as the boil
/// animation will move it.
class _Sheet extends CustomPainter {
  _Sheet(this.sprites);
  final PotSprites sprites;
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF8A3A1C),
    );
    final w = size.width / 6;
    final poses = <(PotPhase, double, double)>[
      for (final phase in PotPhase.values) (phase, 0, 0),
      (PotPhase.ready, .06, -.12),
      (PotPhase.cooking, .03, .05),
    ];
    for (final (i, (phase, rattle, tilt)) in poses.indexed) {
      final dst = Rect.fromLTWH(i * w + 6, 60, w - 12, (w - 12) / 1.1);
      sprites
        ..drawBody(canvas, phase, dst, _paint)
        ..drawLid(canvas, phase, dst, _paint, rattle: rattle, tilt: tilt);
    }
  }

  @override
  bool shouldRepaint(_Sheet oldDelegate) => false;
}

void main() {
  testWidgets("slices the painted pots into bodies and lids", (tester) async {
    final image = (await tester.runAsync(_sheet))!;
    final sprites = PotSprites(image);
    final cellW = image.width / 4;
    final cellH = image.height / 3;

    for (final phase in PotPhase.values) {
      expect(sprites.fullSource(phase).left, phase.index * cellW);
      expect(sprites.fullSource(phase).height, cellH);
    }
    final lid = sprites.lidSource(PotPhase.ready)!;
    final body = sprites.readyBodySource;
    expect(lid.bottom, body.top, reason: "lid and body meet without a gap");
    expect(lid.top, 0);
    expect(body.bottom, cellH);
    expect(sprites.lidSource(PotPhase.cooking)!.bottom, lessThan(lid.bottom));
    expect(sprites.lidSource(PotPhase.empty), isNull);
    expect(sprites.lidSource(PotPhase.burnt), isNull);
    expect(PotSprites.hasLid(PotPhase.cooking), isTrue);
    expect(PotSprites.hasLid(PotPhase.ready), isTrue);
    expect(PotSprites.hasLid(PotPhase.empty), isFalse);
    expect(PotSprites.hasLid(PotPhase.burnt), isFalse);

    tester.view
      ..physicalSize = const Size(1500, 320)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          painter: _Sheet(sprites),
          size: const Size(1500, 320),
        ),
      ),
    );
    if (Platform.isMacOS) {
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile("goldens/pot_states.png"),
      );
    }
  });

  testWidgets("a still cooking dome draws nothing extra", (tester) async {
    final image = (await tester.runAsync(_sheet))!;
    final sprites = PotSprites(image);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const dst = Rect.fromLTWH(0, 0, 110, 100);
    // Must not throw and must leave the canvas balanced.
    sprites
      ..drawLid(canvas, PotPhase.cooking, dst, Paint())
      ..drawLid(canvas, PotPhase.empty, dst, Paint())
      ..drawLid(canvas, PotPhase.burnt, dst, Paint());
    expect(canvas.getSaveCount(), 1);
    recorder.endRecording().dispose();
  });
}
