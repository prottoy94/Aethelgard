# CLAUDE.md — Aethelgard

**3D** anime action-RPG (hybrid high-angle camera) in **Godot 4.7.x (standard build, GDScript, Forward+ renderer, Jolt physics)**.
Switched from 2D on 2026-11-03 (owner-approved; see 3D_PROPOSAL.md).
The player is **Aurelia**, a silver-haired elf mage who starts with almost no magic. She grows by learning spells,
crafting gear and raising a pet dragon, and her goal is to defeat **Ignis Varos, Herald of the Final Ember**.

## Project status
- **Phases 1, 1b and 2 done** 2026-11-03. **Phase 2b in progress:** animation pipeline + animated stand-in done; **waiting for the
  owner's VRoid export** at `assets/models/characters/aurelia.vrm` (guide: AURELIA_VROID_GUIDE.md). When it arrives: inspect it with
  `tools/dev/inspect_scene.gd`, view it with `character_viewer.tscn -- --model=res://assets/models/characters/aurelia.vrm`,
  then make it the Player's default visual (HumanoidVisual) and build the style diorama.
- **Phase 3 (combat core) done** 2026-11-03: health/stamina/spells/strike/hurt/death, Thornling enemy, HUD. **62/62 tests pass.**
  Combat code: `src/components/` (Health, Stamina, Hitbox, Hurtbox), `src/magic/` (Elements, SpellData, SpellCaster, spells/),
  `src/actors/enemies/` (Enemy, EnemyData, states, thornling/), `src/core/fx/combat_fx.gd`, `src/ui/hud/`. Data: `data/spells/`,
  `data/enemies/`, `data/player/aurelia_combat.tres` (starting spells set via ResourceSaver so the typed array is valid).
  Tests that need hit-stop off set `CombatFx.hit_stop_enabled = false`. `--spawn=combat` starts next to a Thornling.
- **Phase 4 (magic & growth) done** 2026-11-03.
  Growth state lives in the `PlayerData` autoload (learned spells + mastery, unread tomes, loadout, Magic Power, rank; signals;
  `to_dict/from_dict` for saves). Rules: `MagicProgression` (`data/progression/magic_progression.tres`), `SpellLibrary`
  (`data/spells/spell_library.tres`, rebuild with `tools/dev/build_spell_library.gd` after adding a spell), status effects in
  `StatusEffectComponent` + `data/combat/status_rules.tres`. World: `src/world/items/spell_tome.gd`, `src/world/rest_point/`,
  menu `src/ui/menus/grimoire.gd` (Tab). New enemy `src/actors/enemies/ember_wisp/` (ranged, uses `src/magic/projectile.gd`).
- **Phase 6 is built in 3 parts with an owner check-in after each** (6a world systems → 6b persistence & atmosphere → 6c audio).
  **6a done** 2026-11-03. **6b done** 2026-11-04, **158/158 tests pass. Next: 6c** (AudioManager, owner's music, 4 new tracks).
  6b code: `SaveManager` (JSON slots auto + slot_1..3, version/migrate, `capture_player`), `SceneLoader` (regions from
  `data/world/regions.tres`, fades, `scene_parent` for tests), `TimeOfDay` (clock + weather, `data/world/time_settings.tres`),
  `src/world/environment/` (DayNightCycle + `data/world/day_night.tres`), `src/world/regions/` (RegionRuntime = shared
  player/camera/HUD/menus/sky setup, RegionExit, RegionSpawn, `elderroot_village/`), `src/ui/title/` (main scene),
  `src/ui/menus/save_menu.gd` (Esc). Tests use `SaveManager.save_dir = "user://test_saves/"` and `SceneLoader.scene_parent`.
  6a code: `src/ui/dialogue/` (DialogueBox, PortraitView, BarkSpeaker), `src/actors/npcs/` (Npc + placeholder look),
  `src/actors/lumen/` (Lumen, approved by the owner), `src/quests/` + `QuestManager` autoload, `src/world/puzzles/`
  (ElementalReceiver in `src/components/`, LanternBrazier, PushBlock, PressurePlate, HiddenSteps, PuzzleGate, Puzzle),
  `src/world/props/chest.gd`, menus `journal_menu.gd`/`options_menu.gd`, `Cutscene` autoload basics, Settings now saves
  `user://settings.cfg` (tests set `Settings.persist = false`). Data: `data/quests/`, `data/dialogue/`, `data/npcs/`.
  Dialogue drafts: `dialogue/npcs/elderroot_villagers.dialogue`, `dialogue/barks/lumen.dialogue`, `dialogue/glossary.md`.
  Elderroot braziers are lit by Light (owner decision). On a fresh clone run `--import` twice (preloads of `.dialogue` files
  fail until the first import has run). Tests also reset `QuestManager.reset()`.
- **Phase 5 (items & crafting) done** 2026-11-03.
  Items: `src/items/` (ItemData → ConsumableData / EquipmentData, GearBonus, RecipeData, LootTable, ItemLibrary, NewGameItems);
  the `Inventory` autoload holds the bag, 5 equipment slots, known recipes, crafting and `to_dict/from_dict`. PlayerData reads
  gear Magic Power and cooldown bonus from Inventory; the Player applies the other gear stats (`_apply_stats`). Data:
  `data/items/` (+ `gather/`), `data/recipes/`, `data/loot_tables/`; rebuild `data/items/item_library.tres` with
  `tools/dev/build_item_library.gd` after adding items or recipes. World: `src/world/items/` (GatherNode, ItemPickup,
  RecipeScroll), `src/world/props/crafting_station.gd`, `src/components/loot_dropper_component.gd`. Menus share
  `src/ui/menus/menu_screen.gd`; `GameMenu` (Tab) holds the Inventory and Grimoire pages; `CraftingMenu` opens at stations.
  Tests reset with `Inventory.reset()`, `PlayerData.reset([...])` and `GameState.reset()` in `before_each`.
  Main scene = `src/ui/title/title_screen.tscn`. **Any start option after `--` skips the title** into a new game with saving
  off (`--saves` keeps it on; `--title` keeps the title): `--region=elderroot_meadow|elderroot_village`,
  `--spawn=start|viewpoint|combat|wisp|ruins|from_village|from_meadow`, `--open=inventory|grimoire|journal|save|options|crafting`,
  `--talk=elder|maren|tamsin`, `--hour=<0-24>`, `--weather=clear|rain|fog`, `--give=materials`, `--visual=animated`,
  `--benchmark=<dir>`, `--graphics=low|medium|high`. The meadow is `src/world/test/test_level_3d.tscn` (region elderroot_meadow).
  Key code: `src/actors/player/` (Player, states, placeholder model, MovementStats), `src/game/camera/` (CameraRig, CameraSettings),
  `src/world/camera/scenic_viewpoint.gd`, `src/components/interactable_component.gd`, `src/core/` (StateMachine, Cooldown, ToonMaterials).
  Git repo exists (branch `main`, no remote). **The owner makes commits manually: never commit or push.**
  `.gitignore` excludes **all images and audio for now** (owner decision 2026-11-03): `Game Images/`, `Audio_music/`,
  placeholder PNGs (re-create with the generator after a clone). Only the add-ons' own icons are kept.
- Project settings, input map, physics layers, autoloads and audio buses come from `tools/setup/configure_project.gd`.
  Change them there and re-run it rather than hand-editing `project.godot`. World/character placeholders are simple 3D shapes in level scripts; only 2D UI icons come from `tools/placeholders/generate_placeholders.gd`.
- Add-ons (all MIT, in `addons/`): GUT 9.7.1 (tests), Dialogue Manager 4.2.0, Godot VRM importer 2.0.1 + MToon shader (V-Sekai, commit `e15199f`).
- **Blender 5.2.3 LTS** portable at `D:\Tools\Blender\blender.exe` (portable config folder, nothing on C:). VRoid Studio: the owner installs it.
- **Godot 4.7.2 is installed** at `D:\Tools\Godot` (self-contained mode via the `_sc_` file; checksum verified 2026-11-03).
  It is **not on PATH yet**: call `D:\Tools\Godot\godot.cmd` (wraps the console exe).
- **Owner's PC (build machine):** ASUS TUF F15, i5-12500H, RTX 3050 Laptop 4 GB + Intel UHD, **8 GB RAM**, 1080p 144 Hz,
  NVMe SSD with **C: nearly full (~12 GB free)** and D: ~109 GB free. Git + Git LFS, VS Code, Python 3.11 installed.
  → Put everything on **D:** (Godot in `D:\Tools\Godot`, self-contained mode). Keep RAM use low: don't start extra heavy processes,
  run one game instance at a time, close the game after checking it; never run Blender and the game together.
  Renderer **Forward+**. Measured 1080p: 273 FPS RTX 3050 (High), 74 FPS Intel UHD (Low), ~1 GB game RAM. Budgets: TECHNICAL_DESIGN.md §2.
- Owner-made music lives in `Audio_music/` (AI-generated with a Google tool). *Sunlight on Ancient Stone* contains **Aurelia's singing voice**.
  Analysis and usage plan: AUDIO_DESIGN.md §10. Separated instrumental and vocal stems (Demucs) are there too (§10.6).

## Documents (read the relevant one before working)
| File | What it holds |
|---|---|
| [BUILD_PLAN.md](BUILD_PLAN.md) | **Start here:** the phase-by-phase build plan, made for the owner's PC (hardware limits, setup, workflow) |
| [AURELIA_VROID_GUIDE.md](AURELIA_VROID_GUIDE.md) | Owner's step-by-step guide for making Aurelia in VRoid Studio and exporting the VRM |
| [GAME_DESIGN.md](GAME_DESIGN.md) | The game: story, characters, magic, combat, dragons, crafting, puzzles, world, scope |
| [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) | Architecture, folder layout, systems, save format, testing, **milestone roadmap** |
| [REQUIREMENTS.md](REQUIREMENTS.md) | Checkable requirements with IDs, priority (MVP/V1/Stretch) and status |
| [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md) | Conversations, cutscenes, portraits, barks, **character voice guide**, writing workflow |
| [AUDIO_DESIGN.md](AUDIO_DESIGN.md) | Music, sound list, mixer, adaptive music, placeholder generation, licences |
| [CREDITS.md](CREDITS.md) | Source and licence of every non-placeholder asset |
| [DESIGN_NOTES.md](DESIGN_NOTES.md) | Art direction notes from the reference images in `Game Images/` |

## Working rules
- **Design changes go into the docs.** If a decision changes, update GAME_DESIGN.md and REQUIREMENTS.md in the same change.
  Mark requirement status (⬜ → 🟨 → ✅) as work progresses. Never silently drop a requirement; mark it ❌ with a reason.
- Items marked 💡 (suggestion) or ❓ (open) in the GDD are **not approved**. Ask the owner before building on them.
- **Build in milestone order** (M0 → M8 → vertical slice). Don't start content for later regions before the vertical slice works.
- **Scope guard:** respect GDD §15 content targets. New big features go to "Stretch" unless the owner says otherwise.
- **3D art:** placeholders are simple shapes at real size (1 unit = 1 m, Aurelia ≈ 1.6 m) using the shared shaders in `assets/shaders/`
  (toon + toon_outline, ground, grass, stone_moss, water). Characters via VRoid → VRM; CC0 animations; props from CC0 kits/Blender, one palette.
  Keep visuals in a child node so models swap without gameplay-code changes. No free jump in v1.
  Animations: CC0 Quaternius library retargeted to `%GeneralSkeleton` (see TECHNICAL_DESIGN.md §4.15); use `HumanoidAnimSet` roles,
  not clip names. Dev tools in `tools/dev/` (inspect_scene, make_ual_bone_map, measure_gait_speed).
  Stairs = visible steps + one sloped collision box. Solid props = StaticBody3D root with meshes as children (needed for occlusion fade).
  Some files in `Game Images/` are screenshots from other games: **mood reference only, never use them as assets.**

## Code conventions (GDScript)
- Follow the official GDScript style guide. **Static typing everywhere** (`var hp: int`, `func f(x: float) -> void`).
- Files and folders `snake_case`; `class_name` in `PascalCase`; constants `UPPER_SNAKE_CASE`; signals in past tense (`died`, `spell_learned`).
- Organise **by feature** under `src/` (see TECHNICAL_DESIGN.md §3). One scene + its script live side by side.
- **Composition over inheritance:** use components (Health, Stamina, Hitbox, Hurtbox, StatusEffects, Interactable, SpellCaster).
- **State machines:** node-based `StateMachine` + `State` children (`enter/exit/update/physics_update/handle_input`).
- **No gameplay magic numbers in code.** Tunable values go in `.tres` Resources under `data/` (SpellData, ItemData, EnemyData...).
- Communication: call down, signal up; `EventBus` only for cross-system events. Keep the autoload list as in TECHNICAL_DESIGN.md §4.1.
- **Saves are JSON only** (`user://saves/`). Never load `.tres`/`.res` from `user://` (they can run code). Save references by ID.
- Puzzle objects react to spells through `on_element_hit(element)`. Don't special-case spells inside puzzle code.
- **Dialogue:** all player-facing story text lives in `res://dialogue/*.dialogue` files. Follow the voice guide and style rules in DIALOGUE_DESIGN.md §7 and §11.
  New scripts start as `# status: draft` until the owner approves them. Dialogue only calls the objects listed in DIALOGUE_DESIGN.md §2.3.
- **Audio:** play sounds only by event ID through `AudioManager` (never load audio files in gameplay code). Follow the naming in AUDIO_DESIGN.md §2.1.
  Every non-placeholder audio file needs a `CREDITS.md` entry (source, author, licence).

## Commands (`godot` = `D:\Tools\Godot\godot.cmd` until it's added to PATH)
```bash
godot --path . --editor            # open the editor
godot --path .                     # run the game (title screen)
godot --headless --import          # import resources (before headless tests)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit   # run unit tests
godot --path . --fullscreen -- --benchmark=<dir>   # skips the title: measure 300 frames in the meadow, save benchmark.txt + .png, quit
godot --path . --fullscreen --gpu-index 1 -- --benchmark=<dir> --graphics=low   # same on the Intel UHD, Low preset
godot --headless --path . --export-release "Windows Desktop" build/windows/Aethelgard.exe   # Windows build (run from PowerShell:
#   cmd.exe splits the quoted preset name). Templates: Windows x86_64 only, in D:\Tools\Godot\editor_data\export_templates.7.2.stable
```
From Git Bash, call Godot as `cmd.exe //c "D:\Tools\Godot\godot.cmd ..."`.
Run the game and look at it yourself instead of asking the owner what happened. The `game-development` skill's helper needs
Node.js, which is **not installed**, so use `--benchmark` (above), which records numbers and a screenshot then quits by itself.
Measure process RAM from PowerShell (`Start-Process ... -PassThru`, poll `WorkingSet64`). It goes fullscreen for ~10 s, so tell the owner first.
Godot's own `user://` data (saves, test output) lives in `%APPDATA%\Godot\app_userdata\Aethelgard` on C: and is small.

## Definition of done (for any feature)
1. Matches the requirement's acceptance check in REQUIREMENTS.md.
2. Unit tests for pure logic pass headless; no new errors in the Godot output log.
3. Values are in `data/`, not hard-coded.
4. Docs updated (requirement status, any design change).
