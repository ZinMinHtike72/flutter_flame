import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// Realistic pot and lid set cut from the painted equipment sheet
/// (`assets/images/equipment.webp`, 4×3 cells; row 0 holds the four pots).
///
/// Every state keeps the painted enamel, burner and gas flame. The lid is a
/// separate slice so the boil animation can lift, rattle and tilt it:
/// - cooking: the closed glass dome (rows above [cookingDomeBottom]);
/// - ready: the lifted enamel lid (rows above [readySplit]) drawn apart from
///   the pot body below it.
///
/// Source and cell-space rects are precomputed, and drawing maps the cell
/// onto the destination with a canvas transform, so nothing is allocated
/// per frame.
class PotSprites {
  PotSprites(this.sheet)
    : _cellWidth = sheet.width / columns,
      _cellHeight = sheet.height / rows {
    for (final phase in PotPhase.values) {
      _full.add(_src(phase.index, 0, 1));
    }
    _readyLid = _src(PotPhase.ready.index, 0, readySplit);
    _readyBody = _src(PotPhase.ready.index, readySplit, 1);
    _cookingDome = _src(PotPhase.cooking.index, 0, cookingDomeBottom);
    _cellFull = Rect.fromLTWH(0, 0, _cellWidth, _cellHeight);
    _cellReadyLid = Rect.fromLTWH(0, 0, _cellWidth, _cellHeight * readySplit);
    _cellReadyBody = Rect.fromLTRB(
      0,
      _cellHeight * readySplit,
      _cellWidth,
      _cellHeight,
    );
    _cellCookingDome = Rect.fromLTWH(
      0,
      0,
      _cellWidth,
      _cellHeight * cookingDomeBottom,
    );
  }

  static const columns = 4;
  static const rows = 3;

  /// Fraction of the ready cell above which only the lifted lid is painted
  /// (measured: lid rows 12–128, pot rim from row 136 of 362).
  static const readySplit = 130 / 362;

  /// Fraction of the cooking cell holding the closed glass dome.
  static const cookingDomeBottom = 116 / 362;

  /// Lid pivot (rim centre) as fractions of the cell.
  static const _pivot = Offset(.5, 112 / 362);

  final Image sheet;
  final double _cellWidth;
  final double _cellHeight;
  final _full = <Rect>[];
  late final Rect _readyLid;
  late final Rect _readyBody;
  late final Rect _cookingDome;
  late final Rect _cellFull;
  late final Rect _cellReadyLid;
  late final Rect _cellReadyBody;
  late final Rect _cellCookingDome;

  Rect _src(int column, double top, double bottom) => Rect.fromLTRB(
    column * _cellWidth,
    top * _cellHeight,
    (column + 1) * _cellWidth,
    bottom * _cellHeight,
  );

  /// Whether [phase] has a lid that can move.
  static bool hasLid(PotPhase phase) =>
      phase == PotPhase.cooking || phase == PotPhase.ready;

  /// Source rect of the whole painted pot for [phase].
  Rect fullSource(PotPhase phase) => _full[phase.index];

  /// Source rect of the moving lid for [phase] in [sheet], or null.
  Rect? lidSource(PotPhase phase) => switch (phase) {
    PotPhase.cooking => _cookingDome,
    PotPhase.ready => _readyLid,
    PotPhase.empty || PotPhase.burnt => null,
  };

  /// Source rect of the ready pot without its lid.
  Rect get readyBodySource => _readyBody;

  void _toCell(Canvas canvas, Rect dst) {
    canvas
      ..translate(dst.left, dst.top)
      ..scale(dst.width / _cellWidth, dst.height / _cellHeight);
  }

  /// Draws the pot for [phase] into [dst]; the ready pot without its lid.
  void drawBody(Canvas canvas, PotPhase phase, Rect dst, Paint paint) {
    canvas.save();
    _toCell(canvas, dst);
    if (phase == PotPhase.ready) {
      canvas.drawImageRect(sheet, _readyBody, _cellReadyBody, paint);
    } else {
      canvas.drawImageRect(sheet, _full[phase.index], _cellFull, paint);
    }
    canvas.restore();
  }

  /// Draws the lid for [phase] lifted by [rattle] (fraction of the cell
  /// height) and turned by [tilt] radians around its rim. The ready lid is
  /// always drawn; the cooking dome is part of its body and is only redrawn
  /// while it moves.
  void drawLid(
    Canvas canvas,
    PotPhase phase,
    Rect dst,
    Paint paint, {
    double rattle = 0,
    double tilt = 0,
  }) {
    final ready = phase == PotPhase.ready;
    final moving = rattle != 0 || tilt != 0;
    if (!ready && !(phase == PotPhase.cooking && moving)) {
      return;
    }
    final px = _pivot.dx * _cellWidth;
    final py = _pivot.dy * _cellHeight;
    canvas.save();
    _toCell(canvas, dst);
    canvas
      ..translate(px, py - rattle * _cellHeight)
      ..rotate(tilt)
      ..translate(-px, -py);
    if (ready) {
      canvas.drawImageRect(sheet, _readyLid, _cellReadyLid, paint);
    } else {
      canvas.drawImageRect(sheet, _cookingDome, _cellCookingDome, paint);
    }
    canvas.restore();
  }
}
