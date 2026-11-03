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

### Phase 2: Walk & camera (M1) · **M**
- Aurelia (capsule placeholder) moves in any direction, dashes, and climbs stairs automatically (no free jump).
- The **hybrid camera**: follow, rotate, zoom, reset, a scenic viewpoint test, and occlusion fade.
- Interact prompt (press E near a sign).
- **You'll see and play:** walking around the 3D test meadow. You judge the speed, camera and feel.

### Phase 2b: Look test, the "style diorama" · **M**
- **You make Aurelia in VRoid Studio** (I guide you step by step); I import her with her animations.
- One small, beautiful corner of Elderroot: World Tree, ruins, grass, water, golden hour.
- **You'll see:** a screenshot-worthy scene that **locks the art style** before we make lots of art.

### Phase 3: Combat core (M2) · **M** · *+ first Windows export test*
- Health, damage, staff strike, **stamina bar + Exhausted**, first 2 spells with **cooldowns**, dodge.
- One enemy (Thornling) with a visible **wind-up before each attack**, death and respawn, basic HUD.
- **First export:** build a real `.exe` once to make sure exporting works on your PC (export templates, about 1 GB, go to D:).
- **You'll play:** fight and defeat Thornlings. We tune the "feel" (hit freeze, knockback, timing) together.

### Phase 4: Magic & growth (M3) · **M**
- Elements (Light, Wind, Frost, Earth, Fire, Ember) with strengths/weaknesses; status effects.
- Spell book (Grimoire) with 4 slots; spell tomes; learning at a rest point; mastery I–V; **Magic Power and Arcane Rank** (Spark → Sovereign).
- Rank letters above enemies.
- **You'll play:** learning a spell visibly raises Aurelia's rank.

### Phase 5: Items & crafting (M4) · **M**
- Inventory, equipment (staff, cloak, 3 accessories), gathering herbs/ore, loot drops, workbench + recipes, potions.
- **You'll play:** gather materials, craft an accessory, equip it and feel the difference.

### Phase 6: World systems, story & sound (M5 + M6) · **L**
- Conversations with portraits and choices (Dialogue Manager), NPCs, quests, journal, first puzzles (brazier, push block, hidden path), Lumen hints.
- **Save/Load** (JSON), rest points, day/night cycle, rain, region transitions.
- **Audio system** with your music: title song *Sunlight on Ancient Stone*, region music, adaptive explore↔combat music, placeholder sound effects.
  I analyse your four new tracks here (tempo, key, vocals, loop points) and suggest where each fits.
- **You'll play:** talk to villagers, finish a small side quest with a puzzle, save, quit, reload, and everything is as you left it.

### Phase 7: Your dragon (M7) · **M**
- Dragon egg → hatching cutscene → naming → the hatchling follows Aurelia; commands (Follow / Attack / Guard); bond.
- **You'll play:** hatch and name your dragon.

### Phase 8: First boss & vertical slice (M8) · **L**
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
