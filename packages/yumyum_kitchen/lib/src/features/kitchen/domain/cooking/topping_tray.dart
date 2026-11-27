import "package:yumyum_kitchen/src/features/kitchen/domain/cooking/food.dart";

/// What [ToppingTray.take] handed out:
/// - [perfect]: from a batch taken out in its perfect window, still hot
///   (a tip bonus);
/// - [fresh]: good;
/// - [cold]: a hot topping left too long (lowers the tip; no bonus).
enum Portion { none, fresh, perfect, cold }

/// A steel tray of one prepared topping.
///
/// Portions are used oldest first. A hot topping (beef, egg, shrimp, fish
/// balls) goes cold [freshMs] after it was added; a cold portion can still be
/// used but lowers the tip. Condiment jars ([Topping.unlimited]) never run
/// out. Each portion's time sits in a fixed ring buffer, so adding and taking
/// allocate nothing.
class ToppingTray {
  ToppingTray(
    this.topping, {
    this.capacity = defaultCapacity,
    this.freshMs = defaultFreshMs,
  }) : _addedAt = List<int>.filled(capacity, 0),
       _perfect = List<bool>.filled(capacity, false);

  static const defaultCapacity = 8;

  /// Hot toppings stay fresh this long; the heat-lamp upgrade raises it.
  static const defaultFreshMs = 25000;

  final Topping topping;
  final int capacity;
  final int freshMs;
  final List<int> _addedAt;
  final List<bool> _perfect;
  int _head = 0;
  int _count = 0;

  /// Portions left; a jar always reports [capacity].
  int get count => topping.unlimited ? capacity : _count;

  bool get isEmpty => count == 0;

  /// How many more portions fit; 0 for a jar.
  int get room => topping.unlimited ? 0 : capacity - _count;

  /// Adds up to [portions] made at [now]; returns how many fit. [perfect]
  /// marks a batch taken out in its perfect window.
  int add(int portions, int now, {bool perfect = false}) {
    final added = portions < room ? portions : room;
    for (var i = 0; i < added; i++) {
      final slot = (_head + _count) % capacity;
      _addedAt[slot] = now;
      _perfect[slot] = perfect;
      _count++;
    }
    return added;
  }

  /// Hands out the oldest portion.
  Portion take(int now) {
    if (topping.unlimited) {
      return Portion.fresh;
    }
    if (_count == 0) {
      return Portion.none;
    }
    final at = _addedAt[_head];
    final perfect = _perfect[_head];
    _head = (_head + 1) % capacity;
    _count--;
    return _cold(at, now)
        ? Portion.cold
        : perfect
        ? Portion.perfect
        : Portion.fresh;
  }

  /// Whether the next portion [take] hands out is cold (draw the tray grey).
  bool nextIsCold(int now) => _count > 0 && _cold(_addedAt[_head], now);

  /// How many portions are cold at [now].
  int coldCount(int now) {
    var cold = 0;
    for (var i = 0; i < _count; i++) {
      if (_cold(_addedAt[(_head + i) % capacity], now)) {
        cold++;
      }
    }
    return cold;
  }

  bool _cold(int addedAt, int now) => topping.hot && now - addedAt >= freshMs;
}
