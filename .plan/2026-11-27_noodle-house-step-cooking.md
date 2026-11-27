# Yum Yum Noodle House — step-by-step cooking restaurant

## Summary

Replaces the one-tap noodle stall with a restaurant. Every dish is cooked in
real steps: boil water, cook noodles, ladle broth, prepare each topping on its
own station (grill beef, boil eggs, fry shrimp, chop greens), then assemble and
serve. A dining room with tables, a waiter, free green tea, dirty tables and a
takeaway window adds the front-of-house side. The game is renamed from
"Kitchen Madness — Yangon Night Market" to **Yum Yum Noodle House**
(Myanmar: ယမ်ယမ် ခေါက်ဆွဲဆိုင်). The package (`yumyum_kitchen`), the
architecture, the 30 fps pipeline, the safe stage and the hit-area rules from
`.plan/2026-11-26_yum-yum-kitchen.md` all stay.

Epic: GitHub issue "Yum Yum Noodle House — step-by-step cooking restaurant".
Art prompts: `packages/yumyum_kitchen/art/prompts-restaurant.md`.

## Game design

### Roles

- **Player = chef.** Every cooking step is a tap (or a drag) by the player.
- **Waiter (NPC).** Seats guests, carries finished bowls to the right table,
  pours free green tea and clears tables. The player tells the waiter what to
  do with a tap; the waiter walks there (animated), so the waiter is a shared
  resource that can be busy.
- **Customers.** Dine-in guests at tables, takeaway guests and delivery riders
  at the takeaway window.

### Screen layout (1280×720 canvas, same three zones)

| Zone | Contents |
|---|---|
| HUD (top band) | Day goal, coins, time, streak, pause; the **ticket rail** with one ticket per open order |
| Art zone (upper 55 %) | Dining room: entrance on the left, 2–4 tables, the waiter's aisle in front of the tables, takeaway window and shelf on the right |
| Action zone (lower 45 %) | Kitchen line in two rows. **Back row — cooking:** stoves with noodle pots, grill, egg boiler, fryer, tea station. **Front row — assembly:** noodle packs, broth stockpots, bowl slots, topping trays, cutting board, takeaway packing, bin |

Stations unlock day by day, so the line never shows more stations than the
layout can fit at 48 dp each on a 640×360 dp phone. The layout test decides the
cap. The target is at most 12 tappable kitchen stations plus the tables.

### The core loop

1. A guest enters. The waiter seats them at a free table (automatic) and a
   ticket appears on the rail showing the full order as icons.
2. The player cooks the order step by step on the kitchen line.
3. The player taps the finished bowl. The waiter carries it to the table whose
   ticket matches; if none match, the bowl shakes and stays.
4. The guest eats (short loop), pays coins plus a tip on the table, and leaves.
5. The table is dirty. Tap it: the waiter collects coins and bowls. Only then
   can a new guest sit there. A dishwasher upgrade clears tables automatically.

### Step-by-step cooking

Every cooker uses one state machine. It is empty, then loaded, then cooking (a
progress ring). Next it is done, with a green **perfect** window and then a
yellow window. Last it is ruined (burnt, soggy or charred) and must be binned.
Taking food out in the perfect window earns a bonus.

**Noodle soup (the base of every bowl):**

| Step | Station | Action | Time |
|---|---|---|---|
| 1 | Stove pot | Tap the empty pot: water pours in (kettle) | instant |
| 2 | Stove pot | Water heats on its own: cold → simmer → rolling boil | 2.5 s |
| 3 | Noodle pack | Tap the pack: a noodle block drops into the boiling pot (only into boiling water; cold water rejects it with a shake) | instant |
| 4 | Stove pot | Noodles cook: hard block → softening → ready (perfect) → soggy (ruined) | 3 s cook, 2 s perfect, 4 s more ready |
| 5 | Stove pot → bowl | Tap the ready pot: noodles go into the selected empty bowl; the pot is left empty and needs water again | instant |
| 6 | Broth stockpot → bowl | Tap the stockpot of the ordered flavour (Chicken, Tom Yum or Mala): the ladle pours broth | instant |
| 6′ | Sauce bottle → bowl | Dry noodles (Mala chapter): sauce and chilli oil instead of broth | instant |

Wrong order is blocked with feedback: toppings and broth need noodles in the
bowl first, and a bowl takes one broth only.

**Toppings that need preparation (each has its own station):**

| Topping | Station | Steps | Ruin state |
|---|---|---|---|
| Grilled beef | Grill (3 places) | Tap raw beef tray → slice lands on the grill → sear (2 s) → **flip** by tapping it (a half-cooked slice must be flipped or it chars) → second side (2 s) → tap to move to the beef tray (2 portions per slice) | Charred |
| Boiled egg | Egg boiler | Tap egg basket → 2 eggs into boiling water → 4 s → tap: eggs are halved into the egg tray (4 halves) | Cracked, overcooked |
| Fried shrimp | Fryer | Tap shrimp → basket dips → golden at 3 s → tap to lift and drain into the shrimp tray (3 portions) | Burnt |
| Fish balls | Stove pot (re-uses a noodle pot) | Drop into boiling water → 2.5 s → tap out to tray | Burst |
| Spring onion, coriander, chilli, lime | Cutting board | Tap the vegetable onto the board, tap it 3 times to chop (each tap shows a cut), the chopped pile goes to its tray (5 portions; lime gives 4 wedges) | — |
| Fried garlic, chilli oil | Condiment jars | Ready to use | — |

Prepared toppings sit in steel trays with a portion count. Hot items (beef,
shrimp, eggs) stay fresh for 25 s and then go cold and grey. A cold portion
lowers the tip, and the heat-lamp upgrade keeps them hot longer. When the
player taps a tray, one portion goes on the selected bowl.

**Bowl selection.** Tapping a bowl selects it (gold outline). Noodles, broth
and toppings go to the selected bowl. After an action, selection moves on its
own to the bowl that best matches the oldest ticket, so one-handed play needs
no extra taps. Dragging a tray or pot onto a bowl also works.

**Drinks (later days).** Myanmar milk tea: tap the tea station to fill the cup
with tea (2 s brew), then add condensed milk, then serve. Iced lemon tea: cup,
ice, tea, lime.

**Free green tea (front-of-house).** Tap a waiting table: the waiter pours free
green tea, a Myanmar teashop custom. It refills 25 % patience, once per guest.
It costs the waiter's time.

### Takeaway and delivery

- Takeaway guests queue at the window, and delivery riders arrive with a phone
  order. Their tickets carry a bag icon.
- Cook as usual, but in a **takeaway bowl**: tap the packing station to put a
  paper bowl in the slot. After assembly, tap the packing station again: lid,
  then bag. The waiter puts the bag on the takeaway shelf, and the guest or
  rider picks it up.
- Riders are less patient but pay a delivery bonus. Takeaway never needs a
  table, so it can save a crowded room.

### Orders and tickets

A ticket shows every step as icons, read left to right: the base (noodles,
broth flavour or dry sauce), toppings in a row, a drink, and dine-in or
takeaway. A patience bar runs under the ticket, and the same bar shows over the
guest's head. Tickets are sorted by patience. The rail shakes and turns red
when the oldest ticket is under 25 %.

### Scoring, stars and streaks

- Price = base noodles (30) + broth (10) + each topping (5–15, prepared
  toppings pay more) + drink (10).
- Tip = up to 40 % for speed (patience left), +10 % for every perfect-window
  item in the bowl, −10 % for each cold topping.
- Service streak: consecutive serves without losing a guest raise the
  multiplier by 0.1 up to ×2. It replaces the lantern combo.
- Each day gives 1–3 stars for the goal, the 2★ coin line and the 3★ coin
  line. Days unlock with 1★.

### Campaign — 12 days in 3 chapters

| Day | Chapter (product) | New this day | Tables | Takeaway |
|---|---|---|---|---|
| 1 | Chicken Noodle Soup (Original Chicken) | Guided: water → noodles → bowl → chicken broth → serve | 2 | — |
| 2 | Chicken | Cutting board: spring onion | 2 | — |
| 3 | Chicken | Egg boiler: boiled egg | 3 | — |
| 4 | Chicken | Dirty tables and free green tea | 3 | — |
| 5 | Tom Yum (Xcite Tom Yum Chicken) | Tom Yum broth (second stockpot), lime | 3 | — |
| 6 | Tom Yum | Grill: grilled beef with flip | 3 | — |
| 7 | Tom Yum | Takeaway window and packing | 3 | ✓ |
| 8 | Tom Yum | Fryer: fried shrimp | 4 | ✓ |
| 9 | Mala dry noodles (Ultra Mala Xiang Guo) | Dry noodles: sauce bottle instead of broth, chilli | 4 | ✓ |
| 10 | Mala | Delivery riders (phone orders) | 4 | ✓ |
| 11 | Mala | Myanmar milk tea | 4 | ✓ |
| 12 | All | Rush hour: every dish and station | 4 | ✓ |

Every day must be winnable at 1★ with no upgrades. The rules test plays each
day with a scripted perfect chef.

### Upgrades (coins between days)

Second and third stove, auto water tap (step 1 is automatic), bigger grill (4
places), heat lamp (hot toppings stay fresh for 45 s), faster waiter, second
waiter, dishwasher (auto-clears tables), decor (−15 % patience drain), premium
bowls (+10 % price).

### Feedback and motion

Every step has a sprite state, a sound and a haptic: pour, bubble, drop,
sizzle, flip, chop, fryer crackle, ladle, bell, coins and tea pour. Steam
(existing `SteamField`) rises from pots, stockpots, the grill and the fryer.
Progress rings show cook state, with a green arc for the perfect window.
Reduced motion keeps every state readable without animation. All existing
rules still apply: 100 ms response, 48 dp hit areas and opaque overlay scrims.

### Engineering shape

- `domain/cooking/`: a generic `Cooker` state machine (load, cook, perfect
  window, ruin) plus `CookerSpec` data per station (pot, grill, egg boiler,
  fryer, tea). `Ingredient`, `PrepChain` and `ToppingTray` (portions,
  freshness). Pure Dart, fixed 30 Hz `advance`, index loops, no allocation per
  step.
- `domain/orders/`: `Recipe` (base, broth or sauce, toppings, drink, takeaway),
  `Bowl` assembly rules, `Ticket`, pricing and tips.
- `domain/dining/`: `Table` (free → seated → waiting → eating → dirty),
  `Waiter` task queue with walk times, `TakeawayQueue` and the green-tea rule.
- `domain/campaign.dart`: 12 `Day` configs (stations, menu, tables, arrivals,
  patience, star lines).
- Presentation: the Flame renderer draws stations from atlases packed by
  `tool/pack_art.dart`. `StageLayout` gains a two-row kitchen line and table
  slots. The waiter and seated guests use `CustomerCast`-style time-driven
  animators.
- `KitchenRun` is replaced by `RestaurantRun`, which composes the three
  domains. The BLoC, overlays, progress and settlement keep their shape.

## Plan Steps

- [x] status: done - Created plan file with the game design.
- [x] status: done - Wrote image prompts for every new asset (`art/prompts-restaurant.md`).
- [x] status: done - Opened the new epic and its issues on GitHub.

## Implementation

- [ ] status: pending - Receive generated assets; check angle, scale and style; pack atlases (`tool/pack_art.dart`)
- [ ] status: pending - Domain: generic cooker state machine and prep chains, with tests
- [ ] status: pending - Domain: recipes, bowl assembly, tickets, pricing and tips, with tests
- [ ] status: pending - Domain: tables, waiter tasks, green tea and takeaway queue, with tests
- [ ] status: pending - Domain: 12-day campaign, star lines and scripted-chef winnability test
- [ ] status: pending - Layout: two-row kitchen line and table slots within the 48 dp rule; hit-area test
- [ ] status: pending - Render: stations, trays, bowls with topping overlays, progress rings
- [ ] status: pending - Render: dining room, waiter and seated guests animation
- [ ] status: pending - HUD: ticket rail with step icons
- [ ] status: pending - Tutorial: guided day 1 and first-use hints for each new station
- [ ] status: pending - Upgrades shop rework
- [ ] status: pending - Sounds and haptics for each step
- [ ] status: pending - Rename to Yum Yum Noodle House (en, my), brand and store names
- [ ] status: pending - Update docs/features.md (and docs/api.md if anything changes)

## Test Plan

- [ ] status: pending - Cooker: every transition, perfect window and ruin boundary, at the 30 Hz step and on slow frames
- [ ] status: pending - Assembly: order rules (noodles first, one broth), exact recipe match, wrong items rejected
- [ ] status: pending - Dining: table life cycle, waiter queue order and walk time, green tea once per guest, takeaway pickup
- [ ] status: pending - Campaign: each day winnable at 1★ by a scripted chef with no upgrades
- [ ] status: pending - Pricing and tips: speed, perfect, cold and streak
- [ ] status: pending - Widgets: a full day 1 journey; pause freezes every cooker, table and waiter
- [ ] status: pending - Hit areas: non-overlapping 48 dp on 640×360, notched phone, tablet
- [ ] status: pending - Goldens: kitchen line in each chapter, dining room, ticket rail, light and dark, en and my, small phone
- [ ] status: pending - Performance: zero per-frame allocations with day 12 fully loaded; 30 fps budget

## Verification

- status: pending
- Command: `flutter analyze`, `make test`, `make test-packages`, `make coverage`
- Result: (fill after running)
