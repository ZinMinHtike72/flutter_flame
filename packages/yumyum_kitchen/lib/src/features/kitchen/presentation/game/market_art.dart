import "dart:ui";

import "package:flame/cache.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";

/// One preloaded image region, drawable without building rects per frame.
class ArtSprite {
  ArtSprite(this.image, this.source)
    : _local = Rect.fromLTWH(0, 0, source.width, source.height);

  final Image image;
  final Rect source;
  final Rect _local;

  double get aspect => source.width / source.height;

  /// Draws into a precomputed [dst].
  void drawRect(Canvas canvas, Rect dst, Paint paint) =>
      canvas.drawImageRect(image, source, dst, paint);

  /// Draws into the box at ([left], [top]) of [width] × [height] through a
  /// canvas transform, so no [Rect] is created.
  void drawAt(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(left, top)
      ..scale(width / _local.width, height / _local.height)
      ..drawImageRect(image, source, _local, paint)
      ..restore();
  }
}

/// The market backdrop, counter, product packs and the equipment sheet
/// (4×3 cells: pots 0–3, empty bowl 4, dishes 5–7, garnishes 8–10,
/// lantern 11), all preloaded with their source rects precomputed.
class MarketArt {
  final images = Images(prefix: "packages/yumyum_kitchen/assets/images/");
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  late final ArtSprite market;
  late final ArtSprite awning;
  late final ArtSprite counter;

  /// Product packs, by [NoodleProduct.index].
  late final List<ArtSprite> packs;
  late final List<ArtSprite> _equipment;

  static const emptyBowl = 4;
  static const lantern = 11;
  static int dishOf(NoodleProduct product) => 5 + product.index;
  static int garnishOf(Garnish garnish) => 8 + garnish.index;

  Paint get paint => _paint;

  Future<void> load() async {
    await images.loadAll([
      "market.webp",
      "counter.webp",
      "awning.webp",
      "equipment.webp",
      for (final p in NoodleProduct.values) "${p.key}.png",
    ]);
    ArtSprite whole(String file) {
      final image = images.fromCache(file);
      return ArtSprite(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      );
    }

    market = whole("market.webp");
    awning = whole("awning.webp");
    counter = whole("counter.webp");
    packs = [for (final p in NoodleProduct.values) whole("${p.key}.png")];
    final sheet = images.fromCache("equipment.webp");
    final w = sheet.width / 4;
    final h = sheet.height / 3;
    _equipment = [
      for (var cell = 0; cell < 12; cell++)
        ArtSprite(sheet, Rect.fromLTWH((cell % 4) * w, (cell ~/ 4) * h, w, h)),
    ];
  }

  /// Draws equipment [cell] into the given box.
  void item(
    Canvas c,
    int cell,
    double left,
    double top,
    double width,
    double height,
  ) => _equipment[cell].drawAt(c, left, top, width, height, _paint);

  /// Draws equipment [cell] into a precomputed [dst].
  void itemRect(Canvas c, int cell, Rect dst) =>
      _equipment[cell].drawRect(c, dst, _paint);

  /// Draws a bowl: empty when [toppings] is null, else [product]'s dish with
  /// each topping placed by its kind (so order never changes the picture).
  void dish(
    Canvas c,
    NoodleProduct product,
    Set<Garnish>? toppings,
    double left,
    double top,
    double width,
    double height,
  ) {
    item(
      c,
      toppings == null ? emptyBowl : dishOf(product),
      left,
      top,
      width,
      height,
    );
    if (toppings == null) {
      return;
    }
    const kinds = Garnish.values;
    for (var i = 0; i < kinds.length; i++) {
      if (!toppings.contains(kinds[i])) {
        continue;
      }
      final w = width * .34;
      final h = height * .32;
      item(
        c,
        garnishOf(kinds[i]),
        left + width * (.35 + i * .15) - w / 2,
        top + height * .4 - h / 2,
        w,
        h,
      );
    }
  }
}
