import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/sprite_atlas.dart";

/// Painted pots, lids and boiling surface from `assets/images/pots.webp`
/// (packed from `art/sources/pot_bodies.png`, `pot_lids.png` and
/// `boil_surface.png`).
///
/// All pot frames share one square cell; positions below are fractions of
/// that cell, measured from the source art (1024 px cells): the pot rim's
/// centre is at (512, 292) and a lid's rim centre at (511, 532), so a seated
/// lid sits [lidSeat] of the cell above the pot.
class PotSprites {
  PotSprites(this.atlas)
    : _bodies = [
        for (final phase in PotPhase.values) atlas.id("pot_${phase.name}"),
      ],
      _glass = atlas.id("lid_glass"),
      _enamel = atlas.id("lid_enamel"),
      _boil = [for (var i = 0; i < boilFrames; i++) atlas.id("boil_$i")];

  final SpriteAtlas atlas;
  final List<int> _bodies;
  final int _glass;
  final int _enamel;
  final List<int> _boil;

  /// Pot cells are square.
  static const aspect = 1.0;

  /// Rim centre of the pot, as fractions of the cell.
  static const rimX = .5;
  static const rimY = 292 / 1024;

  /// How far a seated lid's cell sits above the pot's cell.
  static const lidSeat = 240 / 1024;

  static const boilFrames = 4;

  /// Bubbling surface box inside the pot cell (fractions): the surface
  /// ellipse matches the water just below the rim.
  static const _boilLeft = .025;
  static const _boilTop = .051;
  static const _boilWidth = .95;
  static const _boilHeight = .475;

  /// Whether [phase] shows a lid.
  static bool hasLid(PotPhase phase) =>
      phase == PotPhase.cooking || phase == PotPhase.ready;

  /// Resting lid pose for [phase]: (lift, shift, tilt) — lift and shift as
  /// fractions of the cell, tilt in radians. Ready lids are lifted aside.
  static (double, double, double) poseFor(PotPhase phase) => switch (phase) {
    PotPhase.ready => (.2, .12, -.3),
    _ => (0, 0, 0),
  };

  /// Draws the lidless painted pot for [phase] into the square [cell].
  void drawBody(Canvas canvas, PotPhase phase, Rect cell, Paint paint) =>
      atlas.draw(canvas, _bodies[phase.index], cell, paint);

  /// Draws bubbling-surface [frame] on the water of the pot in [cell].
  void drawBoil(Canvas canvas, int frame, Rect cell, Paint paint) =>
      atlas.drawAt(
        canvas,
        _boil[frame % boilFrames],
        cell.left + cell.width * _boilLeft,
        cell.top + cell.height * _boilTop,
        cell.width * _boilWidth,
        cell.height * _boilHeight,
        paint,
      );

  /// Draws the lid for [phase] on the pot in [cell], raised by [rattle]
  /// (fraction of the cell) and turned by [tilt] radians around the rim.
  void drawLid(
    Canvas canvas,
    PotPhase phase,
    Rect cell,
    Paint paint, {
    double rattle = 0,
    double tilt = 0,
  }) {
    if (!hasLid(phase)) {
      return;
    }
    final (lift, shift, rest) = poseFor(phase);
    final px = cell.left + cell.width * rimX;
    final py = cell.top + cell.height * rimY;
    canvas
      ..save()
      ..translate(px + shift * cell.width, py - (lift + rattle) * cell.height)
      ..rotate(rest + tilt)
      ..translate(-px, -py - lidSeat * cell.height);
    atlas.draw(canvas, phase == PotPhase.ready ? _enamel : _glass, cell, paint);
    canvas.restore();
  }
}
