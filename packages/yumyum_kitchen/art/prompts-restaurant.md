# Image prompts — Yum Yum Noodle House (step-by-step cooking)

Assets for the restaurant redesign (`.plan/2026-11-27_noodle-house-step-cooking.md`).
Generate them **in the order below**: the keyframe sets the style, and every
later image uses it (and the earlier sheets) as reference images.

## Rules for every image

- **Transparent background** (PNG with alpha) for every sprite sheet. Only the
  keyframe and the room background are opaque.
- **Style**: semi-realistic painted illustration, the same as the existing art
  (`assets/images/equipment.webp`, `pots.webp`, `customers/`): warm indoor
  light from the upper left, soft reflections, clean outlines, friendly and
  appetising. No text, no logos, no watermarks, no UI.
- **Kitchen camera**: three-quarter view from the front, looking down about
  35°, like a cook standing at the counter. Every kitchen sheet uses this same
  angle and the same scale.
- **Grid sheets**: equal cells exactly as given, each object centred with an
  empty margin of at least 8 % of the cell, the same scale and the same
  position in every cell, nothing crossing a cell edge, no grid lines.
- **Matching motifs**: cream enamel with a navy-blue rim and painted red roses
  for pots and bowls (as in `pots.webp`). Brushed steel for trays and the
  range. Warm teak wood for tables and the counter edge.
- Attach `assets/images/equipment.webp` and `art/sources/pot_bodies.png` as
  style and angle references for every kitchen sheet.

---

## 0. Style keyframe (reference only) — `restaurant_keyframe.png`

> 2560×1440, opaque. Semi-realistic painted illustration of a cosy Yangon
> noodle restaurant at dinner time, seen from behind the kitchen counter. Upper
> half: the dining room with teak walls, green-and-cream tiled floor, a ceiling
> fan, warm pendant lamps, an open entrance door on the left with a street
> glimpse, four small teak tables with low stools in a row, a waiter in a white
> shirt and dark green apron carrying a bowl, three guests eating noodles, a
> takeaway window with a shelf on the right where a delivery rider in a red
> jacket waits. Lower half: the kitchen line in two rows: back row a steel
> cooking range with two cream enamel pots with red roses on gas burners, a
> grill with beef slices, a small egg pot and a deep fryer; front row a steel
> and teak prep counter with noodle packs, two big steel broth stockpots with
> ladles, three empty cream enamel bowls with red roses, steel topping trays
> (spring onion, coriander, chilli, lime, eggs, grilled beef), a wooden cutting
> board and a takeaway packing spot. Steam rising, warm cheerful mood, three-
> quarter view looking down about 35° on the counter. No text.

---

## 1. Dining room background — `restaurant_room.png`

> 2560×1440, opaque. Same restaurant and style as the keyframe, **empty**: no
> people, no tables, no stools, no food. Teak wainscot walls, cream upper
> walls, green-and-cream tiled floor, pendant lamps, ceiling fan, framed old
> Yangon photos, a potted palm, the open entrance door on the far left, the
> takeaway window with an empty steel shelf on the far right. The floor area
> across the middle (from 30 % to 55 % of the height) is clear and evenly lit
> for tables to be placed on it. The bottom 45 % is plain dark floor (it will
> be covered by the counter). Camera as in the keyframe.

## 2. Kitchen counter — `kitchen_counter.png`

> 2560×720, transparent above the counter. Same camera and style. A long
> two-tier counter filling the width: **back row** a brushed-steel cooking
> range (empty, no burners drawn), **front row** a brushed-steel prep surface
> with a warm teak front edge. Completely empty: no appliances, no food. The
> top edge of the back row is a straight line at 12 % of the height, the row
> split at 50 %.

## 3. Tables — `tables.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×768, transparent. Same
> dining-room camera as the keyframe (eye level, slightly above).
> 1. small square teak table with two low wooden stools behind it, clean;
> 2. a free green-tea set alone: small clay teapot and two small cups;
> 3. a dirty-table overlay alone: two empty used noodle bowls with chopsticks
> and a few coins and folded kyat notes;
> 4. a small stack of gold coins alone.
> Items 2–4 are drawn at the size and position they would sit on table 1's top.

## 4. Stove and noodle pot — `stove_pot.png`

> Sprite sheet, 4 columns × 2 rows, each cell 1024×1024, transparent. The same
> cream enamel pot with navy rim, loop handles and painted red roses as
> `pot_bodies.png`, on the same square cast-iron gas burner, **no lid**,
> identical pot, burner, size and position in every cell; only the contents
> and flame change:
> 1. empty pot, burner off;
> 2. clear cold water, burner on (blue flame), still surface;
> 3. water at a rolling boil, big bubbles, flame on;
> 4. a hard square block of dry instant noodles just dropped into boiling
> water;
> 5. noodles softening and loosening in boiling water;
> 6. perfectly cooked golden wavy noodles in hot water, glossy;
> 7. overcooked soggy, swollen, pale mushy noodles, murky water;
> 8. round white fish balls boiling in water.
> No steam (added in game), no text.

## 5. Kettle — `kettle.png`

> Sprite sheet, 2 columns × 1 row, each cell 1024×1024, transparent. A dented
> aluminium kettle with a black handle: 1. standing upright; 2. tilted about
> 45° pouring a clear stream of water to the lower left.

## 6. Broth stockpots and sauce — `broths.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×1024, transparent. A tall
> brushed-steel stockpot with a long steel ladle resting inside, identical pot
> in cells 1–2:
> 1. clear golden chicken broth with a few herbs;
> 2. orange-red Tom Yum broth with lemongrass, kaffir lime leaves and chilli;
> 3. dry-noodle sauce set: a glass bottle of dark Mala sauce and a small jar
> of red chilli oil with a spoon;
> 4. the ladle alone, tilted, pouring a stream of golden broth.

## 7. Grill and beef — `grill.png` and `beef.png`

`grill.png`:
> 2048×1024, transparent. A rectangular charcoal grill with a black iron grate
> and glowing orange coals beneath, three equal grilling places from left to
> right, empty, same camera.

`beef.png`:
> Sprite sheet, 4 columns × 1 row, each cell 512×512, transparent. One thin
> slice of beef, the size of one grill place, same angle as the grill:
> 1. raw, red and marbled;
> 2. seared on the underside only, edges browning, top still red (needs a
> flip);
> 3. fully cooked, glossy brown with dark crossed grill marks;
> 4. charred black and shrunken, burnt.

## 8. Egg boiler — `egg_boiler.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×1024, transparent. A small
> steel saucepan with a long handle on a small gas burner, same in every cell:
> 1. boiling water, empty;
> 2. two whole white eggs in boiling water;
> 3. two cracked overcooked eggs leaking white foam (ruined);
> 4. **item only, no pot**: one soft-boiled egg cut in half showing a jammy
> orange yolk, two halves side by side.

## 9. Fryer and shrimp — `fryer.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×1024, transparent. A small
> steel deep fryer with a wire basket, same in every cell:
> 1. hot golden oil, empty basket lowered;
> 2. pale battered shrimp sizzling in the oil, small bubbles;
> 3. basket lifted, crisp golden fried shrimp draining;
> 4. basket lifted, burnt dark-brown shrimp, a wisp of smoke.

## 10. Cutting board — `cutting_board.png`

> Sprite sheet, 4 columns × 2 rows, each cell 1024×1024, transparent. The same
> round wooden cutting board in every cell, a cleaver lying at the top edge:
> 1. empty board;
> 2. a whole bunch of spring onions;
> 3. spring onions half chopped (left half sliced into rings);
> 4. a neat pile of chopped spring onion rings;
> 5. a whole lime;
> 6. the lime cut into four wedges;
> 7. a bunch of fresh coriander;
> 8. a small pile of sliced red bird's-eye chillies.

## 11. Topping trays and sources — `trays.png`

> Sprite sheet, 4 columns × 4 rows, each cell 512×512, transparent. The same
> small rectangular brushed-steel tray (bain-marie insert) in every cell, filled
> generously:
> 1. chopped spring onion; 2. coriander leaves; 3. sliced red chilli;
> 4. lime wedges; 5. soft-boiled egg halves; 6. grilled beef slices;
> 7. fried shrimp; 8. fish balls; 9. golden fried garlic in a small glass jar;
> 10. red chilli oil in a small glass jar; 11. a tray of raw beef slices;
> 12. a tray of raw peeled shrimp; 13. a small wire basket of whole white eggs;
> 14. a stack of three dry instant-noodle blocks (no packaging);
> 15. the same spring-onion tray almost empty (one portion left);
> 16. the same grilled-beef tray gone cold: greyish, no shine.

## 12. Bowls — `bowls.png`

> Sprite sheet, 4 columns × 2 rows, each cell 1024×1024, transparent. The same
> cream enamel noodle bowl with a navy rim and painted red roses in cells 1–6,
> identical size and position:
> 1. empty clean bowl;
> 2. cooked golden noodles only, no broth;
> 3. noodles in clear golden chicken broth;
> 4. noodles in orange-red Tom Yum broth;
> 5. dry noodles tossed in dark red Mala sauce, glossy;
> 6. dirty empty bowl with a little broth left and chopsticks;
> 7. a round kraft-paper takeaway bowl, empty;
> 8. the same takeaway bowl with noodles in golden broth.

## 13. Bowl topping overlays — `bowl_toppings.png`

> Sprite sheet, 4 columns × 2 rows, each cell 1024×1024, transparent, **exactly
> the same frame as `bowls.png`** (attach it as reference): only the topping,
> placed where it sits on the noodles in bowl cell 3, so it can be layered on
> top of any filled bowl. Each topping keeps to its own area so several can
> stack:
> 1. three grilled beef slices fanned on the right;
> 2. two soft-boiled egg halves at the front;
> 3. three fried shrimp on the left;
> 4. four fish balls at the back;
> 5. chopped spring onion sprinkled in the centre;
> 6. coriander leaves at the back right;
> 7. sliced red chilli scattered at the front left;
> 8. one lime wedge on the rim at the right.

## 14. Takeaway — `takeaway.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×1024, transparent:
> 1. the kraft takeaway bowl closed with a clear dome lid;
> 2. a kraft-paper carry bag with a blank cream label area, handles up;
> 3. a takeaway drink cup with lid and straw;
> 4. a small steel packing counter with a roll of bags and a stack of lids.

## 15. Tea station — `tea.png`

> Sprite sheet, 4 columns × 2 rows, each cell 1024×1024, transparent:
> 1. a large steel tea urn with a tap;
> 2. an empty small glass cup on a saucer;
> 3. the cup filled with dark brewed tea;
> 4. the cup with creamy Myanmar milk tea (laphet yay), light caramel colour;
> 5. an open can of condensed milk with a spoon;
> 6. a tall glass of iced lemon tea with ice and a lime slice;
> 7. a tall empty glass with ice cubes;
> 8. a small clay teapot pouring green tea into a small cup.

## 16. Ticket icons — `ticket_icons.png`

> Sprite sheet, 6 columns × 3 rows, each cell 256×256, transparent. Small
> painted food icons, front view, bold and readable at 32 px, each with a thin
> white sticker outline, same style as the trays:
> noodles, chicken broth (golden ladle), Tom Yum broth (orange ladle), Mala
> sauce bottle, spring onion, coriander, chilli, lime wedge, egg half, grilled
> beef slice, fried shrimp, fish ball, milk tea cup, iced lemon tea, takeaway
> bag, dine-in table, delivery scooter, green-tea cup.

---

## 17. Waiter — `waiter_model.png` then `waiter_anim.png`

Same scale and rules as `prompts-customers.md`: adult 640 px tall in a
768×1024 cell, feet 40 px above the cell bottom, full body, transparent.

Character: young Myanmar man, ~24, neat short black hair, friendly smile,
white short-sleeve shirt, dark green apron with a small pocket, black
longyi-style trousers, black slip-on shoes, a small notepad in the apron pocket.

`waiter_model.png`, 4 columns × 1 row: front, three-quarter right, side right,
back. Neutral standing pose.

`waiter_anim.png`, 6 columns × 4 rows, each cell 768×1024, using the model
sheet as reference. All side or three-quarter views **facing right** (the game
mirrors them):
- row 1: walking cycle carrying one noodle bowl on a round steel tray at
  shoulder height, 6 frames, contact-pass-contact-pass;
- row 2: walking cycle carrying a stack of two dirty bowls in both hands,
  6 frames;
- row 3: placing a bowl on a table (3 frames: reach, set down, step back);
  pouring green tea from a clay teapot (3 frames);
- row 4: idle breathing (2 frames), small polite bow (2 frames), wiping a
  table with a cloth (2 frames).

## 18. Chef guide — `chef_guide.png`

> Sprite sheet, 4 columns × 2 rows, each cell 768×768, transparent. Waist-up
> portrait of the same friendly Myanmar woman chef, ~35, hair tied back under
> a white chef's cap, white chef jacket with green piping, a small towel over
> one shoulder, same character in every cell, same scale and position:
> 1. neutral smile; 2. big happy smile; 3. pointing to the right (teaching);
> 4. thumbs up; 5. worried, hand on cheek; 6. celebrating, both arms up;
> 7. surprised; 8. wink.

## 19. Seated guests — `<prefix>_seated.png` (one per customer)

For each of the six existing customers in `prompts-customers.md`, using that
customer's model sheet as the reference:

> Sprite sheet, 4 columns × 1 row, each cell 768×768, transparent. The same
> character **seated at a table, seen from the front, upper body only, cut off
> straight at the hips** (a table will cover the cut), arms resting where a
> table top would be, same scale and position in every cell:
> 1. waiting, looking ahead politely;
> 2. eating noodles with chopsticks, noodles lifted to the mouth;
> 3. eating, chopsticks lowered, chewing happily;
> 4. satisfied, thumbs up, big smile.

The existing standing sheets cover entering, waiting at the takeaway window
and leaving angry, so no new standing art is needed.

---

## Hand-off

Drop the PNGs into `packages/yumyum_kitchen/art/sources/restaurant/` (create
the folder). I will check the angle, scale and style against the keyframe,
trim and pack them into WebP atlases with `tool/pack_art.dart`, and report any
sheet that needs a re-roll before wiring it in.

| Priority | Files | Needed for |
|---|---|---|
| 1 — first playable | 0, 1, 2, 3, 4, 5, 6, 12, 16 | Day 1: water → noodles → broth → serve |
| 2 — toppings | 7, 8, 9, 10, 11, 13 | Days 2–8 |
| 3 — people | 17, 18, 19 | Waiter, guide, seated guests |
| 4 — later days | 14, 15 | Takeaway, drinks |

---

## 20. Clean dining room — `restaurant_clean.png` (image edit)

The kitchen already uses the keyframe's own counter (`tool/pack_art.dart`
builds `kitchen_plate.webp` from it), so only the **dining room** still
needs a version without people. Use an **image-edit** tool with
`restaurant_keyframe.png` as the input image:

> Edit this exact image. Keep the camera, composition, lighting, colours and
> every object's position pixel-identical. Remove only these, filling in
> what was behind them so it looks naturally empty:
> 1. all six people: the three seated guests on the left and middle
> tables, the grandmother on the right, the waiter in the green apron, and
> the delivery rider at the takeaway window;
> 2. everything on the four tables: bowls, noodles, chopstick cups and
> sauce jars (keep the tables and all wooden stools);
> 3. the boxes on the takeaway shelf.
> Leave the kitchen counter in the lower half exactly as it is. Output
> 2560×1440, no text.

Drop it in `art/sources/restaurant/restaurant_clean.png`.
