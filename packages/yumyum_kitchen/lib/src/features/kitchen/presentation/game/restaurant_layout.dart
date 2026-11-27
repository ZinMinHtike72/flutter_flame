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

/// Screen geometry of the restaurant, composed exactly like the reference
/// keyframe (`art/sources/restaurant/restaurant_keyframe.png`, 2560×1440,
/// i.e. the 1280×720 design canvas at 2×).
///
/// The whole scene uses one contain fit of the design canvas, so it keeps
/// the keyframe's arrangement on every screen; a screen wider than 16:9
/// continues the art's outer edges, shaded, on both sides. The kitchen is the
/// keyframe's own counter (`kitchen_plate.webp`), so everything on it is
/// where the reference has it; the game only draws what changes on top —
/// the two pots on the range and the three bowls — exactly over their
/// painted places. Tap areas are grown to 48 dp and moved inside the safe
/// stage where needed; the art never moves.
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
    required this.tables,
    required this.potSprites,
    required this.bowlSprites,
    required this.potBodies,
    required this.bowlBodies,
    required this.tableBoxes,
    required this.guestBoxes,
    required this.ticketBoxes,
    required this.overlayBoxes,
    required this.waiterHeight,
    required this.floorY,
  }) : potRings = [for (final r in potBodies) _ring(r)],
       bowlOutlines = [for (final r in bowlBodies) _outline(r)],
       roomRect = _cover(scale, origin, roomDesign),
       kitchenRect = _cover(scale, origin, kitchenDesign);

  factory RestaurantLayout.compute({
    required Size screen,
    required Rect insets,
    required RestaurantDay day,
  }) {
    const g = StageLayout.gap;
    final scale = math.min(
      screen.width / StageLayout.designSize.width,
      screen.height / StageLayout.designSize.height,
    );
    final origin = Offset(
      (screen.width - StageLayout.designSize.width * scale) / 2,
      (screen.height - StageLayout.designSize.height * scale) / 2,
    );
    Rect cover(Rect r) => _cover(scale, origin, r);
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
    final action = Rect.fromLTRB(
      safe.left,
      math.max(origin.dy + kitchenDesign.top * scale, hud.bottom + g),
      safe.right,
      safe.bottom,
    );

    // Dining room: tables, guests and the waiter.
    final floorY = origin.dy + floorDesign * scale;
    final tableBoxes = <Rect>[];
    final guestBoxes = <Rect>[];
    final ticketBoxes = <Rect>[];
    final overlayBoxes = <Rect>[];
    final tables = <Rect>[];
    for (var i = 0; i < day.tables; i++) {
      final top = _tableTops[i];
      final guest = cover(_guestCell(top));
      tableBoxes.add(cover(_tableCell(top)));
      guestBoxes.add(guest);
      ticketBoxes.add(cover(_ticketCell(top)));
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

    Rect target(Rect design) =>
        _atLeast(cover(design), StageLayout.minHit, action);

    return RestaurantLayout._(
      screen: screen,
      scale: scale,
      origin: origin,
      safe: safe,
      hud: hud,
      action: action,
      pack: target(_packDesign),
      pots: [for (var i = 0; i < day.pots; i++) target(_potBodyDesign[i])],
      stockpots: [
        for (var i = 0; i < day.soups.length; i++)
          target(_stockpotDesign[day.soups[i].index]),
      ],
      bowls: [for (var i = 0; i < day.bowls; i++) target(_bowlBodyDesign[i])],
      tables: tables,
      potSprites: [for (var i = 0; i < day.pots; i++) cover(_potCell(i))],
      bowlSprites: [for (var i = 0; i < day.bowls; i++) cover(_bowlCell(i))],
      potBodies: [for (var i = 0; i < day.pots; i++) cover(_potBodyDesign[i])],
      bowlBodies: [
        for (var i = 0; i < day.bowls; i++) cover(_bowlBodyDesign[i]),
      ],
      tableBoxes: tableBoxes,
      guestBoxes: guestBoxes,
      ticketBoxes: ticketBoxes,
      overlayBoxes: overlayBoxes,
      waiterHeight: waiterDesign * scale,
      floorY: floorY,
    );
  }

  // ---- The keyframe, in design pixels (keyframe pixels ÷ 2). ----

  /// Room art covers the top of the canvas; the keyframe's own counter
  /// (cut at its top edge, keyframe y 724) covers the bottom.
  static const roomDesign = Rect.fromLTWH(0, 0, 1280, 432);
  static const kitchenDesign = Rect.fromLTWH(0, 362, 1280, 358);

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

  /// The two enamel pots on the range (body and handles), and the noodle
  /// blocks, stockpots and bowls on the front counter, as painted.
  static const _potBodyDesign = [
    Rect.fromLTWH(171, 343, 141, 139),
    Rect.fromLTWH(322, 343, 141, 139),
  ];
  static const _packDesign = Rect.fromLTWH(0, 562, 140, 100);

  /// By `Soup.index`: chicken, Tom Yum.
  static const _stockpotDesign = [
    Rect.fromLTWH(146, 496, 164, 158),
    Rect.fromLTWH(314, 496, 158, 158),
  ];
  static const _bowlBodyDesign = [
    Rect.fromLTWH(480, 560, 88, 74),
    Rect.fromLTWH(572, 560, 88, 74),
    Rect.fromLTWH(664, 560, 88, 74),
  ];

  /// The stove sprite cell for pot [i]: the pot with handles fills 80 % of
  /// the cell's width and its burner ends 89 % down, on the range top.
  static Rect _potCell(int i) {
    final body = _potBodyDesign[i];
    final size = body.width / .8;
    return Rect.fromLTWH(
      body.center.dx - size / 2,
      body.bottom - size * .89,
      size,
      size,
    );
  }

  /// The bowl sprite cell for bowl [i]: the bowl fills 80 % of the cell's
  /// width, its rim 15.5 % down.
  static Rect _bowlCell(int i) {
    final body = _bowlBodyDesign[i];
    final size = body.width / .8;
    return Rect.fromLTWH(
      body.center.dx - size / 2,
      body.top - size * .155,
      size,
      size,
    );
  }

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

  /// The order bubble beside the guest's head (never over the face, and
  /// below the HUD band on every screen).
  static Rect _ticketCell(Rect top) =>
      Rect.fromLTWH(top.center.dx + 40, 138, 92, 38);

  static Rect _overlayCell(Rect top) {
    final width = top.width * 1.1;
    return Rect.fromLTWH(
      top.center.dx - width / 2,
      top.top - width * .16,
      width,
      width * .75,
    );
  }

  final Size screen;
  final double scale;
  final Offset origin;
  final Rect safe;
  final Rect hud;

  /// The kitchen line's area, inside the safe stage.
  final Rect action;

  // Hit boxes (each at least 48 dp).
  final Rect pack;
  final List<Rect> pots;
  final List<Rect> stockpots;
  final List<Rect> bowls;
  final List<Rect> tables;

  /// Where the game draws the pots (stove cells) and bowls (bowl cells),
  /// and where their painted bodies are.
  final List<Rect> potSprites;
  final List<Rect> bowlSprites;
  final List<Rect> potBodies;
  final List<Rect> bowlBodies;

  /// Progress rings on each pot.
  final List<Rect> potRings;

  /// Butter outline of the selected bowl.
  final List<Path> bowlOutlines;

  /// The table art, the seated guest, the order bubble and the tea set /
  /// dirty bowls / coins.
  final List<Rect> tableBoxes;
  final List<Rect> guestBoxes;
  final List<Rect> ticketBoxes;
  final List<Rect> overlayBoxes;

  /// The waiter's standing height and the floor line, in screen pixels.
  final double waiterHeight;
  final double floorY;

  final Rect roomRect;
  final Rect kitchenRect;

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

  /// [target] clipped to [area], then grown about its centre to at least [min]
  /// each way and kept in [area]. Clipping first means a target that is
  /// already big enough is never pushed into its neighbour.
  static Rect _atLeast(Rect target, double min, Rect area) {
    final clipped = target.intersect(area);
    final r = clipped.width > 0 && clipped.height > 0 ? clipped : target;
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
    return Rect.fromLTWH(pot.right - d * .9, pot.top - d * .2, d, d);
  }

  static Path _outline(Rect body) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        body.inflate(body.width * .06),
        Radius.circular(body.width * .2),
      ),
    );
}
