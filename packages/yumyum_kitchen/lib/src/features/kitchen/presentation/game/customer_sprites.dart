import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/presentation/game/customer_cast.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/sprite_atlas.dart";

/// The six full-body customers, one packed atlas each
/// (`assets/images/customers/<name>.webp`, from `art/sources/customers/`).
///
/// Frames are placed by the feet: every source cell is 384×768 with the
/// soles on a baseline 726 px down, and an adult stands 630 px tall, so a
/// customer drawn at height `H` keeps the same feet position and relative
/// size (the teen and grandmother stay a little shorter) in every frame.
class CustomerSprites {
  CustomerSprites(this._atlases)
    : _ids = [
        for (final atlas in _atlases)
          [
            for (final clip in CustomerClip.values)
              [
                for (var f = 0; f < clip.frames; f++)
                  atlas.id("${clip.name}_$f"),
              ],
          ],
      ];

  /// Atlas names in look order (`CustomerActor.look`).
  static const names = ["teen", "flower", "uncle", "phone", "grandma", "rider"];

  /// Feet baseline as a fraction of the cell height.
  static const baseline = 726 / 768;

  /// An adult's height as a fraction of the cell height.
  static const adultHeight = 630 / 768;

  /// Cell width / height.
  static const cellAspect = 384 / 768;

  final List<SpriteAtlas> _atlases;
  final List<List<List<int>>> _ids;

  int get looks => _atlases.length;

  /// Draws [look]'s [clip] frame with the feet at ([feetX], [feetY]) for an
  /// adult [height]; [flip] mirrors it to face left.
  void draw(
    Canvas canvas,
    int look,
    CustomerClip clip,
    int frame,
    double feetX,
    double feetY,
    double height,
    Paint paint, {
    bool flip = false,
  }) {
    final cellHeight = height / adultHeight;
    final cellWidth = cellHeight * cellAspect;
    final left = feetX - cellWidth / 2;
    final top = feetY - baseline * cellHeight;
    final atlas = _atlases[look % _atlases.length];
    final id = _ids[look % _atlases.length][clip.index][frame % clip.frames];
    if (!flip) {
      atlas.drawAt(canvas, id, left, top, cellWidth, cellHeight, paint);
      return;
    }
    canvas
      ..save()
      ..translate(feetX, 0)
      ..scale(-1, 1)
      ..translate(-feetX, 0);
    atlas.drawAt(canvas, id, left, top, cellWidth, cellHeight, paint);
    canvas.restore();
  }
}
