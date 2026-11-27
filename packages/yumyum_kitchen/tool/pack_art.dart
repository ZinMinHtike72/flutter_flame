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
  ..._restaurantAtlases,
];

const _restaurant = "art/sources/restaurant";

/// Kitchen stations and dining props share one scale (.3 of a 1024 cell) so
/// pots, bowls and trays keep the relative sizes they were painted at.
final _restaurantAtlases = <Atlas>[
  Atlas("assets/images/restaurant/kitchen", [
    Sheet("$_restaurant/stove_pot.png", 4, 2, [
      "stove_empty",
      "stove_water",
      "stove_boil",
      "stove_block",
      "stove_soften",
      "stove_ready",
      "stove_soggy",
      "stove_fishballs",
    ], scale: .3),
    Sheet("$_restaurant/kettle.png", 2, 1, [
      "kettle_idle",
      "kettle_pour",
    ], scale: .3),
    Sheet("$_restaurant/broths.png", 4, 1, [
      "broth_chicken",
      "broth_tomyum",
      "sauce_mala",
      "ladle_pour",
    ], scale: .3),
    Sheet("$_restaurant/grill.png", 1, 1, ["grill"], scale: .3),
    Sheet("$_restaurant/beef.png", 4, 1, [
      "beef_raw",
      "beef_seared",
      "beef_cooked",
      "beef_charred",
    ], scale: .3),
    Sheet("$_restaurant/egg_boiler.png", 4, 1, [
      "eggpot_boil",
      "eggpot_eggs",
      "eggpot_cracked",
      "egg_halves",
    ], scale: .3),
    Sheet("$_restaurant/fryer.png", 4, 1, [
      "fryer_oil",
      "fryer_frying",
      "fryer_golden",
      "fryer_burnt",
    ], scale: .3),
    Sheet("$_restaurant/cutting_board.png", 4, 2, [
      "board_empty",
      "board_onion",
      "board_onion_half",
      "board_onion_chopped",
      "board_lime",
      "board_lime_wedges",
      "board_coriander",
      "board_chilli",
    ], scale: .3),
    Sheet("$_restaurant/trays.png", 4, 4, [
      "tray_onion",
      "tray_coriander",
      "tray_chilli",
      "tray_lime",
      "tray_egg",
      "tray_beef",
      "tray_shrimp",
      "tray_fishball",
      "jar_garlic",
      "jar_chilli_oil",
      "source_beef",
      "source_shrimp",
      "source_eggs",
      "source_noodles",
      "tray_onion_low",
      "tray_beef_cold",
    ], scale: .4),
  ]),
  Atlas("assets/images/restaurant/dining", [
    Sheet("$_restaurant/tables.png", 4, 1, [
      "table",
      "table_tea",
      "table_dirty",
      "table_coins",
    ], scale: .3),
    Sheet("$_restaurant/bowls.png", 4, 2, [
      "bowl_empty",
      "bowl_noodles",
      "bowl_chicken",
      "bowl_tomyum",
      "bowl_mala",
      "bowl_dirty",
      "takeaway_empty",
      "takeaway_soup",
    ], scale: .3),
    // Same cell size and scale as the bowls, so each overlay's offset
    // (ox, oy) lands on the noodles of a filled bowl.
    Sheet("$_restaurant/bowl_toppings.png", 4, 2, [
      "top_beef",
      "top_egg",
      "top_shrimp",
      "top_fishball",
      "top_onion",
      "top_coriander",
      "top_chilli",
      "top_lime",
    ], scale: .3),
    Sheet("$_restaurant/takeaway.png", 4, 1, [
      "takeaway_lid",
      "takeaway_bag",
      "takeaway_cup",
      "packing_station",
    ], scale: .3),
    Sheet("$_restaurant/tea.png", 4, 2, [
      "tea_urn",
      "cup_empty",
      "cup_tea",
      "cup_milk_tea",
      "condensed_milk",
      "glass_lemon_tea",
      "glass_ice",
      "green_tea_pour",
    ], scale: .3),
    Sheet("$_restaurant/ticket_icons.png", 6, 3, [
      "icon_noodles",
      "icon_broth_chicken",
      "icon_broth_tomyum",
      "icon_sauce_mala",
      "icon_onion",
      "icon_coriander",
      "icon_chilli",
      "icon_lime",
      "icon_egg",
      "icon_beef",
      "icon_shrimp",
      "icon_fishball",
      "icon_milk_tea",
      "icon_lemon_tea",
      "icon_takeaway",
      "icon_dine_in",
      "icon_delivery",
      "icon_green_tea",
    ]),
  ]),
  Atlas("assets/images/restaurant/waiter", [
    Sheet("$_restaurant/waiter_anim.png", 6, 4, [
      for (var i = 0; i < 6; i++) "walk_tray_$i",
      for (var i = 0; i < 6; i++) "walk_dirty_$i",
      for (var i = 0; i < 3; i++) "place_$i",
      for (var i = 0; i < 3; i++) "pour_$i",
      "idle_0",
      "idle_1",
      "bow_0",
      "bow_1",
      "wipe_0",
      "wipe_1",
    ], scale: .55),
  ]),
  Atlas("assets/images/restaurant/guests", [
    for (final c in _customers)
      Sheet("$_restaurant/customer_${c}_seated.png", 4, 1, [
        "${c}_wait",
        "${c}_eat_0",
        "${c}_eat_1",
        "${c}_happy",
      ], scale: .4),
  ]),
  Atlas("assets/images/restaurant/chef", [
    Sheet("$_restaurant/chef_guide.png", 4, 2, [
      "chef_neutral",
      "chef_smile",
      "chef_point",
      "chef_thumbs",
      "chef_worried",
      "chef_cheer",
      "chef_surprised",
      "chef_wink",
    ], scale: .4),
  ]),
];

/// Opaque backgrounds: scaled to a width, keeping the top share
/// (the counter covers the rest), encoded as WebP.
const _plates = [
  (
    "$_restaurant/restaurant_room.png",
    "assets/images/restaurant/room",
    1920,
    .6,
  ),
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

/// `dart run tool/pack_art.dart [filter...]`: with filters, packs only the
/// outputs whose path contains one of them (for example `restaurant`), so
/// existing atlases are not re-encoded.
Future<void> main(List<String> filters) async {
  bool wanted(String output) => filters.isEmpty || filters.any(output.contains);
  var decodedBytes = 0;
  for (final plate in _plates) {
    if (wanted(plate.$2)) {
      decodedBytes += _packPlate(plate.$1, plate.$2, plate.$3, plate.$4);
    }
  }
  if (wanted(_kitchenPlate)) {
    decodedBytes += _packKitchenPlate();
  }
  for (final atlas in atlases.where((a) => wanted(a.output))) {
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

/// The kitchen counter, taken from the reference keyframe itself so the
/// line looks exactly like it: everything from the counter's top edge
/// (keyframe y 724, design y 362) down. The two painted pots are replaced
/// by the empty steel range strip just right of them (mirror-tiled), so the
/// game can draw its own pots in every cooking state on the bare range.
/// Bowls stay painted: the game's bowls are the same art and cover them.
const _kitchenPlate = "assets/images/restaurant/kitchen_plate";
const _keyframe = "$_restaurant/restaurant_keyframe.png";
const _counterTop = 724;
const _potPatch = (left: 318, right: 936, bottom: 986);
const _rangeStrip = (left: 936, right: 1128);

int _packKitchenPlate() {
  final keyframe = img.decodePng(File(_keyframe).readAsBytesSync())!;
  final plate = img.copyCrop(
    keyframe,
    x: 0,
    y: _counterTop,
    width: keyframe.width,
    height: keyframe.height - _counterTop,
  );
  final strip = _rangeStrip.right - _rangeStrip.left;
  for (var y = _counterTop; y < _potPatch.bottom; y++) {
    for (var x = _potPatch.left; x < _potPatch.right; x++) {
      final k = (x - _potPatch.left) % (2 * strip);
      final sx = k < strip
          ? _rangeStrip.left + k
          : _rangeStrip.right - 1 - (k - strip);
      plate.setPixel(x, y - _counterTop, keyframe.getPixel(sx, y));
    }
  }
  return _writePlate(plate, _kitchenPlate, 1920, 1);
}

/// Writes one opaque background and returns its decoded size in bytes.
int _packPlate(String source, String output, int width, double keep) =>
    _writePlate(
      img.decodePng(File(source).readAsBytesSync())!,
      output,
      width,
      keep,
    );

int _writePlate(img.Image image, String output, int width, double keep) {
  final scaled = img.copyResize(
    image,
    width: width,
    interpolation: img.Interpolation.average,
  );
  final top = img.copyCrop(
    scaled,
    x: 0,
    y: 0,
    width: scaled.width,
    height: (scaled.height * keep).round(),
  );
  final png = File("$output.png")..parent.createSync(recursive: true);
  png.writeAsBytesSync(img.encodePng(top));
  final result = Process.runSync("cwebp", [
    "-quiet",
    "-q",
    "85",
    png.path,
    "-o",
    "$output.webp",
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    exit(1);
  }
  png.deleteSync();
  final bytes = top.width * top.height * 4;
  stdout.writeln(
    "$output.webp  ${top.width}x${top.height}  "
    "${(File("$output.webp").lengthSync() / 1024).round()} KB on disk, "
    "${(bytes / 1048576).toStringAsFixed(1)} MB decoded",
  );
  return bytes;
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
