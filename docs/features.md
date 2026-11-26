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
- **Steam**: pooled steam (ready/cooking) and smoke (burnt) puffs per pot in fixed typed arrays, drawn with one `drawRawAtlas`; budget per pot 4/10/18 by quality tier; reduced motion shows one static wisp.
- **Graphics quality**: on first launch a startup benchmark (two pots of high-tier steam, update + picture recording) picks low/medium/high and saves it; the pause menu's Graphics button cycles the tier. The benchmark never overrides a saved choice.
- **Debug**: `YumYumKitchenScreen(showHitBoxes: true)` paints the safe stage, zones and hit boxes; the standalone app enables it with `--flavor development --dart-define=SHOW_HIT_BOXES=true`.
- Rules, campaign and progress are pure Dart in `domain/`; progress is saved locally and settled once per run.

New game areas belong in `lib/features/<feature>/` with domain, data, presentation, and DI layers when those layers have responsibilities. Flame components stay in the owning feature's presentation/game code. Game rules and persistent state belong in domain/data respectively.
