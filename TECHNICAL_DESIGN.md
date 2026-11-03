# Aethelgard — Technical Design & Build Plan

> Status: **v0.2: converted to 3D** (approved 2026-11-03, see [3D_PROPOSAL.md](3D_PROPOSAL.md)). First written 2026-11-03.
> **How** we build the game described in [GAME_DESIGN.md](GAME_DESIGN.md). Requirement IDs (e.g. `FR-MAG-03`) refer to [REQUIREMENTS.md](REQUIREMENTS.md).

---

## 1. Tech stack

| Area | Choice | Why |
|---|---|---|
| Engine | **Godot 4.7.x stable, standard build** (4.7.2 is current as of Aug 2026) | Free; Forward+ 3D renderer, Jolt physics, AnimationTree, 3D navigation, GPU particles, MultiMesh. |
| 3D characters | **VRoid Studio** → `.vrm` → **Godot VRM importer** (V-Sekai, MIT, commit `e15199f`) with the **MToon** anime shader | Anime characters without 3D-modelling skill; hair/cape sway via VRM spring bones. |
| Animations | **Quaternius Universal Animation Library** (CC0), Mixamo optional; retargeted with Godot's humanoid `BoneMap` | 120+ humanoid animations, free for commercial use. |
| 3D editing | **Blender 5.2.3 LTS** (portable, `D:\Tools\Blender`) | Editing/recolouring models, simple props, exporting glTF. |
| Physics | **Jolt Physics** (built into Godot 4.4+) | Faster and more stable 3D physics than the default engine. |
| Language | **GDScript with static typing** | Native to Godot, fast to iterate. No .NET build needed. |
| Dialogue | **Dialogue Manager** addon (nathanhoad), MIT | Text-based `.dialogue` files: easy to diff in git and easy for Claude to write. Has conditions and mutations that call into game code. *Dialogic 2 is the visual alternative.* |
| Tests | **GUT** (Godot Unit Test) | Pure-GDScript project; runs headless from the command line. |
| Version control | **git** (+ Git LFS rules ready) | Repo set up in Phase 1. Images/audio are git-ignored for now (owner decision); the owner commits manually. |
| Target platform | Windows PC first (keyboard/mouse + gamepad) | Linux/Web export later if wanted. |

> Before installing an addon, check that its current release supports the Godot version we're using.

## 2. Rendering, camera & performance

- **Renderer: Forward+ (Vulkan).** Needed for the anime 3D look (soft shadows, fog, glow, SSAO). Measured on the owner's laptop
  (3D_PROPOSAL.md §1, BUILD_PLAN.md Phase 1b): the 3D test level runs at **~270 FPS on the RTX 3050 (High, 1080p)** and **~74 FPS on the
  built-in Intel UHD (Low, 1080p)**, with ~0.9–1.0 GB game RAM.
- **Base viewport 1920×1080**, stretch mode `canvas_items` (UI), aspect `expand`. 3D renders at `render_scale` × window size (graphics presets).
- **Graphics presets** Low / Medium / High in `data/graphics/*.tres` (`GraphicsPreset`): render scale + FSR upscaling, MSAA, shadow distance,
  SSAO, glow, fog, grass density. `Settings.set_graphics_preset()`; levels listen to `Settings.graphics_changed`. Test with `-- --graphics=low`.
- **Camera (hybrid, approved):** high-angle follow camera (~40–45° down, FOV 40, distance ~13 m, zoom 7–22 m, rotate with Q/R or
  middle-mouse drag, reset with Z). At **scenic viewpoints** an `Area3D` blends the camera to a low, wide shot of a vista, then back.
  Objects between camera and player fade out (occlusion fade).
- **Units:** 1 Godot unit = 1 metre. Aurelia ≈ 1.6 m tall. No free jumping in v1: stairs/steps up to ~0.35 m are climbed automatically; gaps use Gale Step.
- **Budgets (game):** 60 FPS at 1080p on the RTX 3050 with headroom (aim ≤ 10 ms), game RAM ≤ 2.5 GB, video memory ≤ 2.5 GB,
  characters ~20–40k triangles, textures mostly 1K–2K, area load ≤ 5 s. Check with the performance overlay (F1–F4) and `--benchmark`.

---

## 3. Project folder structure (organised by feature)

```
res://
├─ project.godot
├─ addons/                    # dialogue_manager/, gut/
├─ assets/
│  ├─ art/                    # placeholders/ui (generated icons), ui/, portraits/, textures/
│  ├─ models/                 # characters/ (.vrm), enemies/, props/, environment/ (.glb exports)
│  ├─ animations/             # retargeted animation libraries
│  ├─ materials/              # shared .tres materials using the shaders below
│  ├─ audio/                  # music/, sfx/
│  ├─ fonts/
│  └─ shaders/                # toon, toon_outline, ground, grass, stone_moss, water (+ hit_flash, dissolve later)
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
| `Inventory` | Items and quantities, add/remove/has, equipment slots, known recipes and crafting (built in Phase 5). |
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
- `HitboxComponent` (Area3D): carries a `DamageInfo`; deals damage.
- `HurtboxComponent` (Area3D): receives hits → forwards to Health + StatusEffects; handles i-frames.
- `StatusEffectComponent`: burn, chill/freeze, stagger, root, daze, ember mark (timers + stacks).
- `InteractableComponent`: prompt text + `interacted` signal (NPCs, chests, rest points, gather nodes).
- `LootDropperComponent`: rolls a `LootTable` on death and scatters `ItemPickup`s (added by `Enemy` when its data has loot).
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

**Items as built in Phase 5** (`src/items/`):
- Materials use `ItemData` directly (no `MaterialData` subclass was needed). `ConsumableData` (heal, stamina) and
  `EquipmentData` (slot; magic_power, max_health, max_stamina, defense, stamina_regen, strike_damage, move_speed,
  spell_cooldown, one element resistance) extend it. Passive effect ids come with the first accessory that needs one.
- `RecipeData` keeps `inputs: Array[ItemData]` plus a parallel `input_counts`; `LootTable` uses parallel arrays
  (items, chances, min/max counts). Both are easy to hand-edit in `.tres`.
- `ItemLibrary` (`data/items/item_library.tres`, built by `tools/dev/build_item_library.gd`) resolves ids for saves.
  `NewGameItems` holds the starting bag, gear and recipes. `GatherNodeData` (`data/items/gather/`) sets a gather node's
  item, yield and regrow time.
- The `Inventory` autoload: `counts` (id → amount, capped by `max_stack`), `equipment` (5 ids: staff, cloak, 3 accessories;
  worn items leave the bag; one accessory can't fill two slots), known `recipes`, `craft(recipe, station)`, `gear_bonus()`
  (`GearBonus`). PlayerData listens to `equipment_changed` for gear Magic Power and the cooldown bonus; the Player applies
  max HP/stamina (topping up the gain), defense, regen, strike damage, move speed and resistances
  (`HealthComponent.resistances`).
- Menus extend `MenuScreen` (parchment panel, pauses, Esc/B/Start closes, keeps gamepad focus). `GameMenu` (Tab/Start) holds
  the Inventory and Grimoire pages; `CraftingMenu` is opened by a `CraftingStation`'s `used` signal.

> Shared `.tres` resources are read-only templates. Per-instance runtime state (current HP, cooldown timers) lives in nodes, or in `duplicate()`d copies.

### 4.5 Damage pipeline

```
Hitbox(DamageInfo) ──overlap──► Hurtbox ──► i-frames? ──► StatusEffects.apply()
                                         └─► HealthComponent.apply_damage(info)
                                                 └─► final = base × power_scale × element_mult × (crit?) − defense
                                                       └─► signals: damaged / died ──► VFX, hit-stop, knockback, EventBus
```

- `DamageInfo` (RefCounted): `amount, element, knockback, stagger, source`, plus `status, status_duration, status_power`
  (Phase 4, `with_status()`). Crits are not used yet.
- **Status effects (Phase 4):** the Hurtbox multiplies damage by `StatusEffectComponent.damage_taken_multiplier()` (Ember
  Mark), deals the hit, then applies the hit's status. Burn ticks damage, 3 Chill stacks become Freeze (→ Stagger on
  enemies), Daze slows. Movement multiplies speed by `speed_multiplier()`. Numbers: `data/combat/status_rules.tres`.
- **Projectiles (Phase 4):** `Projectile.launch(...)` in `src/magic/projectile.gd` flies straight, hits the other team's
  hurtboxes or a wall, and bursts. Used by the Ember Wisp (`perform_attack()` / `end_attack()` virtuals on `Enemy`).
- **Teams (built in Phase 3):** `HurtboxComponent.team` puts it on `player_hurtbox` (5) or `enemy_hurtbox` (6);
  `HitboxComponent.team` masks the *other* team's hurtboxes, so friendly fire is impossible. Each activation hits each
  hurtbox once. Projectiles set `collide_with_world` to stop at walls. Instant area spells (Gust) query the `enemy` group
  and call `hurtbox.receive_hit()` directly.
- **Feedback:** `CombatFx` (hit flash via the toon shader's `hit_flash` instance uniform, global hit-stop through
  `Engine.time_scale` (off in tests), floating damage numbers), `CameraRig.add_shake()`, `WorldHealthBar`.
- **Enemies (Phase 3):** `Enemy` base + `EnemyData`; states Idle/Chase/Telegraph/Attack/Recover/Stagger/Dead in
  `src/actors/enemies/states/`. Chasing uses direct steering for now; `NavigationAgent3D` arrives with bigger maps.
- `Elements.multiplier(attack, defender_element, defender_weakness)` returns ×1.5 / ×1.0 / ×0.5 (`FR-MAG-06`).
- `power_scale = 1 + MagicPower / 500` (to tune) for player spells.

### 4.6 Magic system implementation
1. Input `cast_n` → `SpellCaster.try_cast(slot, aim_dir)`.
2. Checks, in order: not exhausted → slot cooldown ready → global cooldown ready → `Stamina.try_spend(cost)`.
3. Instantiate `spell_data.scene` (extends `Spell` base with `cast(caster, aim, data, power)`), start cooldowns, play Cast state animation.
   Cost, cooldown and power come from `SpellCaster.modifiers_provider` → `PlayerData.modifiers_for(spell)` (`SpellModifiers`).
4. On a cast and on each hit (`Spell.landed`), add mastery XP → `PlayerData` recalculates **Magic Power** and **rank** →
   emits `magic_power_changed` / `rank_changed(rank, previous)` (the player adds the rank's stamina/HP bonus; the HUD shows a banner).
5. **Built in Phase 4:** `MagicProgression` holds rank thresholds (F 0 · E 50 · D 150 · C 300 · B 500 · A 800 · S 1200),
   mastery xp (20/50/100/200) and the formulas: Magic Power = Σ power_value × (1 + 0.25 × (mastery − 1)) + equipment;
   damage × (1 + MP × 0.002) × (1 + 0.1 × mastery steps); cost and cooldown −5% per step. `SpellTome` objects are taken
   into `PlayerData.tomes`; `RestPoint.rest()` calls `PlayerData.read_tomes()`, which learns every tome the Magic Power
   allows, repeating so one new spell can unlock the next. The Grimoire edits `PlayerData.loadout`; the player's
   `SpellCaster` follows `loadout_changed`. `PlayerData.to_dict()/from_dict()` are ready for the save system.
6. Puzzle objects implement `on_element_hit(element: Elements.Type)`, so the *same* spell scenes interact with braziers, water, fans and more (`FR-PUZ-01`).

### 4.7 World building (3D)
- **One scene per region**, made of a few connected areas. Transitions use a `RegionExit` Area3D → `SceneLoader.change_region(region_id, spawn_id)`.
- **Terrain:** sculpted ground meshes (Blender or Godot) with the `ground` shader (grass tones + painted dirt paths via vertex colour).
- **Modular kits:** ruins (arches, columns, walls, stairs), rocks, trees as reusable scenes with the `toon` / `stone_moss` shaders and simple collision shapes.
- **Grass & flowers:** `MultiMeshInstance3D` with the `grass` shader; density follows the graphics preset.
- **Elevation:** real 3D height. **Stairs collide as a smooth ramp** (one sloped collision box under the visible steps, ≤ ~30°),
  so the character walks up them without jumping; ledges block. No free jump (§2).
- **Occlusion fade:** solid objects are a `StaticBody3D` root with their meshes as children; non-solid blockers (tree canopies)
  get an `Area3D` child on layer 11. The `CameraRig` raycasts to the player and sets the `fade` instance uniform on all meshes
  under the hit root (toon, toon_outline and stone_moss shaders dither them out). Canopies within `near_fade_radius`
  (4.5 m) of the lens fade too, even when they don't hide the player (Phase 4); the ground is never faded.
- **Navigation:** `NavigationRegion3D` baked per area for enemies and the dragon (`NavigationAgent3D`).
- **Performance:** automatic mesh LODs on import, `visibility_range` on small props, `OccluderInstance3D` for big ruins/cliffs, shadows only near the camera, fog hides the far distance.
- **Persistent objects** (chests, puzzle states, bosses) have a unique `persist_id` and read/write `GameState` when spawned or changed.

### 4.8 Day/night & weather
- `TimeOfDay` rotates the sun (`DirectionalLight3D`) and blends sun colour, sky, ambient light and fog colour (dawn gold → day → dusk violet → night blue moonlight).
- `OmniLight3D` on Aurelia's lantern, braziers and windows (stronger at night); emissive materials + glow for magic.
- `GPUParticles3D` for rain, fireflies, light motes, waterfall spray. A `WeatherController` per region with allowed weather types.

### 4.9 Save system
- **JSON files in `user://saves/slot_N.json`.** Never load `.tres`/`.res` from `user://`: Godot resources can embed scripts, so a modified save file could run code (GDQuest save-system notes).
- Each saveable autoload implements `to_dict() -> Dictionary` and `from_dict(d: Dictionary)`. Every file has a `"version"` field, used to migrate old saves.
- **Autosave** at rest points and region changes. 3 manual slots.
- Items, spells and quests are saved **by ID** and resolved through a registry (`data/` lookup), never as object references.

### 4.10 Quests & dialogue
- `QuestData` holds steps; each step has objectives of type `talk | collect | defeat | reach | solve | learn_spell | custom`.
- `QuestManager` subscribes to `EventBus` signals and advances matching objectives.
- **Built in Phase 6a:** `QuestStep` (one objective per step: TALK, COLLECT, DEFEAT, REACH, SOLVE, LEARN_SPELL, FLAG;
  "custom" became FLAG), `QuestData` (steps + reward items/recipes), `QuestLibrary` (`data/quests/quest_library.tres`).
  COLLECT checks what is in the bag; TALK steps are advanced by the conversation (`do QuestManager.advance(...)`).
  `QuestManager.tracked` feeds the HUD tracker; `JournalMenu` lists quests. Saved with `to_dict/from_dict`.
- **Conversations:** `DialogueBox` (`src/ui/dialogue/`) drives Dialogue Manager lines itself (no example balloon):
  `DialogueLabel` typewriter, `PortraitView` placeholders from `data/dialogue/portraits.tres`, choice buttons,
  text speed/auto-advance from `Settings` (`data/dialogue/dialogue_tuning.tres`). `Npc` emits `talk_requested`; the level
  connects it to the box. `BarkSpeaker` shows speech bubbles (random `%` lines, cooldown, priority).
- **Lumen** (`src/actors/lumen/`) follows the player, glows near `revealable` nodes and barks hints from
  `dialogue/barks/lumen.dialogue`; tuning in `data/dialogue/lumen_hints.tres` (a `hints` property per instance).
- **Puzzles** (`src/world/puzzles/`): spells call `on_element_hit(element, from)` on `ElementalReceiver` components
  (group `elemental`, found by distance, no extra physics layer). Parts (`LanternBrazier`, `PressurePlate`,
  `HiddenSteps`) have `is_on()` + `state_changed`; a `Puzzle` node checks them, calls `activate(instant)` on its targets
  (`PuzzleGate`, `Chest`), emits `EventBus.puzzle_solved` and keeps its state in GameState. `PushBlock` slides one grid
  cell away from the caster. `Cutscene` autoload has letterbox/fade/wait so far.
- Full dialogue and cutscene plan (file layout, allowed calls, `Cutscene` API, portraits, barks): [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md).
- Dialogue Manager `.dialogue` files reference `GameState`/`QuestManager` for conditions (`if GameState.has_flag("met_sylvaris")`) and actions (`do QuestManager.start("dragon_egg")`).

### 4.11 Pet dragon AI
- **Follow:** stay at an offset behind Aurelia; teleport back if more than ~12 m away (leash).
- **Attack:** target = Aurelia's last-hit or aimed enemy; otherwise the nearest enemy threatening Aurelia.
- **Guard:** stay within ~2 m, face the nearest threat, block projectiles (Earth) or counter-attack.
- Avoids active telegraph zones (enemies register danger areas in a shared group).
- Skill on its own cooldown; stats come from `DragonSpeciesData` × stage × bond.

### 4.12 Bosses
- `BossBase` extends the enemy with a `PhaseController` (HP thresholds → phase signals) and `AttackPattern` resources (sequences of moves with telegraph times).
- Boss arena: doors lock, music changes, boss HP bar appears. Phase checkpoints on Story difficulty.
- Ignis scripted encounters use a `ScriptedEncounter` (invulnerable boss, timer or HP-threshold → cutscene).

### 4.13 Input map (actions)
`move_up/down/left/right`, `aim` (mouse or right stick), `attack`, `cast_1…cast_4`, `dash`, `interact`, `dragon_command`, `dragon_skill`,
`menu`, `map`, `journal`, `pause`, `ui_*`, and for the 3D camera `camera_rotate_left` (Q), `camera_rotate_right` (R),
`camera_zoom_in/out` (mouse wheel), `camera_drag` (middle mouse), `camera_reset` (Z). All actions are remappable and saved in `Settings`.

### 4.14 Physics layers (3D)

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
| 9 | water | water surfaces (frozen → walkable) |
| 10 | high_ground | elevated level collision |
| 11 | camera_occluder | non-solid volumes (tree canopies) the camera checks for occlusion fade |

### 4.15 Placeholder & art pipeline (`NFR-ART-01`)
- **Placeholders are simple 3D shapes** (capsules, boxes, cylinders, spheres) at real-world size, using the final shaders, as in
  `src/world/test/test_level_3d.gd`. Only 2D UI icons are generated as images (`tools/placeholders/`).
- **Characters:** VRoid Studio → `.vrm` (reduce polygons on export) → `assets/models/characters/`. Animations retargeted to the humanoid skeleton;
  `AnimationTree` with a locomotion blend space (idle/walk/run) + one-shots (cast, strike, hurt, dash).
- **Animation pipeline (Phase 2b):** source = Quaternius Universal Animation Library (CC0) in `assets/animations/quaternius_ual/`.
  Its `.glb.import` retargets the Rigify skeleton with `ual_bone_map.tres` (made by `tools/dev/make_ual_bone_map.gd`) to Godot's
  `SkeletonProfileHumanoid`, renamed to the **unique node `%GeneralSkeleton`** (rest fixer: overwrite axis + fix silhouette).
  Animation tracks therefore address `%GeneralSkeleton:<Bone>` and play on **any** humanoid model whose skeleton is renamed to
  `GeneralSkeleton` with `unique_name_in_owner` (HumanoidVisual does this for VRM models).
- **`HumanoidVisual`** (`src/actors/character/`): instantiates the model, scales it to `target_height`, turns it to face -Z,
  adds the animation library, attaches `AureliaStaff` to the `RightHand` bone, and picks animations from movement
  (`update_motion`) with playback speed = real speed ÷ native gait speed (measured with `tools/dev/measure_gait_speed.gd`).
  `play_action()` plays one-shots (cast, strike, hurt…). Which clip is used for what: `HumanoidAnimSet`, data in
  `data/animations/humanoid_default.tres`. Same interface as the shape placeholder, so `Player.set_visual()` can swap them.
- **Animation naming:** clip names come from the library (`Idle`, `Walk`, `Jog_Fwd`, `Sprint`, `Spell_Simple_Shoot`,
  `Sword_Attack`, `Hit_Chest`, `Death01`, `Interact`, `Sitting_Idle`…); gameplay code uses the `HumanoidAnimSet` roles
  (idle, walk, run, dash, cast, strike, hurt, death, interact, rest), never clip names directly.
- **Props/environment:** CC0 kits (Quaternius, Kenney) and own models from Blender, exported as `.glb`, recoloured to one palette, using the project shaders.
- Swapping a placeholder for real art = replacing the mesh/scene of the visual child node. Gameplay nodes (collision, components) don't change.
- Reference images in `Game Images/` are for mood only; screenshots of other games are never used as assets.

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
| **M0** ✅ | Setup | Install Godot 4.7.2, `git init` + LFS, project skeleton (§3), autoload stubs, input map, physics layers, GUT + Dialogue Manager, placeholder art generator | Project opens; empty test runs pass |
| **M0b** ✅ | Switch to 3D | Forward+, Jolt, 3D layers, camera actions, graphics presets, shaders, 3D test level, performance overlay + benchmark mode | 3D test level runs at 60+ FPS on both GPUs |
| **M1** | Walk & camera | Aurelia (capsule) moves in full 360° + dash, steps up stairs; hybrid camera (follow, rotate, zoom, scenic viewpoint, occlusion fade); interaction prompt | You can walk around the 3D test meadow |
| **M1b** | Look test (style diorama) | VRoid Aurelia + animations, World Tree corner, ruins kit, water, golden hour: locks the art style | A screenshot-worthy scene |
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
| **Art bottleneck** (3D characters, animation) | VRoid for characters, CC0 animation library, CC0 kits recoloured to one palette, simple shapes as placeholders, one dragon body for all elements. |
| **Combat feels floaty** | Do M2 early and iterate on feel (hit-stop, knockback, telegraphs) before building content. |
| **Camera problems** (walls blocking the view, motion sickness) | Occlusion fade, limited rotation speed, screen-shake toggle, test early in M1. |
| **RAM pressure on the 8 GB laptop** | One heavy app at a time (Godot or Blender); budgets checked with the overlay each phase; optional RAM upgrade. |
| **Save bugs / broken saves after updates** | IDs not references, versioned JSON, round-trip unit tests. |
| **Balance (power curve)** | All numbers in `data/`; a debug overlay showing Magic Power, DPS and enemy rank; a balance pass after each region. |
| **Addon breaks on a Godot update** | Pin the Godot version per milestone; check addon compatibility before upgrading. |

---

## 8. Research references

- Godot download, current stable 4.7.2: <https://godotengine.org/download/windows/>
- GDQuest *Godot Open RPG* (structure reference for an RPG in Godot 4; 2D, but the architecture applies): <https://github.com/gdquest-demos/godot-open-rpg>
- Save-system safety (resources can run code; prefer JSON): <https://www.gdquest.com/library/cheatsheet_save_systems/>
- Node-based state machines: <https://gamedevacademy.org/godot-state-machine-tutorial/>, <https://ziva.sh/blogs/godot-state-machine>
- Dialogue Manager addon: <https://godotengine.org/asset-library/asset/edit/15252>
- Companion AI behaviour modes: <https://www.cs.mcgill.ca/~jtremb59/Papers/Adaptive%20Companions%20in%20FPS%20Games.pdf>
- Boss design (telegraphs, phases, fairness): <https://www.wayline.io/blog/crafting-legendary-boss-battles>
- Crafting without grind (recipe loops): <https://blog.bscotch.net/post/looping-recipes-pre-beta-devlog-part-1/>
