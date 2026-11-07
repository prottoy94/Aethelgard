# Aethelgard — Design Notes (from the `Game Images` folder)

Small-scale, cozy-but-adventurous **3D anime open-world** game (switched from 2D on 2026-11-03; see [3D_PROPOSAL.md](3D_PROPOSAL.md)).
These notes come from looking at all 14 reference images. Nothing is final yet.

---

## 1. What the images tell us (overall feel)

- **Theme:** an ancient, overgrown world. Nature has taken back a lost kingdom.
  Ruins everywhere: arches, ivy-covered towers, broken columns, mossy stone stairs, tree roots over paths.
- **Mood:** peaceful and full of wonder, with a hint of mystery (a ring/portal in the sky, a broken spire, floating rubble).
- **Art style:** painterly anime backgrounds with soft light, god rays, mist, glowing particles and fireflies.
  Characters use clean anime line art with warm, detailed shading.
- **Lighting is the star.** Almost every image is about time of day: golden dawn, bright noon, purple dusk, starry night, stormy rain.
  → A **day/night cycle plus weather** will do most of the work to make the world feel alive.

### Colour palette (pulled from the images)
| Use | Colours |
|---|---|
| Grass / foliage | warm yellow-green, deep moss green |
| Stone / ruins | warm grey, grey-lavender in shadow |
| Water | turquoise / cyan with white sparkles |
| Dawn / day light | gold, peach, soft cream |
| Dusk / night | violet, magenta-orange horizon, navy sky |
| Magic accents | glowing blue (butterfly), amber (lantern), gold particles |

---

## 2. Image-by-image notes

| Image | What I see | Idea for the game |
|---|---|---|
| `7e840aa1…jpg` | Giant tree, god rays, stone tiles, ruined city in the distance | **World Tree**, the central landmark/hub |
| `…fiww…(1).jpeg` | Same giant tree at golden sunrise, misty ruins, stone stairs, roots | Starting area: **Elderroot Meadow** |
| `…fiww….jpeg` | Bright turquoise bay, green cliffs, waterfall, castle ruins on a cliff | **Azure Coast** region (swimming/fishing, beach) |
| `…k6vm….jpeg` | Dusk meadow, ivy arches, ruined towers, winding path, fireflies, small party of travelers | **Ruined Valley** region, best at dusk/night; hints at companions |
| `…s545…(1).jpeg` | Twilight valley, ruined tower, columns, cliffs with waterfalls, distant castle | Same Ruined Valley; the distant castle can be a later goal |
| `…s545….jpeg` | Rainy storm, gothic spire, floating rock fragments, flooded stone path | **Stormspire Highlands**: a darker, harder region with rain |
| `images.jpeg` | Broken tower under a dark ring/portal in the sky, ruined bridge | **Main mystery**: a "Sky Rift" above the world |
| `images (1).jpeg` | Island cliffs, sandy coves, sunset | Coast/islands overview: good for the world-map layout |
| `images (2).jpeg` | Bright flower meadow, rock spires, blue sky | Open plains, flowers to gather |
| `images (3).jpeg` | Golden ginkgo tree, small pagoda, floating mountain with a bone/serpent shape | Eastern-style **Floating Isle**, the final area |
| `white_hair_girl_character.jpeg` | Main heroine, standing with staff | **Player character**: main design sheet |
| `pose_1.jpeg` | Heroine kneeling, reading a glowing book | Idle animation / journal & quest menu art |
| `pose_2.jpeg` | Heroine looking back, winking, cape flowing | Title screen / character select pose |
| `pose_3.jpeg` | Heroine sitting on a wall with a glowing blue butterfly | Rest/save point pose; **butterfly companion** |

> Note: `images.jpeg`, `images (1)`, `images (2)`, `images (3)` and `7e840aa1…jpg` look like screenshots from existing games or trailers
> (`images (3)` even has a trailer disclaimer). We use them **only for mood**. All in-game art has to be our own.

---

## 3. Main character (from the 4 character images)

- **Look:** elf girl with long silver-white hair, side braids with small beads, pointed ears, amber/brown eyes, red teardrop earrings.
  The owner's close-up portrait (2026-11-07) shows no earrings and a crown braid on her right; the stand-in follows the
  portrait for her face and hair (earrings left off for now).
- **Outfit:** dark plum hooded cape with gold embroidery, green tunic over a cream dress, brown leather belts and straps,
  a satchel on the hip, fingerless gloves, dark leggings and boots.
- **Gear:** gnarled wooden staff with a gem on top and a **hanging lantern**.
  - ⚠ The gem colour changes between images (blue, red, teal). We should pick one.
    Idea: the gem **changes colour with the active element/spell**, which turns the inconsistency into a feature.
- **Personality (from the poses):** cheerful, curious, a little playful (the wink), a scholar/explorer (the book).
- **Role idea:** a young mage-explorer who records the lost kingdom in her journal.
- **Companion:** a glowing **blue spirit butterfly**. It can guide the player, light dark areas, and point to secrets.

---

## 4. Game ideas taken from the images

**World (small, about 5 regions linked around the World Tree):**
1. **Elderroot Meadow**: starting area, World Tree hub, tutorial.
2. **Azure Coast**: bay, waterfall, cliff castle ruins.
3. **Ruined Valley**: ivy arches and towers, fireflies at night.
4. **Stormspire Highlands**: constant rain, floating rubble, the gothic spire.
5. **Floating Isle / Sky Rift**: ginkgo trees, pagoda, the portal in the sky. Endgame.

**Core gameplay to consider:**
- Exploring with the staff lantern (lights caves and ruins at night).
- Simple staff magic combat (a few elemental spells, so the gem changes colour).
- **Journal**: discover ruins, creatures and lore and record them (ties to the reading pose).
- Gathering flowers and herbs (flowers appear in almost every image).
- Rest points at ruin walls / stone benches (sitting pose), used as save points.
- Day/night cycle plus rain weather; some secrets only appear at night or in rain.
- Climbing stairs and ruins, crossing cliffs and waterfalls.

**Visual tech we'll need:**
- Layered tilemaps (ground, details, Y-sorted objects, overhead canopy that fades when the player walks under it).
- Drifting cloud shadows and fog overlays (stands in for the parallax depth of the reference art).
- Particles: fireflies, light motes, rain, waterfall spray, magic sparkles.
- Light overlay / tinting for time of day, god-ray sprites, mist layers.
- Cape and hair animation (both blow in the wind in every image).

---

## 5. Open decisions (need the user's input)

1. ✅ **Camera: 3D hybrid** (decided 2026-11-03): high-angle play camera + low scenic camera at viewpoints. *Replaces the earlier 2D top-down 3/4 decision; the notes below are kept for history.*
   - ~~Camera view: top-down 3/4 view~~ (2D, superseded):
   - The reference images are side-on scenic paintings, so they act as **mood/colour targets**, not direct backgrounds.
     They can still be used directly for the title screen, loading screens and region-intro splash art.
   - Ruins, trees and towers are drawn as tall sprites with **Y-sorting** (the player walks behind and in front of them).
   - Cliffs and waterfalls become height levels/ledges on the tilemap; stairs connect the levels.
   - Parallax only for clouds/fog drifting over the map and the sky at the edges of high cliffs.
2. ✅ **Engine: Godot 4** (decided). Use TileMapLayer, Y-sort, CanvasModulate for time of day, PointLight2D for the lantern, GPUParticles2D for fireflies/rain.
3. ✅ **Art: placeholders first** (decided). Build everything with simple shapes and generated placeholder art,
   and keep sprite sizes/animation names consistent so real art can be swapped in later without code changes.
4. ✅ **Combat: light action combat** (decided). Real-time staff magic against a handful of enemy types.
   Exploration stays the main focus; combat should be short and readable, not grindy.
5. ✅ **Heroine's name: Aurelia.** The story (Ignis Varos, the unknown enemy, the Sky Rift) is now in [GAME_DESIGN.md](GAME_DESIGN.md).

---

## 6. First to-do list (once the decisions above are made)

- [x] Choose view (top-down 3/4)
- [x] Choose engine (Godot 4), art approach (placeholders) and combat level (light action)
- [ ] Set up the Godot project skeleton
- [ ] Basic staff attack + one simple enemy (after movement works)
- [ ] Player movement + camera on a test map
- [ ] Heroine placeholder sprite (idle / walk, 4 or 8 directions)
- [ ] First region: Elderroot Meadow with the World Tree
- [ ] Day/night tint + fireflies/particles
- [ ] Butterfly companion that follows the player
- [ ] Interaction system (talk / inspect / pick up) + journal UI
- [ ] Save/rest points
- [ ] Add the next regions one by one
