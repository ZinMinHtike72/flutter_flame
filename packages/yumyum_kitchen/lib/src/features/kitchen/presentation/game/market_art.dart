import "dart:ui";
import "package:flame/cache.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";

class MarketArt {
  final images = Images(prefix: "packages/yumyum_kitchen/assets/images/");
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  Future<void> load() async {
    await images.loadAll([
      "market.webp",
      "counter.webp",
      "awning.webp",
      "equipment.webp",
      "people.webp",
      ...NoodleProduct.values.map((p) => "${p.key}.png"),
    ]);
  }

  void draw(
    Canvas canvas,
    String file,
    Rect dst, {
    int cols = 1,
    int rows = 1,
    int cell = 0,
  }) {
    final image = images.fromCache(file);
    final w = image.width / cols;
    final h = image.height / rows;
    final src = Rect.fromLTWH((cell % cols) * w, (cell ~/ cols) * h, w, h);
    canvas.drawImageRect(image, src, dst, _paint);
  }

  void item(Canvas c, int cell, Rect dst) =>
      draw(c, "equipment.webp", dst, cols: 4, rows: 3, cell: cell);
  void guest(Canvas c, int id, int pose, Rect dst) =>
      draw(c, "people.webp", dst, cols: 6, rows: 4, cell: pose * 6 + id % 6);
  void dish(Canvas c, NoodleProduct product, Set<Garnish>? toppings, Rect dst) {
    item(c, toppings == null ? 4 : 5 + product.index, dst);
    if (toppings == null) {
      return;
    }
    for (final topping in toppings) {
      final position = Offset(
        dst.left + dst.width * (.35 + topping.index * .15),
        dst.top + dst.height * .4,
      );
      item(
        c,
        8 + topping.index,
        Rect.fromCenter(
          center: position,
          width: dst.width * .34,
          height: dst.height * .32,
        ),
      );
    }
  }
}
