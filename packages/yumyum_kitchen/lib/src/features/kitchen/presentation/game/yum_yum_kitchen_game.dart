import "dart:async";
import "dart:math" as math;
import "dart:ui";

import "package:flame/components.dart";
import "package:flame/events.dart";
import "package:flame/game.dart";
import "package:flutter/scheduler.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/market_art.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/stage_layout.dart";

/// Full-screen kitchen: the 1280×720 art fills the screen with cover fit and
/// the interactive counter is laid out inside the safe stage.
class YumYumKitchenGame extends FlameGame {
  YumYumKitchenGame(this.bloc, this.audio) {
    // Flame's own loop runs every vsync. Keep it stopped and step the engine
    // from [_onVsync] instead, which caps update and render at 30 fps.
    paused = true;
  }
  final KitchenBloc bloc;
  final KitchenAudio audio;
  final art = MarketArt();
  bool reducedMotion = false;

  /// Paints the safe stage, zones and hit boxes (development builds).
  bool showHitBoxes = false;

  /// System view padding (left, top, right, bottom) from the host widget.
  Rect insets = Rect.zero;
  StageLayout? _layout;
  final _throttle = FrameThrottle();
  final _rulesClock = FixedStepClock();
  bool _driving = false;

  /// Engine steps run so far (update + render), for frame-cap tests.
  int engineSteps = 0;

  @override
  Color backgroundColor() => const Color(0xFF102A2D);

  /// Layout for the current screen size, insets and run equipment.
  StageLayout? get layout {
    final run = bloc.run;
    if (run == null || !hasLayout || size.x <= 0 || size.y <= 0) {
      return null;
    }
    final current = _layout;
    final screen = Size(size.x, size.y);
    if (current != null &&
        current.screen == screen &&
        current.pots.length == run.pots.length &&
        current.garnishes.length == run.shift.garnishCount &&
        _layoutInsets == insets) {
      return current;
    }
    _layoutInsets = insets;
    return _layout = StageLayout.compute(
      screen: screen,
      insets: insets,
      pots: run.pots.length,
      garnishes: run.shift.garnishCount,
    );
  }

  Rect _layoutInsets = Rect.zero;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.wait([art.load(), audio.preload()]);
    add(_Counter(this));
  }

  @override
  void onAttach() {
    super.onAttach();
    _driving = true;
    _throttle.reset();
    SchedulerBinding.instance.scheduleFrameCallback(_onVsync);
  }

  @override
  void onDetach() {
    _driving = false;
    super.onDetach();
  }

  void _onVsync(Duration timestamp) {
    if (!_driving) {
      return;
    }
    SchedulerBinding.instance.scheduleFrameCallback(_onVsync);
    final dt = _throttle.onVsync(timestamp);
    if (dt != null) {
      stepEngine(stepTime: dt);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    engineSteps++;
    _rulesClock.advance(dt * 1000, bloc.tick);
  }

  void tap(CounterTarget target) => bloc.tap(target.station, target.index);

  @override
  void onDispose() {
    unawaited(audio.dispose());
    art.images.clearCache();
    super.onDispose();
  }
}

class _Counter extends PositionComponent with TapCallbacks {
  _Counter(this.kitchen);
  final YumYumKitchenGame kitchen;
  final _paint = Paint();
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = const Color(0xFFFFD169);
  int _feedback = -1;
  int _effectAt = -2000;
  KitchenRun? _previous;
  bool _wasReady = false;
  MarketArt get art => kitchen.art;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    final run = kitchen.bloc.run;
    final layout = kitchen.layout;
    if (run == null || layout == null) {
      return;
    }
    final target = layout.hit(event.canvasPosition.toOffset(), run);
    if (target != null) {
      kitchen.tap(target);
    }
  }

  @override
  void render(Canvas c) {
    final layout = kitchen.layout;
    final run = kitchen.bloc.run;
    _artLayer(c, layout, (canvas) {
      art.draw(canvas, "market.webp", const Rect.fromLTWH(0, 0, 1280, 421));
      art.draw(canvas, "awning.webp", const Rect.fromLTWH(0, -35, 1280, 142));
      if (run != null) {
        _lanterns(canvas, run);
      }
    });
    if (run == null || layout == null) {
      _artLayer(c, layout, _drawCounterArt);
      return;
    }
    if (!identical(run, _previous)) {
      _previous = run;
      _feedback = 0;
      _effectAt = -2000;
      _wasReady = false;
    }
    _feedbackFor(run);
    for (final customer in run.customers) {
      if (customer != null) {
        _customer(c, layout, run, customer);
      }
    }
    _departure(c, layout, run);
    _artLayer(c, layout, _drawCounterArt);
    for (final customer in run.customers) {
      if (customer != null) {
        _ticket(c, layout, run, customer);
      }
    }
    _pack(c, layout, run);
    for (var i = 0; i < run.pots.length; i++) {
      _pot(c, layout, run, i);
    }
    for (var i = 0; i < run.bowls.length; i++) {
      _bowl(c, layout, run, i);
    }
    for (var i = 0; i < layout.garnishes.length; i++) {
      final rect = StageLayout.fit(layout.garnishes[i], 1.4);
      c.drawOval(rect, _paint..color = const Color(0xFF64422D));
      c.drawOval(rect.deflate(5), _paint..color = const Color(0xFFF1DBB2));
      art.item(c, 8 + i, rect.deflate(5));
    }
    _serving(c, layout, run);
    if (kitchen.showHitBoxes) {
      _hitBoxes(c, layout);
    }
  }

  void _drawCounterArt(Canvas canvas) =>
      art.draw(canvas, "counter.webp", const Rect.fromLTWH(0, 421, 1280, 299));

  /// Draws [paint] in design-canvas coordinates, cover-fitted to the screen.
  void _artLayer(
    Canvas c,
    StageLayout? layout,
    void Function(Canvas canvas) paint,
  ) {
    final scale = layout?.scale ?? math.max(size.x / 1280, size.y / 720);
    final dx = layout?.origin.dx ?? (size.x - 1280 * scale) / 2;
    final dy = layout?.origin.dy ?? (size.y - 720 * scale) / 2;
    c
      ..save()
      ..translate(dx, dy)
      ..scale(scale);
    paint(c);
    c.restore();
  }

  void _hitBoxes(Canvas c, StageLayout layout) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c
      ..drawRect(layout.safe, line..color = const Color(0xFF00E5FF))
      ..drawRect(layout.action, line..color = const Color(0xFF76FF03))
      ..drawRect(layout.hud, line..color = const Color(0xFFFFEA00));
    for (final target in layout.allTargets()) {
      c
        ..drawRect(target.bounds, Paint()..color = const Color(0x33FF1744))
        ..drawRect(target.bounds, line..color = const Color(0xFFFF1744));
    }
  }

  void _feedbackFor(KitchenRun run) {
    final profile = kitchen.bloc.state.profile;
    final ready = run.pots.any((p) => p.phase == PotPhase.ready);
    if (ready && !_wasReady) {
      kitchen.audio.ready(sound: profile.sound);
    }
    _wasReady = ready;
    if (_feedback != run.feedbackSequence) {
      _feedback = run.feedbackSequence;
      _effectAt = run.now;
      kitchen.audio.play(
        run.cue,
        sound: profile.sound,
        haptics: profile.haptics,
      );
    }
  }

  void _halo(Canvas c, Rect rect) {
    c.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(18)),
      _stroke,
    );
  }

  void _pack(Canvas c, StageLayout layout, KitchenRun run) {
    final image = art.images.fromCache("${run.shift.product.key}.png");
    final rect = StageLayout.fit(layout.pack, image.width / image.height);
    if (run.guide == Guide.pack) {
      _halo(c, rect);
    }
    art.draw(c, "${run.shift.product.key}.png", rect);
  }

  void _bowl(Canvas c, StageLayout layout, KitchenRun run, int i) {
    final rect = StageLayout.fit(layout.bowls[i], 1.25);
    if (run.guide == Guide.serve && run.bowls[i] != null) {
      _halo(c, rect);
    }
    art.dish(c, run.shift.product, run.bowls[i], rect);
    if (run.discardBowl != i) {
      return;
    }
    final slot = layout.discards[i];
    final at = slot.center;
    final radius = math.min(slot.height, slot.width) / 2 - 4;
    c.drawCircle(at, radius, _paint..color = const Color(0xFFD03F34));
    final arm = radius * .38;
    for (final sign in const [-1.0, 1.0]) {
      c.drawLine(
        at.translate(-arm, -arm * sign),
        at.translate(arm, arm * sign),
        _paint
          ..color = const Color(0xFFFFECD0)
          ..strokeWidth = 5,
      );
    }
  }

  void _pot(Canvas c, StageLayout layout, KitchenRun run, int index) {
    final pot = run.pots[index];
    final rect = StageLayout.fit(layout.pots[index], 1.1, pad: 8);
    if (run.guide == Guide.pot && pot.phase == PotPhase.ready) {
      _halo(c, rect);
    }
    final ready = pot.phase == PotPhase.ready;
    final bob = ready && !kitchen.reducedMotion
        ? math.sin(run.now / 100) * 2
        : 0.0;
    c
      ..save()
      ..translate(0, bob);
    art.item(c, pot.phase.index, rect);
    c.restore();
    if (pot.phase != PotPhase.cooking && !ready) {
      return;
    }
    final duration = ready ? 6000 : run.cookMs;
    final left = ((pot.deadline - run.now) / duration).clamp(0.0, 1.0);
    final bar = Rect.fromLTWH(
      rect.left + rect.width * .2,
      rect.bottom - 4,
      rect.width * .6,
      8,
    );
    c
      ..drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(4)),
        _paint..color = const Color(0xFF302B27),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bar.left,
            bar.top,
            bar.width * (ready ? left : 1 - left),
            bar.height,
          ),
          const Radius.circular(4),
        ),
        _paint
          ..color = ready ? const Color(0xFFFFD366) : const Color(0xFF76D8BD),
      );
    if (kitchen.reducedMotion) {
      return;
    }
    final unit = rect.width / 178;
    for (var i = 0; i < 3; i++) {
      final t = ((run.now + i * 350) % 1050) / 1050;
      c.drawCircle(
        Offset(
          rect.center.dx + ((i - 1) * 16 + math.sin(t * 6) * 6) * unit,
          rect.top + (35 - t * 34) * unit,
        ),
        (4 + t * 5) * unit,
        _paint..color = Color.fromRGBO(255, 241, 205, (1 - t) * .45),
      );
    }
  }

  /// Ticket scale: design size, shrunk only when the ticket band is short.
  double _ticketScale(StageLayout layout) =>
      math.min(layout.scale, layout.tickets.height / 150).clamp(.4, 1.2);

  /// Customers stand behind the counter with their head just below their
  /// ticket, so the ticket never covers a face.
  Rect _guestRect(StageLayout layout, double x) {
    final width = 248 * layout.scale;
    final height = 245 * layout.scale;
    final ticketBottom = layout.tickets.top + 92 * _ticketScale(layout);
    final bottom = math.max(
      layout.counterTopY + 8 * layout.scale,
      ticketBottom - height * .06 + height,
    );
    return Rect.fromLTWH(x - width / 2, bottom - height, width, height);
  }

  void _customer(Canvas c, StageLayout layout, KitchenRun run, Customer guest) {
    final x = layout.guestX(guest.slot, run.shift.slots);
    final ratio = ((guest.expires - run.now) / run.shift.patienceMs).clamp(
      0.0,
      1.0,
    );
    final entrance = kitchen.reducedMotion
        ? 0.0
        : (1 - ((run.now - guest.arrived) / 270).clamp(0.0, 1.0)) *
              25 *
              layout.scale;
    art.guest(
      c,
      guest.id,
      ratio < .3 && run.guide == Guide.done ? 1 : 0,
      _guestRect(layout, x + entrance),
    );
  }

  void _ticket(Canvas c, StageLayout layout, KitchenRun run, Customer guest) {
    final x = layout.guestX(guest.slot, run.shift.slots);
    final k = _ticketScale(layout);
    final ticket = Rect.fromLTWH(
      x - 74 * k,
      layout.tickets.top,
      148 * k,
      78 * k,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(ticket, Radius.circular(20 * k)),
      _paint..color = const Color(0xFFFFECC9),
    );
    art.dish(
      c,
      run.shift.product,
      {},
      Rect.fromLTWH(ticket.left + 6 * k, ticket.top + 8 * k, 76 * k, 61 * k),
    );
    var j = 0;
    for (final topping in guest.toppings) {
      art.item(
        c,
        8 + topping.index,
        Rect.fromLTWH(
          ticket.left + (77 + j * 31) * k,
          ticket.top + 13 * k,
          36 * k,
          38 * k,
        ),
      );
      j++;
    }
    final ratio = ((guest.expires - run.now) / run.shift.patienceMs).clamp(
      0.0,
      1.0,
    );
    final bar = Rect.fromLTWH(
      ticket.left + 19 * k,
      ticket.bottom + 4,
      110 * k,
      7,
    );
    c
      ..drawRect(bar, _paint..color = const Color(0xFF42362D))
      ..drawRect(
        Rect.fromLTWH(
          bar.left,
          bar.top,
          bar.width * (run.guide == Guide.done ? ratio : 1),
          bar.height,
        ),
        _paint
          ..color = ratio < .3
              ? const Color(0xFFFF935B)
              : const Color(0xFF70E2C2),
      );
  }

  void _lanterns(Canvas c, KitchenRun run) {
    c.drawLine(
      const Offset(443, 82),
      const Offset(837, 82),
      _paint
        ..color = const Color(0xFF573A27)
        ..strokeWidth = 4,
    );
    for (var i = 0; i < 5; i++) {
      final at = Offset(492 + i * 74.0, 96);
      if (i < run.chain) {
        art.item(c, 11, Rect.fromCenter(center: at, width: 37, height: 48));
      } else {
        c.drawOval(
          Rect.fromCenter(center: at, width: 19, height: 27),
          _paint..color = const Color(0xFF744732),
        );
      }
    }
  }

  bool _served(KitchenRun run) =>
      run.cue == KitchenCue.served || run.cue == KitchenCue.streak;

  void _departure(Canvas c, StageLayout layout, KitchenRun run) {
    final age = run.now - _effectAt;
    if (!_served(run) ||
        age < 0 ||
        age > 650 ||
        run.servedSlot == null ||
        run.customers[run.servedSlot!] != null) {
      return;
    }
    final x = layout.guestX(run.servedSlot!, run.shift.slots);
    final dx = kitchen.reducedMotion
        ? 0.0
        : math.max(0, age - 300) * .22 * layout.scale;
    art.guest(
      c,
      run.servedCustomerId!,
      age < 350 ? 2 : 3,
      _guestRect(layout, x + dx),
    );
  }

  void _serving(Canvas c, StageLayout layout, KitchenRun run) {
    final age = run.now - _effectAt;
    if (kitchen.reducedMotion ||
        !_served(run) ||
        age > 420 ||
        run.servedSlot == null) {
      return;
    }
    final t = (age / 420).clamp(0.0, 1.0);
    final from = StageLayout.fit(layout.bowls[run.servedBowl!], 1.25);
    final end = Offset(
      layout.guestX(run.servedSlot!, run.shift.slots),
      layout.counterTopY - 60 * layout.scale,
    );
    final point =
        Offset.lerp(from.center, end, t)! -
        Offset(0, math.sin(t * math.pi) * 55 * layout.scale);
    art.dish(
      c,
      run.shift.product,
      {},
      Rect.fromCenter(
        center: point,
        width: from.width * (1 - t * .3),
        height: from.height * (1 - t * .3),
      ),
    );
  }
}
