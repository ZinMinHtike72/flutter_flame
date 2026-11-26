# Yum Yum Kitchen Madness — Yangon Night Market

## Summary
Build a standalone Android/iOS game and an embeddable Flutter package for the existing Yum Yum Myanmar app. Twelve landscape shifts take a Yangon noodle stall from dusk to last orders. Lanterns mark fast serves. The scene fills the whole screen edge to edge, runs at a steady 30 fps, and every tap target is large, separate and inside a safe stage.

Revision 2 (2026-11-26): full-screen cover layout with a safe stage and three screen zones, 30 fps target with a fixed 30 Hz rules step, steam and pot realism issues, a motion-design section, and a hit-area QA issue. Everything else is unchanged from the approved plan.

## Player experience
A lifting awning reveals the market entrance and a steaming bowl. Play starts the first guided sale and Continue returns to unlocked tickets. Twelve order tickets show the featured noodle, goal and best score. During a shift, picture orders sit above the counter, appliances and bins below. The HUD presents time, goal, coins, streak and pause. Pause freezes every timer, offers resume, restart, sound, haptics and exit, and opens on backgrounding. A receipt presents coins, customers, streak, goal, retry/next, upgrades and an optional product card.

## Rules and progression
Levels 1–4 feature Original Chicken with spring onion and egg introduced gradually. Levels 5–8 feature Xcite Tom Yum Chicken, lime, up to two toppings and three customers. Levels 9–12 feature dry Ultra Mala Xiang Guo noodles and four customers. The final goal is 1500 coins in 90 seconds. Every level must be achievable with starting equipment.

Tap a pack to fill the first empty pot. Cooking takes 3 seconds, with a 6-second transfer window before burning. A ready pot fills the first empty bowl. A full counter leaves its timer running. Clear burnt pots by tapping. Each topping goes to the first eligible bowl. Tap a bowl to serve the least patient exact match, independent of topping order. Provide an explicit discard action for unmatched bowls. Losing a customer or clearing a burnt pot resets the streak. Pay 60 coins plus 20 per topping and 20 for a fast serve before half patience; consecutive fast serves within five seconds increase the multiplier by 0.25 up to 2. Bank earned coins exactly once and retain best scores. Unlock the next level on success. Spend coins on an extra pot, faster boil, or higher dish value.

## Full-screen layout
- The game renders edge to edge in immersive landscape (`SystemUiMode.immersiveSticky`, Android `layoutInDisplayCutoutMode=shortEdges`, no `SafeArea` around the game). Art, lanterns and the market backdrop bleed under notches, rounded corners and system bars. No letterbox bars.
- Design canvas: 1280×720, scaled with **cover** fit: `scale = max(w / 1280, h / 720)`, centred; the overflow is cropped. Tablets (4:3) crop the sides, tall phones (19.5:9) crop the top and bottom.
- **Safe stage**: the screen rectangle inset by `MediaQuery.viewPadding` plus a 24 px gesture-edge margin on every side. Everything that must stay visible or tappable sits inside it. One pure-Dart `StageLayout(screenSize, viewPadding)` computes the safe stage, the zones and every hit box, and both the Flame renderer and the Flutter HUD read from it.

### Screen zones
| Zone | Where | Contents | Input |
| --- | --- | --- | --- |
| 1. Art | Whole screen, behind everything | Market backdrop, awning, lanterns, customers, steam, counter art | Wrapped in `IgnorePointer`; no buttons |
| 2. Action | Inside the safe stage, lower 45 % of the screen (`y ≥ 0.55 h`) | Noodle pack, pots, bowls, garnish bins, discard targets (above their bowl) | The only game targets |
| 3. HUD | Top-left and top-right corners of the safe stage, 56 px tall | Goal (left); combo, coins, clock, pause (right) | Pause only; never overlaps the action zone |

Order tickets sit in the safe stage between the HUD band and the action zone so they are never cropped or covered.

### Hit areas
- Every tappable element has a hit area of at least 48×48 logical px, even when its sprite is smaller. Hit areas come from equal, gapped action-zone slots, so they never overlap.
- No decorative layer is drawn or hit-tested above an interactive component.
- A debug overlay (development flavor toggle) paints the safe stage, the zones and every hit box.
- A widget test fails if any hit box leaves the safe stage, is smaller than 48×48, or overlaps another (including the HUD pause button), across phone, tall phone with cutout insets, foldable and tablet sizes.

### Overlays
Pause, results and shop use an opaque or blurred scrim. Only the overlay's own controls are tappable while it is open; taps on the scrim never reach the game (the game also ignores input outside the live page).

## Performance target: 30 FPS
- Target a sustained 30 fps in the four-customer rush (shift 12) on the reference devices: **Samsung Galaxy A54 5G** (Exynos 1380, Android 14, 2023) and **iPhone 14** (A15, iOS 17, 2022).
- Budget: p95 frame time under 33 ms, no frame over 50 ms, no GC pause over 8 ms during play.
- **Fixed 30 Hz rules step**: a `FixedStepClock` accumulates real elapsed time and advances `KitchenRun` in steps of exactly 1000/30 ms (33, 33, 34 ms integer pattern), with at most 5 catch-up steps per frame.
- **30 fps render cap**: Flame has no built-in cap. The game pauses Flame's own loop (`pauseEngine`) and drives it from a `Ticker` that calls `stepEngine(stepTime:)` only when at least 1/30 s has passed since the last step (`FrameThrottle`). Frames in between do not repaint the game. Tests: unit tests feed `FrameThrottle` 60 Hz, 90 Hz and 120 Hz vsync timestamps and expect 30 steps per second; a widget test pumps one second at 60 Hz and counts 30 game updates.
- Preload atlases and audio before the clock starts. Pool all particles and sprites (struct-of-arrays `Float32List` buffers drawn with `drawRawAtlas`). No allocation in `update()` or `render()`: layout rects are cached on resize, `Paint`s are reused, animation offsets use `canvas.translate`.
- Quality tier low / medium / high scales particle counts (steam puffs per pot 4 / 10 / 18). The default comes from a startup benchmark that times a fixed particle simulation and picture recording during loading; the result is saved and can be changed in the pause menu.
- Device measurement: `flutter run --profile` with DevTools frame chart and memory (GC) timeline on both reference devices, recorded in the Verification section.

## Steam and pot realism
Follows the separate steam and pot spec (not yet attached; issues record assumptions until it arrives).
- Pot and lid sprite set: pot body and lid per state (empty, cooking, ready, burnt), same angle and light as the counter.
- Steam particle system: pooled puffs whose rate and size follow the pot state, scaled by quality tier, hidden under reduced motion except a static wisp.
- Boil animation and audio sync: bubbles, lid rattle and the boil loop start, peak and stop on the same rules-step frame.

## Motion design
- **Transitions**: page changes use a 220 ms fade-through (`Curves.easeOutCubic` in, `Curves.easeInCubic` out); overlays fade their scrim in 160 ms; the awning lifts in 600 ms `easeOutCubic` on the entrance.
- **Easing**: `easeOutCubic` for things arriving, `easeInCubic` for leaving, `easeInOutSine` for loops (lantern sway, steam drift). Overshoot (`easeOutBack`) only on scale/position (bowl pop, coin pop), never on padding, shadows or containers.
- **Micro-interactions**: every target press scales to 0.94 for 90 ms and back; bowls arc to the customer in 420 ms; coins count up; lanterns light one by one on combo; burnt pots shake.
- **Haptics**: selection click on every accepted tap, light impact on serve, medium impact on streak, heavy on burn; all off with the haptics setting.
- **Audio**: short preloaded cues per action (pack, transfer, garnish, serve, streak, burn, discard) and a boil loop; sound setting mutes all.
- **Response time**: every interaction gives visible feedback within 100 ms (the press state is drawn on the next rendered frame, ≤ 34 ms at 30 fps), with sound and haptics fired in the same frame.
- **Reduced motion**: `MediaQuery.disableAnimationsOf` switches loops to static frames and transitions to `Duration.zero`; essential information (timers, patience, ready state) stays visible.

## Art and sound
Create and inspect a 16:9 ImageGen keyframe, then produce separate environment layers, transparent consistently angled cooking sprites, six customers in four poses, and small-screen state feedback. Use existing company logo and the three matching pack artworks. Animate steam, lanterns, lid rattles, garnish and bowl trajectories. Pair actions with short preloaded sounds. Reduced motion keeps essential information visible.

## Engineering and verification
Use the 1280×720 cover-fit canvas with the safe stage above, 48 logical pixel tap targets, Flame 1.35.1 and an independently consumable package supporting Flutter 3.35.4. The package provides a screen with exit and product callbacks, localized overlays, pure Dart rules, controllable time and randomness, local progress and idempotent settlement. Standalone opens official product pages. Host restores portrait and system bars for product handoff and exit. Verify both consumers, timed game rules, bilingual landscape goldens, per-module 85% coverage and Android/iOS four-customer 30 fps performance.

## Plan Steps
- [x] status: done - Recorded the approved design before implementation.
- [x] status: done - Revision 2: full-screen layout, 30 fps, steam and pot realism, motion design, hit-area QA.

## Implementation
GitHub issue numbers are in brackets.
- [ ] status: pending - Prove dual-SDK package compatibility [#2]
- [x] status: done - Build the full-screen cover viewport, safe stage and three zones [#3] — `StageLayout`, cover-fit art, immersive mode, Android `shortEdges`, HUD on safe stage, Myanmar goldens fixed
- [x] status: done - Enforce 48 px non-overlapping hit areas with a debug overlay and test [#23] — `test/app/hit_area_test.dart` (5 sizes), `SHOW_HIT_BOXES` dart-define, `hit_boxes_notched_phone` golden
- [ ] status: pending - Block game input behind overlay scrims [#24]
- [ ] status: pending - Fixed 30 Hz rules step and 30 fps render cap [#25]
- [ ] status: pending - Preload, pool and remove per-frame allocations [#26]
- [ ] status: pending - Quality tiers chosen by a startup benchmark [#27]
- [ ] status: pending - Implement pot and bowl transitions [#4]
- [ ] status: pending - Implement order matching and patience [#5]
- [ ] status: pending - Wire one playable shift from start to result [#6]
- [ ] status: pending - Create the reference keyframe [#7]
- [ ] status: pending - Produce environment layers [#8]
- [ ] status: pending - Produce food and appliance sprites [#9]
- [ ] status: pending - Produce customer poses [#10]
- [ ] status: pending - Pot and lid sprite set [#28]
- [ ] status: pending - Steam particle system [#29]
- [ ] status: pending - Boil animation and audio sync [#30]
- [ ] status: pending - Integrate animation, audio, and reduced motion [#11]
- [ ] status: pending - Motion design pass: transitions, micro-interactions, haptics, 100 ms response [#31]
- [ ] status: pending - Build the market entrance and ticket selection [#12]
- [ ] status: pending - Teach the first order [#13]
- [ ] status: pending - Implement scoring and lantern combos [#14]
- [ ] status: pending - Configure and balance 12 shifts [#15]
- [ ] status: pending - Save earnings and unlocks [#16]
- [ ] status: pending - Build the upgrade shop [#17]
- [ ] status: pending - Finish HUD, pause, and results overlays [#18]
- [ ] status: pending - Connect product cards in both launch modes [#19]
- [ ] status: pending - Brand the standalone app [#20]
- [ ] status: pending - Verify embedded launch, exit, and orientation restoration [#21]
- [ ] status: pending - Complete bilingual visual and device QA at 30 fps [#22]
- [ ] status: pending - Hit-area audit and safe-area QA on notched, foldable and tablet devices [#32]
- [ ] status: pending - Update docs/features.md and docs/api.md.

## Test Plan
- [ ] status: pending - Rules: timed cooking, burn, matching, patience, scoring, settlement (plain tests with a controlled clock and seeded random).
- [ ] status: pending - Layout: `StageLayout` unit tests and the hit-area widget test (inside safe stage, ≥ 48×48, no overlap) on 852×393 with cutout insets, 640×360, 2208×1768 foldable, 1024×768 tablet.
- [ ] status: pending - Overlay scrim test: taps on the pause/results/shop scrim do not change the run.
- [ ] status: pending - `FrameThrottle` and `FixedStepClock` unit tests; 30-updates-per-second widget test.
- [ ] status: pending - Golden tests of every screen in English and Myanmar, light and dark, phone and small phone.
- [ ] status: pending - Profile runs on Galaxy A54 and iPhone 14 in the shift-12 rush.

## Acceptance
- The scene fills the screen edge to edge on every tested size; no letterbox bars.
- Sustained **30 fps** in the four-customer rush on Galaxy A54 and iPhone 14: p95 frame < 33 ms, no frame > 50 ms, no GC pause > 8 ms.
- The **hit-area widget test** passes: every hit box is ≥ 48×48, inside the safe stage and non-overlapping on all tested sizes.
- **Golden tests in both languages** (English and Myanmar) pass for entrance, tickets, brief, tutorial, live, pause, receipt and shop.
- `flutter analyze` is clean; app and package tests pass; every module ≥ 85 % line coverage.

## Verification
- status: pending
- Commands: `flutter analyze`, `flutter test`, `make coverage`, `flutter run --profile` on both reference devices.
