import "dart:async";
import "dart:math" as math;
import "dart:ui";

import "package:flame/components.dart";
import "package:flame/events.dart";
import "package:flame/game.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/boil_sync.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/market_art.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/pot_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/quality_benchmark.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/sprite_atlas.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/stage_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/steam_field.dart";

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

  /// Pooled steam above the pots (two pots at most).
  final steam = SteamField(emitters: 2);

  /// Tier picked by this device's startup benchmark (medium until it runs).
  SteamQuality benchmarkTier = SteamQuality.medium;

  /// Particle budget: the saved tier, else the benchmark's pick.
  SteamQuality get quality {
    final saved = bloc.state.profile.qualityTier;
    return saved == null ? benchmarkTier : SteamQuality.values[saved];
  }

  /// Realistic pot body and lid slices from the painted sheet (set at load).
  PotSprites? potSprites;

  /// Painted steam wisps and smoke puffs.
  SpriteAtlas? smokeAtlas;

  /// Soft puff sprite baked at load (benchmark workload and fallback).
  Image? puff;
  KitchenRun? _steamRun;

  /// Full-body customers, matched to the rules inside each rules step.
  final cast = CustomerCast();

  /// The six customers' sprites (set at load).
  CustomerSprites? customerSprites;

  /// Bubbles, lid rattle and boil audio, updated inside each rules step.
  final boil = BoilSync();
  KitchenRun? _boilRun;
  bool _loopSound = true;

  // Cached tear-offs so the per-step callbacks allocate nothing.
  late final void Function(int ms) _onRulesStep = _rulesStep;
  late final void Function(BoilChange change) _onBoilChange = _boilChanged;

  /// One fixed 30 Hz rules step: advance the rules, then lock the boil
  /// animation and audio to the state they just produced.
  void _rulesStep(int ms) {
    bloc.tick(ms);
    final run = bloc.run;
    if (!identical(run, _boilRun)) {
      _boilRun = run;
      boil.reset();
      audio.boilLoop(on: false, sound: _loopSound);
    }
    if (run == null) {
      return;
    }
    cast.sync(run, reducedMotion: reducedMotion);
    final sound = bloc.state.profile.sound;
    final flipped = boil.step(run, _onBoilChange);
    if (flipped || sound != _loopSound) {
      _loopSound = sound;
      audio.boilLoop(on: boil.loopOn, sound: sound);
    }
  }

  void _boilChanged(BoilChange change) {
    if (change.to == BoilStage.ready) {
      audio.ready(sound: bloc.state.profile.sound);
    }
  }

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

  /// Loads a packed atlas (`assets/images/<name>.webp` + `.json`). The JSON
  /// is read uncached: a cached future from an earlier, disposed zone would
  /// never complete (seen across widget tests).
  Future<SpriteAtlas> loadAtlas(String name) async {
    final json = await rootBundle.loadString(
      "packages/yumyum_kitchen/assets/images/$name.json",
      cache: false,
    );
    return SpriteAtlas.fromJson(await art.images.load("$name.webp"), json);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.wait([art.load(), audio.preload()]);
    potSprites = PotSprites(await loadAtlas("pots"));
    customerSprites = CustomerSprites([
      for (final name in CustomerSprites.names)
        await loadAtlas("customers/$name"),
    ]);
    final smoke = smokeAtlas = await loadAtlas("smoke");
    steam.useTextures(
      [for (var i = 0; i < 8; i++) smoke.frame(smoke.id("steam_$i")).source],
      [for (var i = 0; i < 4; i++) smoke.frame(smoke.id("smoke_$i")).source],
    );
    final puff = this.puff = await SteamField.bakePuff();
    if (bloc.state.profile.qualityTier == null) {
      benchmarkTier = QualityBenchmark.tierFor(QualityBenchmark.measure(puff));
      bloc.add(KitchenAction(ActionType.benchmark, benchmarkTier.index));
    }
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
    _rulesClock.advance(dt * 1000, _onRulesStep);
    _updateSteam(dt);
  }

  void _updateSteam(double dt) {
    final run = bloc.run;
    final layout = this.layout;
    if (!identical(run, _steamRun) || reducedMotion) {
      _steamRun = run;
      steam.clear();
    }
    if (run == null || layout == null || reducedMotion || run.paused) {
      return;
    }
    steam.update(dt, run.pots, layout.potSprites, quality, layout.scale);
  }

  void tap(CounterTarget target) => bloc.tap(target.station, target.index);

  @override
  void onDispose() {
    puff?.dispose();
    unawaited(audio.dispose());
    art.images.clearCache();
    super.onDispose();
  }
}

class _Counter extends PositionComponent with TapCallbacks {
  _Counter(this.kitchen);
  final YumYumKitchenGame kitchen;
  final _paint = Paint();
  final _spritePaint = Paint()..filterQuality = FilterQuality.medium;

  /// The bubbling surface is drawn see-through so the noodles show.
  final _boilPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..color = const Color(0xB3FFFFFF);
  final _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  final _wispPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0xE6FFF6E6),
      BlendMode.modulate,
    );
  static const _puffSource = Rect.fromLTWH(
    0,
    0,
    SteamField.puffSize,
    SteamField.puffSize,
  );
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = const Color(0xFFFFD169);
  int _feedback = -1;
  int _effectAt = -2000;
  KitchenRun? _previous;
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
    }
    _feedbackFor(run);
    _customers(c, layout, run);
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
    final puff = kitchen.puff;
    if (puff != null && !kitchen.reducedMotion) {
      kitchen.steam.render(c, kitchen.smokeAtlas?.image ?? puff, _atlasPaint);
    }
    for (var i = 0; i < run.bowls.length; i++) {
      _bowl(c, layout, run, i);
    }
    for (var i = 0; i < layout.garnishes.length; i++) {
      final rect = layout.garnishSprites[i];
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
    final rect = layout.bowlSprites[i];
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
    final rect = layout.potSprites[index];
    if (run.guide == Guide.pot && pot.phase == PotPhase.ready) {
      _halo(c, rect);
    }
    final ready = pot.phase == PotPhase.ready;
    final bob = ready && !kitchen.reducedMotion
        ? math.sin(run.now / 100) * 2
        : 0.0;
    final sprites = kitchen.potSprites;
    c
      ..save()
      ..translate(0, bob);
    if (sprites == null) {
      art.item(c, pot.phase.index, rect);
    } else {
      sprites.drawBody(c, pot.phase, rect, _spritePaint);
      final boilFrame = kitchen.boil.boilFrame(index, run.now);
      if (boilFrame >= 0 && !kitchen.reducedMotion) {
        sprites.drawBoil(c, boilFrame, rect, _boilPaint);
      }
      sprites.drawLid(
        c,
        pot.phase,
        rect,
        _spritePaint,
        rattle: kitchen.reducedMotion ? 0 : kitchen.boil.rattle(index, run.now),
        tilt: kitchen.reducedMotion ? 0 : kitchen.boil.tilt(index, run.now),
      );
    }
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
    final puff = kitchen.puff;
    if (kitchen.reducedMotion && puff != null) {
      // Reduced motion: one still wisp keeps "this pot is hot" visible.
      final size = rect.width * .62;
      c.drawImageRect(
        puff,
        _puffSource,
        Rect.fromLTWH(
          rect.center.dx - size / 2,
          rect.top - size * .9,
          size,
          size,
        ),
        _wispPaint,
      );
    }
  }

  final _pose = CustomerPose();
  final _customerPaint = Paint()..filterQuality = FilterQuality.medium;
  final _shadowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .08);

  /// White and black at every alpha, built once so drawing needs no Colors.
  static final _whites = [
    for (var a = 0; a < 256; a++) Color.fromARGB(a, 255, 255, 255),
  ];
  static final _blacks = [
    for (var a = 0; a < 256; a++) Color.fromARGB(a, 0, 0, 0),
  ];
  static Color _white(double opacity) =>
      _whites[(opacity.clamp(0.0, 1.0) * 255).round()];
  static const _unitOval = Rect.fromLTWH(-.5, -.5, 1, 1);

  /// Draws every customer, far ones first, behind the counter art.
  void _customers(Canvas c, StageLayout layout, KitchenRun run) {
    final sprites = kitchen.customerSprites;
    if (sprites == null) {
      return;
    }
    final height = layout.customerHeight;
    final standFeetY = layout.counterTopY + height * StageLayout.waistShare;
    final streetFeetY = layout.counterTopY - 4 * layout.scale;
    // Two passes: customers on their way in or out (deeper) behind those
    // standing at the counter.
    for (final deep in const [true, false]) {
      for (final actor in kitchen.cast.actors) {
        if (!actor.active) {
          continue;
        }
        CustomerCast.pose(
          actor,
          run.now,
          _pose,
          reducedMotion: kitchen.reducedMotion,
          guided: run.guide != Guide.done,
        );
        if ((_pose.depth > 0) != deep) {
          continue;
        }
        final scale = 1 - .2 * _pose.depth;
        final h = height * scale * _pose.breath;
        final feetX =
            layout.guestX(actor.slot, run.shift.slots) + _pose.x * height;
        final feetY = standFeetY + (streetFeetY - standFeetY) * _pose.depth;
        if (feetY < layout.counterTopY) {
          // Feet visible on the street: a soft contact shadow.
          _shadowPaint.color = _blacks[(64 * _pose.opacity).round()];
          c
            ..save()
            ..translate(feetX, feetY)
            ..scale(h * .32, h * .05)
            ..drawOval(_unitOval, _shadowPaint)
            ..restore();
        }
        final from = _pose.fromClip;
        if (from != null && _pose.fromOpacity > 0) {
          _customerPaint.color = _white(_pose.fromOpacity);
          sprites.draw(
            c,
            actor.look,
            from,
            _pose.fromFrame,
            feetX,
            feetY,
            h,
            _customerPaint,
            flip: _pose.flip,
          );
        }
        _customerPaint.color = _white(_pose.opacity);
        sprites.draw(
          c,
          actor.look,
          _pose.clip,
          _pose.frame,
          feetX,
          feetY,
          h,
          _customerPaint,
          flip: _pose.flip,
        );
      }
    }
  }

  void _ticket(Canvas c, StageLayout layout, KitchenRun run, Customer guest) {
    // Hide the order until its customer starts to come in, so it never
    // floats beside the previous customer who is still reacting.
    for (final actor in kitchen.cast.actors) {
      if (actor.active && actor.id == guest.id && run.now < actor.enterAt) {
        return;
      }
    }
    final k = layout.ticketScale;
    final origin = layout.ticketOrigin(guest.slot, run.shift.slots);
    final ticket = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      layout.ticketWidth,
      layout.ticketHeight,
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

  void _serving(Canvas c, StageLayout layout, KitchenRun run) {
    final age = run.now - _effectAt;
    if (kitchen.reducedMotion ||
        !_served(run) ||
        age > 420 ||
        run.servedSlot == null) {
      return;
    }
    final t = (age / 420).clamp(0.0, 1.0);
    final from = layout.bowlSprites[run.servedBowl!];
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
