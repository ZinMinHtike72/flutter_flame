# Features

Last updated: 2026-11-26

| Feature | Route | UI | Data/API | Tests |
| --- | --- | --- | --- | --- |
| Home → Yum Yum Kitchen Madness | `/` | Standalone launch of `YumYumKitchenScreen` (package `yumyum_kitchen`): entrance, shift tickets, brief, live shift, pause, receipt, upgrade shop | Local only (`shared_preferences` progress); no backend calls | `test/app/screens_golden_test.dart`, `test/app_test.dart`, `packages/yumyum_kitchen/test/` |

## Yum Yum Kitchen Madness (`packages/yumyum_kitchen`)

- **Full-screen layout**: the 1280×720 design canvas is scaled with cover fit and drawn edge to edge in immersive landscape (no letterbox bars). Android draws under display cutouts (`shortEdges`, API 28+).
- **Safe stage**: screen inset by `MediaQuery.viewPadding` + 24 px on every side, computed by `StageLayout` (`presentation/game/stage_layout.dart`).
- **Zones**: art (whole screen, not tappable), action (lower 45 % of the screen inside the safe stage: pack, pots, bowls, discard targets, garnish bins), HUD (48 px band at the top of the safe stage: goal, tutorial hint, combo, coins, clock, pause). Order tickets sit between the HUD and the action zone.
- **Hit areas**: every target is ≥ 48×48, inside the safe stage and apart from every other (HUD pause included); `test/app/hit_area_test.dart` enforces it on five device sizes.
- **Overlays**: every page except the live shift sits on an opaque scrim plus `ScrimGuard`; no counter point reaches the game while pause, receipt or shop is open (`test/app/overlay_scrim_test.dart`).
- **Frame rate**: Flame's own loop stays paused; a vsync callback steps the engine through `FrameThrottle` at 30 fps (60/90/120 Hz displays), and `FixedStepClock` advances the rules in exact 1000/30 ms steps (max 5 catch-up steps).
- **Steam**: pooled painted steam wisps (ready/cooking) and smoke puffs (burnt, `assets/images/smoke.webp`) per pot in fixed typed arrays, drawn with one `drawRawAtlas`; budget per pot 4/10/18 by quality tier; reduced motion shows one static wisp.
- **Graphics quality**: on first launch a startup benchmark (two pots of high-tier steam, update + picture recording) picks low/medium/high and saves it; the pause menu's Graphics button cycles the tier. The benchmark never overrides a saved choice.
- **Pots**: generated painted pots without lids (empty, cooking, ready, burnt), separate glass and enamel lids seated on the measured rim, and a bubbling water surface at the rolling boil (`PotSprites`, `assets/images/pots.webp`). The glass lid rattles at the rolling boil; the enamel lid is lifted aside when ready.
- **Art pipeline**: `dart run tool/pack_art.dart` (in `packages/yumyum_kitchen`, needs `cwebp`) cuts `art/sources/*` sheets into trimmed, scaled frames, packs WebP atlases and writes JSON frame maps read by `SpriteAtlas`.
- **Boil**: `BoilSync` runs inside each rules step — simmer (first half of cooking, small bubbles), rolling (second half, more bubbles, lid knocks every 180 ms, boil loop), ready (lid pops and settles, loop stops, chime), burnt (silent). Pause stops the loop; reduced motion keeps sound but drops bubbles and rattle.
- **Customers**: six full-body customers (`assets/images/customers/*.webp`, packed from `art/sources/customers/`). `CustomerCast` derives one actor per customer inside each rules step and poses it from `run.now`: walk in from the nearer side (1.2 s, walk frames locked to distance), idle, impatient below 30 % patience (never in the tutorial), happy with the bowl when served or annoyed when missed (0.6 s), then walk away (1.1 s). A new customer's entrance waits until the previous one in that slot has finished reacting; their ticket appears with them. Standing customers keep their waist at the counter top and their head just under the HUD; order tickets float beside the head (`StageLayout.ticketOrigin`). Reduced motion: 150 ms fades in place, one still frame per state.
- **Allocation-free frames**: steady frames create no objects from game code. Geometry (pack, halos, discard marks, garnish insets, cook bars, tickets) is cached per layout as rects and paths; sprites draw through canvas transforms with precomputed source rects; the rules step uses index loops; Flame's unused camera subtree is neither rendered nor ticked. `test/app/performance_test.dart` traces allocations to enforce it (needs `flutter test --enable-vmservice`, which `make test` uses; otherwise it is skipped).
- **Preload**: every image, atlas and sound loads before the game mounts (`YumYumKitchenGame.preloaded`); until then there is no menu, no shift and no rules clock.
- **Debug**: `YumYumKitchenScreen(showHitBoxes: true)` paints the safe stage, zones and hit boxes; the standalone app enables it with `--flavor development --dart-define=SHOW_HIT_BOXES=true`.
- Rules, campaign and progress are pure Dart in `domain/`; progress is saved locally and settled once per run.

New game areas belong in `lib/features/<feature>/` with domain, data, presentation, and DI layers when those layers have responsibilities. Flame components stay in the owning feature's presentation/game code. Game rules and persistent state belong in domain/data respectively.
