# Aethelgard — Technical Design & Build Plan

> Status: **v0.1 draft (planning phase)**, written 2026-11-03.
> **How** we build the game described in [GAME_DESIGN.md](GAME_DESIGN.md). Requirement IDs (e.g. `FR-MAG-03`) refer to [REQUIREMENTS.md](REQUIREMENTS.md).

---

## 1. Tech stack

| Area | Choice | Why |
|---|---|---|
| Engine | **Godot 4.7.x stable, standard build** (4.7.2 is current as of Aug 2026) | Free, strong 2D tools: TileMapLayer, Y-sort, 2D lights, particles, AnimationTree, navigation. |
| Language | **GDScript with static typing** | Native to Godot, fast to iterate. No .NET build needed. |
| Dialogue | **Dialogue Manager** addon (nathanhoad), MIT | Text-based `.dialogue` files: easy to diff in git and easy for Claude to write. Has conditions and mutations that call into game code. *Dialogic 2 is the visual alternative.* |
| Tests | **GUT** (Godot Unit Test) | Pure-GDScript project; runs headless from the command line. |
| Version control | **git** + **Git LFS** for art/audio | The project folder isn't a git repo yet. Set this up in milestone M0. |
| Target platform | Windows PC first (keyboard/mouse + gamepad) | Linux/Web export later if wanted. |

> Before installing an addon, check that its current release supports the Godot version we're using.

## 2. Rendering & resolution

- **Renderer: Compatibility (OpenGL)** 💡, chosen for the owner's 8 GB laptop: lowest RAM/VRAM use, also runs on integrated Intel graphics. Switch to Forward+ only if a needed effect requires it. See [BUILD_PLAN.md](BUILD_PLAN.md) §2–3.
- **Base viewport 1920×1080**, stretch mode `canvas_items`, aspect `expand`. The game is HD painterly anime, not pixel art.
- **Tile size 64×64 px.** That shows about 30×17 tiles on screen.
- **Character frames 128×128 px**; Aurelia is ~110 px tall (about 1.7 tiles). Large bosses use 256–512 px frames.
- Camera2D follows the player with smoothing, limits per map, and a small look-ahead toward the aim direction.
- These sizes are fixed **now**, so placeholder art and final art are interchangeable (`NFR-ART-01`).

---

## 3. Project folder structure (organised by feature)

```
res://
├─ project.godot
├─ addons/                    # dialogue_manager/, gut/
├─ assets/
│  ├─ art/                    # placeholders/ (generated), characters/, tiles/, props/, vfx/, ui/
│  ├─ audio/                  # music/, sfx/
│  ├─ fonts/
│  └─ shaders/                # hit_flash.gdshader, dissolve, outline, water
├─ data/                      # ALL tunable game data as .tres Resources
│  ├─ spells/  items/  recipes/  enemies/  bosses/  dragons/  quests/  loot_tables/
├─ src/
│  ├─ autoload/               # global singletons (see §4.1)
│  ├─ core/                   # state_machine/, damage/ (DamageInfo, Elements), utils
│  ├─ components/             # health, stamina, hitbox, hurtbox, status_effects, interactable, loot_dropper
│  ├─ actors/
│  │  ├─ player/              # player.tscn/.gd, states/
│  │  ├─ enemies/             # base_enemy.tscn + one folder per enemy type
│  │  ├─ bosses/              # boss_base + one folder per boss
│  │  ├─ dragon/              # pet dragon + AI states
│  │  └─ npcs/
│  ├─ magic/                  # spell_caster.gd, spell.gd (base), spells/<spell_id>/
│  ├─ items/                  # inventory, equipment, crafting logic
│  ├─ quests/
│  ├─ world/
│  │  ├─ regions/             # elderroot_meadow/, azure_coast/, ruined_valley/, stormspire/, floating_isle/
│  │  ├─ props/  puzzles/     # brazier, freezable_water, push_block, pressure_plate, rune, mirror ...
│  │  ├─ rest_point/
│  │  └─ environment/         # day_night, weather, region_exit
│  └─ ui/                     # hud/, menus/, dialogue_balloon/, common/
├─ dialogue/                  # *.dialogue files
├─ tests/                     # GUT tests: unit/, integration/
└─ tools/                     # dev scripts: placeholders/ + setup/ (GDScript, run headless); audio/ (Python, has its own .gdignore)
```

---

## 4. Core architecture

### 4.1 Autoloads (global singletons). Keep this list short.

| Autoload | Responsibility |
|---|---|
| `EventBus` | Global signals only (e.g. `enemy_defeated(enemy_id)`, `spell_learned(spell_id)`, `item_collected(item_id, qty)`). Decouples systems. |
| `GameState` | Story flags, world state (opened chests, solved puzzles, defeated bosses, keyed by unique IDs), current region, play time. |
| `PlayerData` | Persistent player progress: HP/stamina max, learned spells + mastery, loadout, equipment, Magic Power/rank (derived). |
| `Inventory` | Items and quantities, add/remove/has, equipment slots. |
| `QuestManager` | Active/completed quests; listens to `EventBus` to advance objectives. |
| `DragonManager` | Pet dragon data: stage, element, bond, skills, name. |
| `TimeOfDay` | Game clock, emits `hour_changed`, drives day/night and weather. |
| `SaveManager` | Save/load slots as **JSON** (see §4.9). |
| `SceneLoader` | Region transitions with a fade; places the player at a spawn ID. |
| `AudioManager` | Plays sounds by event ID (`SoundEvent` resources), voice pool, adaptive music, ambience, stingers. See [AUDIO_DESIGN.md](AUDIO_DESIGN.md) §4. |
| `Cutscene` | Scripted camera, actor movement, fades and letterbox for cutscenes. See [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md) §5. |
| `Settings` | Options (volume, keybinds, accessibility), saved to `user://settings.cfg`. |

**Rule:** scenes talk *down* by calling children and *up* by emitting signals. Use `EventBus` for cross-system events only. Avoid hard references between unrelated scenes.

### 4.2 Composition with components
Actors are built from small reusable nodes:

- `HealthComponent`: hp, max_hp, `apply_damage(info: DamageInfo)`, signals `damaged`, `died`.
- `StaminaComponent`: current/max, regen delay & rate, **exhausted** state, `try_spend(cost) -> bool`.
- `HitboxComponent` (Area2D): carries a `DamageInfo`; deals damage.
- `HurtboxComponent` (Area2D): receives hits → forwards to Health + StatusEffects; handles i-frames.
- `StatusEffectComponent`: burn, chill/freeze, stagger, root, daze, ember mark (timers + stacks).
- `InteractableComponent`: prompt text + `interacted` signal (NPCs, chests, rest points, gather nodes).
- `LootDropper`: rolls a `LootTable` on death.
- `SpellCaster` (player and caster enemies): cooldowns, global cooldown, stamina check, spawns spell scenes.

### 4.3 State machines
Node-based finite state machine (the GDQuest pattern): a `StateMachine` node with child `State` nodes,
each with `enter()`, `exit()`, `update(delta)`, `physics_update(delta)` and `handle_input(event)`.

| Actor | States |
|---|---|
| Player | Idle, Move, Dash, StaffStrike, Cast, Hurt, Exhausted (overlay flag), Dead, Interacting |
| Enemy | Idle, Patrol, Chase, Telegraph, Attack, Recover, Hurt, Dead |
| Boss | PhaseController (HP thresholds) + an attack-pattern sequencer; same base states as enemies |
| Pet dragon | Follow, Attack, Guard, UseSkill, Return, KnockedOut |

**Telegraph → Attack → Recover** is a fixed pattern for every enemy attack, which guarantees readable combat (`FR-CMB-05`).

### 4.4 Data-driven design with Resources
All numbers live in `.tres` files under `data/`, not in scripts. Designers (or Claude) tune the game by editing data.

```gdscript
# src/magic/spell_data.gd
class_name SpellData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var element: Elements.Type = Elements.Type.LIGHT
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var base_damage: float = 10.0
@export var power_value: int = 10           # contribution to Magic Power
@export var required_magic_power: int = 0   # gate for learning
@export var mastery_xp_per_level: Array[int] = [20, 50, 100, 200]
@export var scene: PackedScene              # the spell's runtime behaviour
```

Other Resource types: `ItemData` (→ `MaterialData`, `ConsumableData`, `EquipmentData` with stat modifiers & passive effect id),
`RecipeData` (inputs, output, station), `EnemyData` (stats, rank, element, weakness, loot table), `BossData` (phases),
`DragonSpeciesData` (per element: skills per bond level, stats per stage), `QuestData` (steps → objectives), `LootTable`.

> Shared `.tres` resources are read-only templates. Per-instance runtime state (current HP, cooldown timers) lives in nodes, or in `duplicate()`d copies.

### 4.5 Damage pipeline

```
Hitbox(DamageInfo) ──overlap──► Hurtbox ──► i-frames? ──► StatusEffects.apply()
                                         └─► HealthComponent.apply_damage(info)
                                                 └─► final = base × power_scale × element_mult × (crit?) − defense
                                                       └─► signals: damaged / died ──► VFX, hit-stop, knockback, EventBus
```

- `DamageInfo` (RefCounted): `amount, element, knockback, status_effects[], source, is_crit`.
- `Elements.multiplier(attack, defender_element, defender_weakness)` returns ×1.5 / ×1.0 / ×0.5 (`FR-MAG-06`).
- `power_scale = 1 + MagicPower / 500` (to tune) for player spells.

### 4.6 Magic system implementation
1. Input `cast_n` → `SpellCaster.try_cast(slot, aim_dir)`.
2. Checks, in order: not exhausted → slot cooldown ready → global cooldown ready → `Stamina.try_spend(cost)`.
3. Instantiate `spell_data.scene` (extends `Spell` base with `cast(caster, aim_dir, data, mastery)`), start cooldowns, play Cast state animation.
4. On successful use, add mastery XP → `PlayerData` recalculates **Magic Power** and **rank** → emit `EventBus.magic_power_changed`.
5. Puzzle objects implement `on_element_hit(element: Elements.Type)`, so the *same* spell scenes interact with braziers, water, fans and more (`FR-PUZ-01`).

### 4.7 World building
- **One scene per region**, each made of several connected maps if needed. Transitions use `RegionExit` Area2D → `SceneLoader.change_region(region_id, spawn_id)`.
- **TileMapLayer layers per map:** `Ground` → `GroundDetail` → `Cliffs` (collision) → `YSortObjects` (trees, ruins, props as Y-sorted scenes) → `Canopy` (fades when the player is under it).
- **Elevation:** cliffs as separate layers with a Y-sort origin offset; stairs/ramps switch the player's collision mask between height levels. Keep heights to 2–3 levels per map to stay simple.
- **Navigation:** NavigationRegion2D baked from the tilemap for enemies and the dragon (NavigationAgent2D).
- **Persistent objects** (chests, puzzle states, bosses) have a unique `persist_id` and read/write `GameState` when spawned or changed.

### 4.8 Day/night & weather
- `TimeOfDay` drives a `CanvasModulate` colour from a Gradient (dawn gold → day → dusk violet → night blue).
- `PointLight2D` on Aurelia's lantern, fireflies, braziers and windows (stronger at night).
- `GPUParticles2D` for rain, fog, fireflies and light motes. A `WeatherController` per region with allowed weather types.

### 4.9 Save system
- **JSON files in `user://saves/slot_N.json`.** Never load `.tres`/`.res` from `user://`: Godot resources can embed scripts, so a modified save file could run code (GDQuest save-system notes).
- Each saveable autoload implements `to_dict() -> Dictionary` and `from_dict(d: Dictionary)`. Every file has a `"version"` field, used to migrate old saves.
- **Autosave** at rest points and region changes. 3 manual slots.
- Items, spells and quests are saved **by ID** and resolved through a registry (`data/` lookup), never as object references.

### 4.10 Quests & dialogue
- `QuestData` holds steps; each step has objectives of type `talk | collect | defeat | reach | solve | learn_spell | custom`.
- `QuestManager` subscribes to `EventBus` signals and advances matching objectives.
- Full dialogue and cutscene plan (file layout, allowed calls, `Cutscene` API, portraits, barks): [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md).
- Dialogue Manager `.dialogue` files reference `GameState`/`QuestManager` for conditions (`if GameState.has_flag("met_sylvaris")`) and actions (`do QuestManager.start("dragon_egg")`).

### 4.11 Pet dragon AI
- **Follow:** stay at an offset behind Aurelia; teleport back if more than ~12 tiles away (leash).
- **Attack:** target = Aurelia's last-hit or aimed enemy; otherwise the nearest enemy threatening Aurelia.
- **Guard:** stay within 2 tiles, face the nearest threat, block projectiles (Earth) or counter-attack.
- Avoids active telegraph zones (enemies register danger areas in a shared group).
- Skill on its own cooldown; stats come from `DragonSpeciesData` × stage × bond.

### 4.12 Bosses
- `BossBase` extends the enemy with a `PhaseController` (HP thresholds → phase signals) and `AttackPattern` resources (sequences of moves with telegraph times).
- Boss arena: doors lock, music changes, boss HP bar appears. Phase checkpoints on Story difficulty.
- Ignis scripted encounters use a `ScriptedEncounter` (invulnerable boss, timer or HP-threshold → cutscene).

### 4.13 Input map (actions)
`move_up/down/left/right`, `aim` (mouse or right stick), `attack`, `cast_1…cast_4`, `dash`, `interact`, `dragon_command`, `dragon_skill`,
`menu`, `map`, `journal`, `pause`, `ui_*`. All actions are remappable and saved in `Settings`.

### 4.14 Physics layers

| # | Layer | Used by |
|---|---|---|
| 1 | world | walls, cliffs, props |
| 2 | player | player body |
| 3 | enemy | enemy bodies |
| 4 | ally | pet dragon, NPCs |
| 5 | player_hurtbox | hit by enemy attacks |
| 6 | enemy_hurtbox | hit by player/dragon attacks |
| 7 | interactable | NPCs, chests, rest points, gather nodes |
| 8 | elemental | puzzle objects that react to spells |
| 9 | water | water tiles (frozen → walkable) |
| 10 | high_ground | elevated level collision |

### 4.15 Placeholder art pipeline (`NFR-ART-01`)
- A small tool script generates placeholder art: coloured shapes with labels and a direction arrow, at the final frame sizes.
- **Animation naming:** `{action}_{direction}`, e.g. `idle_down`, `walk_up_left`, `cast_right`. 8 directions for Aurelia, 4 for most enemies.
- Swapping in real art = replacing the `SpriteFrames` resource. No code changes.
- AI-generated reference images (in `Game Images/`) are used for mood only; screenshots of other games are never used as assets.

---

## 5. Testing strategy

| Level | What | How |
|---|---|---|
| Unit (GUT) | Damage formula, element multipliers, stamina & exhaustion, cooldowns, Magic Power & rank, inventory, crafting, quest objective matching, save `to_dict`/`from_dict` round-trip | `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` |
| Integration | Spell hits brazier → lit; boss phase change at threshold; save → load restores the world | GUT scene tests |
| Run & look | Launch the game, take screenshots, read logs | Claude `game-development` skill |
| Playtest | Feel, difficulty, readability | Manual checklist per milestone |

> Run `godot --headless --import` once before headless tests (e.g. in CI) so all resources are imported.

---

## 6. Roadmap (milestones)

Each milestone ends with something **playable** that can be checked.

| # | Milestone | Main contents | Done when |
|---|---|---|---|
| **M0** | Setup | Install Godot 4.7.2, `git init` + LFS, project skeleton (§3), autoload stubs, input map, physics layers, GUT + Dialogue Manager, placeholder art generator | Project opens; empty test runs pass |
| **M1** | Walk the world | Aurelia 8-direction movement + dash, camera, test map with tile layers, Y-sort, collisions, cliffs/stairs, interaction prompt | You can walk around a test meadow behind trees and ruins |
| **M2** | Combat core | Health, hitbox, hurtbox, staff strike, stamina + exhaustion, SpellCaster with 2 spells + cooldowns, 1 enemy (FSM with telegraphs), death/respawn, basic HUD | Fight and beat a Thornling |
| **M3** | Magic & progression | Elements + weaknesses, status effects, SpellBook/loadout, spell tomes, learn at a rest point, mastery, Magic Power & rank, rank badges on enemies | Learning a spell visibly raises your rank |
| **M4** | Items & crafting | Inventory, equipment & accessories with stat modifiers, gather nodes, loot tables, workbench + recipes, consumables | Craft an accessory and see its effect |
| **M5** | World systems | Dialogue Manager integration, NPCs, QuestManager, journal UI, 3 puzzle types, Lumen hints | Finish a side task involving dialogue and a puzzle |
| **M6** | Persistence & atmosphere | JSON save/load + autosave, rest points + fast travel, day/night, weather, region transitions | Quit and reload with the world exactly as you left it |
| **M7** | Dragon | Egg → hatch, follow/attack/guard AI, dragon skill, bond, dragon menu, treats | The dragon fights at your side |
| **M8** | Boss framework | PhaseController, attack patterns, arena, boss HP bar; **Cinder Warden** + prologue Ignis scene | Beat the first boss |
| **🎯 VS** | **Vertical slice** | Prologue + Elderroot Meadow polished (GDD §15.1) | 30–45 min of fun, complete play |
| M9 | Region 2–3 | Azure Coast, Ruined Valley: enemies, spells, puzzles, bosses 2–3, juvenile dragon | Acts 1–2 playable |
| M10 | Region 4–5 | Stormspire, Floating Isle, Vharka, Ignis encounters + final fight, adult dragon flight | Game completable |
| M11 | Polish & ship | Real art swap-in, audio, VFX, balancing pass, settings/accessibility, Windows export | v1.0 build |

---

## 7. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Scope creep** (open world + crafting + dragons + bosses is a lot) | Build the vertical slice first; enforce GDD §15 content targets; stretch goals only after 1.0. |
| **Art bottleneck** (anime art is expensive) | Placeholders first, fixed frame sizes, recolour variants, one dragon body for all elements. |
| **Combat feels floaty** | Do M2 early and iterate on feel (hit-stop, knockback, telegraphs) before building content. |
| **Y-sort/elevation bugs with tilemaps** | Keep 2–3 height levels; build the M1 test map specifically to try cliffs and stairs. |
| **Save bugs / broken saves after updates** | IDs not references, versioned JSON, round-trip unit tests. |
| **Balance (power curve)** | All numbers in `data/`; a debug overlay showing Magic Power, DPS and enemy rank; a balance pass after each region. |
| **Addon breaks on a Godot update** | Pin the Godot version per milestone; check addon compatibility before upgrading. |

---

## 8. Research references

- Godot download, current stable 4.7.2: <https://godotengine.org/download/windows/>
- GDQuest *Godot Open RPG* (structure reference for a 2D RPG in Godot 4): <https://github.com/gdquest-demos/godot-open-rpg>
- Save-system safety (resources can run code; prefer JSON): <https://www.gdquest.com/library/cheatsheet_save_systems/>
- Node-based state machines: <https://gamedevacademy.org/godot-state-machine-tutorial/>, <https://ziva.sh/blogs/godot-state-machine>
- TileMapLayer + Y-sort for stacked cliffs: <https://forum.godotengine.org/t/best-practice-for-stacking-tilemaplayer-nodes-with-ysort-in-godot-4-4/120306>
- Dialogue Manager addon: <https://godotengine.org/asset-library/asset/edit/15252>
- Companion AI behaviour modes: <https://www.cs.mcgill.ca/~jtremb59/Papers/Adaptive%20Companions%20in%20FPS%20Games.pdf>
- Boss design (telegraphs, phases, fairness): <https://www.wayline.io/blog/crafting-legendary-boss-battles>
- Crafting without grind (recipe loops): <https://blog.bscotch.net/post/looping-recipes-pre-beta-devlog-part-1/>
