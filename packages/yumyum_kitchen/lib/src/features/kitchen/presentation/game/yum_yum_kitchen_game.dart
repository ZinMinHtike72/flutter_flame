import "dart:async";
import "dart:math" as math;
import "dart:ui";
import "package:flame/components.dart";
import "package:flame/events.dart";
import "package:flame/game.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/counter_layout.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/market_art.dart";

class YumYumKitchenGame extends FlameGame {
  YumYumKitchenGame(this.bloc, this.audio)
    : super(
        camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
      );
  final KitchenBloc bloc;
  final KitchenAudio audio;
  final art = MarketArt();
  bool reducedMotion = false;
  double _fraction = 0;
  @override
  Color backgroundColor() => const Color(0xFF102A2D);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    await Future.wait([art.load(), audio.preload()]);
    world.add(_Counter(this));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fraction += dt * 1000;
    final ms = _fraction.floor();
    _fraction -= ms;
    bloc.tick(ms);
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
  _Counter(this.kitchen) : super(size: Vector2(1280, 720));
  final YumYumKitchenGame kitchen;
  final _paint = Paint();
  int _feedback = -1;
  int _effectAt = -2000;
  KitchenRun? _previous;
  bool _wasReady = false;
  MarketArt get art => kitchen.art;

  @override
  void onTapDown(TapDownEvent event) {
    final run = kitchen.bloc.run;
    if (run == null) {
      return;
    }
    final point = event.localPosition.toOffset();
    for (final target in CounterLayout.targets(run)) {
      if (target.bounds.contains(point)) {
        kitchen.tap(target);
        return;
      }
    }
  }

  @override
  void render(Canvas c) {
    art.draw(c, "market.webp", const Rect.fromLTWH(0, 0, 1280, 421));
    final run = kitchen.bloc.run;
    art.draw(c, "awning.webp", const Rect.fromLTWH(0, -35, 1280, 142));
    if (run != null) {
      if (!identical(run, _previous)) {
        _previous = run;
        _feedback = 0;
        _effectAt = -2000;
        _wasReady = false;
      }
      _feedbackFor(run);
      _lanterns(c, run);
      for (final customer in run.customers.nonNulls) {
        _customer(c, run, customer);
      }
      _departure(c, run);
    }
    art.draw(c, "counter.webp", const Rect.fromLTWH(0, 421, 1280, 299));
    if (run == null) {
      return;
    }
    final banner = CounterLayout.pack;
    if (run.guide == Guide.pack) {
      _halo(c, banner);
    }
    art.draw(c, "${run.shift.product.key}.png", banner);
    for (var i = 0; i < run.pots.length; i++) {
      _pot(c, run, i);
    }
    for (var i = 0; i < 2; i++) {
      final rect = CounterLayout.bowl(i);
      if (run.guide == Guide.serve && run.bowls[i] != null) {
        _halo(c, rect);
      }
      art.dish(c, run.shift.product, run.bowls[i], rect);
      if (run.discardBowl == i) {
        final at = CounterLayout.discard(i).center;
        c.drawCircle(at, 26, _paint..color = const Color(0xFFD03F34));
        for (final sign in [-1, 1]) {
          c.drawLine(
            at + Offset(-9, -9.0 * sign),
            at + Offset(9, 9.0 * sign),
            _paint
              ..color = const Color(0xFFFFECD0)
              ..strokeWidth = 5,
          );
        }
      }
    }
    for (var i = 0; i < run.shift.garnishCount; i++) {
      final rect = CounterLayout.garnish(i);
      c.drawOval(rect.deflate(7), _paint..color = const Color(0xFF64422D));
      c.drawOval(rect.deflate(13), _paint..color = const Color(0xFFF1DBB2));
      art.item(c, 8 + i, rect.deflate(13));
    }
    _serving(c, run);
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
      RRect.fromRectAndRadius(rect, const Radius.circular(25)),
      Paint()
        ..color = const Color(0xFFFFD169)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  void _pot(Canvas c, KitchenRun run, int index) {
    final pot = run.pots[index];
    final rect = CounterLayout.pot(index);
    if (run.guide == Guide.pot && pot.phase == PotPhase.ready) {
      _halo(c, rect);
    }
    final ready = pot.phase == PotPhase.ready;
    final bob = ready && !kitchen.reducedMotion
        ? math.sin(run.now / 100) * 2
        : 0.0;
    art.item(c, pot.phase.index, rect.shift(Offset(0, bob)));
    if (pot.phase == PotPhase.cooking || ready) {
      final duration = ready ? 6000 : run.cookMs;
      final left = ((pot.deadline - run.now) / duration).clamp(0.0, 1.0);
      final bar = Rect.fromLTWH(
        rect.left + 36,
        rect.bottom - 5,
        rect.width - 72,
        9,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(5)),
        _paint..color = const Color(0xFF302B27),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bar.left,
            bar.top,
            bar.width * (ready ? left : 1 - left),
            bar.height,
          ),
          const Radius.circular(5),
        ),
        _paint
          ..color = ready ? const Color(0xFFFFD366) : const Color(0xFF76D8BD),
      );
      if (!kitchen.reducedMotion) {
        for (var i = 0; i < 3; i++) {
          final t = ((run.now + i * 350) % 1050) / 1050;
          c.drawCircle(
            Offset(
              rect.center.dx + (i - 1) * 16 + math.sin(t * 6) * 6,
              rect.top + 35 - t * 34,
            ),
            4 + t * 5,
            _paint..color = Color.fromRGBO(255, 241, 205, (1 - t) * .45),
          );
        }
      }
    }
  }

  void _customer(Canvas c, KitchenRun run, Customer guest) {
    final x = CounterLayout.guestX(guest.slot, run.shift.slots);
    final ratio = ((guest.expires - run.now) / run.shift.patienceMs).clamp(
      0.0,
      1.0,
    );
    final entrance = kitchen.reducedMotion
        ? 0.0
        : (1 - ((run.now - guest.arrived) / 270).clamp(0.0, 1.0)) * 25;
    art.guest(
      c,
      guest.id,
      ratio < .3 && run.guide == Guide.done ? 1 : 0,
      Rect.fromLTWH(x - 124 + entrance, 184, 248, 245),
    );
    final ticket = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, 154), width: 148, height: 78),
      const Radius.circular(20),
    );
    c.drawRRect(ticket, _paint..color = const Color(0xFFFFECC9));
    art.dish(c, run.shift.product, {}, Rect.fromLTWH(x - 68, 122, 76, 61));
    var j = 0;
    for (final topping in guest.toppings) {
      art.item(
        c,
        8 + topping.index,
        Rect.fromLTWH(x + 3 + j * 31, 135, 36, 38),
      );
      j++;
    }
    final bar = Rect.fromLTWH(x - 55, 192, 110, 7);
    c.drawRect(bar, _paint..color = const Color(0xFF42362D));
    c.drawRect(
      Rect.fromLTWH(
        bar.left,
        bar.top,
        bar.width * (run.guide == Guide.done ? ratio : 1),
        7,
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
  void _departure(Canvas c, KitchenRun run) {
    final age = run.now - _effectAt;
    if (!_served(run) ||
        age < 0 ||
        age > 650 ||
        run.servedSlot == null ||
        run.customers[run.servedSlot!] != null) {
      return;
    }
    final x = CounterLayout.guestX(run.servedSlot!, run.shift.slots);
    final dx = kitchen.reducedMotion ? 0.0 : math.max(0, age - 300) * .22;
    art.guest(
      c,
      run.servedCustomerId!,
      age < 350 ? 2 : 3,
      Rect.fromLTWH(x - 124 + dx, 184, 248, 245),
    );
  }

  void _serving(Canvas c, KitchenRun run) {
    final age = run.now - _effectAt;
    if (kitchen.reducedMotion ||
        !_served(run) ||
        age > 420 ||
        run.servedSlot == null) {
      return;
    }
    final t = (age / 420).clamp(0.0, 1.0);
    final start = CounterLayout.bowl(run.servedBowl!).center;
    final end = Offset(
      CounterLayout.guestX(run.servedSlot!, run.shift.slots),
      315,
    );
    final point =
        Offset.lerp(start, end, t)! - Offset(0, math.sin(t * math.pi) * 55);
    art.dish(
      c,
      run.shift.product,
      {},
      Rect.fromCenter(center: point, width: 130 - t * 36, height: 105 - t * 25),
    );
  }
}
