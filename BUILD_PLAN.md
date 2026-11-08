# Aethelgard — Build Plan (made for your PC)

> Written 2026-11-03. This is the **step-by-step plan for building the game on your laptop**.
> What the game *is*: [GAME_DESIGN.md](GAME_DESIGN.md). How the code is organised: [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md).
> What must work: [REQUIREMENTS.md](REQUIREMENTS.md). This file ties them into a plan you can follow.
>
> **Update 2026-11-03: the game is now 3D** (approved; see [3D_PROPOSAL.md](3D_PROPOSAL.md)). This plan is updated to match;
> the 3D look and performance were measured on your laptop before switching.

---

## 1. Your PC, and can it build this game?

I checked your laptop's hardware and software:

| Part | Your PC | Enough for this 3D game? |
|---|---|---|
| Laptop | ASUS TUF Gaming F15 (FX507ZC4) | ✅ |
| Processor | Intel Core i5-12500H, 12 cores / 16 threads | ✅ **Very good.** Fast for Godot, exports and tools |
| Graphics | NVIDIA **RTX 3050 Laptop (4 GB)** + Intel UHD (built-in) | ✅ **Yes, measured:** the 3D test level runs at ~270 FPS at 1080p (High); ~74 FPS on the Intel UHD (Low) |
| Screen | 1920×1080, 144 Hz | ✅ Exactly our game's base resolution |
| Memory (RAM) | **8 GB** (one 8 GB stick); only ~0.7 GB was free with your usual apps open | ⚠ **The main limit.** Fine if we're careful (§3) |
| Storage | 512 GB NVMe SSD. **C: 12 GB free** · **D: 109 GB free** | ⚠ C: is nearly full. ✅ D: has plenty, so **everything goes on D:** |
| Windows | Windows 11 (64-bit) | ✅ |
| Already installed | Git 2.45 + **Git LFS** ✅ · VS Code ✅ · Python 3.11 ✅ | ✅ Saves setup time |

### Verdict
**Yes, your laptop can build the whole game, in 3D too.** Measured on your PC: the 3D test level (shadows, fog, glow, 50,000 grass blades)
runs at ~270 FPS at 1080p on the RTX 3050 and uses about 1 GB of RAM. The real work in 3D is making the art (3D_PROPOSAL.md §5).
Only two things need care:
1. **RAM (8 GB).** Don't keep many heavy apps open while Godot is running, and **don't run Blender and Godot at the same time** with big files.
2. **Drive C: (12 GB free).** Install everything for the game on **D:** and keep C: from filling up.

> 💡 **Recommended for 3D (not required):** this laptop model usually has a **second RAM slot**. Adding another 8 GB DDR4-3200 stick (16 GB total)
> would remove the RAM limit and make the built-in graphics faster too. Check the free slot (or ask a shop) before buying.

---

## 2. Choices made to fit your PC

| Decision | Choice | Why it fits your PC |
|---|---|---|
| Engine | **Godot 4.7.2**, standard build (not .NET) | Small download, starts fast, no extra SDKs. Already chosen |
| **Graphics renderer** | **Forward+** (Vulkan) ✅ | Needed for the anime 3D look (shadows, fog, glow). Measured on your RTX 3050: ~3.7 ms per frame at 1080p, so plenty of headroom. Graphics presets (Low/Medium/High) keep it playable on weaker PCs |
| Where things live | Project on **D:\Aethelgard** (already there), Godot in **D:\Tools\Godot** | Keeps C: free |
| Godot "self-contained" mode | Settings, caches and export templates stored **next to Godot on D:**, not on C: | Saves ~1–2 GB on C: |
| Code editor | Godot's **built-in script editor** | Uses less RAM than running VS Code alongside (VS Code stays optional) |
| Placeholder art | **Simple 3D shapes** built by the level scripts | No art software needed early on |
| Placeholder sounds | Small **Python script** (Python is already installed) | Light; no extra apps |
| Version control | **Git + Git LFS** (already installed) | Saves every step; you can undo mistakes |
| 3D tools | **Blender 5.2.3** (portable, `D:\Tools\Blender`) ✅, **VRoid Studio** (you install), **Godot VRM importer** ✅ | All free; everything on D: |
| Source files Godot shouldn't import | `.gdignore` in `Game Images/` and `Audio_music/` | Godot won't make copies of 23 MB of reference images and the MP3s, so less disk and RAM |

---

## 3. Keeping within 8 GB of RAM

**While working on the game:**
- Close Chrome/Edge tabs you don't need, especially video and big web apps. Each tab can use 200–800 MB.
- Don't run other games, Blender or video editors at the same time as Godot.
- Keep **one** copy of the game running at a time (Godot can launch several by accident).
- Plug in the charger and set Windows power mode to **Best performance** while developing.

**Make Godot use the NVIDIA GPU** (one-time): Windows Settings → System → Display → Graphics → add the Godot `.exe` → **High performance**.
We also test the game on the Intel graphics sometimes (`--gpu-index 1`), to be sure it runs on weaker PCs.

**The game itself (performance budget):** the finished game must also run well on 8 GB PCs like yours.

| Budget | Target |
|---|---|
| Frame rate | Solid **60 FPS** at 1080p on the RTX 3050 (High); playable on the built-in Intel graphics (Low) |
| Game RAM use | **under 2.5 GB** |
| Video memory | **under 2.5 GB** |
| Area loading time | **under 5 s** (your NVMe SSD helps) |
| Download size of the finished game | **under 3 GB** |

How we stay inside it: textures mostly 1K–2K; characters ~20–40k triangles; automatic detail levels for far objects; grass drawn in batches;
music **streamed** from OGG files (not loaded fully into RAM); only the current region loaded at a time; object pooling for projectiles.

---

## 4. Keeping drive C: healthy

C: has **12 GB free**. Windows needs room for updates and its page file (13 GB already reserved), so aim for **20 GB+ free**:
1. Windows Settings → System → Storage → **Temporary files** → clean up; turn on **Storage Sense**.
2. Empty the Recycle Bin; move big files from Downloads/Desktop/Videos to **D:**.
3. Uninstall programs/games you no longer use.
4. **My own temporary analysis tools** (the Python environment and models I used to analyse your music) take **2.6 GB on C:** (measured, in the Temp folder). I can delete them; I'll ask you first.

**Rule from now on:** game tools, downloads, art and music files go on **D:**.

---

## 5. How we work together

| You (the owner) | Me (Claude) |
|---|---|
| Decide the story, look and feel; approve designs (💡 items) | Write the code, scenes, data files and dialogue drafts |
| Install software (or let me download it, with your OK) | Set up the project, Git, add-ons and settings |
| **Play each new build** for 5–10 minutes and tell me what feels wrong | Run automated tests, launch the game myself and take screenshots to check it |
| Make art and music with your tools (e.g. Gemini, Google's music tool) | Analyse, trim, convert and wire your art and music into the game |
| Approve commits/backups | Keep the docs and requirement status up to date |

**Every work session follows the same loop:**
```
Pick the next task in this plan → I build it → I test it (tests + run + screenshot)
→ you play it → you give feedback → I adjust → save to Git (with your OK) → tick the requirement ✅
```

**Godot basics you'll need** (5 minutes to learn): open the project in Godot → press **F5** to play → **F8** to stop.
The left panel shows the scene's objects, the bottom shows errors. That's enough to play-test.

---

## 6. The plan, phase by phase

Each phase ends with something you can **play or see**. Sizes: **S** = small, **M** = medium, **L** = large.
Phases 1–8 build the **vertical slice**: the first 30–45 minutes of the game, fully playable. Nothing from later regions is built before that works.

### Phase 0: Prepare your PC (one time) · **S**
- [ ] Free space on C: (§4).
- [x] Download **Godot 4.7.2, standard, Windows 64-bit** from the official GitHub release (86 MB zip, SHA-512 checksum verified). *Done 2026-11-03.*
- [x] Unzip to `D:\Tools\Godot\`, with an empty `_sc_` file next to the `.exe` (self-contained mode). *Done.*
- [x] `D:\Tools\Godot\godot.cmd` launcher created; `godot --version` → `4.7.2.stable.official`. *Done.*
- [ ] Optional: add `D:\Tools\Godot` to your user PATH so `godot` works in any terminal (I can do it with your OK).
- [x] Godot uses the NVIDIA GPU: confirmed in Phase 1, it chose the RTX 3050 on its own. Setting "High performance" in Windows (§3) is still a good safety step.
- [ ] Check Git knows your name and email (for saving history).
- **Done when:** Godot opens on your PC and `godot --version` works in the terminal.

### Phase 1: Project skeleton (M0) · **S** · ✅ Done 2026-11-03 (first Git commit waiting for your OK)
> **Result:** Godot opens the project; the check screen showed Godot 4.7.2, the Compatibility renderer (switched to Forward+ in Phase 1b) on the **RTX 3050**
> (it picked the NVIDIA GPU by itself) and all 13 global managers loaded; **12/12 tests pass**; frames take ~0.3 ms to draw.
> Re-run settings: `godot --headless --path . --script res://tools/setup/configure_project.gd`.
> Re-draw placeholders: `godot --headless --path . --script res://tools/placeholders/generate_placeholders.gd`.

- Git repository in `D:\Aethelgard` with `.gitignore` (Godot's `.godot/` cache folder) and **Git LFS** for images/audio.
- `.gdignore` in `Game Images/` and `Audio_music/` (keeps them as your source files, not game imports).
- `project.godot` set up: Compatibility renderer, 1920×1080, stretch mode, 60 FPS physics, V-Sync, input actions (WASD, mouse, gamepad), physics layer names.
- Folder structure from TECHNICAL_DESIGN.md §3; empty global managers (EventBus, GameState, AudioManager…).
- Add-ons: **GUT** (tests) and **Dialogue Manager** (conversations), downloaded with your OK.
- Placeholder art script: draws labelled coloured shapes at the final sizes.
- **You'll see:** the project opens in Godot; pressing F5 shows a test screen; the test runner says "all passed".

### Phase 1b: Switch to 3D · **S** · ✅ Done 2026-11-03
> **Result:** Forward+ renderer, Jolt physics, 3D physics layers, camera keys (Q/R rotate, wheel zoom, Z reset),
> Low/Medium/High graphics presets (F1–F3), shared anime shaders (toon, outline, ground, grass, mossy stone, water),
> a 3D test level with collisions, a performance overlay (F4) and a `--benchmark` mode. **19/19 tests pass.**
> Measured at 1080p: **273 FPS on the RTX 3050 (High)**, **74 FPS on the Intel UHD (Low)**, ~0.9–1.0 GB RAM.
> Blender 5.2.3 and the Godot VRM importer are installed. The 2D check screen and 2D sprite placeholders were retired.

### Phase 2: Walk & camera (M1) · **M** · ✅ Done 2026-11-03
> **Result:** Aurelia (a placeholder built from simple shapes following her character art: silver hair and braids,
> elf ears, plum capelet with gold trim, green coat, staff with teal gem and lantern) walks in any direction relative to
> the camera, dashes (cooldown, input buffer, i-frames), climbs stairs and is stopped by ledges. The hybrid camera follows,
> rotates (Q/R, middle-mouse drag), zooms (wheel), resets (Z), swings to a **scenic World Tree view** on the platform, and
> **fades walls and trees** that block the view. Signs can be read (E). The meadow now follows the Elderroot art: World Tree
> with sunbeams, arch gate with ivy, broken walls, stone slabs, flowers, cliffs with a waterfall, lantern shrine, and Lumen the
> blue butterfly. **38/38 tests pass.** Measured 1080p RTX 3050 High: 224–244 FPS, ~0.8 GB RAM.
- Aurelia (capsule placeholder) moves in any direction, dashes, and climbs stairs automatically (no free jump).
- The **hybrid camera**: follow, rotate, zoom, reset, a scenic viewpoint test, and occlusion fade.
- Interact prompt (press E near a sign).
- **You'll see and play:** walking around the 3D test meadow. You judge the speed, camera and feel.

### Phase 2b: Look test, the "style diorama" · **M** · 🟨 In progress (my part ready; waiting for your VRoid Aurelia)
> **Done so far:** 120+ free **CC0 animations** (Quaternius) downloaded and **retargeted** to Godot's standard humanoid
> skeleton, so they will drive your VRoid model too. A new animated character system picks idle/walk/jog/dash from movement,
> matches the animation speed to her real speed (no foot sliding), plays one-shot actions (casting, hits…), and puts her
> **staff in her right hand**. Try it now: press **V** in the meadow to switch to the animated stand-in mannequin, or open
> `src/world/test/character_viewer.tscn` (keys 1–7 play animations). **43/43 tests pass.**
> **Your step:** follow **[AURELIA_VROID_GUIDE.md](AURELIA_VROID_GUIDE.md)** and save `assets/models/characters/aurelia.vrm`.
- **You make Aurelia in VRoid Studio** (I guide you step by step); I import her with her animations.
- One small, beautiful corner of Elderroot: World Tree, ruins, grass, water, golden hour.
- **You'll see:** a screenshot-worthy scene that **locks the art style** before we make lots of art.

### Phase 3: Combat core (M2) · **M** · *+ first Windows export test* · ✅ Done 2026-11-03
> **Result:** health, magic stamina (Exhausted at 0, refills after 0.8 s), a free **staff strike** (left click), **Light Mote**
> (1, a homing light bolt) and **Gust** (2, wind cone that knocks back and staggers), per-spell cooldowns plus a short
> global cooldown, mouse/stick aiming with a ground reticle, getting hurt (knockback, brief protection), defeat and
> respawn at the shrine. Enemy: the **Thornling** (wanders, chases, shows a growing red ring before its spin attack,
> recovers, can be staggered; respawns after 6 s in the test meadow). Feedback: hit flash, hit-stop, screen shake,
> damage numbers (gold = weakness), enemy health bars. HUD: HP, stamina, 4 spell slots. Elements with strengths/weaknesses.
> **62/62 tests pass** (8 are real fights in a physics world). 1080p RTX 3050: ~238 FPS, ~0.8 GB RAM.
> Since Phase 4, Gust is no longer a starting spell: its tome lies on the World Tree platform (the Elderroot Trial comes later).
> **First Windows export works:** `build/windows/Aethelgard.exe` (104 MB engine + 1.7 MB game data) runs at 240 FPS.
> Export templates (Windows 64-bit only, ~210 MB, checksum verified) are in `D:\Tools\Godot\editor_data\export_templates\`.
- Health, damage, staff strike, **stamina bar + Exhausted**, first 2 spells with **cooldowns**, dodge.
- One enemy (Thornling) with a visible **wind-up before each attack**, death and respawn, basic HUD.
- **First export:** build a real `.exe` once to make sure exporting works on your PC (export templates, about 1 GB, go to D:).
- **You'll play:** fight and defeat Thornlings. We tune the "feel" (hit freeze, knockback, timing) together.

### Phase 4: Magic & growth (M3) · **M** · ✅ Done 2026-11-03
> **Result:** Aurelia now starts at **F · Spark** with only **Light Mote** and **Lantern Glow** (a light aura that dazes
> nearby enemies and **reveals hidden things**). She finds **spell tomes** in the meadow: Gust on the World Tree platform,
> and Mending Bloom (heal over time, needs Magic Power 20) **hidden at the arch** until Lantern Glow lights it up.
> Tomes are read by **resting at the Lantern Shrine** (heals, refills, clears effects, sets the respawn point); reading
> Gust raises her Magic Power enough to learn Mending Bloom in the same rest. Spells gain **mastery I–V** by use (more
> damage, lower cost and cooldown, more Magic Power). **Magic Power → Arcane Rank** (F Spark … S Sovereign) with a HUD
> badge, a progress bar and a **RANK UP** banner; each rank adds max stamina and HP. **Status effects:** Burn, Chill →
> Freeze, Daze, Ember Mark, with HUD chips and timers. The **Grimoire** (Tab or Start) pauses the game and lets you put
> any learned spell in any of the 4 slots. New enemy: the **Ember Wisp**, a floating flame that keeps its distance, aims
> (glow + ground line) and shoots **Burning** bolts; Light hits it for ×1.5. Enemy bars show their **rank letter**.
> The camera now also fades tree canopies right in front of the lens. **86/86 tests pass.**
> Measured 1080p RTX 3050 High: 220 FPS near the wisps, 237 FPS with the Grimoire open, ~0.8–0.9 GB RAM.
> Try it: `-- --spawn=wisp` starts next to an Ember Wisp, `-- --open=grimoire` opens the Grimoire.
> Not yet: the Elderroot Trial (Gust's real source), Arcane Seals (with puzzles, Phase 6), saving at the shrine (Phase 6).
- Elements (Light, Wind, Frost, Earth, Fire, Ember) with strengths/weaknesses; status effects.
- Spell book (Grimoire) with 4 slots; spell tomes; learning at a rest point; mastery I–V; **Magic Power and Arcane Rank** (Spark → Sovereign).
- Rank letters above enemies.
- **You'll play:** learning a spell visibly raises Aurelia's rank.

### Phase 5: Items & crafting (M4) · **M** · ✅ Done 2026-11-03
> **Result:** Aurelia now has a **bag** (items stack and sort by category) and **gear**: a staff, a cloak and 3 accessory
> slots. Equipping changes her stats at once. She starts with an Apprentice Staff, her Plum Capelet, one Healing Potion
> and two recipes. In the meadow she can **gather** Sunpetal, Moonbloom, Elderwood, Iron Ore and Lumen Crystals (they grow
> back), and enemies **drop materials** you walk over to collect (Thornlings: Thorn Fibre; Ember Wisps: Ember Cinders).
> **Recipe scrolls** are hidden around the meadow. Craft potions at the **crafting kit** beside the Lantern Shrine and
> accessories at the new **workbench** near the start: Lantern Heart Amulet (+20 max stamina), Ember-Ward Ring (−30% Ember
> damage), Swift Quill Charm (−10% cooldowns), each +5 Magic Power. **Tab** opens a book with **Inventory** and **Grimoire**
> pages (Q/R turns the page); potions are used from the Inventory. Picked-up items show in the lower right.
> **112/112 tests pass.** Measured 1080p RTX 3050 High: 218 FPS at the start, 226 FPS with a menu open, ~0.83 GB RAM.
> Try it: `-- --give=materials --open=crafting` (5 of every material, workbench open), `-- --open=inventory`.
> Not yet: upgrades +1 to +3 (V1), special accessory passives (V1), regrowth in in-game hours and saving (Phase 6).
- Inventory, equipment (staff, cloak, 3 accessories), gathering herbs/ore, loot drops, workbench + recipes, potions.
- **You'll play:** gather materials, craft an accessory, equip it and feel the difference.

### Phase 6: World systems, story & sound (M5 + M6) · **L** · ✅ Done 2026-11-04 (built in 3 parts with a check-in after each)
> **6a, world systems: ✅ done 2026-11-03.** Three villagers to talk to: the **Elder** by the shrine, **Maren** the
> herbalist and little **Tamsin** by the pond. Talking opens a parchment **dialogue box** with name plate,
> placeholder **portraits** that change expression, typing text and **choices**. Two **side quests**: *Herbs for Maren*
> (gather 3 Sunpetal → her Stamina Tonic recipe) and *Tamsin's Lost Satchel* in the new **old shrine ruins** east of
> the pond. There, light both **lantern braziers** (Light Mote or Lantern Glow) to sink the gate; **Lantern Glow reveals
> hidden steps** up to the satchel; optionally **Gust pushes a stone block** onto a plate to unlock a chest. Solved
> puzzles stay solved. **Lumen** (approved) now follows Aurelia, glows near secrets and gives gentle hints in speech
> bubbles when you're stuck; villagers make remarks as you pass. The Tab menu gained **Journal** (J) and **Options**
> (text speed, auto-advance, graphics, saved) pages, and the HUD shows the tracked quest. Conversations are drafts in
> `dialogue/` waiting for your approval. **138/138 tests pass.** 1080p RTX 3050 High: 202–235 FPS, ~0.8 GB RAM.
> Try it: `-- --spawn=ruins`, `-- --talk=maren` (or elder, tamsin), `-- --open=journal`.
> **6b, persistence & atmosphere: ✅ done 2026-11-04.** The game now opens on a **title screen** (Continue, New Game,
> Load Game, Options, Quit) over a painted Elderroot dusk. **Saving:** resting at a Lantern Shrine autosaves, so does
> arriving in a new area; **Esc** opens the Save page with 3 manual slots (save while standing by a shrine; load and
> quit to the title anywhere). Saves are JSON with a version number; quitting and loading puts Aurelia back where she
> stood with the world as she left it (puzzles, chests, picked plants, quests, items, spells, the clock).
> **Day and night:** a 20-minute day turns the sun and moon and colours the sky; nights are moonlit blue and the
> lanterns glow. **Weather:** every few game hours it may turn rainy (rain, darker light) or foggy. **A second area:**
> walk through the gate at the meadow's south edge to **Elderroot Village**: cottages around a well, a Lantern Shrine,
> Maren's herb garden; the Elder and Maren now live there. The HUD shows the day, time and weather.
> **158/158 tests pass.** 1080p RTX 3050 High: 207–276 FPS (title 366); Intel UHD Low at night in rain: 60 FPS;
> ≤ 1.3 GB RAM. Try it: `-- --region=elderroot_village`, `-- --hour=22 --weather=rain`, `-- --open=save`
> (any option skips the title, with saving off; add `--saves` to keep saving).
> **6c, audio: ✅ done 2026-11-04.** The game now has sound. Your song **Sunlight on Ancient Stone** plays on the title
> screen; **Where the Forest Remembers** plays in the meadow by day and its quiet middle by night; **Edge of the Blue**
> plays in the village (suggestions: you decide). A drum **combat layer** fades in while an enemy is after you and
> leaves a few seconds after. About 70 **placeholder sounds** (made by our own script): footsteps on grass and stone,
> staff, spells, hits per element, status effects, enemy alerts and wind-ups (as long as the visual warning), loot,
> chests, gathering, shrines, puzzles, menus, dialogue blips, and short stingers for new spells, rank-ups, quests,
> secrets and crafting. Birds and breeze by day, crickets by night, rain when it rains. Music is muffled while
> paused and quieter during conversations. **Options** has volume sliders. I analysed your four new tracks (tempo,
> key, vocals, loops: AUDIO_DESIGN.md §10.7). **169/169 tests pass**; 194–348 FPS.
> **Phase 6 is complete.**
- Conversations with portraits and choices (Dialogue Manager), NPCs, quests, journal, first puzzles (brazier, push block, hidden path), Lumen hints.
- **Save/Load** (JSON), rest points, day/night cycle, rain, region transitions.
- **Audio system** with your music: title song *Sunlight on Ancient Stone*, region music, adaptive explore↔combat music, placeholder sound effects.
  I analyse your four new tracks here (tempo, key, vocals, loop points) and suggest where each fits.
- **You'll play:** talk to villagers, finish a small side quest with a puzzle, save, quit, reload, and everything is as you left it.

### Phase 7: Your dragon (M7) · **M**
> **✅ Done 2026-11-04.** Help both villagers, then talk to the **Elder**: he gives Aurelia a **dragon egg** (your choice:
> the Elder gives it for now). Fight, solve puzzles and explore to warm it (the HUD shows its warmth); when it glows,
> **rest at a Lantern Shrine**: the egg wobbles, you pick its colour, **Frost, Wind, Earth or Light** (your choice: one
> dragon, element picked at hatching), it hatches and you **name it** (empty keeps **Pip**). The hatchling follows
> Aurelia and fights: **G** switches **Follow** (bites what comes after her) / **Attack** (goes after her target) /
> **Guard** (stands between her and danger, catches bolts); **H** is its **breath** (Frost chills, Wind throws back,
> Earth hits hard, Light dazes and lights braziers). It steps out of enemy warning rings, enemies it bites turn on it,
> and at 0 HP it curls up and comes back after 20 s or when you rest. **Bond** 1–10 grows from fighting together,
> **Dragon Treats** (new kit recipe) and petting (**E**); it adds Magic Power and unlocks a trait at bond 3. New HUD
> panel (bottom left) and a **Dragon page** in the Tab menu (stats, skills, command, feed, rename). Placeholder dragon
> of simple shapes, recoloured per element; 16 new placeholder sounds and a hatching stinger. Lines are drafts.
> **203/203 tests pass.** RTX 3050 High 207 FPS in a fight with the dragon; Intel UHD Low 62–63 FPS (64 without it);
> ~0.9 GB RAM. Try it: `-- --dragon=hatch` (the hatching scene now), `-- --dragon=frost --spawn=combat`
> (or wind, earth, light), `-- --dragon=ready` (then rest at the shrine), `-- --open=dragon --give=treats`.
> **Next: Phase 8, the first boss and the vertical slice.**
- Dragon egg → hatching cutscene → naming → the hatchling follows Aurelia; commands (Follow / Attack / Guard); bond.
- **You'll play:** hatch and name your dragon.

### Phase 8: First boss & vertical slice (M8) · **L**
> Built in 3 parts with a check-in after each (owner decision 2026-11-04): **8a** boss fight + Emberbound Scout,
> **8b** prologue with Ignis (Sylvaris, approved, drives him off) + the Gust Trial, **8c** the slice put together.
> **Before 8a (owner request 2026-11-04): ✅ map (M) and "show the way" (N)** with a main quest, *A Morning in
> Elderroot*, so there is always a next step.
> **8a: ✅ done 2026-11-05.** Follow the north path past the arch to a **scorched clearing**: a ring of fire seals it
> and the **Cinder Warden** (Emberbound Captain) fights you to your music *The Last Ascent*, with a boss bar at the top.
> Every attack shows its warning on the ground (sweep, charge lane, fire ring, ember fan); at 60% he calls Ember Wisps,
> at 30% he charges twice. Win: **Ember Core #1**, the Ember-Ward Ring and its recipe. Fall: he resets to full. New
> enemy: the **Emberbound Scout** (sword slash, fire dash). **221/221 tests pass.** Try it: `-- --boss`
> (straight into the fight; add `--dragon=light` for help), `-- --spawn=warden` (walk in yourself), `-- --spawn=scout`.
> **8b: ✅ done 2026-11-07.** **New Game now opens on Rank Day** in Elderroot Village: Aurelia reads on the bench by
> her cottage (the intro and first verse of *Sunlight on Ancient Stone*), walks to the new **Rank Stone** by the well
> (N shows the way) and touches it: the light stops at the first mark, **Spark**, and the Elder comforts her (your
> choice: the Elder holds the test). A strange horn: two **Emberbound Scouts** run in and the villagers hide. When
> they fall, **Ignis Varos** walks down the north road ("Power is a ledger, Spark. Yours is empty.") and you fight
> him: he can't be hurt ("Immune", rank "???" on the boss bar), you can't fall, and after 35 s or at 35% health he
> raises a great ember sphere. **Sylvaris** lands between you, breaks it with golden breath and sends Ignis away;
> he speaks to Aurelia, **Lumen wakes** (asleep until now) and he points her to an old Trial of the wind. The Elder
> sends her to the Trial and to Maren and Tamsin (your choice: the Elder still gives the egg later), and the road
> north opens. Every scene can be skipped by holding **Esc** (it fast-forwards, so nothing is lost; the dragon's
> colour still asks you). In the meadow, east of the old ruins, the **Windcall Shrine** hides three runes in the mist:
> **Lantern Glow** finds them, **Light Mote** lights them in order (one curl, two, three), then a **ring of wind**
> seals you in for two short waves, and the **Gust tome** rises on the altar (your music *The World Holds Its
> Breath* plays when you find it). Sylvaris and Ignis are placeholders of simple shapes; all lines are drafts.
> **263/263 tests pass.** Try it: New Game on the title screen, or `-- --prologue` (also `=stone`, `=attack`,
> `=ignis`, `=sylvaris`, `=elder` to start at a beat), `-- --spawn=trial` (walk to the shrine), `-- --trial`
> (straight into the Trial's fight). **Next: 8c, the slice put together — after your check-in.**
- Boss system (phases, arena, boss health bar), **Cinder Warden**, the prologue scene where **Ignis** appears and can't be beaten.
- Put it all together: prologue → Elderroot Meadow → first boss → egg hatches.
- **🎯 Milestone: the vertical slice.** 30–45 minutes of complete, polished play (placeholder art is fine).
- **You'll play:** the whole opening of the game. **This is the big decision point:** we fix what isn't fun before building more.

### Phase 9: Real art & sound for the slice · **M–L**
- Replace placeholders in the slice with real art and sound (see §7). The rest of the game then follows the same art pipeline.
- **You'll see:** the opening of the game looking and sounding like *Aethelgard*.

### Phase 10: The rest of the world (M9–M10) · **L**
- Azure Coast → Ruined Valley → Stormspire Highlands → Floating Isle: enemies, spells, puzzles, bosses, juvenile and adult dragon, Ignis encounters and the final battle, ending.
- Built **one region at a time**, each fully playable before the next starts.

### Phase 11: Polish & release build (M11) · **M**
- Balancing pass, menus, settings and accessibility, bug fixing, credits.
- Final Windows build; test on the Intel graphics and on another PC if possible.
- **Done when:** a finished `.exe` you can share.

---

## 7. Art & music pipeline on your PC (3D)

| | Early (Phases 1–8) | Final (Phase 9+) |
|---|---|---|
| **Characters** | Simple shapes (capsules) | **VRoid Studio** models (Aurelia first, in Phase 2b) |
| **Animations** | None or basic | **Quaternius Universal Animation Library** (CC0), Mixamo optional |
| **World** | Simple shapes with the final shaders | CC0 kits (Quaternius, Kenney) + own models in **Blender**, recoloured to one palette |
| **Effects** | Particles + glowing materials | Polished spell, hit and weather effects |
| **Music** | Your Google-tool tracks (6 so far) | More tracks; I analyse, trim, loop and convert them |
| **Sound effects** | Code-generated placeholders (Python) | Free CC0/CC-BY libraries (Kenney, Freesound), credited in CREDITS.md |
| **Portraits** | Labelled silhouettes | Rendered from the VRoid models, or AI-generated + cleanup |

**RAM tip:** close Blender before testing the game in Godot, and keep browser tabs to a minimum.
Full details: [3D_PROPOSAL.md](3D_PROPOSAL.md) §5–6.

---

## 8. Saving your work (backups)

- **Git** saves the full history on your PC, so you can undo any change.
- Your laptop has **one SSD**; if it fails, everything is lost. So also keep a copy elsewhere:
  - ❓ **Option A:** a **private GitHub repository** (free; check its storage limits for large art/audio files with Git LFS).
  - ❓ **Option B:** a regular copy to an external drive or cloud storage (Google Drive, OneDrive).
- I never push or upload anything without your OK.

---

## 9. Risks on this PC and what we do about them

| Risk | What could happen | What we do |
|---|---|---|
| RAM runs out | Godot slows down or freezes; Windows uses the page file | Close heavy apps (§3); keep game RAM under 1.5 GB; optional RAM upgrade |
| C: fills up | Windows updates fail; programs crash | Everything on D:; Godot self-contained; clean C: (§4) |
| Laptop overheats on long sessions | Slower performance | Charger plugged in, good airflow; Godot's editor only redraws when something changes (already the default) |
| Hybrid graphics (Intel vs NVIDIA) | Godot runs on the weaker GPU by mistake | Set "High performance" for Godot (§3); test on both on purpose |
| Disk failure / mistakes | Lost work | Git + an off-PC backup (§8) |
| Scope too big | The game never gets finished | Vertical slice first; build one region at a time; GDD §15 limits |

---

## 10. Decisions I need from you

1. ✅ **3D decided** (2026-11-03): Forward+ renderer, hybrid camera, VRoid characters, no free jump in v1. Blender + VRM importer installed.
2. ✅ **Godot downloaded and installed** by Claude (2026-11-03). ❓ The two add-ons (GUT, Dialogue Manager) get downloaded in Phase 1, with your OK.
3. ❓ **Backup:** private GitHub repo, external drive/cloud, or both?
4. ❓ **Cleanup:** may I delete my temporary music-analysis tools from C: (2.6 GB)?
5. ✅ **Art approach:** VRoid characters + CC0 kits + Blender (§7). Next for you: **install VRoid Studio** before Phase 2b.
6. Still open from the design docs: the 💡 story/mechanic ideas (GAME_DESIGN.md §16, DIALOGUE_DESIGN.md §15).
