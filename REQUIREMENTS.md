# Aethelgard — Requirements

> Status: **v0.2: updated for 3D** (2026-11-03, [3D_PROPOSAL.md](3D_PROPOSAL.md)). Every requirement starts as ⬜ Planned.
> Design background: [GAME_DESIGN.md](GAME_DESIGN.md) · How we build it: [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md)

**Priority**
- **MVP**: needed for the vertical slice (Prologue + Elderroot Meadow).
- **V1**: needed for the full 1.0 game.
- **Stretch**: only if time allows after 1.0.

**Status:** ⬜ Planned · 🟨 In progress · ✅ Done · ❌ Dropped

Rule: when a requirement changes, update this file in the same change. Never silently drop one; mark it ❌ with a reason.

---

## 1. Functional requirements

### 1.1 Player & movement (PLY)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-PLY-01 | Aurelia is the playable character from the start of the game. | MVP | New game starts with Aurelia in Elderroot Meadow. | 🟨 Aurelia (placeholder model) spawns in the test meadow (Phase 2); story start in Phase 6 |
| FR-PLY-02 | Free 360° movement in 3D with blended locomotion animations (idle / walk / run). | MVP | Aurelia turns smoothly toward any direction; speed is the same in all directions. | 🟨 360° movement tested (Phase 2); real animations (idle/walk/jog/dash) on the animated stand-in with foot-speed matching (Phase 2b); waiting for Aurelia's VRoid model |
| FR-PLY-03 | Mouse / right-stick aiming for attacks and spells. | MVP | Spells fire toward the cursor/stick direction. | ✅ Phase 3 (mouse on the ground plane or right stick; aim reticle) |
| FR-PLY-04 | Dash with a short cooldown and brief invincibility; does not use stamina. | MVP | Dashing through an enemy attack causes no damage. | ✅ Phase 3 (dashing through a Thornling attack avoids the hit; tested) |
| FR-PLY-05 | Free staff strike (melee, no stamina cost). | MVP | Usable even when stamina is 0. | ✅ Phase 3 (wind-up, active window, recovery; tested) |
| FR-PLY-06 | Interact with NPCs, chests, rest points and gather nodes, with a visible prompt. | MVP | A prompt appears in range; the interact key triggers it. | ✅ Phase 2 (prompt + E, tested) |
| FR-PLY-07 | Stats: HP, Stamina, Magic Power, Defense, Move speed. | MVP | Visible in the status menu; changed by equipment. | ✅ Phase 5 (shown on the Inventory page; equipment changes them at once, tested) |
| FR-PLY-08 | On defeat, respawn at the last rest point without losing items. | MVP | Inventory is identical before and after respawn. | ✅ Phase 3/5 (respawn at the shrine; the inventory is identical before and after, tested) |

### 1.2 Magic (MAG)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-MAG-01 | Every spell costs stamina; casting with too little stamina fails with feedback. | MVP | The cast is refused with a sound and the bar flashes. | ✅ Phase 3 (refused cast flashes the stamina bar; tested) |
| FR-MAG-02 | Stamina regenerates after a short delay since the last cast. | MVP | Regen starts ~0.8 s after the last cast (data-driven value). | ✅ Phase 3 (0.8 s delay, exact refill timing; tested) |
| FR-MAG-03 | Each spell has its own cooldown, plus a short global cooldown. | MVP | A spell can't be recast until its radial cooldown is complete. | ✅ Phase 3 (per-slot cooldowns + 0.25 s global cooldown, radial HUD sweep; tested) |
| FR-MAG-04 | **Exhausted** state at 0 stamina: no casting until ~30% refill. | MVP | Casting is blocked until the threshold; strike and dash still work. | ✅ Phase 3 (Exhausted until 30%, strike and dash still work; tested) |
| FR-MAG-05 | 4 equipped spell slots; loadout editable in the Grimoire. | MVP | Swapping a spell updates the HUD slot. | ✅ Phase 4 (Grimoire: choose a spell, then a slot or key 1–4; the HUD slot follows; tested) |
| FR-MAG-06 | Elements Light, Wind, Frost, Earth, Fire (+ enemy Ember) with strong/weak pairs (×1.5 / ×0.5). | MVP | Frost on an Ember enemy deals 1.5× damage (unit tested). | ✅ Phase 3 (element pairs + Frost/Ember special cases; tested) |
| FR-MAG-07 | Spells are obtained from tomes, trials, quests, bosses, teachers and dragons. | MVP (tomes, trials) / V1 (rest) | Picking up a tome adds it to "unlearned". | 🟨 Tomes work (pick up → carried as unread; tested). Trials, quests, bosses, teachers, dragons come later |
| FR-MAG-08 | Spells are learned by reading the tome at a rest point; some need a minimum Magic Power. | MVP | A gated tome shows the required MP and can't be learned below it. | ✅ Phase 4 (read at a Lantern Shrine; gated tomes show the needed Magic Power and wait; tested) |
| FR-MAG-09 | Spell mastery I–V gained by use; improves the spell and adds Magic Power. | MVP | Using a spell enough raises its level and the MP total. | ✅ Phase 4 (xp per cast and per hit; I–V raise damage, cut cost and cooldown, add Magic Power; tested) |
| FR-MAG-10 | Magic Power is computed from spells, mastery and equipment and maps to Arcane Rank F–S. | MVP | Rank badge updates when MP crosses a threshold. | ✅ Phase 4 (Magic Power from spells + mastery + equipment slot; rank badge and RANK UP banner; tested) |
| FR-MAG-11 | Each new rank gives +max stamina and opens Arcane Seals of that rank. | V1 | Reaching rank D opens D-seals. | 🟨 +10 max stamina and +5 max HP per rank (Phase 4, tested); Arcane Seals come with puzzles (Phase 6) |
| FR-MAG-12 | The staff gem colour matches the element of the last cast. | V1 | Casting Frost turns the gem blue. | ⬜ |
| FR-MAG-13 | Status effects: Burn, Chill→Freeze, Stagger, Root, Daze, Ember Mark. | MVP (Burn, Chill, Stagger) / V1 (rest) | Each effect has a visible icon and timer. | 🟨 Burn, Chill→Freeze, Daze, Ember Mark with HUD chips and timers (Phase 4, tested); Stagger from Phase 3; Root in V1 |
| FR-MAG-14 | ~16 player spells in total. | V1 | All listed in GDD §6.4 are implemented. | 🟨 4 of ~16 spells: Light Mote, Gust (Phase 3), Lantern Glow, Mending Bloom (Phase 4) |

### 1.3 Combat & enemies (CMB)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-CMB-01 | Real-time combat with hit-stop, knockback and hit flash. | MVP | Every hit visibly reacts. | ✅ Phase 3 (hit-stop, knockback, hit flash, plus screen shake and damage numbers) |
| FR-CMB-02 | Enemies have HP, element, weakness and rank, shown above them. | MVP | Rank letter + HP bar appear when engaged. | ✅ Phase 4 (rank letter, HP bar and status text above enemies while engaged) |
| FR-CMB-03 | Enemies can use magic (projectiles, shields, buffs, summons). | MVP (projectiles) / V1 | At least one caster enemy in the slice. | 🟨 Ember Wisp shoots aimed Burning bolts after a telegraph (Phase 4, tested); shields, buffs, summons in V1 |
| FR-CMB-04 | Some enemies have elemental shields broken only by a specific element. | V1 | Wrong elements deal no damage while the shield is up. | ⬜ |
| FR-CMB-05 | Every enemy attack follows Telegraph → Attack → Recover, with a visual and audio cue. | MVP | No attack deals damage without a preceding telegraph. | 🟨 Visual telegraph ring before every attack (Phase 3, tested); telegraph sounds come with audio (Phase 6) |
| FR-CMB-06 | Enemies drop loot from loot tables. | MVP | Defeated enemies drop materials per their table. | ✅ Phase 5 (LootTable per enemy: Thornling → Thorn Fibre, Ember Wisp → Ember Cinder; walk over drops to collect; tested) |
| FR-CMB-07 | Difficulty settings: Story / Normal / Hard. | V1 | Changing difficulty changes damage taken and telegraph length. | ⬜ |
| FR-CMB-08 | ~12 enemy types across the regions. | V1 | All types listed in GDD §7.1 exist. | 🟨 2 of ~12 types: Thornling (Phase 3), Ember Wisp (Phase 4) |

### 1.4 Bosses (BOS)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-BOS-01 | Each boss has 2–3 phases triggered by HP thresholds. | MVP | Boss behaviour changes at the set thresholds. | ⬜ |
| FR-BOS-02 | Boss arena: doors lock, boss HP bar and name appear, music changes. | MVP | Leaving the arena is impossible until the fight ends. | ⬜ |
| FR-BOS-03 | Boss difficulty rises through the game (speed, combos, damage). | V1 | Boss data shows increasing values; playtests confirm. | ⬜ |
| FR-BOS-04 | Prologue Ignis encounter cannot be won (scripted), showing the enemy's strength. | MVP | Encounter ends in a cutscene regardless of outcome. | ⬜ |
| FR-BOS-05 | Final boss Ignis Varos with 3 phases. | V1 | Defeating him triggers the ending. | ⬜ |
| FR-BOS-06 | Corrupted good dragons are freed, not killed, when defeated. | V1 | Brinecoil becomes an ally after the fight. | ⬜ |
| FR-BOS-07 | Ember Cores: each region boss drops one; Ignis's rank drops per core destroyed. (Pending approval.) | V1 | Ignis's displayed rank/HP changes with cores destroyed. | ⬜ |
| FR-BOS-08 | On Story difficulty, bosses have phase checkpoints. | V1 | Dying in phase 2 restarts at phase 2. | ⬜ |

### 1.5 Dragons (DRG)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-DRG-01 | The player receives a dragon egg that hatches after progress. | MVP | The egg hatches at the end of the vertical slice. | ⬜ |
| FR-DRG-02 | Pet dragon follows Aurelia and fights with her. | V1 (MVP: follow only) | The dragon attacks enemies near the player. | ⬜ |
| FR-DRG-03 | Commands: Follow / Attack / Guard, plus a dragon skill on cooldown. | V1 | Each command visibly changes behaviour. | ⬜ |
| FR-DRG-04 | Growth stages: hatchling → juvenile → adult. | V1 | Model, stats and skills change per stage. | ⬜ |
| FR-DRG-05 | Bond level 1–10 raised by battle, treats, petting and training; unlocks skills. | V1 | Feeding a treat raises bond XP. | ⬜ |
| FR-DRG-06 | Element chosen at hatching (Frost/Wind/Earth/Light), each with its own skill set. (Pending approval.) | V1 | Different element → different skills. | ⬜ |
| FR-DRG-07 | Knocked-out dragon returns after a delay or at a rest point; never dies permanently. | V1 | Dragon reappears after ~20 s. | ⬜ |
| FR-DRG-08 | Adult dragon flight: fast travel between Dragon Roosts and access to the Floating Isle. | V1 | Flying to the Floating Isle works only with an adult dragon. | ⬜ |
| FR-DRG-09 | Good wild dragons (Sylvaris, Brinecoil, sun dragon) as story NPCs. | V1 | Each appears in the main quest. | ⬜ |
| FR-DRG-10 | More than one pet dragon. | Stretch | — | ⬜ |
| FR-DRG-11 | Real-time dragon riding. | Stretch | — | ⬜ |

### 1.6 Items, equipment & crafting (ITM)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-ITM-01 | Inventory with materials, consumables, equipment, key items and spell tomes. | MVP | Items stack and sort by category. | ✅ Phase 5 (Inventory autoload: stacks by id with a stack limit, sorted by category; unread tomes listed; tested) |
| FR-ITM-02 | Equipment slots: 1 staff, 1 cloak, 3 accessories, with stat modifiers and passives. | MVP | Equipping changes stats immediately. | ✅ Phase 5 (staff, cloak, 3 accessories; equipping changes stats at once, tested). Special passives (e.g. Frostbite Band) arrive with the accessories that need them (V1) |
| FR-ITM-03 | Gather nodes (herbs, ore, wood, crystals) that respawn over time. | MVP | Gathering adds items; the node respawns after N in-game hours. | ✅ Phase 6b (Sunpetal, Moonbloom, Elderwood, Iron Ore, Lumen Crystal grow back after 1–2 game hours; saved; tested) |
| FR-ITM-04 | Crafting at the workbench using recipes and materials. | MVP | Crafting consumes inputs and adds the output. | ✅ Phase 5 (workbench makes everything, the shrine's crafting kit makes potions; inputs used up; tested) |
| FR-ITM-05 | Recipes are found, given, bought or earned from bosses. | MVP | Unknown recipes are hidden or shown as "???". | 🟨 Recipes found as scrolls in the world; unknown ones show as "???" (tested). Given/bought/boss recipes come with NPCs and bosses |
| FR-ITM-06 | Equipment upgrades +1 to +3. | V1 | Upgrading raises stats and consumes materials. | ⬜ |
| FR-ITM-07 | Consumables: potions, stamina tonics, element oils, cleansing water, dragon treats. | MVP (potion, tonic) / V1 | Using a potion heals. | 🟨 MVP part done: Healing Potion and Stamina Tonic, used from the Inventory (tested). Oils, cleansing water, treats in V1 |
| FR-ITM-08 | The journal shows where each material can be found. | V1 | Material entries list regions/enemies. | ⬜ |
| FR-ITM-09 | ~25 recipes, ~15 accessories, ~5 staffs. | V1 | Content counts met. | 🟨 5 of ~25 recipes, 3 of ~15 accessories, 1 of ~5 staffs (the vertical-slice amounts, GDD §15.1) |

### 1.7 Puzzles (PUZ)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-PUZ-01 | Puzzle objects react to spell elements (brazier, water, fan, push block, pillar plate). | MVP (brazier, push block) / V1 | Fire lights a brazier; Frost freezes water into walkable ice. | 🟨 MVP part done (Phase 6a, tested): lantern braziers lit by Light (owner decision 2026-11-03: no Fire in the slice) and a push block moved by Gust onto a pressure plate. Water, fans, pillars in V1 |
| FR-PUZ-02 | Light/lantern puzzles: hidden runes and paths revealed by light. | MVP | A hidden path appears under Lantern Glow. | ✅ Phase 6a (Lantern Glow reveals hidden spirit steps up to a ledge; hidden tome since Phase 4; tested) |
| FR-PUZ-03 | Rune-sequence puzzles. | V1 | Correct order opens the door; a wrong one resets. | ⬜ |
| FR-PUZ-04 | Day/night-dependent puzzles. | V1 | A moon door opens only at night. | ⬜ |
| FR-PUZ-05 | Dragon-assisted puzzles. | V1 | The dragon hits a switch the player can't reach. | ⬜ |
| FR-PUZ-06 | Solved puzzles stay solved (persisted). | MVP | Reloading keeps the puzzle solved. | ✅ Phase 6b (puzzle states live in GameState, which is saved; tested) |
| FR-PUZ-07 | Lumen gives an optional hint after the player is stuck for a while. | V1 | Hint appears after N seconds without progress. | ✅ Phase 6a, early (Lumen hints after time near a puzzle without progress; Lumen approved 2026-11-03) |

### 1.8 Quests, dialogue & story (QST)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-QST-01 | Main quest following the acts in GDD §3.6. | MVP (prologue + Act 1 start) / V1 | Story beats trigger in order. | ⬜ |
| FR-QST-02 | Side tasks with objectives: talk, collect, defeat, reach, solve, learn spell. | MVP (2 tasks) / V1 (~20) | Objectives update automatically. | ✅ Phase 6a (QuestManager with talk/collect/defeat/reach/solve/learn/flag objectives; 2 side tasks: Herbs for Maren, Tamsin's Lost Satchel; tested) |
| FR-QST-03 | Trials (spell shrines) that reward spells. | MVP (1) / V1 (~10) | Completing a trial gives its spell tome. | ⬜ |
| FR-QST-04 | Branching dialogue with conditions based on game state. | MVP | NPC lines change after quest progress. | ✅ Phase 6a (villager lines change with quest progress and flags, tested) |
| FR-QST-05 | Journal: quests, bestiary, spells, materials, lore. | MVP (quests) / V1 (all) | Journal tabs show unlocked entries. | 🟨 MVP part done: the Journal lists quests with steps (Phase 6a). Bestiary, spells, materials, lore in V1 |
| FR-QST-06 | Bounties for named elite enemies. | V1 | Bounty board lists active bounties. | ⬜ |
| FR-QST-07 | Aether Shards: 3 shards = +max stamina. | V1 | Collecting the 3rd shard raises max stamina. | ⬜ |
| FR-QST-08 | Ending sequence (Ignis defeat → Sky Rift cliffhanger). | V1 | Credits roll after the ending. | ⬜ |

### 1.9 World (WLD)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-WLD-01 | 3D world built from terrain and modular kits (ruins, rocks, trees), seen through the hybrid camera. | MVP | Aurelia walks on terrain and around/behind objects; collisions work. | 🟨 Elderroot test meadow with collisions (Phase 2) |
| FR-WLD-02 | Real 3D height: stairs and ramps are walkable, ledges block; no free jump in v1. | MVP | Aurelia climbs the test stairs automatically and can't step up a ledge. | ✅ Phase 2 (stairs ramp climbed, 1.2 m ledge blocks; tested) |
| FR-WLD-03 | Hub + 5 regions connected around the World Tree. | V1 (MVP: Elderroot) | All regions reachable. | 🟨 Elderroot has two connected areas so far: the meadow and Elderroot Village (Phase 6b). Other regions after the vertical slice |
| FR-WLD-04 | Spell-gated paths (Gust, Glacial Path, Stone Spire, dragon flight). | V1 | A gated path can't be crossed without its spell. | ⬜ |
| FR-WLD-05 | Rest points: save, heal, learn spells, change loadout, fast travel. | MVP (save, heal, learn) / V1 (travel) | All functions available at a shrine. | 🟨 MVP part done: Lantern Shrines heal, refill, clear effects, set the respawn point, read tomes and autosave; manual saves next to a shrine (Phases 4–6b, tested). The loadout changes in the Grimoire anywhere; fast travel in V1 |
| FR-WLD-06 | Day/night cycle (~20 real minutes per day) affecting lighting, enemies and NPCs. | MVP (lighting) / V1 | The screen tint changes over time. | 🟨 MVP part done: a 20-minute day turns the sun and moon and blends light, sky, ambient and fog (Phase 6b, tested). Enemies and NPCs changing with time in V1 |
| FR-WLD-07 | Weather: clear, rain, fog, storm, per region. | V1 (MVP: rain particles) | Stormspire is always stormy. | 🟨 MVP part done: clear/rain/fog rolled every few game hours, rain particles and darker light, fog (Phase 6b, tested). Per-region weather and storms in V1 |
| FR-WLD-08 | Objects between the camera and Aurelia fade out (occlusion fade). | V1 | A wall in front of the camera becomes see-through while Aurelia is behind it. | ✅ Phase 2 (dithered occlusion fade, tested) |
| FR-WLD-09 | Opened chests, gathered nodes, defeated bosses and solved puzzles persist. | MVP | State survives a region change and a reload. | ✅ Phase 6b (chests, puzzles, tomes, scrolls, placed items and gather nodes keep their state through region changes and save/load; tested) |

### 1.10 UI (UI)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-UI-01 | HUD: HP, stamina (Exhausted flash), 4 spell slots with radial cooldowns, rank badge, quest tracker. | MVP | All elements update live. | ✅ HP, stamina with Exhausted warning, radial cooldowns (Phase 3), rank badge, status chips (Phase 4), quest tracker (Phase 6a) |
| FR-UI-02 | HUD dragon panel: portrait, HP, current command. | V1 | Shows after hatching. | ⬜ |
| FR-UI-03 | Menus: Inventory, Equipment, Grimoire, Crafting, Journal, Map, Settings. | MVP (Inventory, Grimoire, Crafting, Settings) / V1 | Each opens and closes with keyboard and gamepad. | 🟨 Tab/Start menu: Inventory, Grimoire, Journal, Save (Esc), Options (Q/R turns the page, J opens the Journal); Crafting at stations; all pause and close with Esc/B/Start (tested). Map later |
| FR-UI-04 | Dragon menu (stats, bond, skills, name). | V1 | — | ⬜ |
| FR-UI-05 | Title screen with New / Continue / Settings / Quit. | MVP | Continue loads the latest save. | ✅ Phase 6b (title screen: Continue = latest save, New Game, Load Game, Options, Quit; the owner's song comes with the audio work, 6c) |
| FR-UI-06 | Dialogue box with portraits and text speed option. | MVP | Text speed setting is applied. | ✅ Phase 6a (dialogue box with placeholder portraits; text speed applies at once) |

### 1.11 Save (SAV)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-SAV-01 | Saves are JSON files in `user://saves/`, never Godot resources. | MVP | No `.tres`/`.res` loaded from `user://`. | ✅ Phase 6b (JSON files in user://saves/; only JSON is ever read from user://, by id; tested) |
| FR-SAV-02 | Autosave at rest points and region changes; 3 manual slots. | MVP | — | ✅ Phase 6b (autosave when resting at a Lantern Shrine and on arriving in a region; 3 manual slots on the Save page, saving next to a shrine; tested) |
| FR-SAV-03 | Save files carry a version number and are migrated when the format changes. | MVP | Loading an older-version save works or shows a clear message. | ✅ Phase 6b (format version 1; older saves upgraded step by step, newer or damaged ones refused with a message; tested) |
| FR-SAV-04 | Save → load round-trip restores player, inventory, quests, dragon and world state exactly. | MVP | Unit test compares dictionaries before and after. | ✅ Phase 6b (region, position, health, world state, items, spells, quests, clock round-trip; tested. The dragon joins in Phase 7) |

### 1.12 Dialogue & cutscenes (DLG) — details in [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-DLG-01 | Conversations are written in Dialogue Manager `.dialogue` files under `res://dialogue/`. | MVP | No dialogue text is hard-coded in scripts. | ✅ Phase 6a (villager and Lumen lines in `dialogue/*.dialogue`; system toasts are UI text, not dialogue) |
| FR-DLG-02 | Story/NPC dialogue box: name plate, two portrait positions, expression tags, typewriter text with per-character blips. | MVP | `[#happy]` switches the portrait expression. | 🟨 Name plate, portraits on two sides, [#mood] expressions, typewriter text (Phase 6a, tested); per-character blips come with the audio work (6c) |
| FR-DLG-03 | Player choices (keyboard, mouse, gamepad); choices change conversations and some side-quest outcomes, not the main story. | MVP | A choice leads to a different reply. | ✅ Phase 6a (choice buttons work with mouse, keyboard focus and gamepad; a choice changes the reply, tested) |
| FR-DLG-04 | Dialogue reads and changes game state only through the allowed objects (GameState, QuestManager, Inventory, PlayerData, DragonManager, Cutscene, AudioManager). | MVP | Code review + FR-DLG-10 test. | ✅ Phase 6a (test checks every do/if/set target is one of the allowed objects) |
| FR-DLG-05 | Barks: speech bubbles with triggers, cooldowns and priority, without pausing gameplay. | MVP (Lumen, enemies) / V1 | Lumen remarks near a secret; the same bark doesn't repeat within its cooldown. | 🟨 Speech bubbles with cooldowns and priority for Lumen and villagers (Phase 6a, tested); enemy barks come with the boss work (Phase 8) |
| FR-DLG-06 | `Cutscene` API (letterbox, camera, spawn, move, face, anim, emote, wait, fade, shake, play); timed actions are awaited. | MVP | The prologue Ignis scene plays fully from a `.dialogue` file. | 🟨 Cutscene basics: letterbox, fade out/in, wait, all awaitable from dialogue (Phase 6a, tested); camera, actors and the prologue scene in Phase 8 |
| FR-DLG-07 | All cutscenes are skippable, and skipping still applies their game effects. | MVP | Skipping the egg cutscene still gives the egg. | ⬜ |
| FR-DLG-08 | NPCs change lines with story flags (before/during/after) and give short repeat lines. | MVP | The Elder's lines change after the Warden is defeated. | 🟨 Villagers change lines with quest progress and give short repeat lines (Phase 6a, tested); the Elder's after-Warden lines come with the boss (Phase 8) |
| FR-DLG-09 | Dragon naming text input at hatching. | MVP | The chosen name appears in later dialogue. | ⬜ |
| FR-DLG-10 | Automated test: every `do`/`if` target referenced in `.dialogue` files exists. | MVP | Test fails if a referenced function is renamed. | ✅ Phase 6a (tests/unit/test_dialogue_scripts.gd) |
| FR-DLG-11 | Text speed, auto-advance and instant-finish options. | MVP | Settings apply immediately. | ✅ Phase 6a (Options page: Slow/Normal/Fast/Instant and auto-advance, saved; pressing during typing shows the whole line) |
| FR-DLG-12 | Dialogue history log. (Pending approval.) | V1 | Last ~50 lines can be reviewed. | ⬜ |
| FR-DLG-13 | Translation-ready text (static line IDs, `tr()` for UI); voiced key scenes. | V1 (translation-ready) / Stretch (voice) | Lines can be exported for translation. | ⬜ |

### 1.14 Camera & graphics (CAM) — details in [3D_PROPOSAL.md](3D_PROPOSAL.md) §3
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-CAM-01 | High-angle follow camera (~40–45° down) that smoothly follows Aurelia. | MVP | Camera stays on Aurelia while she walks and dashes. | ✅ Phase 2 |
| FR-CAM-02 | Camera rotate (Q/R, middle-mouse drag, D-pad), zoom (wheel, 7–22 m) and reset (Z). | MVP | Each input works and stays within limits. | ✅ Phase 2 |
| FR-CAM-03 | Scenic viewpoints: entering an area blends the camera to a low, wide vista shot, then back. | V1 (MVP: 1 viewpoint) | The World Tree viewpoint shows the vista. | 🟨 MVP done: platform viewpoint shows the World Tree (Phase 2, tested); more viewpoints in later regions |
| FR-CAM-04 | Occlusion fade (see FR-WLD-08). | V1 | — | ✅ Phase 2 (see FR-WLD-08) |
| FR-CAM-05 | Graphics presets Low / Medium / High (render scale + FSR, MSAA, shadows, SSAO, glow, fog, grass density). | MVP | F1–F3 switch presets live; values from `data/graphics/`. | ✅ Phase 1b (tested) |
| FR-CAM-06 | Developer performance overlay and `--benchmark` mode. | MVP | Overlay shows FPS/ms/draw calls/memory; benchmark writes results + screenshot. | ✅ Phase 1b |
| FR-PLY-09 | No free jump in v1; automatic step-up on stairs (≤ ~0.35 m). | MVP | See FR-WLD-02. | ✅ Phase 2 |
| NFR-ART-04 | Characters made in VRoid Studio, imported as VRM with anime (MToon/toon) shading and spring-bone hair/cape. | MVP (Aurelia) | Aurelia's VRM imports and animates in Godot. | 🟨 Pipeline ready (Phase 2b): VRM importer, CC0 animations retargeted to Godot's humanoid skeleton, HumanoidVisual; waiting for the owner's VRoid export |
| NFR-ART-05 | One visual style: all assets use the project's toon/stone/ground shaders and one colour palette. | V1 | Style check in the Phase 2b look test. | 🟨 Shaders written (Phase 1b) |

### 1.13 Audio (AUD) — details in [AUDIO_DESIGN.md](AUDIO_DESIGN.md)
| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| FR-AUD-01 | `AudioManager` plays sounds by **event ID** through `SoundEvent` resources; game code never references audio files directly. | MVP | Swapping a SoundEvent's stream changes the sound with no code edit. | ⬜ |
| FR-AUD-02 | Bus layout Master / Music / Ambience / SFX (Player, Enemies, Dragon, World) / UI / Dialogue, with reverb on SFX. | MVP | Buses exist in `default_bus_layout.tres`. | ✅ Phase 1 (tested) |
| FR-AUD-03 | Every enemy and boss attack has a telegraph sound that matches the visual wind-up. | MVP | No attack in the slice lacks a telegraph sound. | ⬜ |
| FR-AUD-04 | Each element has its own sound family for casts, impacts and puzzle reactions. | MVP (Light, Wind, Ember) / V1 | Blind test: elements are recognisable by ear. | ⬜ |
| FR-AUD-05 | Random pitch/volume and 3–5 variants for frequent sounds; per-sound polyphony limit. | MVP | Repeated hits don't sound identical; big fights don't clip. | ⬜ |
| FR-AUD-06 | Footsteps change with the ground surface (surface metadata on terrain/materials). | MVP (grass, stone, water) / V1 | Walking from grass to stone changes the sound. | ⬜ |
| FR-AUD-07 | Adaptive music: explore ↔ combat transitions, day/night versions, boss phase sections. | MVP (explore/combat, boss phases) / V1 | Combat layer fades in when an enemy notices the player. | ⬜ |
| FR-AUD-08 | Stingers for spell learned, rank up, quest complete, secret found, crafted, dragon hatched, boss defeated. | MVP | Each event plays its stinger and ducks the music. | ⬜ |
| FR-AUD-09 | Region ambience with day/night and weather variants; positional sources (waterfalls, braziers). | MVP (Elderroot) / V1 | Ambience changes at dusk. | ⬜ |
| FR-AUD-10 | Per-region reverb; muffled music/ambience when paused; music ducks during dialogue. | V1 | Pausing muffles music; UI sounds stay clear. | ⬜ |
| FR-AUD-12 | Owner's song *Sunlight on Ancient Stone* plays on the title screen and in the prologue opening; credits use it too. | MVP (title, prologue) / V1 (credits) | Title screen plays the song; prologue scene uses intro + verse 1. | ⬜ |
| FR-AUD-13 | *Tides of the Morning Shore* is the Azure Coast day exploration loop (trimmed at loop end, `loop_offset` at loop start, seamless). | V1 | Loop point has no audible gap or click. | ⬜ |
| FR-AUD-14 | An instrumental version of *Sunlight on Ancient Stone* is used for Elderroot Meadow exploration (vocal version never loops during gameplay). | MVP | Elderroot exploration music has no vocals. | ⬜ (stem-separated version removed by owner; instrumental still needed) |
| FR-AUD-11 | Spell sounds gain layers with mastery level. (Pending approval.) | V1 | Mastery V sounds fuller than I. | ⬜ |

---

## 2. Non-functional requirements

| ID | Requirement | Priority | Acceptance check | Status |
|---|---|---|---|---|
| NFR-TEC-01 | Engine: Godot 4.7.x stable, standard build, **Forward+** renderer, **Jolt** physics; GDScript with static typing. | MVP | `project.godot` targets 4.7 + Forward Plus; no untyped public functions. | 🟨 Set up (Phase 1b); typing enforced as code is written |
| NFR-TEC-02 | All tunable numbers live in `data/*.tres`, not hard-coded in scripts. | MVP | Code review: no magic numbers for gameplay values. | ⬜ |
| NFR-TEC-03 | Project in git; large binary assets in Git LFS. | MVP | `git status` clean after a build; LFS tracks png/ogg/wav. | 🟨 Repo + LFS rules ready (Phase 1). For now images/audio are git-ignored by owner decision (2026-11-03); owner makes commits manually |
| NFR-PRF-01 | 60 FPS on a mid-range PC at 1080p in the busiest scene. | MVP | Profiler shows ≥60 FPS in a boss fight. | ⬜ |
| NFR-PRF-03 | Runs within the owner's laptop limits: 60 FPS at 1080p on the RTX 3050 (High), playable on the Intel UHD (Low), game RAM ≤ 2.5 GB, video memory ≤ 2.5 GB. | MVP | Overlay + `--benchmark` on both GPUs each phase. | 🟨 Phase 1b test level: 273 FPS RTX/High, 74 FPS Intel/Low. Phase 6b meadow at night in rain: 207–250 FPS RTX/High, 60 FPS Intel/Low, ≤ 1.3 GB RAM (695 draw calls: merge placeholder meshes later) |
| NFR-DEV-01 | The whole project can be developed on the owner's PC (8 GB RAM); all tools and files live on D:, Godot in self-contained mode. | MVP | Setup in BUILD_PLAN.md Phase 0 completed without using C: for project data. | ✅ Phase 0–1: Godot + project on D:, self-contained mode |
| NFR-PRF-02 | Region load under 3 seconds. | V1 | Measured from fade-out to fade-in. | 🟨 Meadow ↔ village in under 2.5 s including both fades (tests); measured properly later |
| NFR-ART-01 | Placeholders are simple 3D shapes at real size using the final shaders; swapping in real models needs no gameplay-code change. | MVP | Replacing a visual child scene works without script edits. | 🟨 Primitive placeholders in the test level (Phase 1b) |
| NFR-ART-02 | Base resolution 1920×1080; 1 unit = 1 m; Aurelia ≈ 1.6 m; characters ~20–40k triangles; textures mostly 1K–2K. | MVP | Checked on import and in the overlay. | 🟨 Resolution + units set (Phase 1b) |
| NFR-ART-03 | No assets copied from existing games; reference screenshots are for mood only. | MVP | All shipped assets are original or properly licensed (tracked in CREDITS.md). | ⬜ |
| NFR-AUD-01 | Audio formats: SFX `.wav` 44.1 kHz/16-bit (mono if positional), music/ambience `.ogg` with loop points; naming per AUDIO_DESIGN.md §2.1. | MVP | Import check: all files follow the rules. | ⬜ |
| NFR-AUD-02 | Every shipped audio file is original or properly licensed and listed in `CREDITS.md`; no NC/ND licences; nothing taken from other games/anime. | MVP | CREDITS.md covers every file in `assets/audio/` except placeholders. | ⬜ |
| NFR-AUD-03 | Placeholder sounds use the final IDs/names, so final audio is a drop-in swap. | MVP | Replacing a placeholder needs no code change. | ⬜ |
| NFR-AUD-04 | Audio accessibility: volume slider per bus, mono option, captions for story moments, visual cue option for off-screen sounds. | V1 (MVP: sliders) | Options exist and work. | ⬜ |
| NFR-INP-01 | Full keyboard+mouse and gamepad support; all actions remappable. | MVP (KB/M) / V1 (gamepad, remap) | Whole game playable with each input type. | ⬜ |
| NFR-ACC-01 | Accessibility: text size, text speed, subtitles, screen-shake toggle, damage-number toggle. | V1 | Options exist and work. | ⬜ |
| NFR-ACC-02 | Elements are distinguishable by icon/shape, not colour alone. | MVP | Readable in a greyscale screenshot. | 🟨 Element icons differ by shape (Phase 1 placeholders) |
| NFR-QA-01 | Core logic has GUT unit tests (damage, elements, stamina, cooldowns, MP/rank, inventory, crafting, save round-trip). | MVP | Headless test run passes. | 🟨 GUT 9.7.1 runs headless; 12 tests pass (Phase 1) |
| NFR-QA-02 | No errors in the Godot output log during a normal vertical-slice playthrough. | MVP | Log is clean at the end of a run. | ⬜ |
| NFR-PLT-01 | Windows desktop export. | V1 | Exported `.exe` runs on a clean Windows PC. | 🟨 First Windows export works on the owner's PC (Phase 3: 104 MB exe + 1.7 MB data, 240 FPS); clean-PC test later |
| NFR-SCP-01 | Total playtime ~6–10 hours for v1; vertical slice 30–45 minutes. | V1 | Measured in playtests. | ⬜ |

---

## 3. Content requirements (v1 targets)

| Content | MVP (vertical slice) | V1 |
|---|---|---|
| Regions | Elderroot Meadow (+ prologue) | Hub + 5 |
| Player spells | 4 | ~16 |
| Enemy types | 3 | ~12 |
| Bosses | Cinder Warden + prologue Ignis scene | 5 + Ignis encounters |
| Puzzle types | 2 | 6+ |
| Trials | 1 | ~10 |
| Side tasks | 2 | ~20 |
| Recipes | 5 | ~25 |
| Accessories | 3 | ~15 |
| Pet dragons | Egg → hatch | 1 dragon, 3 stages, 4 element variants |

---

## 4. Open items blocking requirements
See GAME_DESIGN.md §16. FR-BOS-07 (Ember Cores) and FR-DRG-06 (element choice) wait for the owner's approval.
