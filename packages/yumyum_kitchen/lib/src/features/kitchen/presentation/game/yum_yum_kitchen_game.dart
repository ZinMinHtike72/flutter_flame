import "dart:async";
import "dart:math" as math;
import "dart:ui";

import "package:flame/components.dart";
import "package:flame/events.dart";
import "package:flame/game.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/restaurant_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/boil_sync.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/frame_timing.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/market_art.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/pot_sprites.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/press_feedback.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/quality_benchmark.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/restaurant_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/restaurant_view.dart";
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
    assert(_preloaded, "The shift clock must not run before preload.");
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

  /// Game motion clock in milliseconds (engine time, 30 steps a second);
  /// drives press feedback and other micro-interactions.
  double motionMs = 0;

  /// Press response of counter targets.
  final press = PressFeedback();

  @override
  Color backgroundColor() => const Color(0xFF102A2D);

  /// Layout for the current screen size, insets and run equipment.
  StageLayout? get layout {
    final run = bloc.run;
    if (run == null || !hasLayout || size.x <= 0 || size.y <= 0) {
      return null;
    }
    final current = _layout;
    if (current != null &&
        current.screen.width == size.x &&
        current.screen.height == size.y &&
        current.pots.length == run.pots.length &&
        current.garnishes.length == run.shift.garnishCount &&
        _layoutInsets == insets) {
      return current;
    }
    _layoutInsets = insets;
    return _layout = StageLayout.compute(
      screen: Size(size.x, size.y),
      insets: insets,
      pots: run.pots.length,
      garnishes: run.shift.garnishCount,
    );
  }

  Rect _layoutInsets = Rect.zero;

  /// The restaurant's packed art (set at load).
  RestaurantArt? restaurantArt;
  RestaurantView? _restaurantView;
  RestaurantLayout? _restaurantLayout;
  RestaurantDay? _restaurantDay;
  Rect _restaurantInsets = Rect.zero;

  /// The last restaurant spot tapped, when, and whether it was refused
  /// (drawn pressed or shaking for a moment).
  RestaurantTarget? lastRestaurantTap;
  double lastRestaurantTapAt = double.negativeInfinity;
  bool lastRestaurantTapRefused = false;

  /// Layout of the restaurant day in play, for this screen and insets.
  RestaurantLayout? get restaurantLayout {
    final run = bloc.restaurant;
    if (run == null || size.x <= 0 || size.y <= 0) {
      return null;
    }
    final current = _restaurantLayout;
    if (current != null &&
        identical(_restaurantDay, run.day) &&
        current.screen.width == size.x &&
        current.screen.height == size.y &&
        _restaurantInsets == insets) {
      return current;
    }
    _restaurantDay = run.day;
    _restaurantInsets = insets;
    return _restaurantLayout = RestaurantLayout.compute(
      screen: Size(size.x, size.y),
      insets: insets,
      day: run.day,
    );
  }

  /// One restaurant step: press feedback on the next frame, the rules, then
  /// the sound and haptic of what happened.
  void tapRestaurant(RestaurantTarget target) {
    bloc.tapRestaurant(target.spot, target.index);
    final run = bloc.restaurant;
    if (run == null) {
      return;
    }
    lastRestaurantTap = target;
    lastRestaurantTapAt = motionMs;
    lastRestaurantTapRefused = run.cue == RestaurantCue.rejected;
    final profile = bloc.state.profile;
    audio.play(
      switch (run.cue) {
        RestaurantCue.noodles => KitchenCue.pack,
        RestaurantCue.bowlFilled => KitchenCue.transfer,
        RestaurantCue.water ||
        RestaurantCue.ladle ||
        RestaurantCue.tea ||
        RestaurantCue.selected => KitchenCue.garnish,
        RestaurantCue.served => KitchenCue.served,
        RestaurantCue.clearing ||
        RestaurantCue.binned ||
        RestaurantCue.cleared => KitchenCue.discarded,
        RestaurantCue.lost => KitchenCue.missed,
        RestaurantCue.none || RestaurantCue.rejected => KitchenCue.none,
      },
      sound: profile.sound,
      haptics: profile.haptics,
    );
  }

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
    restaurantArt = RestaurantArt(
      room: await art.images.load("restaurant/room.webp"),
      counter: await loadAtlas("restaurant/counter"),
      kitchen: await loadAtlas("restaurant/kitchen"),
      dining: await loadAtlas("restaurant/dining"),
      waiter: await loadAtlas("restaurant/waiter"),
      guests: await loadAtlas("restaurant/guests"),
    );
    add(_counter = _Counter(this));
    add(_restaurantView = RestaurantView(this));
    _preloaded = true;
  }

  bool _preloaded = false;

  /// True once every atlas, image and sound is loaded. Until then the game
  /// is not mounted, so no shift can start and the rules clock cannot run.
  bool get preloaded => _preloaded;

  _Counter? _counter;

  /// The kitchen draws everything itself in screen space. Flame's default
  /// camera and its empty world draw nothing yet allocate closures on every
  /// frame, so only the counter's tree is rendered.
  @override
  void renderTree(Canvas canvas) {
    if (bloc.restaurant != null) {
      _restaurantView?.renderTree(canvas);
      return;
    }
    _counter?.renderTree(canvas);
  }

  /// Same for updates: lifecycle events (adds and removes) are still
  /// processed, but the unused camera subtree is not ticked. The counter has
  /// no update logic of its own; the game's [update] drives everything.
  @override
  void updateTree(double dt) {
    processLifecycleEvents();
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
    motionMs += dt * 1000;
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

  /// Shows the press on the next frame, then hands the tap to the rules.
  void tap(CounterTarget target) {
    press.press(target.station, target.index, motionMs);
    bloc.tap(target.station, target.index);
  }

  @override
  void onDispose() {
    puff?.dispose();
    unawaited(audio.dispose());
    art.images.clearCache();
    super.onDispose();
  }
}

/// Geometry of one layout + product + customer count, built once so the
/// frame loop only does arithmetic and canvas transforms.
class _Geometry {
  _Geometry(this.layout, this.product, this.slots, MarketArt art)
    : pack = StageLayout.fit(layout.pack, art.packs[product.index].aspect),
      garnishInner = [for (final r in layout.garnishSprites) r.deflate(5)],
      ticket = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, layout.ticketWidth, layout.ticketHeight),
            Radius.circular(20 * layout.ticketScale),
          ),
        ),
      ticketLeft = [
        for (var i = 0; i < slots; i++) layout.ticketOrigin(i, slots).dx,
      ],
      ticketTop = [
        for (var i = 0; i < slots; i++) layout.ticketOrigin(i, slots).dy,
      ],
      guestX = [for (var i = 0; i < slots; i++) layout.guestX(i, slots)] {
    packHalo = _halo(pack);
    potHalos = [for (final r in layout.potSprites) _halo(r)];
    bowlHalos = [for (final r in layout.bowlSprites) _halo(r)];
    for (final r in layout.potSprites) {
      final bar = Rect.fromLTWH(
        r.left + r.width * .2,
        r.bottom - 4,
        r.width * .6,
        8,
      );
      bars.add(bar);
      barPaths.add(
        Path()
          ..addRRect(RRect.fromRectAndRadius(bar, const Radius.circular(4))),
      );
    }
    for (final slot in layout.discards) {
      final c = slot.center;
      final radius =
          (slot.height < slot.width ? slot.height : slot.width) / 2 - 4;
      final arm = radius * .38;
      discardCenters.add(c);
      discardRadius.add(radius);
      discardLines.add([
        c.translate(-arm, -arm),
        c.translate(arm, arm),
        c.translate(-arm, arm),
        c.translate(arm, -arm),
      ]);
    }
  }

  final StageLayout layout;
  final NoodleProduct product;
  final int slots;
  final Rect pack;
  late final Path packHalo;
  late final List<Path> potHalos;
  late final List<Path> bowlHalos;
  final bars = <Rect>[];
  final barPaths = <Path>[];
  final discardCenters = <Offset>[];
  final discardRadius = <double>[];
  final discardLines = <List<Offset>>[];
  final List<Rect> garnishInner;
  final Path ticket;
  final List<double> ticketLeft;
  final List<double> ticketTop;
  final List<double> guestX;

  static Path _halo(Rect r) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(18)),
    );

  bool matches(StageLayout l, NoodleProduct p, int s) =>
      identical(l, layout) && p == product && s == slots;
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
  final _crossPaint = Paint()
    ..color = const Color(0xFFFFECD0)
    ..strokeWidth = 5;
  final _pressRing = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  int _chainSeen = 0;
  double _chainAt = double.negativeInfinity;
  int _feedback = -1;
  int _effectAt = -2000;
  KitchenRun? _previous;
  _Geometry? _geometry;
  MarketArt get art => kitchen.art;

  static const _unit = Rect.fromLTWH(0, 0, 1, 1);
  static const _lanternPopMs = 260.0;
  static const _market = Rect.fromLTWH(0, 0, 1280, 421);
  static const _awning = Rect.fromLTWH(0, -35, 1280, 142);
  static const _counterArt = Rect.fromLTWH(0, 421, 1280, 299);
  static final _unlitLanterns = [
    for (var i = 0; i < 5; i++)
      Rect.fromCenter(
        center: Offset(492 + i * 74.0, 96),
        width: 19,
        height: 27,
      ),
  ];
  static final _litLanterns = [
    for (var i = 0; i < 5; i++)
      Rect.fromCenter(
        center: Offset(492 + i * 74.0, 96),
        width: 37,
        height: 48,
      ),
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  /// The counter sits at the origin with an identity transform and no
  /// children or decorators, so its tree is just [render]. Flame's default
  /// path tears off `super.renderTree` and runs the decorator chain, which
  /// allocates closures every frame.
  @override
  void renderTree(Canvas canvas) => render(canvas);

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

  _Geometry _geometryFor(StageLayout layout, KitchenRun run) {
    final current = _geometry;
    if (current != null &&
        current.matches(layout, run.shift.product, run.shift.slots)) {
      return current;
    }
    return _geometry = _Geometry(
      layout,
      run.shift.product,
      run.shift.slots,
      art,
    );
  }

  @override
  void render(Canvas c) {
    final layout = kitchen.layout;
    final run = kitchen.bloc.run;
    _beginArt(c, layout);
    art.market.drawRect(c, _market, art.paint);
    art.awning.drawRect(c, _awning, art.paint);
    if (run != null) {
      _lanterns(c, run);
    }
    c.restore();
    if (run == null || layout == null) {
      _beginArt(c, layout);
      art.counter.drawRect(c, _counterArt, art.paint);
      c.restore();
      return;
    }
    final g = _geometryFor(layout, run);
    if (!identical(run, _previous)) {
      _previous = run;
      _feedback = 0;
      _effectAt = -2000;
    }
    _feedbackFor(run);
    _customers(c, layout, g, run);
    _beginArt(c, layout);
    art.counter.drawRect(c, _counterArt, art.paint);
    c.restore();
    for (var i = 0; i < run.customers.length; i++) {
      final customer = run.customers[i];
      if (customer != null) {
        _ticket(c, g, run, customer);
      }
    }
    if (run.guide == Guide.pack) {
      c.drawPath(g.packHalo, _stroke);
    }
    final packPressed = _pressIn(c, Station.pack, 0, g.pack, ring: g.packHalo);
    art.packs[run.shift.product.index].drawRect(c, g.pack, art.paint);
    if (packPressed) {
      c.restore();
    }
    for (var i = 0; i < run.pots.length; i++) {
      _pot(c, layout, g, run, i);
    }
    final puff = kitchen.puff;
    if (puff != null && !kitchen.reducedMotion) {
      kitchen.steam.render(c, kitchen.smokeAtlas?.image ?? puff, _atlasPaint);
    }
    for (var i = 0; i < run.bowls.length; i++) {
      _bowl(c, layout, g, run, i);
    }
    for (var i = 0; i < layout.garnishes.length; i++) {
      final pressed = _pressIn(c, Station.garnish, i, layout.garnishSprites[i]);
      c
        ..drawOval(
          layout.garnishSprites[i],
          _paint..color = const Color(0xFF64422D),
        )
        ..drawOval(g.garnishInner[i], _paint..color = const Color(0xFFF1DBB2));
      art.itemRect(
        c,
        MarketArt.garnishOf(Garnish.values[i]),
        g.garnishInner[i],
      );
      if (pressed) {
        c.restore();
      }
    }
    _serving(c, layout, g, run);
    if (kitchen.showHitBoxes) {
      _hitBoxes(c, layout);
    }
  }

  /// Saves the canvas and maps the 1280×720 design canvas onto the screen
  /// with cover fit. Pair with `restore()`.
  void _beginArt(Canvas c, StageLayout? layout) {
    final scale = layout?.scale ?? math.max(size.x / 1280, size.y / 720);
    final dx = layout?.origin.dx ?? (size.x - 1280 * scale) / 2;
    final dy = layout?.origin.dy ?? (size.y - 720 * scale) / 2;
    c
      ..save()
      ..translate(dx, dy)
      ..scale(scale);
  }

  /// Debug overlay only (development builds); allocation here is fine.
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
    if (_feedback != run.feedbackSequence) {
      final profile = kitchen.bloc.state.profile;
      _feedback = run.feedbackSequence;
      _effectAt = run.now;
      kitchen.audio.play(
        run.cue,
        sound: profile.sound,
        haptics: profile.haptics,
      );
    }
  }

  /// Starts the press response for [station] [index]: scales the canvas about
  /// [rect]'s centre (returns true: restore after drawing), or under reduced
  /// motion draws a fading ring along [ring] (or around [rect]) instead.
  bool _pressIn(Canvas c, Station station, int index, Rect rect, {Path? ring}) {
    final press = kitchen.press;
    final now = kitchen.motionMs;
    final t = press.progress(station, index, now);
    if (t >= 1) {
      return false;
    }
    if (kitchen.reducedMotion) {
      _pressRing.color = _white(.9 * (1 - t));
      if (ring != null) {
        c.drawPath(ring, _pressRing);
      } else {
        c.drawOval(rect, _pressRing);
      }
      return false;
    }
    final scale = press.scale(station, index, now);
    final cx = rect.left + rect.width / 2;
    final cy = rect.top + rect.height / 2;
    c
      ..save()
      ..translate(cx, cy)
      ..scale(scale)
      ..translate(-cx, -cy);
    return true;
  }

  /// Draws a filled bar of [fraction] inside [bar] (unit rect + transform).
  void _fill(Canvas c, Rect bar, double fraction, Paint paint) {
    c
      ..save()
      ..translate(bar.left, bar.top)
      ..scale(bar.width * fraction, bar.height)
      ..drawRect(_unit, paint)
      ..restore();
  }

  void _bowl(Canvas c, StageLayout layout, _Geometry g, KitchenRun run, int i) {
    final rect = layout.bowlSprites[i];
    if (run.guide == Guide.serve && run.bowls[i] != null) {
      c.drawPath(g.bowlHalos[i], _stroke);
    }
    final pressed = _pressIn(c, Station.bowl, i, rect, ring: g.bowlHalos[i]);
    art.dish(
      c,
      run.shift.product,
      run.bowls[i],
      rect.left,
      rect.top,
      rect.width,
      rect.height,
    );
    if (pressed) {
      c.restore();
    }
    if (run.discardBowl != i) {
      return;
    }
    final lines = g.discardLines[i];
    final discardPressed = _pressIn(c, Station.discard, i, layout.discards[i]);
    c
      ..drawCircle(
        g.discardCenters[i],
        g.discardRadius[i],
        _paint..color = const Color(0xFFD03F34),
      )
      ..drawLine(lines[0], lines[1], _crossPaint)
      ..drawLine(lines[2], lines[3], _crossPaint);
    if (discardPressed) {
      c.restore();
    }
  }

  void _pot(
    Canvas c,
    StageLayout layout,
    _Geometry g,
    KitchenRun run,
    int index,
  ) {
    final pot = run.pots[index];
    final rect = layout.potSprites[index];
    final ready = pot.phase == PotPhase.ready;
    if (run.guide == Guide.pot && ready) {
      c.drawPath(g.potHalos[index], _stroke);
    }
    final bob = ready && !kitchen.reducedMotion
        ? math.sin(run.now / 100) * 2
        : 0.0;
    final shake = kitchen.reducedMotion
        ? 0.0
        : kitchen.boil.shake(index, run.now) * rect.width;
    final sprites = kitchen.potSprites;
    final pressed = _pressIn(
      c,
      Station.pot,
      index,
      rect,
      ring: g.potHalos[index],
    );
    c
      ..save()
      ..translate(shake, bob);
    if (sprites == null) {
      art.itemRect(c, pot.phase.index, rect);
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
    if (pressed) {
      c.restore();
    }
    if (pot.phase != PotPhase.cooking && !ready) {
      return;
    }
    final duration = ready ? 6000 : run.cookMs;
    final left = ((pot.deadline - run.now) / duration).clamp(0.0, 1.0);
    c
      ..drawPath(g.barPaths[index], _paint..color = const Color(0xFF302B27))
      ..save()
      ..clipPath(g.barPaths[index]);
    _fill(
      c,
      g.bars[index],
      ready ? left : 1 - left,
      _paint..color = ready ? const Color(0xFFFFD366) : const Color(0xFF76D8BD),
    );
    c.restore();
    final puff = kitchen.puff;
    if (kitchen.reducedMotion && puff != null) {
      // Reduced motion: one still wisp keeps "this pot is hot" visible.
      final size = rect.width * .62;
      c
        ..save()
        ..translate(rect.left + rect.width / 2 - size / 2, rect.top - size * .9)
        ..scale(size / SteamField.puffSize)
        ..drawImageRect(puff, _puffSource, _puffSource, _wispPaint)
        ..restore();
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
  void _customers(Canvas c, StageLayout layout, _Geometry g, KitchenRun run) {
    final sprites = kitchen.customerSprites;
    if (sprites == null) {
      return;
    }
    final height = layout.customerHeight;
    final standFeetY = layout.counterTopY + height * StageLayout.waistShare;
    final streetFeetY = layout.counterTopY - 4 * layout.scale;
    final actors = kitchen.cast.actors;
    // Two passes: customers on their way in or out (deeper) behind those
    // standing at the counter.
    for (var pass = 0; pass < 2; pass++) {
      final deep = pass == 0;
      for (var i = 0; i < actors.length; i++) {
        final actor = actors[i];
        if (!actor.active || actor.slot >= g.guestX.length) {
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
        final feetX = g.guestX[actor.slot] + _pose.x * height;
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

  void _ticket(Canvas c, _Geometry g, KitchenRun run, Customer guest) {
    // Hide the order until its customer starts to come in, so it never
    // floats beside the previous customer who is still reacting.
    final actors = kitchen.cast.actors;
    for (var i = 0; i < actors.length; i++) {
      final actor = actors[i];
      if (actor.active && actor.id == guest.id && run.now < actor.enterAt) {
        return;
      }
    }
    if (guest.slot >= g.ticketLeft.length) {
      return;
    }
    final k = g.layout.ticketScale;
    final left = g.ticketLeft[guest.slot];
    final top = g.ticketTop[guest.slot];
    c
      ..save()
      ..translate(left, top)
      ..drawPath(g.ticket, _paint..color = const Color(0xFFFFECC9))
      ..restore();
    art.dish(
      c,
      run.shift.product,
      _noToppings,
      left + 6 * k,
      top + 8 * k,
      76 * k,
      61 * k,
    );
    var j = 0;
    const kinds = Garnish.values;
    for (var i = 0; i < kinds.length; i++) {
      if (!guest.toppings.contains(kinds[i])) {
        continue;
      }
      art.item(
        c,
        MarketArt.garnishOf(kinds[i]),
        left + (77 + j * 31) * k,
        top + 13 * k,
        36 * k,
        38 * k,
      );
      j++;
    }
    final ratio = ((guest.expires - run.now) / run.shift.patienceMs).clamp(
      0.0,
      1.0,
    );
    final barLeft = left + 19 * k;
    final barTop = top + g.layout.ticketHeight + 4;
    final barWidth = 110 * k;
    _box(
      c,
      barLeft,
      barTop,
      barWidth,
      7,
      _paint..color = const Color(0xFF42362D),
    );
    _box(
      c,
      barLeft,
      barTop,
      barWidth * (run.guide == Guide.done ? ratio : 1),
      7,
      _paint
        ..color = ratio < .3
            ? const Color(0xFFFF935B)
            : const Color(0xFF70E2C2),
    );
  }

  /// An empty topping set for order tickets (the dish without garnish).
  static const Set<Garnish> _noToppings = {};

  void _box(
    Canvas c,
    double left,
    double top,
    double width,
    double height,
    Paint paint,
  ) {
    c
      ..save()
      ..translate(left, top)
      ..scale(width, height)
      ..drawRect(_unit, paint)
      ..restore();
  }

  void _lanterns(Canvas c, KitchenRun run) {
    c.drawLine(
      const Offset(443, 82),
      const Offset(837, 82),
      _paint
        ..color = const Color(0xFF573A27)
        ..strokeWidth = 4,
    );
    if (run.chain != _chainSeen) {
      if (run.chain > _chainSeen) {
        _chainAt = kitchen.motionMs;
      }
      _chainSeen = run.chain;
    }
    for (var i = 0; i < 5; i++) {
      final popAge = kitchen.motionMs - _chainAt;
      if (i == run.chain - 1 &&
          popAge < _lanternPopMs &&
          !kitchen.reducedMotion) {
        // The newest lantern pops in: overshoot on scale only.
        final t = popAge / _lanternPopMs;
        final u = t - 1;
        final pop = .3 + .7 * (1 + 2.70158 * u * u * u + 1.70158 * u * u);
        final r = _litLanterns[i];
        final cx = r.left + r.width / 2;
        final cy = r.top + r.height / 2;
        c
          ..save()
          ..translate(cx, cy)
          ..scale(pop)
          ..translate(-cx, -cy);
        art.itemRect(c, MarketArt.lantern, r);
        c.restore();
      } else if (i < run.chain) {
        art.itemRect(c, MarketArt.lantern, _litLanterns[i]);
      } else {
        c.drawOval(_unlitLanterns[i], _paint..color = const Color(0xFF744732));
      }
    }
  }

  bool _served(KitchenRun run) =>
      run.cue == KitchenCue.served || run.cue == KitchenCue.streak;

  void _serving(Canvas c, StageLayout layout, _Geometry g, KitchenRun run) {
    final age = run.now - _effectAt;
    final slot = run.servedSlot;
    final bowl = run.servedBowl;
    if (kitchen.reducedMotion ||
        !_served(run) ||
        age > 420 ||
        slot == null ||
        bowl == null ||
        slot >= g.guestX.length) {
      return;
    }
    final t = (age / 420).clamp(0.0, 1.0);
    final from = layout.bowlSprites[bowl];
    final fromX = from.left + from.width / 2;
    final fromY = from.top + from.height / 2;
    final endX = g.guestX[slot];
    final endY = layout.counterTopY - 60 * layout.scale;
    final x = fromX + (endX - fromX) * t;
    final y =
        fromY + (endY - fromY) * t - math.sin(t * math.pi) * 55 * layout.scale;
    final w = from.width * (1 - t * .3);
    final h = from.height * (1 - t * .3);
    art.dish(c, run.shift.product, _noToppings, x - w / 2, y - h / 2, w, h);
  }
}
