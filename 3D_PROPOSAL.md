# Aethelgard in 3D: Proposal

> Written 2026-11-03. **✅ APPROVED the same day** with these decisions: **hybrid camera (C)**, **VRoid Studio** for characters,
> **install Blender + the VRM importer** (done), **convert to 3D** (done, Phase 1b), **no free jump in v1**.
> The design docs are updated to match. This file stays as the record of the reasoning and measurements.
> 💡 = my suggestion · ❓ = your decision.

---

## 1. Short answer

**Yes, Aethelgard can be a 3D anime game built on your laptop.** I didn't guess this; I measured it.

I built a **throwaway 3D test scene** (in a scratch folder, not in your project) and ran it once on your laptop at full 1920×1080 with the
features an anime look needs: toon shading, outlines, shadows, fog, glow, ambient occlusion, 50,000 swaying grass blades, 4,000 flowers,
80 trees, ruins, water, fireflies and a glowing spell.

| Measured on your laptop | Result | What it means |
|---|---|---|
| Graphics | **RTX 3050, Vulkan, Forward+ renderer** | The full Godot 3D feature set works |
| Speed at 1080p | **~180–190 frames per second** (5.3 ms per frame) | 60 FPS needs 16.7 ms, so there's about **3× headroom** for real art |
| Game RAM | **985 MB** peak | Fits in 8 GB, even with the editor open |
| Video memory | **304 MB** of 4 GB | Lots of room for real textures |
| Errors | **none** | |

**The real limit isn't your PC, it's making 3D art.** Characters, animations and environments take more work than 2D sprites.
§5 explains how we keep that manageable with free tools and free, legal asset libraries.

---

## 2. How it would look

### 2.1 The test frames (made from basic shapes; final art will look far better)

**Gameplay camera** (what you see most of the time):

![Gameplay camera test](docs/concept/3d_test_gameplay_camera.png)

**Scenic camera** (special moments, e.g. reaching a viewpoint):

![Scenic camera test](docs/concept/3d_test_scenic_camera.png)

These use only spheres, boxes and cones, with **no artwork at all**. They show the *camera angles, lighting and mood*, not the final quality.
In the real game, Aurelia is a proper anime character, trees have leafy canopies, ruins are carved stone, and so on.

### 2.2 The visual style 💡
**"Painterly anime 3D"**: the warm, soft look of your reference images, made in 3D with:
- **Cel-shaded characters:** two-tone anime shading, a soft rim light and thin outlines, so Aurelia looks drawn, not realistic.
- **Soft, painterly environments:** gentle colour gradients, wind-swayed grass and trees, moss growing on top of stone (already working in the test), sparkling turquoise water.
- **Light as the star** (as in the art notes): golden dawn, violet dusk, starry night and rain, with fog that fades distant mountains, glow on magic and lanterns, fireflies at night.
- **Readable combat:** attack warnings shown as **glowing rings on the ground** (the red ring in the test), with spell trails and impact flashes.

### 2.3 Your reference images → 3D

| Reference | In 3D |
|---|---|
| Giant World Tree with sunbeams | A huge landmark tree, visible from much of Elderroot. Sunlight glows through the canopy (the sun is behind it in the scenic test) |
| Turquoise bay, cliffs, waterfall | Stylised water shader with sparkles, foam at the edges, animated waterfall, real cliffs you walk along |
| Ivy arches, ruined towers, fireflies at dusk | Modular stone ruins (arches, columns, stairs) with moss, plus firefly particles at night |
| Stormy spire, rain, floating rubble | Dark sky, rain particles, wet stone, floating rocks bobbing in the air |
| Floating isle, golden ginkgo, pagoda | A real island in the sky, reached by dragon flight |
| Aurelia's four pose images | Her 3D model, idle animations and menu poses: reading the book, winking, the butterfly on her hand |

> Some of your reference images are screenshots from existing 3D anime games. We use them only for the **feeling** (anime 3D, bright open world).
> Our characters, world, models and designs will be our own.

---

## 3. The camera ❓ (the biggest decision)

| | **A. High-angle 3D camera** 💡 recommended | **B. Behind-the-shoulder camera** | **C. Hybrid** 💡 (A + scenic moments) |
|---|---|---|---|
| What it's like | Camera above and behind Aurelia, about 40–50° down, can **rotate** and **zoom** (first test frame) | Camera close behind her, you see to the horizon all the time (second test frame) | A for play; the camera swings low at special viewpoints to show the vista |
| Feel | Classic action-adventure: clear fights, easy mouse aiming, great for puzzles | Big open-world feel | Clear play **and** big views at chosen moments |
| Design changes | **Almost none.** The current design (mouse-aimed spells, puzzles, dash) works as written | Combat redesign (aim at screen centre, lock-on), camera collision | Same as A |
| Art needed | Only what's near the player needs detail | **Everything to the horizon** needs art and detail levels (much more work) | A, plus a few polished viewpoints |
| Speed on your PC | Very good | Good, but heavier | Very good |

**My recommendation: C (Hybrid).** It keeps the game manageable to build and plays well with mouse-aimed magic. It also gives you the
breathtaking views from your reference images at the moments that matter: arriving at the World Tree, the first sight of the Azure Coast, the Sky Rift.

---

## 4. What stays the same and what changes

**Stays the same (most of the work so far):**
- The story, characters, magic, stamina/cooldowns, crafting, dragons, puzzles, bosses, quests ([GAME_DESIGN.md](GAME_DESIGN.md)).
- Dialogue and cutscene plans, audio plans, your music and Aurelia's voice.
- **Phase 1 setup:** Godot 4.7.2 on D:, project, global managers, add-ons, tests, controls, audio channels, git. All reused.

**Changes:**

| Area | 2D plan | 3D plan |
|---|---|---|
| Renderer | Compatibility (OpenGL) | **Forward+ (Vulkan)**, needed for the anime 3D look (fog, glow, soft shadows, ambient occlusion). Your RTX 3050 runs it easily (§1) |
| Art | Sprite sheets drawn in 8 directions | **3D models + animations** (§5) |
| World | Tile maps | **3D terrain + modular pieces** (ruin kits, rocks, trees) |
| Characters | AnimatedSprite2D | Animated 3D models with an animation state tree (walk/run/cast/hurt blending) |
| Camera | Fixed 2D camera | **3D camera rig**: follow, rotate, zoom, scenic viewpoints |
| Physics | 2D bodies | 3D bodies, 3D navigation for enemies and the dragon |
| Attack warnings | Sprite flashes | **Glowing ground rings** |
| Placeholders | Generated 2D sprites | Simple 3D shapes, like the test |
| Controls | — | + camera rotate (Q/E or right mouse), zoom (mouse wheel) |
| Jumping ❓ | — | 💡 **No free jumping in v1**: climb ledges and stairs automatically, dash over gaps with Gale Step. Keeps levels and combat simpler |

---

## 5. Making 3D art on your PC (free tools, legal sources)

| What | How | Cost |
|---|---|---|
| **Aurelia and the main characters** | **VRoid Studio** (free, made by pixiv): an anime character maker with sliders and brushes, no 3D modelling skill needed. Silver hair, braids, pointed ears, outfit. Exports a VRM file, which a **Godot VRM importer add-on** loads, with anime (toon) shading and **automatic hair and cape sway**. You own and set the licence of characters you make yourself | Free |
| **Animations** | **Quaternius Universal Animation Library**: 120+ animations (walk, run, jog, idle, deaths…), **CC0** (free for any use), made for retargeting. Optional: Adobe **Mixamo** (free with an Adobe account) | Free |
| **Trees, rocks, ruins, props** | Free CC0 3D packs (Quaternius stylised nature, Kenney) as a base, recoloured and edited in **Blender**, plus our own simple models | Free |
| **Enemies & the dragon** | CC0 animated monster packs to start (e.g. Quaternius monsters include a dragon), customised in Blender. Commissioning the pet dragon is optional | Free (or paid, optional) |
| **Terrain** | Sculpted hills and paths with painted grass/dirt/stone, built in Godot | Free |
| **Effects** | Godot particles + glowing materials (like the spell and fireflies in the test) | Free |
| **Textures & concept art** | Your AI images (Gemini) for concepts, colour palettes and painted skies | Free |
| **UI, portraits** | 2D, as already planned (portraits can be rendered from the VRoid models) | Free |

Every asset gets an entry in [CREDITS.md](CREDITS.md) with its licence. CC0 means "use for anything". Assets for which we can't confirm the licence are never used.

---

## 6. Fitting your PC

### 6.1 Budgets for the game (so it also runs on 8 GB PCs like yours)
| Budget | Target | Test scene used |
|---|---|---|
| Frame time at 1080p (RTX 3050) | ≤ 16.7 ms (60 FPS), aim for ≤ 10 ms | 5.3 ms |
| Game RAM | ≤ 2.5 GB | 0.99 GB |
| Video memory | ≤ 2.5 GB | 0.3 GB |
| Characters | ~20–40k triangles each (VRoid can reduce polygons on export) | — |
| Area loading | ≤ 5 s | — |

How we stay inside the budgets: one region loaded at a time, automatic detail levels (Godot makes simpler meshes for far objects), grass drawn
in big batches (like the test), shadows only near the camera, fog hiding the far distance, textures mostly 1K–2K.
A **graphics settings menu** (Low/Medium/High plus resolution scaling) helps weaker PCs.

> **Honest note about the built-in Intel graphics:** 3D with this look will run on the Intel UHD only at **Low settings and lower resolution**.
> The RTX 3050 is the real target. For players, the minimum would be roughly a GTX 1050-class graphics card with 8 GB RAM.

### 6.2 Working within 8 GB of RAM
- Godot editor with a 3D level: about **1.5–2.5 GB**. The game while testing: **1–2.5 GB**. Blender with a model: **0.5–1.5 GB**.
- So: **don't run Blender, Godot and many browser tabs at the same time.** Close Chrome tabs while working, and close Blender before testing the game.
- 💡 **Upgrade recommended for 3D:** a second **8 GB DDR4-3200 stick (16 GB total)**. It isn't required, but 3D work becomes much more comfortable.

### 6.3 Disk
All tools and art on **D:** (109 GB free). Expect about **10–30 GB** of tools and 3D source files over the whole project. C: is untouched.

### 6.4 Tools to install (only with your OK)
| Tool | What for | Size (approx.) | Where |
|---|---|---|---|
| **Blender** (portable zip) | Editing models, recolouring kits | ~400 MB download, ~1.2 GB unpacked | `D:\Tools\Blender` |
| **VRoid Studio** | Making Aurelia and other characters | ~1–2 GB | D: (choose D: in the installer or Steam library) |
| **Godot VRM importer** add-on | Loading VRoid characters into Godot | small | inside the project |
| Asset packs (Quaternius, Kenney) | Animations and environment pieces | ~0.1–1 GB | `D:\Aethelgard` (git-ignored for now) |

---

## 7. Revised build plan (3D)

The 2D plan's phases stay in the same order. Each phase still ends with something you can play.

| Phase | Name | Contents | You'll see |
|---|---|---|---|
| 1 ✅ | Project skeleton | Done (reused) | Check screen |
| **1b** | **Switch to 3D** | Forward+ renderer, 3D physics layers, camera controls, graphics presets, a basic shapes test level, performance overlay | A 3D test level runs on your PC |
| **2** | **Walk & camera** | Aurelia (capsule placeholder) walks, dashes and climbs stairs; camera follow/rotate/zoom; scenic viewpoint test; interact prompt | Walk around a 3D meadow |
| **2b** | **Look test ("style diorama")** 💡 | One small, beautiful corner of Elderroot: World Tree, ruins, grass, water, golden hour, your **VRoid Aurelia** with animations. **Locks the art style before mass-producing art** | A screenshot-worthy scene that sets the look |
| 3 | Combat core | Staff strike, stamina + Exhausted, spells with cooldowns, Thornling with ground-ring warnings, death/respawn, HUD | Fight Thornlings |
| 4 | Magic & growth | Elements, Grimoire, learning spells, mastery, Magic Power & rank | Rank up |
| 5 | Items & crafting | Inventory, equipment, gathering, workbench | Craft and equip |
| 6 | World, story & sound | Dialogue, quests, puzzles, save/load, day/night, weather, your music | A side quest with a puzzle |
| 7 | Dragon | Egg → hatchling (3D) following Aurelia | Hatch your dragon |
| 8 | First boss → 🎯 **vertical slice** | Cinder Warden, prologue Ignis scene, everything together | The opening 30–45 minutes |
| 9–11 | Art, rest of the world, polish | As in BUILD_PLAN.md | The full game |

**Effort, honestly:** 3D takes more work than 2D, mostly in art and animation; roughly **1.5–2×** for the same content.
To keep the game finishable I'd keep the **same scope** (5 small regions, vertical slice first) and **build regions smaller and denser** rather than large and empty.

---

## 8. Risks

| Risk | Plan |
|---|---|
| Character animation looks stiff | Use the professional CC0 animation library; retarget it; tune blends early (Phase 2b) |
| Art style inconsistent (mixed asset packs) | Recolour everything to one palette; same toon shader on everything; lock the style in Phase 2b |
| RAM pressure while working | One heavy app at a time; optional RAM upgrade; budgets checked every phase |
| Scope grows with 3D | Same content targets as GDD §15; stretch goals stay stretch (e.g. real-time dragon flying) |
| Add-on (VRM importer) breaks on a Godot update | Pin versions; test before upgrading |

---

## 9. Decisions I need from you (before I start any work)

1. ❓ **Camera:** A (high-angle), B (behind-the-shoulder) or **C (hybrid, recommended)**?
2. ❓ **Characters:** make Aurelia in **VRoid Studio** (recommended), or another way (Blender, commissioning)?
3. ❓ **Tools:** may I download and install **Blender** (portable, on D:) and the **Godot VRM importer**? VRoid Studio you install yourself or I guide you.
4. ❓ **Go-ahead:** convert the project to 3D (Phase 1b) and update all design docs to match?
5. ❓ Jumping: no free jump in v1 (recommended), or yes?
6. 💡 Optional: RAM upgrade to 16 GB.

### Sources
- [VRoid conditions of use (VRoid Hub licence fields)](https://developer.vroid.com/en/guidelines/conditions_of_use.html)
- [Godot VRM importer (V-Sekai)](https://github.com/V-Sekai/godot-vrm)
- [Quaternius Universal Animation Library (CC0)](https://quaternius.itch.io/universal-animation-library)
