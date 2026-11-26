# Image prompts — realistic pot, lid and steam assets

Generated assets replace the sliced lids in `PotSprites` (#28) and the
procedural steam puff (#29) with properly painted, separable pieces.

## Rules for every image

- **Transparent background** (PNG with alpha). No shadow on the ground, no table.
- **Same camera** as the existing art (`assets/images/equipment.webp`, top row):
  three-quarter view from the front, looking down about 30°, pot centred.
- **Same style**: semi-realistic painted illustration, warm night-market light
  from the upper left, soft reflections; cream enamel with a navy-blue rim and
  handles and a band of red roses with green leaves, like the existing pots.
- **Grid layout** where asked: equal square cells, each object centred and the
  same scale in every cell, nothing crossing a cell edge.
- Attach `assets/images/equipment.webp` as a style and angle reference if the
  generator accepts a reference image.

---

## 1. Pot bodies without lids — `pot_bodies.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×1024, transparent background.
> Semi-realistic painted illustration of the same vintage cream enamel cooking
> pot with navy-blue rim and loop handles and a band of painted red roses with
> green leaves, sitting on a small square cast-iron gas burner with a blue gas
> flame ring, three-quarter view from the front looking down about 30 degrees,
> warm light from the upper left. **No lid in any cell.** Identical pot, burner,
> size and position in every cell; only the contents change:
> 1. empty clean pot, burner off (no flame);
> 2. water at a rolling boil with a block of instant noodles softening, small
> bubbles, flame on;
> 3. cooked golden instant noodles, glossy, flame on;
> 4. burnt blackened noodles stuck to the pot, scorch marks on the inner wall,
> flame on.
> No steam, no lid, no text, no ground shadow.

## 2. Lids — `pot_lids.png`

> Sprite sheet, 2 columns × 1 row, each cell 1024×1024, transparent background.
> Same style and camera as the pot sheet, and drawn exactly to fit that pot's
> rim (same width and ellipse as the rim):
> 1. a clear tempered-glass lid with a navy-blue enamel knob and a thin navy
> rim, seen closed and level, with soft reflections and a little condensation;
> 2. a matching cream enamel lid with a navy rim, a navy knob and one painted
> red rose on top, seen closed and level.
> Lids only, centred, no pot, no steam, no text.

## 3. Steam puffs — `steam_puffs.png`

> Sprite sheet, 4 columns × 2 rows, each cell 512×512, transparent background.
> Realistic soft white cooking steam wisps rising from a hot pot, eight
> different shapes from a thin curling wisp to a full billowing puff, soft
> edges, semi-transparent, white with a very faint warm tint, lit from the
> upper left, each centred in its cell with empty margin. No pot, no background.

## 4. Burnt smoke puffs — `smoke_puffs.png`

> Sprite sheet, 4 columns × 1 row, each cell 512×512, transparent background.
> Realistic dark grey-brown smoke puffs from burnt food, four shapes from a thin
> curl to a thick billow, soft edges, semi-transparent, each centred with empty
> margin. No pot, no background.

## 5. Boiling surface overlay (optional) — `boil_surface.png`

> Sprite sheet, 4 columns × 1 row, each cell 1024×512, transparent background.
> Top-down-at-30-degrees view of a boiling water surface shaped as a flat
> ellipse that matches the pot mouth, animation frames of bubbles forming and
> popping with small splashes, realistic, light from the upper left. Only the
> water surface ellipse, everything else transparent.

---

## Hand-off

Drop the PNGs into `packages/yumyum_kitchen/art/sources/`. I will check the
angle and scale against the current pots, trim and pack them into WebP atlases
in `assets/images/`, and wire them into `PotSprites` and `SteamField`.
