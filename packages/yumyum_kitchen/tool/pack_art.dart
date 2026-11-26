// Packs the generated source art in `art/sources/` into WebP atlases plus
// JSON frame maps in `assets/images/`.
//
// Run from `packages/yumyum_kitchen`:
//
//   dart run tool/pack_art.dart
//
// Needs `cwebp` on PATH (macOS: `brew install webp`). Each cell of a source
// sheet is scaled, trimmed to its visible pixels and shelf-packed. The JSON
// keeps the trimmed rect's offset inside the scaled cell (`ox`, `oy`, `cw`,
// `ch`), so the game can draw every frame exactly where the full cell would
// have been: pots stay on their burner and feet stay on their baseline.
import "dart:convert";
import "dart:io";
import "dart:math" as math;

import "package:image/image.dart" as img;

/// One source sheet cut into equal cells.
class Sheet {
  const Sheet(
    this.path,
    this.columns,
    this.rows,
    this.names, {
    this.scale = .5,
    this.glassTint = const {},
  });

  final String path;
  final int columns;
  final int rows;

  /// Frame name per cell, row by row; null skips a cell.
  final List<String?> names;
  final double scale;

  /// Frames whose clear centre gets a faint glass tint.
  final Set<String> glassTint;
}

/// One output atlas.
class Atlas {
  const Atlas(this.output, this.sheets);

  /// Output path without extension, relative to the package root.
  final String output;
  final List<Sheet> sheets;
}

const _customers = ["teen", "flower", "uncle", "phone", "grandma", "rider"];

List<String> _customerFrames() => [
  for (var i = 0; i < 8; i++) "walk_$i",
  for (var i = 0; i < 4; i++) "idle_$i",
  for (var i = 0; i < 4; i++) "impatient_$i",
  for (var i = 0; i < 4; i++) "happy_$i",
  for (var i = 0; i < 4; i++) "annoyed_$i",
  for (var i = 0; i < 8; i++) "away_$i",
];

final atlases = [
  const Atlas("assets/images/pots", [
    Sheet("art/sources/pot_bodies.png", 4, 1, [
      "pot_empty",
      "pot_cooking",
      "pot_ready",
      "pot_burnt",
    ]),
    Sheet(
      "art/sources/pot_lids.png",
      2,
      1,
      ["lid_glass", "lid_enamel"],
      glassTint: {"lid_glass"},
    ),
    Sheet("art/sources/boil_surface.png", 4, 1, [
      "boil_0",
      "boil_1",
      "boil_2",
      "boil_3",
    ]),
  ]),
  Atlas("assets/images/smoke", [
    Sheet("art/sources/steam_puffs.png", 4, 2, [
      for (var i = 0; i < 8; i++) "steam_$i",
    ]),
    Sheet("art/sources/smoke_puffs.png", 4, 1, [
      for (var i = 0; i < 4; i++) "smoke_$i",
    ]),
  ]),
  for (final customer in _customers)
    Atlas("assets/images/customers/$customer", [
      Sheet(
        "art/sources/customers/customer_${customer}_anim.png",
        8,
        4,
        _customerFrames(),
        scale: .55,
      ),
    ]),
];

class _Frame {
  _Frame(this.name, this.image, this.ox, this.oy, this.cw, this.ch);
  final String name;
  final img.Image image;
  final int ox;
  final int oy;
  final int cw;
  final int ch;
  int x = 0;
  int y = 0;
}

/// Alpha above this counts as visible when trimming (drops faint haze).
const _alphaFloor = 6;
const _padding = 2;

/// Widest atlas tried; every target GPU handles 4096 px textures.
const _maxWidth = 4096;

Future<void> main() async {
  var decodedBytes = 0;
  for (final atlas in atlases) {
    final frames = <_Frame>[];
    for (final sheet in atlas.sheets) {
      frames.addAll(_cut(sheet));
    }
    final (width, height) = _pack(frames);
    final canvas = img.Image(width: width, height: height, numChannels: 4);
    for (final f in frames) {
      img.compositeImage(
        canvas,
        f.image,
        dstX: f.x,
        dstY: f.y,
        blend: img.BlendMode.direct,
      );
    }
    final png = File("${atlas.output}.png")..parent.createSync(recursive: true);
    png.writeAsBytesSync(img.encodePng(canvas));
    final webp = "${atlas.output}.webp";
    final result = Process.runSync("cwebp", [
      "-quiet",
      "-q",
      "88",
      "-alpha_q",
      "100",
      "-exact",
      png.path,
      "-o",
      webp,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(1);
    }
    png.deleteSync();
    final name = webp.split("/").last;
    File("${atlas.output}.json").writeAsStringSync(
      const JsonEncoder.withIndent("  ").convert({
        "image": name,
        "width": width,
        "height": height,
        "frames": {
          for (final f in frames)
            f.name: {
              "x": f.x,
              "y": f.y,
              "w": f.image.width,
              "h": f.image.height,
              "ox": f.ox,
              "oy": f.oy,
              "cw": f.cw,
              "ch": f.ch,
            },
        },
      }),
    );
    final bytes = width * height * 4;
    decodedBytes += bytes;
    stdout.writeln(
      "${atlas.output}.webp  ${width}x$height  "
      "${(File(webp).lengthSync() / 1024).round()} KB on disk, "
      "${(bytes / 1048576).toStringAsFixed(1)} MB decoded",
    );
  }
  stdout.writeln(
    "total decoded ${(decodedBytes / 1048576).toStringAsFixed(1)} MB",
  );
}

List<_Frame> _cut(Sheet sheet) {
  final source = img.decodePng(File(sheet.path).readAsBytesSync())!;
  final cellW = source.width ~/ sheet.columns;
  final cellH = source.height ~/ sheet.rows;
  final cw = (cellW * sheet.scale).round();
  final ch = (cellH * sheet.scale).round();
  final frames = <_Frame>[];
  for (var i = 0; i < sheet.columns * sheet.rows; i++) {
    final name = sheet.names[i];
    if (name == null) {
      continue;
    }
    final cell = img.copyCrop(
      source,
      x: (i % sheet.columns) * cellW,
      y: (i ~/ sheet.columns) * cellH,
      width: cellW,
      height: cellH,
    );
    final scaled = img.copyResize(
      cell,
      width: cw,
      height: ch,
      interpolation: img.Interpolation.average,
    );
    if (sheet.glassTint.contains(name)) {
      _tintGlass(scaled);
    }
    final box = _visibleBox(scaled);
    frames.add(
      _Frame(
        name,
        img.copyCrop(
          scaled,
          x: box.$1,
          y: box.$2,
          width: box.$3,
          height: box.$4,
        ),
        box.$1,
        box.$2,
        cw,
        ch,
      ),
    );
  }
  return frames;
}

/// (x, y, width, height) of visible pixels plus a 1 px margin.
(int, int, int, int) _visibleBox(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (final p in image) {
    if (p.a > _alphaFloor) {
      left = math.min(left, p.x);
      right = math.max(right, p.x);
      top = math.min(top, p.y);
      bottom = math.max(bottom, p.y);
    }
  }
  if (right < 0) {
    return (0, 0, 1, 1);
  }
  left = math.max(0, left - 1);
  top = math.max(0, top - 1);
  right = math.min(image.width - 1, right + 1);
  bottom = math.min(image.height - 1, bottom + 1);
  return (left, top, right - left + 1, bottom - top + 1);
}

/// Fills the clear centre of a glass lid with a faint cool tint so it reads
/// as glass over the pot instead of an empty hole. Keeps rim and knob.
void _tintGlass(img.Image lid) {
  final box = _visibleBox(lid);
  final cx = box.$1 + box.$3 / 2;
  final rx = box.$3 / 2 * .95;
  // The rim ellipse sits in the lower part of the lid; the dome rises above.
  final cy = box.$2 + box.$4 * .64;
  final ry = box.$4 * .34;
  for (final p in lid) {
    final dx = (p.x - cx) / rx;
    final dy = (p.y - cy) / ry;
    final inside = dx * dx + dy * dy <= 1;
    if (!inside || p.a >= 60) {
      continue;
    }
    // Brighter towards the upper left, like the lighting on the pots.
    final shine = (1 - (dx + dy + 2) / 4).clamp(0.0, 1.0);
    final alpha = 46 + (shine * 38).round();
    final mix = p.a / 60;
    p
      ..r = (p.r * mix + 226 * (1 - mix)).round()
      ..g = (p.g * mix + 238 * (1 - mix)).round()
      ..b = (p.b * mix + 244 * (1 - mix)).round()
      ..a = math.max(p.a.toInt(), alpha);
  }
}

/// Shelf packing, tallest first. Tries atlas widths from 1024 to
/// [_maxWidth] and keeps the one with the smallest area.
(int, int) _pack(List<_Frame> frames) {
  (int, int)? best;
  int? bestWidth;
  for (var limit = 1024; limit <= _maxWidth; limit += 64) {
    final size = _shelves(frames, limit);
    if (size == null) {
      continue;
    }
    if (best == null || size.$1 * size.$2 < best.$1 * best.$2) {
      best = size;
      bestWidth = limit;
    }
  }
  return _shelves(frames, bestWidth!)!;
}

/// Places [frames] on shelves no wider than [limit]; null if one frame is
/// wider than [limit] or the result is taller than [_maxWidth].
(int, int)? _shelves(List<_Frame> frames, int limit) {
  final order = [...frames]
    ..sort((a, b) => b.image.height.compareTo(a.image.height));
  var x = 0;
  var y = 0;
  var rowHeight = 0;
  var width = 0;
  for (final f in order) {
    if (f.image.width > limit) {
      return null;
    }
    if (x + f.image.width > limit) {
      x = 0;
      y += rowHeight + _padding;
      rowHeight = 0;
    }
    f
      ..x = x
      ..y = y;
    x += f.image.width + _padding;
    rowHeight = math.max(rowHeight, f.image.height);
    width = math.max(width, x);
  }
  final height = y + rowHeight;
  return height > _maxWidth ? null : (width, height);
}
