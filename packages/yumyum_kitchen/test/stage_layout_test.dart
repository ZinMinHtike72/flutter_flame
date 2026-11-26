import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/stage_layout.dart";

/// Screen sizes with their landscape system insets (left, top, right, bottom).
const devices = <String, (Size, Rect)>{
  "notched phone": (Size(852, 393), Rect.fromLTRB(59, 0, 59, 21)),
  "tall phone": (Size(915, 412), Rect.fromLTRB(32, 0, 0, 16)),
  "small phone": (Size(640, 360), Rect.zero),
  "16:9 phone": (Size(1280, 720), Rect.zero),
  "foldable inner": (Size(884, 841), Rect.fromLTRB(0, 24, 0, 16)),
  "tablet": (Size(1024, 768), Rect.fromLTRB(0, 24, 0, 20)),
};

bool encloses(Rect outer, Rect inner) =>
    inner.left >= outer.left - 1e-6 &&
    inner.top >= outer.top - 1e-6 &&
    inner.right <= outer.right + 1e-6 &&
    inner.bottom <= outer.bottom + 1e-6;

void main() {
  for (final MapEntry(key: name, value: (screen, insets)) in devices.entries) {
    group(name, () {
      final layout = StageLayout.compute(
        screen: screen,
        insets: insets,
        pots: 2,
        garnishes: 3,
      );

      test("cover fit fills the screen with no bars", () {
        final art = Rect.fromLTWH(
          layout.origin.dx,
          layout.origin.dy,
          1280 * layout.scale,
          720 * layout.scale,
        );
        expect(art.left, lessThanOrEqualTo(0));
        expect(art.top, lessThanOrEqualTo(0));
        expect(art.right, greaterThanOrEqualTo(screen.width - 1e-9));
        expect(art.bottom, greaterThanOrEqualTo(screen.height - 1e-9));
      });

      test("safe stage is the view padding plus a 24 px margin", () {
        expect(layout.safe.left, insets.left + 24);
        expect(layout.safe.top, insets.top + 24);
        expect(layout.safe.right, screen.width - insets.right - 24);
        expect(layout.safe.bottom, screen.height - insets.bottom - 24);
      });

      test("action zone is inside the safe stage, in the lower 45 %", () {
        expect(layout.action.top, greaterThanOrEqualTo(screen.height * .55));
        expect(encloses(layout.safe, layout.action), isTrue);
        for (final target in layout.allTargets()) {
          expect(
            encloses(layout.action, target.bounds),
            isTrue,
            reason: "${target.station} ${target.index}",
          );
        }
      });

      test("HUD band never overlaps the action zone or tickets", () {
        expect(layout.hud.bottom, lessThan(layout.action.top));
        expect(layout.hud.bottom, lessThanOrEqualTo(layout.tickets.top));
        expect(layout.tickets.bottom, lessThanOrEqualTo(layout.action.top));
      });

      test("customers stay inside the safe stage", () {
        for (var slot = 0; slot < 4; slot++) {
          final x = layout.guestX(slot, 4);
          expect(x, inInclusiveRange(layout.safe.left, layout.safe.right));
        }
      });
    });
  }

  test("fit keeps the aspect ratio and bottom-aligns", () {
    final rect = StageLayout.fit(const Rect.fromLTWH(0, 0, 100, 200), 2);
    expect(rect.width / rect.height, closeTo(2, 1e-9));
    expect(rect.bottom, 196);
    final tall = StageLayout.fit(const Rect.fromLTWH(0, 0, 300, 100), 1);
    expect(tall.height, 92);
  });
}
