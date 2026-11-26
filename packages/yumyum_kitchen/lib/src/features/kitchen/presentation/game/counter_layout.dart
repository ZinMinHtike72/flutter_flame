import "dart:ui";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

class CounterTarget {
  const CounterTarget(this.station, this.index, this.bounds);
  final Station station;
  final int index;
  final Rect bounds;
}

abstract final class CounterLayout {
  static const size = Size(1280, 720);
  static const horizon = 421.0;
  static Rect pot(int i) => Rect.fromLTWH(240 + i * 185.0, 432, 178, 160);
  static Rect bowl(int i) => Rect.fromLTWH(704 + i * 227.0, 427, 210, 166);
  static Rect garnish(int i) => Rect.fromLTWH(360 + i * 190.0, 600, 170, 108);
  static const pack = Rect.fromLTWH(50, 447, 165, 148);
  static Rect discard(int i) => Rect.fromLTWH(bowl(i).right - 20, 443, 92, 94);
  static double guestX(int slot, int slots) =>
      640 + (slot - (slots - 1) / 2) * 261;
  static Iterable<CounterTarget> targets(KitchenRun run) sync* {
    final rejected = run.discardBowl;
    if (rejected != null) {
      yield CounterTarget(Station.discard, rejected, discard(rejected));
    }
    yield const CounterTarget(Station.pack, 0, pack);
    for (var i = 0; i < run.pots.length; i++) {
      yield CounterTarget(Station.pot, i, pot(i));
    }
    for (var i = 0; i < 2; i++) {
      yield CounterTarget(Station.bowl, i, bowl(i));
    }
    for (var i = 0; i < run.shift.garnishCount; i++) {
      yield CounterTarget(Station.garnish, i, garnish(i));
    }
  }
}
