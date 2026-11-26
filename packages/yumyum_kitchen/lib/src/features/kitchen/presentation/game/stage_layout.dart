import "dart:math" as math;
import "dart:ui";

import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// A tappable element of the action zone, in screen logical pixels.
class CounterTarget {
  const CounterTarget(this.station, this.index, this.bounds);
  final Station station;
  final int index;
  final Rect bounds;
}

/// Screen geometry of a shift: the 1280×720 design canvas scaled with cover
/// fit, the safe stage, the three zones and every hit box.
///
/// All rectangles are in screen logical pixels.
class StageLayout {
  StageLayout._({
    required this.screen,
    required this.scale,
    required this.origin,
    required this.safe,
    required this.action,
    required this.hud,
    required this.tickets,
    required this.pack,
    required this.pots,
    required this.bowls,
    required this.discards,
    required this.garnishes,
  }) : potSprites = [for (final r in pots) fit(r, potAspect, pad: 8)],
       bowlSprites = [for (final r in bowls) fit(r, bowlAspect)],
       garnishSprites = [for (final r in garnishes) fit(r, garnishAspect)];

  /// Lays out a stage for [screen] with system [insets] (left, top, right,
  /// bottom view padding).
  factory StageLayout.compute({
    required Size screen,
    required Rect insets,
    required int pots,
    required int garnishes,
  }) {
    final scale = math.max(
      screen.width / designSize.width,
      screen.height / designSize.height,
    );
    final origin = Offset(
      (screen.width - designSize.width * scale) / 2,
      (screen.height - designSize.height * scale) / 2,
    );
    final safe = Rect.fromLTRB(
      insets.left + edgeMargin,
      insets.top + edgeMargin,
      screen.width - insets.right - edgeMargin,
      screen.height - insets.bottom - edgeMargin,
    );
    final action = Rect.fromLTRB(
      safe.left,
      math.max(safe.top + hudHeight + gap, screen.height * actionStart),
      safe.right,
      safe.bottom,
    );
    final hud = Rect.fromLTWH(safe.left, safe.top, safe.width, hudHeight);
    final tickets = Rect.fromLTRB(
      safe.left,
      hud.bottom + gap,
      safe.right,
      math.max(hud.bottom + gap, action.top - gap),
    );

    final weights = <double>[
      packWeight,
      for (var i = 0; i < pots; i++) potWeight,
      for (var i = 0; i < 2; i++) bowlWeight,
      for (var i = 0; i < garnishes; i++) garnishWeight,
    ];
    final total = weights.fold<double>(0, (sum, w) => sum + w);
    final gaps = gap * (weights.length - 1);
    final unit = math.min((action.width - gaps) / total, maxUnit * scale);
    final rowWidth = unit * total + gaps;
    var x = action.center.dx - rowWidth / 2;
    final slots = <Rect>[];
    for (final weight in weights) {
      slots.add(Rect.fromLTWH(x, action.top, unit * weight, action.height));
      x += unit * weight + gap;
    }
    final discardHeight = math.max(minHit, action.height * .32);
    final bowlSlots = slots.sublist(1 + pots, 3 + pots);
    return StageLayout._(
      screen: screen,
      scale: scale,
      origin: origin,
      safe: safe,
      action: action,
      hud: hud,
      tickets: tickets,
      pack: slots.first,
      pots: slots.sublist(1, 1 + pots),
      bowls: [
        for (final slot in bowlSlots)
          Rect.fromLTRB(
            slot.left,
            slot.top + discardHeight + gap,
            slot.right,
            slot.bottom,
          ),
      ],
      discards: [
        for (final slot in bowlSlots)
          Rect.fromLTWH(slot.left, slot.top, slot.width, discardHeight),
      ],
      garnishes: slots.sublist(3 + pots),
    );
  }

  static const designSize = Size(1280, 720);

  /// Gesture-edge margin added to the system insets on every side.
  static const edgeMargin = 24.0;

  /// The action zone starts this far down the screen (lower 45 %).
  static const actionStart = .55;
  static const hudHeight = 48.0;
  static const minHit = 48.0;
  static const gap = 8.0;
  static const packWeight = .8;
  static const potWeight = 1.0;
  static const bowlWeight = 1.1;
  static const garnishWeight = .75;

  /// Largest slot unit in design pixels so tablets don't get giant pots.
  static const maxUnit = 190.0;

  /// Height of the counter top edge in the design canvas.
  static const counterTop = 421.0;

  final Size screen;
  final double scale;
  final Offset origin;
  final Rect safe;
  final Rect action;
  final Rect hud;
  final Rect tickets;
  final Rect pack;
  final List<Rect> pots;
  final List<Rect> bowls;
  final List<Rect> discards;
  final List<Rect> garnishes;

  /// Sprite rects inside each slot, computed once so render never allocates.
  final List<Rect> potSprites;
  final List<Rect> bowlSprites;
  final List<Rect> garnishSprites;

  static const potAspect = 1.0;
  static const bowlAspect = 1.25;
  static const garnishAspect = 1.4;

  /// Screen y of the counter's top edge.
  double get counterTopY => origin.dy + counterTop * scale;

  /// Share of a standing customer's height hidden below the counter top.
  static const waistShare = .46;

  /// Order-ticket size in design pixels, and its gap from the head as a
  /// share of the customer height.
  static const ticketDesignWidth = 148.0;
  static const ticketDesignHeight = 78.0;
  static const ticketGap = .09;

  /// Scale of order tickets: design size, shrunk when the ticket band is
  /// short or the screen is narrow (eight ticket widths fit across).
  double get ticketScale => math
      .min(
        math.min(scale, tickets.height / 150),
        safe.width / (8 * ticketDesignWidth),
      )
      .clamp(.4, 1.2)
      .toDouble();
  double get ticketWidth => ticketDesignWidth * ticketScale;
  double get ticketHeight => ticketDesignHeight * ticketScale;

  /// Most customers at the counter (shifts 9–12).
  static const maxSlots = 4;

  /// Head half-width share of H, minus the overlap a ticket may have.
  static const _headClearance = .035;

  /// Full standing height of a customer: head just below the HUD band and
  /// waist at the counter top, capped so tablets don't get giants and so a
  /// four-customer row still fits every ticket beside its customer's head.
  double get customerHeight {
    final fromCounter = (counterTopY - tickets.top) / (1 - waistShare);
    final rowFits =
        (safe.width - (maxSlots + 1) * ticketWidth) /
        ((maxSlots + 1) * ticketGap + maxSlots * _headClearance);
    return math
        .min(fromCounter, rowFits)
        .clamp(60 * scale, 450 * scale)
        .toDouble();
  }

  /// Space kept free right of the last customer for their ticket.
  double get _ticketReserve => ticketWidth + customerHeight * ticketGap;

  /// Horizontal centre of customer [slot] of [slots]. Customers are spread
  /// across the safe stage with room on the right for each order ticket,
  /// which floats beside the head.
  double guestX(int slot, int slots) {
    final width = safe.width - _ticketReserve;
    final spacing = math.min(261 * scale, width / slots);
    return safe.left + width / 2 + (slot - (slots - 1) / 2) * spacing;
  }

  /// Top-left of [slot]'s order ticket: beside the head, on the right.
  Offset ticketOrigin(int slot, int slots) {
    final headTop = counterTopY - customerHeight * (1 - waistShare);
    return Offset(
      guestX(slot, slots) + customerHeight * ticketGap,
      math.max(tickets.top, headTop + customerHeight * .03),
    );
  }

  /// Every hit box, reserved even when the element is idle (discards).
  Iterable<CounterTarget> allTargets() sync* {
    yield CounterTarget(Station.pack, 0, pack);
    for (var i = 0; i < pots.length; i++) {
      yield CounterTarget(Station.pot, i, pots[i]);
    }
    for (var i = 0; i < bowls.length; i++) {
      yield CounterTarget(Station.bowl, i, bowls[i]);
      yield CounterTarget(Station.discard, i, discards[i]);
    }
    for (var i = 0; i < garnishes.length; i++) {
      yield CounterTarget(Station.garnish, i, garnishes[i]);
    }
  }

  /// The target under [point], or null. Discards only answer while rejected.
  CounterTarget? hit(Offset point, KitchenRun run) {
    for (final target in allTargets()) {
      if (!target.bounds.contains(point)) {
        continue;
      }
      if (target.station == Station.discard &&
          run.discardBowl != target.index) {
        return null;
      }
      return target;
    }
    return null;
  }

  /// A rect of [aspect] fitted inside [slot], bottom-aligned, deflated by [pad].
  static Rect fit(Rect slot, double aspect, {double pad = 4}) {
    final box = slot.deflate(pad);
    var width = box.width;
    var height = width / aspect;
    if (height > box.height) {
      height = box.height;
      width = height * aspect;
    }
    return Rect.fromLTWH(
      box.center.dx - width / 2,
      box.bottom - height,
      width,
      height,
    );
  }
}
