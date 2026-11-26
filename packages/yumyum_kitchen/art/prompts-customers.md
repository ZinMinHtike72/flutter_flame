# Image prompts — full-body customers

Six customers, full body, with the animation states the game needs. Generate
in two passes per customer so the character stays the same in every frame:

1. **Model sheet** (one image): defines the character.
2. **Animation sheet** (one image): every state, using the model sheet as the
   reference image.

Attach `assets/images/people.webp` as a style reference for pass 1, and the
customer's own model sheet as the reference for pass 2.

## Rules for every image

- **Transparent background** (PNG with alpha). No floor, no ground shadow, no
  text, no frame numbers, no grid lines.
- **Style**: semi-realistic painted illustration, the same as the existing
  customers: warm Yangon night-market lighting from the upper left, soft rim
  light, friendly faces, clean outlines.
- **Full body, head to shoes**, standing on the same baseline in every cell:
  feet 40 px above the bottom edge of the cell, never touching the cell edges.
- **Same scale** for every customer: an adult is 640 px tall from shoe sole to
  top of head in a 768 px tall cell. The teen is 600 px, the grandmother 580 px.
- **Grid**: equal cells exactly as specified, the character centred
  horizontally in each cell.

## The six customers

| # | File prefix | Character | Full-body outfit |
|---|---|---|---|
| 1 | `customer_teen` | Teenage boy, ~16, curly black hair, big smile | Green plaid flannel shirt open over a white T-shirt, black headphones around his neck, brown canvas backpack, blue jeans, white sneakers |
| 2 | `customer_flower` | Young woman, ~25, black hair in a low bun with a white frangipani flower, small gold earrings | Cream lace Myanmar blouse (eingyi), golden-beige silk htamein (wrap skirt) to the ankles, brown leather shoulder bag, slim watch, flat gold sandals |
| 3 | `customer_uncle` | Heavy-set man, ~45, curly hair, round wire glasses, moustache and goatee, warm smile | Lavender short-sleeve shirt, purple checked scarf over one shoulder, dark green checked longyi (wrap sarong) knotted at the waist, brown velvet slippers, wristwatch |
| 4 | `customer_phone` | Young woman, ~22, shoulder-length black bob, sunglasses pushed up on her head, gold hoop earrings | White button shirt, light-blue straight jeans, tan crossbody bag, lilac smartphone in her hand, white sneakers |
| 5 | `customer_grandma` | Grandmother, ~70, silver hair in a bun, kind wrinkles, slightly stooped | Purple floral blouse, lavender shawl over her shoulders, deep purple htamein to the ankles, black velvet slippers, small cloth handbag |
| 6 | `customer_rider` | Delivery rider, ~28, glossy red motorbike helmet with open visor | Red jacket with grey reflective stripes, black gloves, large red insulated square delivery backpack, dark cargo trousers, black sneakers |

---

## Pass 1 — model sheet (one per customer)

File: `<prefix>_model.png`, 4 columns × 1 row, each cell 768×1024,
transparent background.

> Character model sheet, semi-realistic painted illustration, warm Yangon
> night-market lighting from the upper left, transparent background, full body
> head to shoes, four views of the same character in a neutral standing pose:
> front, three-quarter front facing right, side profile facing right, back.
> Same height, same baseline, same scale in all four cells, arms relaxed.
> Character: **[paste the "Character" and "Full-body outfit" cells from the
> table]**. No text, no floor, no shadow, no grid lines.

---

## Pass 2 — animation sheet (one per customer)

File: `<prefix>_anim.png`, **8 columns × 4 rows**, each cell **384×768**
(sheet 3072×3072), transparent background.

> Sprite animation sheet for a 2D game, semi-realistic painted illustration
> matching the reference character exactly (same face, hair, outfit, colours
> and proportions in every frame), warm light from the upper left,
> transparent background, full body head to shoes, feet on the same baseline
> 40 px above the bottom of each cell, 8 columns × 4 rows of equal 384×768
> cells, the character centred in each cell. Rows:
>
> **Row 1 — walk cycle, side view facing right, 8 frames**: a smooth looping
> natural walk: contact, down, passing, up, contact (other foot), down,
> passing, up. Arms swing opposite to legs, the head bobs slightly. Frame 8
> must flow back into frame 1.
>
> **Row 2, frames 1–4 — waiting, front view, 4 frames**: a calm idle loop,
> gentle breathing, a small blink in frame 3, looking up at a menu with a
> friendly expression. Frame 4 flows back into frame 1.
>
> **Row 2, frames 5–8 — impatient, front view, 4 frames**: the same position,
> frowning slightly, glancing at a wristwatch (or phone), tapping one foot,
> shifting weight. Loops.
>
> **Row 3, frames 1–4 — served and happy, front view, 4 frames**: reaching
> forward with both hands, receiving a bowl of noodles, lifting it a little,
> then a delighted smile with eyes closed and a small thank-you bow while
> holding the bowl. Plays once.
>
> **Row 3, frames 5–8 — missed and annoyed, front view, 4 frames**: an
> exaggerated sigh, shoulders drop, arms cross, then the character starts to
> turn away to the right. Plays once. Comedic, not angry or aggressive.
>
> **Row 4 — walk away, back three-quarter view walking right, 8 frames**: a
> looping walk seen from behind and slightly to the side, holding the noodle
> bowl in frames for a happy exit (the game can mirror it). Frame 8 flows back
> into frame 1.
>
> Character: **[paste the "Character" and "Full-body outfit" cells from the
> table]**. No text, no numbers, no floor, no shadow, no grid lines.

### Tips for a consistent result

- Generate the model sheet first and reuse it as the reference image for the
  animation sheet; regenerate single rows if a frame drifts.
- If the generator cannot do 8×4 in one image, generate each row as its own
  8×1 (or 4×1) image at the same cell size: `<prefix>_walk.png`,
  `<prefix>_idle.png`, `<prefix>_impatient.png`, `<prefix>_happy.png`,
  `<prefix>_annoyed.png`, `<prefix>_walk_away.png`.
- Keep the feet on the baseline in every frame: this is what makes the walk
  look smooth instead of jittery.

## Hand-off

Put the PNGs in `packages/yumyum_kitchen/art/sources/customers/`. Then give the
developer the prompt in `art/dev-prompt-customers.md`.
