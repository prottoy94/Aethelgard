# Aethelgard — Game Design Document (GDD)

> Status: **v0.2: the game is 3D** (approved 2026-11-03: hybrid high-angle camera, VRoid characters, no free jump; see [3D_PROPOSAL.md](3D_PROPOSAL.md)).
> This document says **what** the game is. [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) says **how** we build it.
> [REQUIREMENTS.md](REQUIREMENTS.md) lists the requirements we can check off. [DESIGN_NOTES.md](DESIGN_NOTES.md) holds the art references.
>
> Items marked **💡 Idea** are my suggestions and still need the owner's approval.
> Items marked **❓ Open** are undecided.

---

## 1. One-line pitch

**A 3D anime action-RPG (high-angle camera with scenic vistas) where Aurelia, a silver-haired elf with almost no magic,
grows from the weakest mage in Aethelgard into the one who can stand against Ignis Varos,
Herald of the Final Ember. She does it by finding and learning spells, crafting gear, and raising her own dragon.**

## 2. Design pillars

Every feature should support at least one of these. If it doesn't, cut it.

1. **From weakest to equal.** The player must *feel* the growth. Early enemies are scary; later the same enemies are easy.
   Power comes from what you **learn and find**, not from grinding XP.
2. **Magic is everything.** The same spells are used for combat, puzzles, traversal and crafting.
3. **A beautiful, ruined world worth exploring.** Small, but dense with secrets, ruins and views.
   Light and time of day carry the mood (see the art notes).
4. **Bond with a dragon.** Your pet dragon grows with you from egg to adult and fights at your side.
5. **Small but complete.** About 5 regions and 6–10 hours of play, fully finished and polished. No endless content.

---

## 3. World & story

### 3.1 The world of Aethelgard
- Magic is the **measure of worth and power**. Humans and elves live with it every day.
- People gain magical power by **finding spells and learning them**. Spells are found in tomes, ruins, trials,
  and from teachers, dragons and defeated foes. Doing different tasks is how people find spells.
- Every mage has a **Magic Power** value and an **Arcane Rank** (see §5.2). Rank shapes social standing; the low-ranked are looked down on.
- The land is an old kingdom now overgrown by nature: ruins, a giant **World Tree** at its heart, and a strange **Sky Rift** in the heavens.

### 3.2 Main characters

| Character | Role | Notes |
|---|---|---|
| **Aurelia** | Player character | Silver-haired elf, staff with a hanging lantern, plum hooded cape. Cheerful, curious, bookish. Starts with **very little magic**, far below everyone else. |
| **Lumen** 💡 | Spirit companion (blue butterfly) | From the `pose_3` art. A fragment of the World Tree's spirit. Gives hints, points toward goals, glows near secrets. Doesn't fight. |
| **Pet dragon** | Battle companion | Hatched by the player from an egg. Player names it. Grows hatchling → juvenile → adult. See §8. |
| **Sylvaris** 💡 | Good elder dragon | Ancient guardian of the World Tree. Mentor figure, gives Aurelia her dragon egg. |
| **Ignis Varos, Herald of the Final Ember** | Main antagonist | Powerful fire mage-general, sent by an unknown master. Goal: take over Aethelgard. Commands the **Emberbound**. |
| **The Unknown One** ❓ | Hidden final threat | Sent Ignis. If Ignis fails, *it* comes itself, and its arrival could wipe out the world. Linked to the **Sky Rift** 💡. Name and nature undecided. |

### 3.3 The central tension
Ignis is the immediate threat, but **beating him is also dangerous**. If he fails, the Unknown One comes.
The story keeps that tension alive: winning carries a cost and a mystery.

### 3.4 Why the enemy is stronger, and how we catch up 💡
- At the start, Ignis's side is far stronger: higher ranks, more magic, and his forces hold the regions.
- **Two ways the gap closes** (the user's concept: "as we progress we will start to have power matching the enemy"):
  1. **Aurelia grows.** New spells, mastery, crafted gear and her dragon raise her Magic Power.
  2. **Ignis weakens.** 💡 Each region boss guards an **Ember Core** that feeds Ignis's power. Destroying a core lowers his rank.
     So the gap closes from both sides, and the player can see it on the rank display.

### 3.5 💡 Idea: why Aurelia is so weak (needs approval)
Her magic isn't missing, it's **sealed**. Every spell she learns and every Ember Core destroyed loosens the seal.
Late reveal: the seal was placed to hide her from the Unknown One because she is connected to the Sky Rift.
This sets up the ending and a possible sequel. **Optional.** The simple version ("she is just weak and works hard") also works.

### 3.6 Story outline (acts)

| Act | Region(s) | Story beats |
|---|---|---|
| **Prologue** | Elderroot Meadow | Aurelia fails her rank test (rank **Spark**, the lowest). The Emberbound attack the village. **Ignis appears**; the fight cannot be won (scripted). Sylvaris drives him off. Aurelia meets Lumen and vows to grow strong. |
| **Act 1** | Elderroot Meadow → Azure Coast | Learn the basics: first spells, crafting, rest points. Sylvaris gives her a **dragon egg**. Boss 1: **Cinder Warden** (Emberbound captain). Boss 2: free the corrupted sea dragon **Brinecoil**. The egg hatches. |
| **Act 2** | Ruined Valley | Explore the old kingdom; learn the history of the Sky Rift. Night-only secrets. Dragon becomes a juvenile and can really fight. Boss 3: **The Hollow King** (an ancient spectral knight possessed by ember). |
| **Act 3** | Stormspire Highlands | Ignis's storm fortress. Boss 4: **Vharka the Stormbound**, Ignis's lieutenant. **Second Ignis encounter**: now Aurelia can survive and push him back. Dragon becomes an adult and can fly. |
| **Act 4** | Floating Isle / Sky Rift | Fly the dragon to the isle. Learn pure **Dawnflame** from the sun dragon 💡. **Final boss: Ignis Varos** (3 phases). |
| **Ending** | — | Ignis falls → he warns that his master is coming → the Sky Rift cracks open. ❓ Cliffhanger/post-game (recommended for scope), or a final fight with the Unknown One. |

---

## 4. Core gameplay loop

```
 Explore the world ──► Find tasks, puzzles, enemies, resources
        ▲                              │
        │                              ▼
 New areas & bosses open ◄── Rewards: spells • accessories • recipes • materials • dragon treats
        ▲                              │
        │                              ▼
 Magic Power & rank go up ◄── Learn spells • craft gear • train dragon • master spells by using them
```

- **Moment to moment (seconds):** move, dodge, cast spells, watch stamina and cooldowns.
- **Session (minutes):** clear a ruin, solve a puzzle, finish a task, craft a new accessory.
- **Long term (hours):** learn every spell, raise the dragon to adult, destroy the Ember Cores, defeat Ignis.

---

## 5. Player character: Aurelia

### 5.1 Stats

| Stat | Start | Purpose |
|---|---|---|
| **HP** | 100 | Health. 0 = defeated → respawn at the last rest point. |
| **Stamina** (magic stamina) | 40 | Every spell costs stamina. Regenerates over time. Prevents unlimited magic. |
| **Magic Power (MP)** | ~10 | Her overall magical strength. Sets her **Arcane Rank** and scales spell damage. |
| **Defense** | 0 | Reduces damage taken (mostly from cloak and accessories). |
| **Move speed** | base | Some accessories and spells change it. |

> **No XP levels.** Power comes from **spells learned + spell mastery + equipment + dragon bond**. This follows the concept: learning spells gives magical power.

### 5.2 Magic Power & Arcane Rank
- `Magic Power = Σ (each learned spell's power value × mastery bonus) + equipment bonuses`
- Rank thresholds (tune later):

| Rank | Name | Magic Power | Example |
|---|---|---|---|
| F | **Spark** | 0–49 | Aurelia at the start |
| E | **Glimmer** | 50–149 | Village apprentice |
| D | **Lantern** | 150–299 | Ordinary adult mage, common Emberbound soldier |
| C | **Beacon** | 300–499 | Guard captain, region boss (early) |
| B | **Star** | 500–799 | Elite mage, lieutenant |
| A | **Radiant** | 800–1199 | Master mage, late bosses |
| S | **Sovereign** | 1200+ | Ignis Varos (shown as "???" at first) |

- **Each new rank:** +10 max stamina, a small HP bonus, and access to stronger spell tomes and **Arcane Seals** (rank-locked doors and chests).
- Enemies show their **rank letter** above their health bar, so the player can read danger at a glance.

### 5.3 Controls (keyboard + mouse; gamepad also supported)

| Action | KB/M | Gamepad |
|---|---|---|
| Move (any direction, 3D) | WASD | Left stick |
| Aim | Mouse | Right stick |
| Staff strike (free, weak) | Left click | X / □ |
| Cast spell slot 1–4 | 1 / 2 / 3 / 4 (right click = slot 1) | LB / RB / LT / RT |
| Dash / dodge | Space | A / ✕ |
| Interact / talk | E | Y / △ |
| Dragon command (Follow → Attack → Guard) | G | D-pad up |
| Dragon skill | H | D-pad down |
| Menu / Map / Journal | Tab / M / J | Start / Select |
| Rotate camera | Q / R (or hold middle mouse and drag) | D-pad left / right |
| Zoom camera | Mouse wheel | — |
| Reset camera | Z | Right stick click |

All keys can be remapped.

### 5.4 Camera (3D, hybrid) ✅
- **Play camera:** high above and behind Aurelia (~40–45° down), follows her smoothly, can rotate and zoom. Clear fights, easy mouse aiming.
- **Scenic viewpoints:** at special places (first sight of the World Tree, the Azure Coast, the Sky Rift) the camera swings low to show the vista, then returns.
- Walls or trees between the camera and Aurelia fade out so she is never hidden.
- **No free jumping in v1.** Steps and stairs are climbed automatically; gaps are crossed with spells (Gale Step) or paths.

---

## 6. Magic system (the heart of the game)

### 6.1 Rules
- **Staff strike:** free, short range, weak. You can always do *something*, even with no stamina.
- **Spells** cost **stamina** and each has its **own cooldown**. A short global cooldown (~0.25 s) applies after any cast.
- **Stamina regen:** starts ~0.8 s after the last cast, at a steady rate.
- **Exhausted:** if stamina hits 0, Aurelia can't cast until it refills to ~30%. She can still strike and dash.
  This makes stamina a real decision, not just a number.
- **Dash** has its own short cooldown and does **not** use stamina, so stamina is only about magic.
- **4 equipped spell slots.** Change the loadout at any time outside combat (or at rest points; ❓ decide during testing).

### 6.2 Elements

| Element | Feel | Strong vs | Common puzzle use |
|---|---|---|---|
| ✨ **Light** | Aurelia's starting affinity (her lantern) | Ember, Shadow-touched | Reveal hidden runes/paths, light dark areas, purify Ember corruption |
| 🌪 **Wind** | Fast, pushes | Earth | Push blocks, spin fans, blow away fog/poison, cross small gaps |
| ❄ **Frost** | Slows, freezes | Fire, Ember | Freeze water into walkable ice, put out fires |
| 🪨 **Earth** | Heavy, protective | Wind | Raise pillars/bridges, press heavy switches, block projectiles |
| 🔥 **Fire** (pure, learned late) | Burst damage | Frost | Light braziers, burn vines and webs |
| 🟥 **Ember** (enemy only) | Ignis's corrupted fire | Fire (resists) | — |

- Strong = ×1.5 damage; weak/resisted = ×0.5. Pairs are easy to remember: **Fire↔Frost, Wind↔Earth, Light↔Ember**.
- The **gem on Aurelia's staff changes colour** to match the element of the last spell cast. This also fixes the colour mismatch between the reference images.
- Elements also show as **icons and shapes**, not only colour (colour-blind friendly).

### 6.3 Getting & learning spells
- **Spell sources:** spell tomes in chests/ruins, **Trials** (spell shrines with a combat or puzzle challenge), quest rewards,
  boss drops, NPC teachers, good dragons.
- **Learning:** read the tome at a **rest point**, using the reading-pose art. Some tomes need a minimum Magic Power or rank.
- **Mastery I → V:** a spell levels up as you use it. Each level adds damage, lowers cost or cooldown, *and* adds Magic Power.
  Using varied spells is rewarded.

### 6.4 Spell list v1 (draft, ~16 spells)

| # | Spell | Element | Type | Where found (draft) |
|---|---|---|---|---|
| 1 | **Light Mote** | Light | Weak homing bolt | Start |
| 2 | **Lantern Glow** | Light | Light aura; reveals hidden things | Start |
| 3 | **Gust** | Wind | Cone push + knockback | Elderroot Trial |
| 4 | **Mending Bloom** | Light | Small heal over time | Elderroot side task |
| 5 | **Frost Shard** | Frost | Piercing projectile, chills | Azure Coast |
| 6 | **Tide Ward** | Frost | Shield that absorbs one hit | Azure Coast Trial |
| 7 | **Glacial Path** | Frost | Freeze water / ground line | Brinecoil (boss reward) |
| 8 | **Stone Spire** | Earth | Raise a pillar: blocks, knocks up, presses switches | Ruined Valley |
| 9 | **Root Bind** | Earth | Roots enemies in place | Ruined Valley Trial |
| 10 | **Radiant Burst** | Light | AoE around Aurelia, purifies Ember Mark | Hollow King (boss reward) |
| 11 | **Gale Step** | Wind | Blink-dash through attacks and over gaps | Stormspire |
| 12 | **Storm Lance** | Wind | Lightning line, chains to a second enemy | Stormspire Trial |
| 13 | **Earthen Guard** | Earth | Temporary defense buff | Side quest |
| 14 | **Prism Ray** | Light | Channelled beam, bounces off mirrors | Late ruins |
| 15 | **Dawnflame** | Fire | Pure fire blast, very strong vs Frost and Ignis's armour phase | Sun dragon, Floating Isle |
| 16 | **Starfall** | Light | Ultimate: delayed meteor AoE, big stamina cost | Final trial |

### 6.5 Status effects

| Effect | From | Result |
|---|---|---|
| **Burn** | Fire / Ember | Damage over time |
| **Chill → Freeze** | Frost | Slowed; 3 stacks = frozen briefly |
| **Stagger** | Wind, Earth, heavy hits | Interrupts the target's attack |
| **Root** | Earth | Can't move, can still attack |
| **Daze** | Light | Enemy misses more / pauses briefly |
| **Ember Mark** (enemy → player) | Ember attacks | Player takes extra damage until cleansed (Light or a potion) |

---

## 7. Combat

- **Real-time 3D with the high-angle camera**, aim with mouse/stick. Fast and readable, not button-mashing.
- **Feel (the "juice"):** hit-stop (short freeze on impact), knockback, screen shake on big hits, damage numbers (toggleable), particle effects.
- **Dash** with brief invincibility to dodge attacks.
- **Telegraphs:** every enemy attack has a visible wind-up (glow, flash, **glowing ring on the ground**) and a sound. A hit should never feel unfair.
- **Enemies use magic too**, as in the concept: casters, elemental shields, buffs, summons.
- **Elemental shields** 💡: some enemies have a shield that only one element breaks, which makes fights a small puzzle (inspired by CrossCode's element-mode design).
- **Defeat:** respawn at the last rest point with no items lost. Regular enemies reset; bosses reset to full.
- **Difficulty settings:** Story / Normal / Hard (damage taken, enemy aggression, telegraph length).

### 7.1 Enemies (draft, ~12 types + variants)

| Region | Enemies (examples) |
|---|---|
| Elderroot Meadow | Ember Wisp (slow fire bolt), Thornling (melee plant), Emberbound Scout (sword + fire dash) |
| Azure Coast | Brine Crab (frontal shell; hit from behind), Tide Caster (water bolts, shield), Corrupted Gull swarm |
| Ruined Valley | Stone Sentinel (slow, Earth-shielded), Lantern Ghost (night only, weak to Light), Ivy Stalker (invisible until revealed) |
| Stormspire Highlands | Storm Hound (fast pack), Emberbound Mage (casts fire circles, summons wisps), Spark Golem (explodes) |
| Floating Isle | Elite Emberbound Knight, Rift Shade (teleports), mixed elites |

- Each enemy has a **rank letter**, an **element**, a **weakness**, and **2–4 attack moves** with clear telegraphs.

### 7.2 Bosses
- **One boss per region plus Ignis encounters.** Each boss teaches or tests one idea, such as a spell or element learned in that region.
- **Phases:** every boss has 2–3 phases. New attacks unlock as its HP drops (e.g. at 66% and 33%).
- **Difficulty curve:** gentle at first, then rising. Early bosses have slow, long telegraphs and few attacks.
  Later bosses are faster, combine attacks, and punish poor stamina use.
- **Story difficulty:** a checkpoint at each phase change. Normal/Hard: restart the whole fight.

| # | Boss | Region | Rec. Magic Power | Mechanic it tests | Reward |
|---|---|---|---|---|---|
| 0 | Ignis (prologue) | Elderroot | — | **Can't win**: shows how strong the enemy is | Story |
| 1 | **Cinder Warden** | Elderroot Meadow | ~40 | Dodging telegraphs, stamina basics | Ember Core #1, recipe, accessory |
| 2 | **Brinecoil** (corrupted sea dragon, *freed* not killed) | Azure Coast | ~150 | Frost vs Ember, using pillars as cover | Glacial Path, Ember Core #2, ally dragon |
| 3 | **The Hollow King** | Ruined Valley | ~300 | Light reveals his weak point; summoned adds | Radiant Burst, Ember Core #3 |
| 4 | **Vharka the Stormbound** | Stormspire | ~500 | Gale Step dodging, Earth blocks lightning | Ember Core #4, legendary staff recipe |
| 5 | Ignis (2nd encounter) | Stormspire | — | Survive 90 s / push him back (scripted retreat) | Story |
| 6 | **Ignis Varos** (final) | Floating Isle | ~900 (+ cores destroyed) | Everything; 3 phases; Dawnflame breaks his armour | Ending |

---

## 8. Dragons

### 8.1 Two kinds of dragons
- **Good wild dragons** (story NPCs): Sylvaris (elder, World Tree), Brinecoil (sea dragon, freed from Ember corruption),
  Aurorath 💡 (sun dragon, Floating Isle). They give quests, teach spells and help in the story. Some are **corrupted by Ignis**:
  those fights end with *freeing* them, not killing them.
- **Pet dragon** (yours): hatched from an egg, raised, trained and used in battle.

### 8.2 Pet dragon lifecycle

| Stage | When | Can do |
|---|---|---|
| **Egg** | Act 1 (from Sylvaris) | Carried. Warmed by fighting and exploring (a progress bar). |
| **Hatchling** | End of Act 1 | Follows, distracts enemies, small breath attack, sniffs out buried items 💡 |
| **Juvenile** | Act 2 | Full combat companion, 2–3 skills |
| **Adult** | End of Act 3 | Strong skills, **flight**: fast travel between Dragon Roosts and the way to the Floating Isle |

- **Element chosen at hatching** 💡: Frost, Wind, Earth or Light (a different skill set per element; one body shape with recolours keeps art cost low).
  ❓ More than one pet dragon is a stretch goal.

### 8.3 Training & bond
- **Bond level 1–10**, raised by: fighting together, feeding **dragon treats** (crafted), petting/playing at the **Dragon Roost**,
  and short **training games** (target practice, fetch race).
- Bond unlocks **new dragon skills** and stat boosts. Dragons can wear crafted **dragon charms**.

### 8.4 Dragon in battle
- **Commands:** **Follow** (stay close, attack nearby threats), **Attack** (go after Aurelia's target), **Guard** (stay at Aurelia's side and block or intercept).
- **Dragon skill:** one special move on its own cooldown, triggered by the player.
- Smart default AI: it never ignores the player's intent, follows the command, and keeps out of telegraphed attack zones where possible.
- **Knocked out:** the dragon retreats and returns after ~20 s, or at a rest point. It never dies permanently.
- **Combo** 💡: some dragon skills combine with Aurelia's spells (dragon Frost breath + her Storm Lance = shatter bonus).

---

## 9. Items, equipment & crafting

### 9.1 Equipment slots
- **Staff** ×1: changes the staff strike, spell power and an element bonus. ~5 staffs in v1 (crafted upgrades).
- **Cloak** ×1: defense plus one passive (e.g. Storm Cloak = less lightning damage).
- **Accessories** ×3: rings, amulets, charms. Examples:
  - *Ember-Ward Ring*: −30% Ember damage
  - *Swift Quill Charm*: −10% spell cooldowns
  - *Lantern Heart Amulet*: +20 max stamina
  - *Frostbite Band*: Frost spells leave an icy trail that chills enemies
  - *Dragonbond Pendant*: dragon gains +1 bond level worth of stats
- Accessories come from **tasks, bosses, chests and crafting**.

### 9.2 Materials
- **Gathered:** flowers and herbs (Sunpetal, Moonbloom), wood, ore, crystals, shells, Stormglass.
- **Enemy drops:** ember cinders, crab shells, ghost essence, golem cores.
- **Boss materials:** one unique material per boss, used for top-tier recipes.
- The **journal shows where each material is found** (no blind grinding).

### 9.3 Crafting
- **Workbench at the World Tree hub** (staffs, cloaks, accessories, dragon charms), plus a **portable kit** at rest points (potions, treats).
- **Recipes** are found in chests, given by NPCs, learned from bosses, or bought.
- **~25 recipes in v1.** Every recipe should be useful. Early recipes use common materials to teach the system; top recipes need boss materials.
- **Upgrading:** staffs and accessories can be upgraded +1 to +3 with extra materials.
- **Consumables:** healing potions, stamina tonics, element oils (temporarily add an element to the staff strike), cleansing water (removes Ember Mark), dragon treats.

---

## 10. Puzzles

Puzzles use **the spells the player has**, so learning a spell feels useful outside combat too.

| Puzzle type | Example |
|---|---|
| Element interactions | Fire lights braziers; Frost freezes water; Wind spins fans and pushes blocks; Earth raises pillars onto pressure plates |
| Light & lantern | Dark ruins need Lantern Glow; hidden runes appear only in light; Prism Ray bounces off mirrors |
| Block / switch | Push or raise blocks to open doors (classic action-adventure puzzles) |
| Rune sequence | Read clues in the ruins, then activate runes in the right order |
| Day/night | A door only opens under moonlight; ghosts appear only at night |
| Dragon-assisted | Dragon breath hits a far switch; the dragon carries a light; adult dragon flight |
| Combat puzzles | Enemies with elemental shields; fights in arenas with hazards |

- Rule: **every puzzle teaches its idea first** (an easy version), then tests it, then twists it.
- **Lumen** gives an optional hint after the player has been stuck for a while.

---

## 11. Quests & tasks

| Type | Description | Typical reward |
|---|---|---|
| **Main quest** | The story acts (§3.6) | Story progress, key spells, Ember Cores |
| **Side tasks** | NPC requests: find, deliver, defeat, gather, investigate | Accessories, recipes, materials, coins |
| **Trials** (spell shrines) | A self-contained combat or puzzle challenge | **A new spell** |
| **Bounties** | Defeat a named elite enemy | Rare materials, accessories |
| **Dragon tasks** | Find treats, train, help wild dragons | Bond, dragon charms, dragon skills |
| **Aether Shards** | Hidden collectibles; 3 shards = +max stamina | Stamina upgrade |

- Target for v1: **~20 side tasks**, **~10 Trials**, **~10 bounties**.
- The **journal** (Aurelia's book) tracks quests, a bestiary, spell descriptions, materials and lore.

---

## 12. World structure

- **Hub + 5 regions**, linked around the **World Tree**.
- **Open, with soft gates.** Most areas are open, but some paths need a spell (Metroidvania-style):

| Region | Theme | Needs to fully explore | Day/night & weather |
|---|---|---|---|
| 1. **Elderroot Meadow** (start + hub) | World Tree, meadows, ruins, golden light | — | Normal cycle |
| 2. **Azure Coast** | Turquoise bay, cliffs, waterfall, castle ruins | Gust (cross wind gaps) | Sunny, sea breeze |
| 3. **Ruined Valley** | Ivy arches, towers, fireflies | Glacial Path (freeze the river) | Best at dusk/night |
| 4. **Stormspire Highlands** | Rain, floating rubble, gothic spire | Stone Spire (raise bridges) | Always stormy |
| 5. **Floating Isle / Sky Rift** | Ginkgo trees, pagoda, the portal | **Adult dragon flight** | Golden mist |

- **Rest points** (Lantern Shrines): save, heal, learn spells, change the loadout, fast travel to other shrines.
- **Day/night cycle:** ~20 real minutes per game day. Some enemies, NPCs and puzzles change with time.
- **Weather:** clear, rain, fog, storm. Some secrets only appear in certain weather.
- Region sizes are kept small: each region is a few connected 3D areas, small and dense rather than huge and empty.

---

## 13. UI / UX

- **HUD:** HP bar, **stamina bar** (flashes when Exhausted), 4 spell slots with **radial cooldown** overlays, dragon portrait + HP + current command,
  rank badge, minimap (optional), quest tracker (1 line).
- **Menus:** Inventory, Equipment, **Grimoire** (spells + loadout + mastery), Crafting, Dragon, Journal (quests/bestiary/lore/materials), Map, Settings.
- **Conversations & cutscenes:** dialogue box with portraits, choices, speech-bubble barks, skippable cutscenes. Full plan and character voice guide: [DIALOGUE_DESIGN.md](DIALOGUE_DESIGN.md).
- **Style:** fantasy book UI (parchment, gold trim from the cape embroidery). Clean and readable.
- **Accessibility:** key remapping, text size, text speed, subtitles, screen-shake toggle, damage-number toggle, colour-blind safe element icons.

---

## 14. Art & audio direction (summary)

- Full art references: [DESIGN_NOTES.md](DESIGN_NOTES.md).
- **Painterly anime 3D:** cel-shaded characters (two-tone shading, rim light, thin outlines), soft painterly environments, moss on stone,
  wind-swayed grass, sparkling water, warm light, fog, glow and fireflies. **Simple 3D shapes as placeholders first**, real art later.
- Characters made in **VRoid Studio** (anime style, hair/cape sway); animations from a free CC0 library; props from CC0 kits edited in Blender,
  all recoloured to one palette. Details: [3D_PROPOSAL.md](3D_PROPOSAL.md) §2 and §5.
- Music: calm, wonder-filled exploration themes per region (flute, strings, harp); stronger battle and boss themes. Ignis gets a heavy, fiery theme.
- SFX: each element has its own sound family, which helps players read telegraphs.
- Full audio plan (music list, sound list, mixer, adaptive music, sourcing and licences): [AUDIO_DESIGN.md](AUDIO_DESIGN.md).

---

## 15. Scope

### 15.1 Vertical slice (first playable goal)
**Prologue + Elderroot Meadow**, about 30–45 minutes:
- Aurelia: movement, dash, staff strike, **4 spells** (Light Mote, Lantern Glow, Gust, Mending Bloom), stamina and cooldowns, Magic Power and rank.
- **3 enemy types** + **boss Cinder Warden**.
- **2 puzzle types** (element and lantern), **1 Trial**.
- Inventory, **5 recipes**, **3 accessories**, workbench.
- Dragon egg (hatches at the end of the slice).
- Rest point with save/load, day/night, dialogue, quest journal.

### 15.2 Version 1.0 content targets

| Content | Target |
|---|---|
| Regions | Hub + 5 |
| Spells | ~16 (+ dragon skills) |
| Enemy types | ~12 (+ variants) |
| Bosses | 5 + Ignis encounters |
| Recipes | ~25 |
| Accessories | ~15 |
| Side tasks / Trials / Bounties | ~20 / ~10 / ~10 |
| Pet dragons | 1 (element chosen at hatching) |
| Playtime | ~6–10 hours |

### 15.3 Stretch goals (only after 1.0 works)
More pet dragons, riding the dragon in real time, New Game+, the Unknown One boss, co-op (unlikely), more regions.

---

## 16. Open questions

1. ❓ The **Unknown One**: name, nature, and whether it appears in v1 (recommend: ending cliffhanger only).
2. ❓ Approve the 💡 **sealed magic** idea for Aurelia?
3. ❓ Approve the 💡 **Ember Core** mechanic (Ignis weakens as cores are destroyed)?
4. ❓ Spell loadout changes: anywhere outside combat, or only at rest points?
5. ❓ Pet dragon: one dragon with element choice (recommended), or a fixed dragon?
6. ❓ Keep the names suggested here (Lumen, Sylvaris, Brinecoil, Hollow King, Vharka, Aurorath)?

---

## 17. Inspiration (systems only; we copy no names, characters, art or levels)

- **CrossCode**: switching elements in combat and puzzles; dungeons themed around one element. [Wikipedia](https://en.wikipedia.org/wiki/CrossCode)
- **Classic top-down Zelda-likes** (e.g. *Elementallis*): ability-gated exploration and item puzzles.
- **Crashlands**: crafting loops where recipes lead you to new areas. [Devlog](https://blog.bscotch.net/post/looping-recipes-pre-beta-devlog-part-1/)
- **Companion AI research**: Follow / Attack / Guard commands; the companion must respect player intent. [McGill paper](https://www.cs.mcgill.ca/~jtremb59/Papers/Adaptive%20Companions%20in%20FPS%20Games.pdf)
- **Boss design**: clear telegraphs, phases, and fair difficulty. [Wayline article](https://www.wayline.io/blog/crafting-legendary-boss-battles), [Game Developer deep dive](https://www.gamedeveloper.com/design/design-deep-dive-angelical-echo-boss-fight)
