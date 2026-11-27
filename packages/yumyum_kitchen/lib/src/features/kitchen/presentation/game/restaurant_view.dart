import "dart:math" as math;
import "dart:ui";

import "package:flame/components.dart";
import "package:flame/events.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/cooker.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/dining/dining.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/restaurant_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/sprite_atlas.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";

/// The restaurant's packed art (`assets/images/restaurant/`), with every
/// frame id looked up once at load.
class RestaurantArt {
  RestaurantArt({
    required this.room,
    required this.kitchenPlate,
    required this.kitchen,
    required this.dining,
    required this.waiter,
    required this.guests,
  }) : stove = {for (final name in _stoves) name: kitchen.id("stove_$name")},
       kettlePour = kitchen.id("kettle_pour"),
       bowlEmpty = dining.id("bowl_empty"),
       bowlNoodles = dining.id("bowl_noodles"),
       bowlSoups = [
         dining.id("bowl_chicken"),
         dining.id("bowl_tomyum"),
         dining.id("bowl_mala"),
       ],
       table = dining.id("table"),
       tableTea = dining.id("table_tea"),
       tableDirty = dining.id("table_dirty"),
       tableCoins = dining.id("table_coins"),
       iconNoodles = dining.id("icon_noodles"),
       iconSoups = [
         dining.id("icon_broth_chicken"),
         dining.id("icon_broth_tomyum"),
         dining.id("icon_sauce_mala"),
       ],
       walkTray = [for (var i = 0; i < 6; i++) waiter.id("walk_tray_$i")],
       walkDirty = [for (var i = 0; i < 6; i++) waiter.id("walk_dirty_$i")],
       place = [for (var i = 0; i < 3; i++) waiter.id("place_$i")],
       pour = [for (var i = 0; i < 3; i++) waiter.id("pour_$i")],
       idle = [waiter.id("idle_0"), waiter.id("idle_1")],
       bow = [waiter.id("bow_0"), waiter.id("bow_1")],
       wipe = [waiter.id("wipe_0"), waiter.id("wipe_1")],
       seated = [
         for (final look in CustomerSprites.names)
           [
             guests.id("${look}_wait"),
             guests.id("${look}_eat_0"),
             guests.id("${look}_eat_1"),
             guests.id("${look}_happy"),
           ],
       ];

  static const _stoves = [
    "empty",
    "water",
    "boil",
    "block",
    "soften",
    "ready",
    "soggy",
  ];

  final Image room;

  /// The reference keyframe's own counter, painted pots removed.
  final Image kitchenPlate;
  final SpriteAtlas kitchen;
  final SpriteAtlas dining;
  final SpriteAtlas waiter;
  final SpriteAtlas guests;
  final Map<String, int> stove;
  final int kettlePour;
  final int bowlEmpty;
  final int bowlNoodles;
  final List<int> bowlSoups;
  final int table;
  final int tableTea;
  final int tableDirty;
  final int tableCoins;
  final int iconNoodles;
  final List<int> iconSoups;
  final List<int> walkTray;
  final List<int> walkDirty;
  final List<int> place;
  final List<int> pour;
  final List<int> idle;
  final List<int> bow;
  final List<int> wipe;

  /// Seated frames per look: wait, eat 0, eat 1, happy.
  final List<List<int>> seated;

  /// The waiter's source cell is 768×1024 with the soles 40 px above its
  /// bottom and the figure 620 px tall.
  static const waiterBaseline = 984 / 1024;
  static const waiterFigure = 620 / 1024;
  static const waiterAspect = 768 / 1024;
}

/// Draws a restaurant day and turns taps into cooking steps.
///
/// Drawn in screen space: the room plate, tables with seated guests, the
/// waiter on the aisle and guests at the door, then the reference kitchen
/// (`kitchen_plate.webp`) with the live pots and bowls drawn over their
/// painted places.
class RestaurantView extends PositionComponent with TapCallbacks {
  RestaurantView(this.game);

  final YumYumKitchenGame game;
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _ringTrack = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x66000000);
  final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFD169);
  final _bubble = Paint()..color = const Color(0xFFFFF0D9);
  final _bubbleShadow = Paint()
    ..color = const Color(0x735A3414)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final _gloss = Paint()..color = const Color(0x73FFFFFF);
  final _glow = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xCCFFC55A)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final _bandShade = Paint();
  final _bubbleEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFFFFFAF0);
  final _barTrack = Paint()..color = const Color(0x55000000);
  final _bar = Paint();
  final _flash = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final _debug = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  int _facing = 1;

  static const _green = Color(0xFF5BD47A);
  static const _amber = Color(0xFFFFC94D);
  static const _red = Color(0xFFE5533D);
  static const _white = Color(0xEEFFFFFF);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void renderTree(Canvas canvas) => render(canvas);

  @override
  void onTapDown(TapDownEvent event) {
    final layout = game.restaurantLayout;
    if (game.bloc.restaurant == null || layout == null) {
      event.continuePropagation = true;
      return;
    }
    final target = layout.hit(event.canvasPosition.toOffset());
    if (target != null) {
      game.tapRestaurant(target);
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final run = game.bloc.restaurant;
    final layout = game.restaurantLayout;
    final art = game.restaurantArt;
    if (run == null || layout == null || art == null) {
      return;
    }
    final now = run.now;
    // Wider than 16:9: each side shows the art's outermost strip stretched
    // (the counter and room carry on instead of repeating), fading darker.
    if (layout.roomRect.left > 0) {
      _bands(c, art.room, layout.roomRect);
      _bands(c, art.kitchenPlate, layout.kitchenRect);
    }
    c.drawImageRect(art.room, _plateSource(art.room), layout.roomRect, _paint);
    _dining(c, run, layout, art, now);
    c.drawImageRect(
      art.kitchenPlate,
      _plateSource(art.kitchenPlate),
      layout.kitchenRect,
      _paint,
    );
    _kitchen(c, run, layout, art, now);
    if (game.showHitBoxes) {
      _hitBoxes(c, layout);
    }
  }

  // ---------------------------------------------------------------- dining

  void _dining(
    Canvas c,
    RestaurantRun run,
    RestaurantLayout layout,
    RestaurantArt art,
    int now,
  ) {
    final dining = run.dining;
    final waiter = dining.waiters.first;
    for (var i = 0; i < dining.tables.length; i++) {
      final table = dining.tables[i];
      final guest = table.guest;
      final box = layout.guestBoxes[i];
      final seated =
          table.phase == TablePhase.waiting ||
          table.phase == TablePhase.served ||
          table.phase == TablePhase.eating;
      if (guest != null && seated) {
        final frames = art.seated[_look(guest)];
        final frame = table.phase != TablePhase.eating
            ? frames[0]
            : table.eatsUntil - now < 900
            ? frames[3]
            : frames[1 + (now ~/ 420) % 2];
        art.guests.draw(c, frame, box, _paint);
      }
      art.dining.draw(c, art.table, layout.tableBoxes[i], _paint);
      if (table.hadTea && table.phase != TablePhase.dirty) {
        art.dining.draw(c, art.tableTea, layout.overlayBoxes[i], _paint);
      }
      if (table.phase == TablePhase.dirty) {
        art.dining
          ..draw(c, art.tableDirty, layout.overlayBoxes[i], _paint)
          ..draw(c, art.tableCoins, layout.overlayBoxes[i], _paint);
      }
      if (table.phase == TablePhase.waiting) {
        _ticket(c, layout, art, dining, i, now);
      }
    }
    // Guests waiting at the door, and the one being led to a table.
    final doorX = layout.aisleX(Dining.door);
    final standing = layout.waiterHeight * .95;
    for (var i = 0; i < dining.waitingAtDoor; i++) {
      game.customerSprites?.draw(
        c,
        _look(dining.doorGuest(i)),
        CustomerClip.idle,
        (now ~/ 300) % CustomerClip.idle.frames,
        doorX + i * standing * .32,
        layout.floorY,
        standing,
        _paint,
      );
    }
    for (var i = 0; i < dining.tables.length; i++) {
      final table = dining.tables[i];
      if (table.phase != TablePhase.booked || table.guest == null) {
        continue;
      }
      final led = waiter.task?.table == i && waiter.load == WaiterLoad.guest;
      final facing = led ? (waiter.facing == 0 ? 1 : waiter.facing) : 1;
      game.customerSprites?.draw(
        c,
        _look(table.guest!),
        led && waiter.action == WaiterAction.walking
            ? CustomerClip.walk
            : CustomerClip.idle,
        (now ~/ 110) % CustomerClip.walk.frames,
        led
            ? layout.aisleX(waiter.positionAt(now)) - facing * standing * .38
            : doorX,
        layout.floorY,
        standing,
        _paint,
        flip: facing < 0,
      );
    }
    _waiter(c, layout, art, waiter, now);
  }

  void _ticket(
    Canvas c,
    RestaurantLayout layout,
    RestaurantArt art,
    Dining dining,
    int index,
    int now,
  ) {
    final ticket = dining.tickets[index];
    if (ticket == null) {
      return;
    }
    final box = layout.ticketBoxes[index];
    // A clay pill: soft shadow below, body, gloss along the top, light rim.
    final radius = Radius.circular(box.height * .45);
    // A small tail pointing back at the guest's face.
    final tail = Path()
      ..moveTo(box.left + box.height * .2, box.center.dy - box.height * .22)
      ..lineTo(box.left - box.height * .32, box.center.dy + box.height * .05)
      ..lineTo(box.left + box.height * .25, box.center.dy + box.height * .2)
      ..close();
    c
      ..drawRRect(
        RRect.fromRectAndRadius(box.shift(Offset(0, box.height * .12)), radius),
        _bubbleShadow,
      )
      ..drawPath(tail, _bubble)
      ..drawRRect(RRect.fromRectAndRadius(box, radius), _bubble)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            box.left + box.width * .12,
            box.top + 2,
            box.width * .76,
            box.height * .38,
          ),
          radius,
        ),
        _gloss,
      )
      ..drawRRect(RRect.fromRectAndRadius(box, radius), _bubbleEdge);
    final icon = box.height * .86;
    final top = box.top + (box.height - icon) / 2;
    art.dining
      ..drawAt(
        c,
        art.iconNoodles,
        box.left + box.width * .1,
        top,
        icon,
        icon,
        _paint,
      )
      ..drawAt(
        c,
        art.iconSoups[ticket.recipe.soup.index],
        box.right - box.width * .1 - icon,
        top,
        icon,
        icon,
        _paint,
      );
    final patience = ticket.patiencePermille(now);
    final barTop = box.bottom + 4;
    final barHeight = math.max(5, box.height * .14).toDouble();
    final barRadius = Radius.circular(barHeight / 2);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(box.left, barTop, box.width, barHeight),
        barRadius,
      ),
      _barTrack,
    );
    _bar.color = patience > 500
        ? _green
        : patience > 250
        ? _amber
        : _red;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          box.left,
          barTop,
          math.max(barHeight, box.width * patience / 1000),
          barHeight,
        ),
        barRadius,
      ),
      _bar,
    );
  }

  void _waiter(
    Canvas c,
    RestaurantLayout layout,
    RestaurantArt art,
    Waiter waiter,
    int now,
  ) {
    if (waiter.facing != 0) {
      _facing = waiter.facing;
    }
    final step = (game.motionMs ~/ 110) % 6;
    final ends = waiter.actionEnds;
    final third = waiter.idle
        ? 0
        : (3 - ((ends - now) * 3 ~/ 400).clamp(1, 3)).clamp(0, 2);
    final id = switch (waiter.action) {
      WaiterAction.walking => switch (waiter.load) {
        WaiterLoad.bowl => art.walkTray[step],
        WaiterLoad.dirtyBowls => art.walkDirty[step],
        _ => art.idle[(now ~/ 400) % 2],
      },
      WaiterAction.greeting ||
      WaiterAction.seating => art.bow[(now ~/ 300) % 2],
      WaiterAction.picking || WaiterAction.dropping => art.place[0],
      WaiterAction.placing => art.place[third],
      WaiterAction.pouring => art.pour[third],
      WaiterAction.wiping => art.wipe[(now ~/ 200) % 2],
      WaiterAction.idle => art.idle[(now ~/ 600) % 2],
    };
    final cellHeight = layout.waiterHeight / RestaurantArt.waiterFigure;
    final cellWidth = cellHeight * RestaurantArt.waiterAspect;
    final feetX = layout.aisleX(waiter.positionAt(now));
    final top = layout.floorY - cellHeight * RestaurantArt.waiterBaseline;
    if (_facing > 0) {
      art.waiter.drawAt(
        c,
        id,
        feetX - cellWidth / 2,
        top,
        cellWidth,
        cellHeight,
        _paint,
      );
      return;
    }
    c
      ..save()
      ..translate(feetX, 0)
      ..scale(-1, 1)
      ..translate(-feetX, 0);
    art.waiter.drawAt(
      c,
      id,
      feetX - cellWidth / 2,
      top,
      cellWidth,
      cellHeight,
      _paint,
    );
    c.restore();
  }

  // --------------------------------------------------------------- kitchen

  void _kitchen(
    Canvas c,
    RestaurantRun run,
    RestaurantLayout layout,
    RestaurantArt art,
    int now,
  ) {
    // Painted stations (noodles, stockpots) glow when tapped.
    _glowIfTapped(c, RestaurantSpot.pack, 0, layout.pack);
    for (var i = 0; i < layout.stockpots.length; i++) {
      _glowIfTapped(c, RestaurantSpot.stockpot, i, layout.stockpots[i]);
    }
    for (var i = 0; i < run.pots.length; i++) {
      final pot = run.pots[i];
      final sprite = layout.potSprites[i];
      _pressed(c, RestaurantSpot.pot, i, sprite, () {
        art.kitchen.draw(c, art.stove[_stoveFrame(pot, now)]!, sprite, _paint);
        if (pot.phase == CookPhase.heating && now - pot.phaseStart < 700) {
          art.kitchen.drawAt(
            c,
            art.kettlePour,
            sprite.left - sprite.width * .25,
            sprite.top - sprite.height * .55,
            sprite.width * .8,
            sprite.width * .8,
            _paint,
          );
        }
      });
      _progressRing(c, layout.potRings[i], pot, now);
    }
    for (var i = 0; i < run.rack.bowls.length; i++) {
      final bowl = run.rack.bowls[i];
      final sprite = layout.bowlSprites[i];
      if (i == run.rack.selected) {
        final body = layout.bowlBodies[i];
        _glow.strokeWidth = math.max(6, body.width * .12);
        _outline.strokeWidth = math.max(2.5, body.width * .035);
        c
          ..drawPath(layout.bowlOutlines[i], _glow)
          ..drawPath(layout.bowlOutlines[i], _outline);
      }
      _pressed(c, RestaurantSpot.bowl, i, sprite, () {
        art.dining.draw(c, _bowlFrame(art, bowl), sprite, _paint);
      });
    }
  }

  /// A soft clay glow over a painted station for a moment after a tap:
  /// butter when the step happened, tomato when it was refused.
  void _glowIfTapped(Canvas c, RestaurantSpot spot, int index, Rect area) {
    final tap = game.lastRestaurantTap;
    final age = game.motionMs - game.lastRestaurantTapAt;
    if (tap == null || tap.spot != spot || tap.index != index || age > 260) {
      return;
    }
    final fade = 1 - age / 260;
    _flash
      ..color = (game.lastRestaurantTapRefused ? _red : const Color(0xFFFFC55A))
          .withValues(alpha: .55 * fade)
      ..strokeWidth = math.max(8, area.shortestSide * .12);
    c.drawRRect(
      RRect.fromRectAndRadius(
        area.deflate(area.shortestSide * .06),
        Radius.circular(area.shortestSide * .22),
      ),
      _flash,
    );
  }

  /// Fills the screen beside [scene] with [image]'s left and right edge
  /// strips, shaded from clear at the scene to dark at the screen edge.
  void _bands(Canvas c, Image image, Rect scene) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final strip = w * .01;
    final left = Rect.fromLTRB(0, scene.top, scene.left, scene.bottom);
    final right = Rect.fromLTRB(scene.right, scene.top, size.x, scene.bottom);
    c
      ..drawImageRect(image, Rect.fromLTWH(0, 0, strip, h), left, _paint)
      ..drawImageRect(
        image,
        Rect.fromLTWH(w - strip, 0, strip, h),
        right,
        _paint,
      );
    _bandShade.shader = Gradient.linear(
      Offset(0, 0),
      Offset(left.right, 0),
      const [Color(0xCC000000), Color(0x33000000)],
    );
    c.drawRect(left, _bandShade);
    _bandShade.shader = Gradient.linear(
      Offset(right.left, 0),
      Offset(right.right, 0),
      const [Color(0x33000000), Color(0xCC000000)],
    );
    c.drawRect(right, _bandShade);
  }

  static Rect _plateSource(Image image) =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  String _stoveFrame(Cooker pot, int now) => switch (pot.phase) {
    CookPhase.empty => "empty",
    CookPhase.heating => "water",
    CookPhase.hot => "boil",
    CookPhase.cooking => pot.progressPermille(now) < 500 ? "block" : "soften",
    CookPhase.perfect || CookPhase.ready || CookPhase.needsFlip => "ready",
    CookPhase.ruined => "soggy",
  };

  int _bowlFrame(RestaurantArt art, Bowl bowl) {
    final soup = bowl.soup;
    if (soup != null) {
      return art.bowlSoups[soup.index];
    }
    return bowl.noodles ? art.bowlNoodles : art.bowlEmpty;
  }

  /// A ring beside the pot: white while heating or cooking, green in the
  /// perfect window, amber after it, red when ruined.
  void _progressRing(Canvas c, Rect ring, Cooker pot, int now) {
    final width = math.max(3, ring.width * .16).toDouble();
    _ring.strokeWidth = width;
    _ringTrack.strokeWidth = width;
    final timed =
        pot.phase == CookPhase.heating ||
        pot.phase == CookPhase.cooking ||
        pot.phase == CookPhase.perfect ||
        pot.phase == CookPhase.ready;
    if (!timed && pot.phase != CookPhase.ruined) {
      return;
    }
    c.drawArc(ring, 0, math.pi * 2, false, _ringTrack);
    final sweep = switch (pot.phase) {
      CookPhase.perfect ||
      CookPhase.ready => 1 - pot.progressPermille(now) / 1000,
      CookPhase.ruined => 1.0,
      _ => pot.progressPermille(now) / 1000,
    };
    _ring.color = switch (pot.phase) {
      CookPhase.perfect => _green,
      CookPhase.ready => _amber,
      CookPhase.ruined => _red,
      _ => _white,
    };
    c.drawArc(ring, -math.pi / 2, math.pi * 2 * sweep, false, _ring);
  }

  /// Draws [paint] pressed (scaled down for 100 ms) or shaking (a refused
  /// tap) when it is the last tapped station.
  void _pressed(
    Canvas c,
    RestaurantSpot spot,
    int index,
    Rect sprite,
    void Function() paint,
  ) {
    final tap = game.lastRestaurantTap;
    final age = game.motionMs - game.lastRestaurantTapAt;
    final mine = tap != null && tap.spot == spot && tap.index == index;
    if (!mine || age > 160 || game.reducedMotion) {
      paint();
      return;
    }
    c.save();
    if (game.lastRestaurantTapRefused) {
      c.translate(math.sin(age / 160 * math.pi * 4) * sprite.width * .05, 0);
    } else {
      final s = age < 100 ? .93 : .93 + .07 * (age - 100) / 60;
      c
        ..translate(sprite.center.dx, sprite.bottom)
        ..scale(s, s)
        ..translate(-sprite.center.dx, -sprite.bottom);
    }
    paint();
    c.restore();
  }

  void _hitBoxes(Canvas c, RestaurantLayout layout) {
    c
      ..drawRect(layout.safe, _debug..color = const Color(0xFF00E5FF))
      ..drawRect(layout.action, _debug..color = const Color(0xFF76FF03))
      ..drawRect(layout.hud, _debug..color = const Color(0xFFFFEA00));
    _debug.color = const Color(0xFFFF1744);
    for (final target in layout.allTargets()) {
      c.drawRect(target.bounds, _debug);
    }
  }

  static int _look(Guest guest) =>
      (guest.id - 1) % CustomerSprites.names.length;
}
