import "dart:math" as math;
import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/stage_layout.dart";

/// A tappable spot of the restaurant, in screen logical pixels.
class RestaurantTarget {
  const RestaurantTarget(this.spot, this.index, this.bounds);
  final RestaurantSpot spot;
  final int index;
  final Rect bounds;
}

/// Equipment drawn on the line that the day does not use yet (second
/// stockpot, grill, egg pot, fryer, trays, board), so the kitchen always
/// looks like the reference keyframe.
enum KitchenDecor { tomYumPot, grill, eggPot, fryer, trays, board }

/// Screen geometry of the restaurant, composed like the reference keyframe
/// (`art/sources/restaurant/restaurant_keyframe.png`, 2560×1440, i.e. the
/// 1280×720 design canvas at 2×).
///
/// The whole scene uses one contain fit of the design canvas, so the room,
/// the tables, guests and waiter keep the keyframe's arrangement on every
/// screen, and the kitchen's two rows stay mirrored about the centre (back:
/// noodles, egg pot, pot, grill, pot, fryer, bin; front: trays, stockpot,
/// three bowls, stockpot, board). A screen wider
/// than 16:9 shows the room art on both sides. Tap areas are grown to 48 dp
/// and moved inside the safe stage where needed; the art never moves.
class RestaurantLayout {
  RestaurantLayout._({
    required this.screen,
    required this.scale,
    required this.origin,
    required this.safe,
    required this.hud,
    required this.action,
    required this.pack,
    required this.pots,
    required this.stockpots,
    required this.bowls,
    required this.bin,
    required this.tables,
    required this.packSprite,
    required this.potSprites,
    required this.stockpotSprites,
    required this.bowlSprites,
    required this.binSprite,
    required this.decor,
    required this.tableBoxes,
    required this.tableFronts,
    required this.guestBoxes,
    required this.ticketBoxes,
    required this.overlayBoxes,
    required this.waiterHeight,
    required this.floorY,
  }) : potRings = [for (final r in potSprites) _ring(r)],
       bowlOutlines = [for (final r in bowlSprites) _outline(r)],
       roomRect = _cover(scale, origin, roomDesign),
       counterRect = _cover(scale, origin, counterDesign),
       roomFill = _fill(screen, roomDesign),
       counterFill = _fill(screen, counterDesign);

  factory RestaurantLayout.compute({
    required Size screen,
    required Rect insets,
    required RestaurantDay day,
  }) {
    const g = StageLayout.gap;
    // Contain fit: the whole keyframe is visible on every screen; extra
    // width shows the room art behind it (see [roomFill]).
    final scale = math.min(
      screen.width / StageLayout.designSize.width,
      screen.height / StageLayout.designSize.height,
    );
    final origin = Offset(
      (screen.width - StageLayout.designSize.width * scale) / 2,
      (screen.height - StageLayout.designSize.height * scale) / 2,
    );
    Rect cover(Rect r) => _cover(scale, origin, r);
    Rect kitchen(Rect r) => cover(r);
    final safe = Rect.fromLTRB(
      insets.left + StageLayout.edgeMargin,
      insets.top + StageLayout.edgeMargin,
      screen.width - insets.right - StageLayout.edgeMargin,
      screen.height - insets.bottom - StageLayout.edgeMargin,
    );
    final hud = Rect.fromLTWH(
      safe.left,
      safe.top,
      safe.width,
      StageLayout.hudHeight,
    );
    final kitchenTop = math.max(
      origin.dy + kitchenDesign.top * scale,
      hud.bottom + g,
    );
    final action = Rect.fromLTRB(
      safe.left,
      kitchenTop,
      safe.right,
      safe.bottom,
    );

    final potSprites = [
      for (var i = 0; i < day.pots; i++) kitchen(_potDesign[i]),
    ];
    final stockpotSprites = [
      for (var i = 0; i < day.soups.length; i++) kitchen(_stockpotDesign[i]),
    ];
    final bowlSprites = [
      for (var i = 0; i < day.bowls; i++) kitchen(_bowlDesign[i]),
    ];
    final packSprite = kitchen(_packDesign);
    final binSprite = kitchen(_binDesign);
    final decor = <KitchenDecor, Rect>{
      if (day.soups.length < 2)
        KitchenDecor.tomYumPot: kitchen(_stockpotDesign[1]),
      KitchenDecor.grill: kitchen(_grillDesign),
      KitchenDecor.eggPot: kitchen(_eggPotDesign),
      KitchenDecor.fryer: kitchen(_fryerDesign),
      KitchenDecor.trays: kitchen(_traysDesign),
      KitchenDecor.board: kitchen(_boardDesign),
    };

    // Dining room: tables, guests and the waiter in cover-fit design space.
    final floorY = origin.dy + floorDesign * scale;
    final tableBoxes = <Rect>[];
    final tableFronts = <Rect>[];
    final guestBoxes = <Rect>[];
    final ticketBoxes = <Rect>[];
    final overlayBoxes = <Rect>[];
    final tables = <Rect>[];
    for (var i = 0; i < day.tables; i++) {
      final top = _tableTops[i];
      final table = cover(_tableCell(top));
      final guest = cover(_guestCell(top));
      final ticket = cover(_ticketCell(top));
      tableBoxes.add(table);
      tableFronts.add(
        cover(
          Rect.fromLTRB(top.left - 6, top.top + 4, top.right + 6, floorDesign),
        ),
      );
      guestBoxes.add(guest);
      final minTop = hud.bottom + 4;
      ticketBoxes.add(
        ticket.top < minTop
            ? ticket.shift(Offset(0, minTop - ticket.top))
            : ticket,
      );
      overlayBoxes.add(cover(_overlayCell(top)));
      tables.add(
        Rect.fromLTRB(
          math.max(cover(top).left, safe.left),
          math.max(guest.top + guest.height * .2, hud.bottom + g),
          math.min(cover(top).right, safe.right),
          math.min(floorY, action.top - g),
        ),
      );
    }

    Rect target(Rect sprite) => _atLeast(sprite, StageLayout.minHit, action);

    return RestaurantLayout._(
      screen: screen,
      scale: scale,
      origin: origin,
      safe: safe,
      hud: hud,
      action: action,
      pack: target(packSprite),
      pots: [for (final r in potSprites) target(r)],
      stockpots: [for (final r in stockpotSprites) target(r)],
      bowls: [for (final r in bowlSprites) target(r)],
      bin: target(binSprite),
      tables: tables,
      packSprite: packSprite,
      potSprites: potSprites,
      stockpotSprites: stockpotSprites,
      bowlSprites: bowlSprites,
      binSprite: binSprite,
      decor: decor,
      tableBoxes: tableBoxes,
      tableFronts: tableFronts,
      guestBoxes: guestBoxes,
      ticketBoxes: ticketBoxes,
      overlayBoxes: overlayBoxes,
      waiterHeight: waiterDesign * scale,
      floorY: floorY,
    );
  }

  // ---- The keyframe, in design pixels (keyframe pixels ÷ 2). ----

  /// Room art covers the top of the canvas; the counter its bottom.
  static const roomDesign = Rect.fromLTWH(0, 0, 1280, 432);
  static const counterDesign = Rect.fromLTWH(0, 360, 1280, 360);

  /// The waiter's and standing guests' feet line, and an adult's height.
  static const floorDesign = 358.0;
  static const waiterDesign = 281.0;

  static const aisleStart = 120.0;
  static const aisleEnd = 1200.0;

  /// Table tops (front edge at the bottom) of the four keyframe tables.
  static const _tableTops = [
    Rect.fromLTRB(208, 250, 410, 262),
    Rect.fromLTRB(458, 250, 611, 262),
    Rect.fromLTRB(717, 250, 906, 262),
    Rect.fromLTRB(925, 250, 1117, 262),
  ];

  /// The whole table sprite cell for a table top (the table art fills 72 %
  /// of its cell width, its top at 10 % of the cell height).
  static Rect _tableCell(Rect top) {
    final width = top.width / .72;
    final height = width * .75;
    return Rect.fromLTWH(
      top.center.dx - width / 2,
      top.top - height * .1,
      width,
      height,
    );
  }

  /// The seated guest: head near y 134, hands resting on the table top.
  static Rect _guestCell(Rect top) {
    const size = 140.0;
    return Rect.fromLTWH(
      top.center.dx - size / 2,
      top.top + 14 - size,
      size,
      size,
    );
  }

  static Rect _ticketCell(Rect top) =>
      Rect.fromCenter(center: Offset(top.center.dx, 96), width: 92, height: 38);

  static Rect _overlayCell(Rect top) {
    final width = top.width * 1.1;
    return Rect.fromLTWH(
      top.center.dx - width / 2,
      top.top - width * .16,
      width,
      width * .75,
    );
  }

  /// The kitchen line from the back row's top to the front row's bottom.
  static const kitchenDesign = Rect.fromLTRB(0, 318, 1280, 664);

  // The line is mirrored about the centre (x 640). Back row: noodles, egg
  // pot, pot | grill | pot, fryer, bin. Front row: trays, chicken stockpot,
  // three bowls, Tom Yum stockpot, board.
  static const _packDesign = Rect.fromLTWH(60, 368, 110, 100);
  static const _eggPotDesign = Rect.fromLTWH(182, 340, 140, 140);
  static const _potDesign = [
    Rect.fromLTWH(334, 318, 150, 150),
    Rect.fromLTWH(796, 318, 150, 150),
  ];
  static const _grillDesign = Rect.fromLTWH(496, 358, 288, 144);
  static const _fryerDesign = Rect.fromLTWH(958, 340, 140, 140);
  static const _binDesign = Rect.fromLTWH(1110, 368, 110, 100);
  static const _traysDesign = Rect.fromLTWH(40, 524, 270, 136);
  static const _stockpotDesign = [
    Rect.fromLTWH(322, 496, 166, 166),
    Rect.fromLTWH(792, 496, 166, 166),
  ];
  static const _bowlDesign = [
    Rect.fromLTWH(488, 540, 96, 96),
    Rect.fromLTWH(592, 540, 96, 96),
    Rect.fromLTWH(696, 540, 96, 96),
  ];
  static const _boardDesign = Rect.fromLTWH(970, 524, 270, 136);

  final Size screen;
  final double scale;
  final Offset origin;
  final Rect safe;
  final Rect hud;

  /// The kitchen line's area, inside the safe stage.
  final Rect action;

  // Hit boxes (each at least 48 dp) …
  final Rect pack;
  final List<Rect> pots;
  final List<Rect> stockpots;
  final List<Rect> bowls;
  final Rect bin;
  final List<Rect> tables;

  // … and the art inside them.
  final Rect packSprite;
  final List<Rect> potSprites;
  final List<Rect> stockpotSprites;
  final List<Rect> bowlSprites;
  final Rect binSprite;

  /// Equipment shown but not used by this day.
  final Map<KitchenDecor, Rect> decor;

  /// Progress rings on each pot.
  final List<Rect> potRings;

  /// Gold outline of the selected bowl.
  final List<Path> bowlOutlines;

  /// The table art, the slice of it drawn again in front of a seated guest
  /// (its top edge down to the floor), the guest, the order bubble and the
  /// tea set / dirty bowls / coins.
  final List<Rect> tableBoxes;
  final List<Rect> tableFronts;
  final List<Rect> guestBoxes;
  final List<Rect> ticketBoxes;
  final List<Rect> overlayBoxes;

  /// The waiter's standing height and the floor line, in screen pixels.
  final double waiterHeight;
  final double floorY;

  final Rect roomRect;
  final Rect counterRect;

  /// The same room and counter art cover-fitted to the whole screen, drawn
  /// dimmed behind the scene so wider screens show the room on both sides.
  final Rect roomFill;
  final Rect counterFill;

  static Rect _fill(Size screen, Rect design) {
    final k = math.max(
      screen.width / StageLayout.designSize.width,
      screen.height / StageLayout.designSize.height,
    );
    final dx = (screen.width - StageLayout.designSize.width * k) / 2;
    final dy = (screen.height - StageLayout.designSize.height * k) / 2;
    return _cover(k, Offset(dx, dy), design);
  }

  /// Screen x of an aisle position (0 door … 1000 takeaway shelf).
  double aisleX(int position) =>
      origin.dx +
      (aisleStart + position * (aisleEnd - aisleStart) / 1000) * scale;

  /// Every target, kitchen first; the order hit testing uses.
  List<RestaurantTarget> allTargets() => [
    RestaurantTarget(RestaurantSpot.pack, 0, pack),
    for (var i = 0; i < pots.length; i++)
      RestaurantTarget(RestaurantSpot.pot, i, pots[i]),
    for (var i = 0; i < stockpots.length; i++)
      RestaurantTarget(RestaurantSpot.stockpot, i, stockpots[i]),
    for (var i = 0; i < bowls.length; i++)
      RestaurantTarget(RestaurantSpot.bowl, i, bowls[i]),
    RestaurantTarget(RestaurantSpot.bin, 0, bin),
    for (var i = 0; i < tables.length; i++)
      RestaurantTarget(RestaurantSpot.table, i, tables[i]),
  ];

  /// The target under [point], or null.
  RestaurantTarget? hit(Offset point) {
    for (final target in allTargets()) {
      if (target.bounds.contains(point)) {
        return target;
      }
    }
    return null;
  }

  static Rect _cover(double scale, Offset origin, Rect r) => Rect.fromLTWH(
    origin.dx + r.left * scale,
    origin.dy + r.top * scale,
    r.width * scale,
    r.height * scale,
  );

  /// [r] grown about its centre to at least [min] each way, kept in [area].
  static Rect _atLeast(Rect r, double min, Rect area) {
    final grown = Rect.fromCenter(
      center: r.center,
      width: math.max(r.width, min),
      height: math.max(r.height, min),
    );
    final dx = grown.left < area.left
        ? area.left - grown.left
        : grown.right > area.right
        ? area.right - grown.right
        : 0.0;
    final dy = grown.top < area.top
        ? area.top - grown.top
        : grown.bottom > area.bottom
        ? area.bottom - grown.bottom
        : 0.0;
    return grown.shift(Offset(dx, dy));
  }

  /// Sits on the pot's upper right, over the rim.
  static Rect _ring(Rect pot) {
    final d = math.max(18, pot.width * .2).toDouble();
    return Rect.fromLTWH(
      pot.right - d * 1.15,
      pot.top + pot.height * .04,
      d,
      d,
    );
  }

  static Path _outline(Rect sprite) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        sprite.deflate(sprite.width * .02),
        Radius.circular(sprite.width * .14),
      ),
    );
}
