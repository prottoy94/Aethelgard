# CLAUDE.md — Aethelgard

2D top-down (3/4 view) anime action-RPG in **Godot 4.7.x (standard build, GDScript)**.
The player is **Aurelia**, a silver-haired elf mage who starts with almost no magic. She grows by learning spells,
crafting gear and raising a pet dragon, and her goal is to defeat **Ignis Varos, Herald of the Final Ember**.

## Project status
- **Phase 1 (M0 project skeleton) done** 2026-11-03. **Next: Phase 2, walk around the world (M1)** (BUILD_PLAN.md §6).
  Git repo exists (branch `main`, no remote). **The owner makes commits manually: never commit or push.**
  `.gitignore` excludes **all images and audio for now** (owner decision 2026-11-03): `Game Images/`, `Audio_music/`,
  placeholder PNGs (re-create with the generator after a clone). Only the add-ons' own icons are kept.
- Project settings, input map, physics layers, autoloads and audio buses come from `tools/setup/configure_project.gd`.
  Change them there and re-run it rather than hand-editing `project.godot`. Placeholder art comes from `tools/placeholders/generate_placeholders.gd`.
- Add-ons: GUT 9.7.1 (tests), Dialogue Manager 4.2.0, both MIT, in `addons/`.
- **Godot 4.7.2 is installed** at `D:\Tools\Godot` (self-contained mode via the `_sc_` file; checksum verified 2026-11-03).
  It is **not on PATH yet**: call `D:\Tools\Godot\godot.cmd` (wraps the console exe).
- **Owner's PC (build machine):** ASUS TUF F15, i5-12500H, RTX 3050 Laptop 4 GB + Intel UHD, **8 GB RAM**, 1080p 144 Hz,
  NVMe SSD with **C: nearly full (~12 GB free)** and D: ~109 GB free. Git + Git LFS, VS Code, Python 3.11 installed.
  → Put everything on **D:** (Godot in `D:\Tools\Godot`, self-contained mode). Keep RAM use low: don't start extra heavy processes,
  run one game instance at a time, close the game after checking it. Planned renderer: **Compatibility** 💡 (see BUILD_PLAN.md §2).
- Owner-made music lives in `Audio_music/` (AI-generated with a Google tool). *Sunlight on Ancient Stone* contains **Aurelia's singing voice**.
  Analysis and usage plan: AUDIO_DESIGN.md §10. Separated instrumental and vocal stems (Demucs) are there too (§10.6).

## Documents (read the relevant one before working)
| File | What it holds |
|---|---|
| [BUILD_PLAN.md](BUILD_PLAN.md) | **Start here:** the phase-by-phase build plan, made for the owner's PC (hardware limits, setup, workflow) |
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
- **Art:** placeholders first, at final sizes (1920×1080 base, 64 px tiles, 128 px character frames, animation names `{action}_{direction}`).
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
godot --path .                     # run the game
godot --headless --import          # import resources (before headless tests)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit   # run unit tests
godot --path . --write-movie <scratch>/frame.png --quit-after 20   # run briefly, save frames to look at
```
From Git Bash, call Godot as `cmd.exe //c "D:\Tools\Godot\godot.cmd ..."`.
Run the game and look at it yourself instead of asking the owner what happened. The `game-development` skill's helper needs
Node.js, which is **not installed**, so use Movie Maker capture (above): it records real frames plus the log, then quits by itself.
Godot's own `user://` data (saves, test output) lives in `%APPDATA%\Godot\app_userdata\Aethelgard` on C: and is small.

## Definition of done (for any feature)
1. Matches the requirement's acceptance check in REQUIREMENTS.md.
2. Unit tests for pure logic pass headless; no new errors in the Godot output log.
3. Values are in `data/`, not hard-coded.
4. Docs updated (requirement status, any design change).
