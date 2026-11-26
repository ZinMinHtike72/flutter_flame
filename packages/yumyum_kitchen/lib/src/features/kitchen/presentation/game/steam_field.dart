import "dart:math" as math;
import "dart:typed_data";
import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// Particle budget per pot. The default comes from the startup benchmark.
enum SteamQuality {
  low(4),
  medium(10),
  high(18);

  const SteamQuality(this.perPot);

  /// Most puffs alive above one pot.
  final int perPot;
}

/// Pooled steam and smoke puffs above every pot.
///
/// All state lives in fixed typed arrays sized for the largest tier, and one
/// [Canvas.drawRawAtlas] call draws every puff, so [update] and [render]
/// allocate nothing.
class SteamField {
  SteamField({required this.emitters, int seed = 0x9E3779B9})
    : capacity = emitters * SteamQuality.high.perPot,
      _seed = seed == 0 ? 1 : seed {
    _x = Float32List(capacity);
    _y = Float32List(capacity);
    _vx = Float32List(capacity);
    _vy = Float32List(capacity);
    _age = Float32List(capacity);
    _life = Float32List(capacity);
    _size = Float32List(capacity);
    _owner = Int8List(capacity);
    _smoke = Uint8List(capacity);
    _alivePerPot = Int32List(emitters);
    _spawnDebt = Float32List(emitters);
    transforms = Float32List(capacity * 4);
    rects = Float32List(capacity * 4);
    _frameW = Float32List(capacity)..fillRange(0, capacity, puffSize);
    _frameH = Float32List(capacity)..fillRange(0, capacity, puffSize);
    colors = Int32List(capacity);
    for (var i = 0; i < capacity; i++) {
      rects
        ..[i * 4 + 2] = puffSize
        ..[i * 4 + 3] = puffSize;
    }
  }

  /// Edge of the square puff sprite in pixels.
  static const puffSize = 64.0;

  final int emitters;
  final int capacity;
  int _seed;
  int _alive = 0;

  late final Float32List _x;
  late final Float32List _y;
  late final Float32List _vx;
  late final Float32List _vy;
  late final Float32List _age;
  late final Float32List _life;
  late final Float32List _size;
  late final Int8List _owner;
  late final Uint8List _smoke;
  late final Int32List _alivePerPot;
  late final Float32List _spawnDebt;

  /// Atlas buffers handed to [Canvas.drawRawAtlas]; reused every frame.
  late final Float32List transforms;
  late final Float32List rects;
  late final Float32List _frameW;
  late final Float32List _frameH;

  /// Painted frames (left, top, right, bottom per frame) in the atlas image
  /// passed to [render]; empty until [useTextures], when the baked soft puff
  /// is used instead.
  Float32List _steamFrames = Float32List(0);
  Float32List _smokeFrames = Float32List(0);
  bool get textured => _steamFrames.isNotEmpty;

  /// Painted steam wisps and smoke puffs, from small to large.
  void useTextures(List<Rect> steam, List<Rect> smoke) {
    Float32List pack(List<Rect> frames) => Float32List.fromList([
      for (final r in frames) ...[r.left, r.top, r.right, r.bottom],
    ]);
    _steamFrames = pack(steam);
    _smokeFrames = pack(smoke);
  }

  late final Int32List colors;

  int get alive => _alive;
  int aliveAbove(int pot) => _alivePerPot[pot];

  /// Puffs per second for a pot in [phase].
  static double rate(PotPhase phase) => switch (phase) {
    PotPhase.empty => 0,
    PotPhase.cooking => 7,
    PotPhase.ready => 14,
    PotPhase.burnt => 9,
  };

  double _random() {
    // xorshift32: deterministic, allocation-free.
    var x = _seed;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _seed = x & 0xFFFFFFFF;
    return _seed / 0xFFFFFFFF;
  }

  /// Ages, moves and retires puffs, then emits new ones above each pot.
  /// [mouths] holds each pot's sprite rect; [scale] is the layout scale.
  void update(
    double dt,
    List<Pot> pots,
    List<Rect> mouths,
    SteamQuality quality,
    double scale,
  ) {
    if (dt <= 0) {
      return;
    }
    var i = 0;
    while (i < _alive) {
      _age[i] += dt;
      if (_age[i] >= _life[i]) {
        _alivePerPot[_owner[i]]--;
        _retire(i);
        continue;
      }
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      _vx[i] += math.sin(_age[i] * 4 + i) * 6 * scale * dt;
      i++;
    }
    final count = math.min(emitters, math.min(pots.length, mouths.length));
    for (var pot = 0; pot < count; pot++) {
      final phase = pots[pot].phase;
      final perSecond = rate(phase) * quality.perPot / SteamQuality.high.perPot;
      if (perSecond <= 0) {
        _spawnDebt[pot] = 0;
        continue;
      }
      _spawnDebt[pot] += perSecond * dt;
      while (_spawnDebt[pot] >= 1) {
        _spawnDebt[pot] -= 1;
        if (_alivePerPot[pot] >= quality.perPot || _alive >= capacity) {
          continue;
        }
        _emit(pot, mouths[pot], phase, scale);
      }
    }
  }

  void _emit(int pot, Rect mouth, PotPhase phase, double scale) {
    final i = _alive++;
    _alivePerPot[pot]++;
    final ready = phase == PotPhase.ready;
    _owner[i] = pot;
    _smoke[i] = phase == PotPhase.burnt ? 1 : 0;
    _x[i] = mouth.left + mouth.width * (.3 + _random() * .4);
    // Pot rim centre (painted pots: 0.285 of the cell height).
    _y[i] = mouth.top + mouth.height * .27;
    _vx[i] = (_random() - .5) * 14 * scale;
    _vy[i] = -(ready ? 60 : 42) * (.8 + _random() * .4) * scale;
    _age[i] = 0;
    _life[i] = ready ? 1.1 + _random() * .5 : .8 + _random() * .5;
    _size[i] = (ready ? 46 : 34) * (.85 + _random() * .3) * scale;
    final o = i * 4;
    if (!textured) {
      rects
        ..[o] = 0
        ..[o + 1] = 0
        ..[o + 2] = puffSize
        ..[o + 3] = puffSize;
      _frameW[i] = puffSize;
      _frameH[i] = puffSize;
      return;
    }
    // Painted wisps are tall: draw them taller than the soft puff. Ready
    // pots use the bigger half of the steam set; burnt pots use smoke.
    _size[i] *= 1.9;
    final frames = _smoke[i] == 1 ? _smokeFrames : _steamFrames;
    final count = frames.length ~/ 4;
    final first = _smoke[i] == 0 && ready ? count ~/ 2 : 0;
    final span = _smoke[i] == 0 ? count ~/ 2 : count;
    final f = (first + (_random() * span).floor().clamp(0, span - 1)) * 4;
    rects
      ..[o] = frames[f]
      ..[o + 1] = frames[f + 1]
      ..[o + 2] = frames[f + 2]
      ..[o + 3] = frames[f + 3];
    _frameW[i] = frames[f + 2] - frames[f];
    _frameH[i] = frames[f + 3] - frames[f + 1];
  }

  void _retire(int i) {
    final last = --_alive;
    if (i == last) {
      return;
    }
    _x[i] = _x[last];
    _y[i] = _y[last];
    _vx[i] = _vx[last];
    _vy[i] = _vy[last];
    _age[i] = _age[last];
    _life[i] = _life[last];
    _size[i] = _size[last];
    _owner[i] = _owner[last];
    _smoke[i] = _smoke[last];
    _frameW[i] = _frameW[last];
    _frameH[i] = _frameH[last];
    final o = i * 4;
    final l = last * 4;
    rects
      ..[o] = rects[l]
      ..[o + 1] = rects[l + 1]
      ..[o + 2] = rects[l + 2]
      ..[o + 3] = rects[l + 3];
  }

  /// Removes every puff (new shift, reduced motion turned on).
  void clear() {
    _alive = 0;
    _alivePerPot.fillRange(0, emitters, 0);
    _spawnDebt.fillRange(0, emitters, 0);
  }

  /// Slots written by the previous render that may now be dead.
  int _drawn = 0;

  /// Draws every live puff in one atlas call over the full, reused buffers;
  /// dead slots are zero-scale and transparent. [image] is the painted
  /// atlas after [useTextures], else the baked puff.
  void render(Canvas canvas, Image image, Paint paint) {
    if (_alive == 0 && _drawn == 0) {
      return;
    }
    for (var i = 0; i < _alive; i++) {
      final t = _age[i] / _life[i];
      final size = _size[i] * (1 + t * (textured ? .8 : 1.6));
      final s = size / _frameH[i];
      final o = i * 4;
      transforms
        ..[o] = s
        ..[o + 1] = 0
        ..[o + 2] = _x[i] - s * _frameW[i] / 2
        // Painted wisps rise from their base; the soft puff is centred.
        ..[o + 3] = _y[i] - size * (textured ? .9 : .5);
      final fade = t < .15 ? t / .15 : 1 - (t - .15) / .85;
      final alpha = (fade * (_smoke[i] == 1 ? 200 : 185)).round().clamp(0, 255);
      // Painted frames carry their own colour; the soft puff is tinted.
      colors[i] = textured
          ? (alpha << 24) | 0xFFFFFF
          : _smoke[i] == 1
          ? (alpha << 24) | 0x4A423C
          : (alpha << 24) | 0xFFF6E6;
    }
    for (var i = _alive; i < _drawn; i++) {
      transforms[i * 4] = 0;
      colors[i] = 0;
    }
    _drawn = _alive;
    if (_alive == 0) {
      return;
    }
    canvas.drawRawAtlas(
      image,
      transforms,
      rects,
      colors,
      BlendMode.modulate,
      null,
      paint,
    );
  }

  /// A soft white puff, rasterized once at load.
  static Future<Image> bakePuff() async {
    final recorder = PictureRecorder();
    const center = Offset(puffSize / 2, puffSize / 2);
    Canvas(recorder).drawCircle(
      center,
      puffSize / 2,
      Paint()
        ..shader = Gradient.radial(
          center,
          puffSize / 2,
          const [Color(0xFFFFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
          const [0, .45, 1],
        ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(puffSize.toInt(), puffSize.toInt());
    picture.dispose();
    return image;
  }
}
