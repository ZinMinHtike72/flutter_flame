import "dart:convert";
import "dart:ui";

/// One packed frame: where it is in the atlas and where it sits inside its
/// original (scaled) cell.
class AtlasFrame {
  const AtlasFrame(this.source, this.inCell, this.cellWidth, this.cellHeight);

  /// Pixels in the atlas image.
  final Rect source;

  /// The trimmed frame's rect inside its cell, in cell pixels.
  final Rect inCell;
  final double cellWidth;
  final double cellHeight;
}

/// A WebP atlas and its JSON frame map, written by `tool/pack_art.dart`.
///
/// Frames are drawn into the rect their *whole cell* should cover, so
/// trimming never shifts art: pots stay on their burner and feet stay on
/// their baseline. Lookups are by integer id; drawing uses a canvas
/// transform and precomputed rects, so it allocates nothing.
class SpriteAtlas {
  SpriteAtlas._(this.image, this._frames, this._ids);

  /// Parses the packer's JSON for [image].
  factory SpriteAtlas.fromJson(Image image, String json) {
    final data = jsonDecode(json) as Map<String, Object?>;
    final frames = <AtlasFrame>[];
    final ids = <String, int>{};
    for (final MapEntry(key: name, value: raw)
        in (data["frames"]! as Map<String, Object?>).entries) {
      final f = raw! as Map<String, Object?>;
      double v(String key) => (f[key]! as num).toDouble();
      ids[name] = frames.length;
      frames.add(
        AtlasFrame(
          Rect.fromLTWH(v("x"), v("y"), v("w"), v("h")),
          Rect.fromLTWH(v("ox"), v("oy"), v("w"), v("h")),
          v("cw"),
          v("ch"),
        ),
      );
    }
    return SpriteAtlas._(image, frames, ids);
  }

  final Image image;
  final List<AtlasFrame> _frames;
  final Map<String, int> _ids;

  int get length => _frames.length;

  /// Id of [name]; throws if the atlas has no such frame.
  int id(String name) {
    final id = _ids[name];
    if (id == null) {
      throw ArgumentError.value(name, "name", "not in atlas");
    }
    return id;
  }

  bool has(String name) => _ids.containsKey(name);

  AtlasFrame frame(int id) => _frames[id];

  /// Draws frame [id] so that its whole cell covers [cell].
  void draw(Canvas canvas, int id, Rect cell, Paint paint) =>
      drawAt(canvas, id, cell.left, cell.top, cell.width, cell.height, paint);

  /// Draws frame [id] with its whole cell covering the box at ([left],
  /// [top]) of [width] × [height], without building a [Rect].
  void drawAt(
    Canvas canvas,
    int id,
    double left,
    double top,
    double width,
    double height,
    Paint paint,
  ) {
    final f = _frames[id];
    canvas
      ..save()
      ..translate(left, top)
      ..scale(width / f.cellWidth, height / f.cellHeight)
      ..drawImageRect(image, f.source, f.inCell, paint)
      ..restore();
  }
}
