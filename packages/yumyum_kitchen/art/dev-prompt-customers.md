# Dev prompt — full-body animated customers at 30 fps

Paste the block below to the developer (or a coding agent) once the customer
images are in `packages/yumyum_kitchen/art/sources/customers/`.

---

> **Task: replace the half-body customers with full-body animated customers
> that walk in, wait, react and walk out smoothly at 30 fps.**
>
> **Repository context.** Flutter + Flame game in
> `packages/yumyum_kitchen` (branch `feat/yum-yum-kitchen`). Read `AGENTS.md`,
> `.plan/2026-11-26_yum-yum-kitchen.md`, `docs/features.md` first and follow
> them (plan file, docs update, tests, goldens, conventional commits, one
> issue per commit). Relevant code:
> - `presentation/game/yum_yum_kitchen_game.dart` — renderer; customers are
>   drawn by `_customer`, `_departure`, `_guestRect`.
> - `presentation/game/market_art.dart` — `guest()` reads the 6×4 half-body
>   `people.webp` sheet; this is what gets replaced.
> - `presentation/game/stage_layout.dart` — `guestX(slot, slots)`,
>   `counterTopY`, `tickets`, the safe stage and zones. Customers are art
>   zone: never tappable, never covering the action zone or HUD.
> - `presentation/game/frame_timing.dart` — the game steps at a fixed 30 fps
>   (`FrameThrottle`) and rules at 30 Hz (`FixedStepClock`). Do not add a
>   second clock.
> - `domain/kitchen_run.dart` — `Customer(id, slot, toppings, arrived,
>   expires)`, `run.now`, `run.customers`, `servedSlot/servedCustomerId`,
>   `KitchenCue.served/missed`. Rules stay unchanged.
>
> **Source art.** Six customers (`customer_teen`, `customer_flower`,
> `customer_uncle`, `customer_phone`, `customer_grandma`, `customer_rider`),
> each an 8×4 sheet of 384×768 cells (or one 8×1/4×1 image per row): row 1
> walk side-right ×8, row 2 idle ×4 + impatient ×4, row 3 happy ×4 + annoyed
> ×4, row 4 walk-away ×8. Feet sit on a baseline 40 px above each cell bottom.
> Check every frame for drift (baseline, scale, outfit); report and stop if a
> sheet is unusable rather than shipping a jittery character.
>
> **1. Asset pipeline.** Write a reproducible script (Dart, in `tool/`) that
> trims shared transparent margins, keeps the baseline, downsizes frames and
> packs them into WebP atlases under `assets/images/customers/` with a JSON
> frame map (rect + anchor at the feet). Memory budget: all customer atlases
> decoded together **≤ 32 MB**; choose the frame size to fit (about 160×320
> per frame) and record the numbers in the plan. Preload them with the other
> art before the shift clock starts.
>
> **2. Pure animation model** (`presentation/game/customer_animator.dart`, no
> Flutter imports, fully unit-tested). One animator per customer slot, driven
> only by `run.now` (milliseconds) so it is deterministic and frame-rate
> independent:
> - States: `walkIn → idle ↔ impatient → (happy → walkOutHappy) | (annoyed →
>   walkOutAnnoyed) → gone`.
> - `walkIn` starts at the customer's `arrived` time from the nearer screen
>   edge (outside the safe stage, in the art zone behind the counter) and
>   ends at `guestX(slot)` in 600 ms with `easeOutCubic` on position;
>   `impatient` when patience < 30 %; `happy` on `KitchenCue.served` for that
>   customer, `annoyed` on `missed`; walk-outs leave toward the nearer edge
>   in 700 ms (`easeInCubic`).
> - Frame rates: walk 12 fps (8 frames), idle 6 fps, impatient 8 fps, happy
>   and annoyed 10 fps played once then held. Walk frame index advances with
>   distance travelled (stride-locked), not just time, so feet never slide.
> - Output per frame: sprite frame id, feet position, scale, horizontal flip,
>   opacity, plus a small procedural layer: idle breathing scale 1.0↔1.008,
>   a 2 px bob on walk contact frames.
> - Smoothness: positions are computed every 30 fps frame from `run.now`
>   (never stepped per sprite frame); sprite frames change at their own rate;
>   when switching states, cross-fade over 100 ms by drawing the outgoing
>   frame with fading opacity. Paused shift freezes everything.
>
> **3. Rendering.** Replace `_customer`/`_departure` with drawing from the
> animator: feet anchored at `counterTopY + 8·scale` for standing slots (the
> counter art hides the legs while waiting; full body shows while walking
> across the market floor), tickets still drawn in the ticket band above.
> Use precomputed source rects and `drawImageRect`, or one `drawRawAtlas`
> for all customers, with reused buffers: **no allocation in update/render**.
> Customers never overlap the HUD or the action zone; the hit-area test
> (`test/app/hit_area_test.dart`) must still pass unchanged.
>
> **4. Reduced motion** (`MediaQuery.disableAnimationsOf`): no walking or
> bobbing; customers fade in/out over 150 ms at their slot and show the
> state's first frame; impatient and happy states stay visible (that is
> gameplay information).
>
> **5. Performance target.** Sustained 30 fps in shift 12 (four customers) on
> a Galaxy A54 and an iPhone 14: p95 frame < 33 ms, no frame > 50 ms, no GC
> pause > 8 ms. Measure with `flutter run --profile` + DevTools and record the
> numbers in the plan's Verification section. Customer drawing must add
> ≤ 2 ms of raster time per frame at four customers.
>
> **6. Tests.**
> - Unit: every state transition and its timing; stride-locked walk frame
>   index; no feet sliding (feet x delta per frame matches stride); pause
>   freezes; reduced motion path; deterministic for a given `run.now`.
> - Widget: a shift where a customer walks in, waits, turns impatient, is
>   served and walks out; another where they are missed — assert states at
>   fixed times with the real 30 fps loop (`settleFrames`, 34 ms pumps).
> - Goldens (light, dark, Myanmar, small phone): walk-in mid-stride, idle,
>   impatient, happy with bowl, annoyed; motion on and reduced motion.
>   Look at every PNG before committing.
> - `flutter analyze` clean; app and package tests pass; coverage ≥ 85 % on
>   touched modules.
>
> **7. Deliverables.** One GitHub issue "Full-body animated customers"
> (parent #1) with this spec as acceptance criteria; plan file and
> `docs/features.md` updated; commits per step (`feat(game): …`); push to
> `feat/yum-yum-kitchen`; close the issue with evidence (commands, counts,
> golden list, profile numbers, anything not verified).
