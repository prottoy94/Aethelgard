# Aethelgard — Dialogue & Cutscene Design

> Status: **v0.1 draft (planning phase)**, written 2026-11-03.
> Part of the design set: [GAME_DESIGN.md](GAME_DESIGN.md) · [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) · [AUDIO_DESIGN.md](AUDIO_DESIGN.md) · [REQUIREMENTS.md](REQUIREMENTS.md) (dialogue = `FR-DLG-*`).
> 💡 = suggestion that needs the owner's approval · ❓ = open question. All sample lines are **drafts**.

---

## 1. Goals

1. **Characters feel alive.** Each one has a clear voice you'd recognise without the name plate.
2. **Short and readable.** Players came to explore and fight. Most conversations take under a minute; long lore goes in the journal.
3. **The world remembers.** NPCs react to story progress, bosses defeated, Aurelia's rank and the dragon.
4. **Easy to write and change.** Plain-text scripts that the owner and Claude can both edit and review in git.

---

## 2. Tool: Dialogue Manager

- **Dialogue Manager** add-on (nathanhoad, MIT) for Godot 4. Scripts are `.dialogue` text files with a built-in syntax checker.
- Check that the add-on release supports our Godot version before installing (M0).

### 2.1 File layout
```
res://dialogue/
├─ main/        # main story: prologue.dialogue, act1_elderroot.dialogue, act1_azure.dialogue, ...
├─ npcs/        # one file per important NPC or per village: elderroot_villagers.dialogue
├─ quests/      # side task dialogue: quest_lost_satchel.dialogue
├─ barks/       # short remarks: lumen.dialogue, enemies.dialogue, dragon.dialogue
├─ system/      # tutorials, rest point, workbench, trial shrines
└─ glossary.md  # names and terms to keep consistent (see §11)
```
- **Title naming:** `~ {scene}_{beat}`, e.g. `~ prologue_rank_trial`, `~ sylvaris_first_meeting`, `~ elder_after_warden`.

### 2.2 Script cheat sheet

```
~ sylvaris_first_meeting
Sylvaris: [#calm] So... you are the little elf who fell at the rank trial.
Aurelia: [#embarrassed] Spark rank. The lowest there is.
Sylvaris: Rank measures what you are. Not what you will become.
- "Then teach me to become more."
	Sylvaris: [#pleased] Spoken like a true mage.
	do QuestManager.start("dragon_egg")
- "Why would a dragon help someone like me?"
	Sylvaris: Because Ignis fears what he cannot measure.
	=> sylvaris_first_meeting
if PlayerData.rank >= Ranks.LANTERN
	Sylvaris: [#surprised] ...Your light has grown already.
=> END
```

| Syntax | Meaning |
|---|---|
| `Name: text` | A spoken line |
| `[#mood]` | Portrait expression tag (see §6). Other tags: `[#left]`/`[#right]` portrait side, `[#shake]` box shake, `[#sfx=id]` play a sound event, `[#ask]` on a choice line: it still waits for the player when the scene is skipped (§5.3) |
| `- text` | A player choice; indented lines are what happens next |
| `if / elif / else` | Show lines only when a condition is true |
| `do Something()` | Make something happen in the game (quest, item, flag, cutscene action) |
| `set GameState.x = y` | Change a value |
| `=> title` / `=> END` | Jump to another part / end the conversation |
| `{{DragonManager.dragon_name}}` | Insert a value into the text |

### 2.3 What dialogue is allowed to call
To keep things safe and tidy, dialogue only talks to these game objects:

| Object | Typical use |
|---|---|
| `GameState` | `has_flag()`, `set_flag()`: story memory |
| `QuestManager` | `start()`, `advance()`, `is_active()`, `is_done()` |
| `Inventory` | `has()`, `add()`, `remove()` |
| `PlayerData` | rank, Magic Power, learned spells |
| `DragonManager` | `dragon_name`, stage, element, bond; `receive_egg()`, `choose_element("frost")`, `ask_name()`, `is_hatched()`, `has_egg()` (Phase 7: the name lives here, not in PlayerData) |
| `Cutscene` | camera, movement, animation, fades (§5) |
| `AudioManager` | music changes, stingers |

Dialogue never touches scene nodes directly. A unit test checks that every `do`/`if` target in every `.dialogue` file exists (`FR-DLG-10`).

---

## 3. Kinds of conversation

| Type | When | Presentation | Game paused? |
|---|---|---|---|
| **Story scene** | Main quest moments | Large dialogue box, **two portraits** (left/right), name plate, expressions | Yes |
| **NPC talk** | Interact with an NPC | Same box, one or two portraits | Yes |
| **Barks** (short remarks) | Lumen hints, enemies spotting you, villagers in passing, dragon reactions | Small **speech bubble** above the character, disappears after ~2–3 s | No |
| **Cutscene** | Prologue attack, Ignis appearances, dragon hatching, boss intros, ending | Letterbox bars + dialogue box + scripted camera and movement | Yes, skippable |
| **System text** | Tutorials, item received, spell learned | Small centred panel | Yes (briefly) |

### 3.1 Dialogue box features
- Typewriter text with a per-character **text blip** sound (different pitch per character, see AUDIO_DESIGN.md).
- **Text speed** setting (slow / normal / fast / instant) and **auto-advance** option.
- Press to finish the current line instantly; press again to continue.
- **History log** 💡: press a key to scroll back through the last ~50 lines.
- **Max 2–3 lines per box** (~100 characters). Longer speeches are split into several boxes.
- Choices show as a vertical list; keyboard, mouse and gamepad all work.

---

## 4. Choices: what they change

Keeping scope small means **choices change the conversation, not the main story**:

| Level | Example | Used in v1? |
|---|---|---|
| **Flavour** | Aurelia answers cheerfully or shyly; same outcome | ✅ Most choices |
| **Info** | Ask about the Sky Rift, Ignis or rank history before continuing | ✅ |
| **Small consequences** | Help a thief or report him → different side-quest reward | ✅ A few side quests |
| **Story branches** | Different endings | ❌ Not in v1 |

- Aurelia **speaks** (she has her own personality). Choices are *how* she says things, not a silent hero picking anything.
- **Naming the dragon:** a text input during the hatching cutscene. If left empty, the default name **Pip** is used (owner decision 2026-11-04). Built in Phase 7 (`do DragonManager.ask_name()` → `Cutscene.ask_text`); text-markup characters are removed.

---

## 5. Cutscenes

### 5.1 Approach
- **Simple scenes** are scripted **inside the `.dialogue` file** with `Cutscene` actions:
  ```
  ~ prologue_ignis_arrives
  do Cutscene.letterbox(true)
  do Cutscene.camera_to("marker_village_gate", 1.5)
  do AudioManager.play_music("mus_boss_ignis", 0.5)
  do Cutscene.spawn("ignis", "marker_gate")
  do Cutscene.move("ignis", "marker_square", 2.0)
  Ignis: [#cold] So this is where the elves hide their little lights.
  do Cutscene.shake(0.4)
  Aurelia: [#scared] W-who are you?!
  Ignis: [#smirk] Ignis Varos. Herald of the Final Ember. Remember it. Briefly.
  do Cutscene.letterbox(false)
  => END
  ```
  `Cutscene` actions that take time (`move`, `camera_to`, `wait`, `fade`) are awaited, so the next line waits for them to finish.
- **Complex scenes** (many characters moving at once, effects timed to music, such as the dragon hatching or the ending) use an
  **AnimationPlayer cutscene scene** that the dialogue starts with `do Cutscene.play("dragon_hatch")`.

### 5.2 `Cutscene` autoload API
`letterbox(on)`, `camera_to(marker, time)`, `camera_follow(actor)`, `camera_zoom(z, time)`, `spawn(actor_id, marker)`, `despawn(actor_id)`,
`move(actor_id, marker, time)`, `face(actor_id, direction)`, `anim(actor_id, name)`, `emote(actor_id, icon)` (💡 ! ? ♪ … bubbles),
`wait(seconds)`, `fade_out(time)` / `fade_in(time)`, `flash(color)`, `shake(strength)`, `play(cutscene_scene_id)`.
Actors and markers are found by ID inside the current region scene (`CutsceneMarker` nodes, a `Marker3D`, in the group
`cutscene_marker`; actors tagged with `CutsceneActor.tag()`: "aurelia", "lumen", "dragon", NPCs by their id, "ignis",
"sylvaris", "rank_stone"). The cutscene camera is a separate `Camera3D` that blends from the play camera.
**Built so far:** `letterbox`, `fade_out`/`fade_in`, `wait` (Phase 6a); Phase 7 adds `play(id)` (adds that id's
`CutsceneScene` next to Aurelia; the scene runs its own dialogue), `cue(name)` (the dialogue asks the playing scene for an
effect, e.g. `do Cutscene.cue("hatch")`, awaited) and `ask_text(question, default, max_length)` (a parchment name box).
The bars sit under the dialogue box; the HUD hides while a scene plays. First scene: `src/cutscenes/dragon_hatch/`.
**Phase 8b** adds `camera_to(marker, time)` / `camera_back(time)`, `spawn`, `despawn`, `move`, `face`, `anim` (Aurelia's
roles, "idle" to stand again, or the actor's own: Sylvaris "land", "roar", "breath", "bow", "rise", "take_off";
Ignis "gather", "release", "recoil", "vanish"), `emote`, `shake(strength, time)`, `flash(colour, time)` and skipping.
Conversations pause the game, so these run while paused; the actors a scene touches keep animating, and the dialogue
box steps aside while a timed action runs. Story scenes written as a single title (`StoryScene`) can be played by a
region with `play_scene()`, which answers their cues (the prologue: `VillagePrologue`). `camera_follow`/`camera_zoom`
are not needed yet.

### 5.3 Rules
- **Every cutscene can be skipped** (hold Esc or B for a second). Skipping still applies all of its game effects (flags,
  quests, items). *Built in Phase 8b as a fast-forward* rather than the `# required` marking first planned: lines
  finish at once, flavour choices take the first answer and timed actions end at once, so every line's effect runs in
  order and nothing has to be marked. A choice the player must make is tagged `[#ask]` and still waits (the dragon's
  colour), and so does the name box.
- Cutscenes play once; their flag (`cs_prologue_ignis_seen`) prevents replays. *Built: every scene sets
  `cs_<id>_seen` when it ends; the prologue also keeps beat flags so a game saved part-way picks up at the last beat.*
- Keep them short: the prologue under ~3 minutes in total, most others under 1 minute.

---

## 6. Portraits

- **Size:** 512×768 px bust portraits (waist up), transparent background. Drawn facing right; flipped when placed on the right side ❓ (asymmetric details like a single braid may need a separate right-facing version).
- **Naming:** `portrait_{character}_{expression}.png` in `assets/art/portraits/`.
- **Placeholders first:** a coloured silhouette with the character name and expression written on it, at the final size.
- **Final portraits** can be rendered from the VRoid models (pose + expression in VRoid or Godot), keeping characters consistent with the 3D game.

| Character | Expressions (v1) |
|---|---|
| Aurelia | neutral, happy, wink (from `pose_2`), excited, embarrassed, sad, scared, determined, angry, surprised, thinking |
| Lumen | (3D butterfly model only, no portrait: a glowing butterfly icon in the name plate) |
| Sylvaris | calm, pleased, stern, sad, surprised |
| Ignis Varos | cold, smirk, angry, amused, wounded *(placeholder: a crown of embers, a high collar)* |
| Village Elder | neutral, worried, proud |
| Rank Examiner 💡 | neutral, dismissive, impressed |
| Rival apprentice 💡 | smug, annoyed, surprised, respectful |
| Brinecoil / Vharka / Hollow King | 3–4 each (neutral, angry, pained, freed/defeated) |
| Generic NPCs | 1–2 each, recolour variants |
| The Shrine (Trial voice) | calm, pleased *(placeholder: carved rings round a curl of wind)* |
| Emberbound (barks and the prologue) | one helmet with a glowing visor |

Estimated count: ~60–70 portrait images for v1 (~20 for the vertical slice).

---

## 7. Character voice guide

How each character **sounds in writing**. Use this to keep lines consistent.

### Aurelia (player)
- **Personality:** cheerful, curious, bookish, a little clumsy, stubborn underneath. Hides hurt with jokes.
- **Speech:** warm, quick, exclamation marks when excited, quotes from books, talks to Lumen and her dragon like friends.
  Grows more confident through the acts. Early: "I-I'll try!" Late: "I'll handle this."
- **Never:** cruel, sarcastic for long, or arrogant.
- *Sample:* "A Spark can still start a fire. ...Not that kind of fire, Lumen, stop glowing at me like that."

### Lumen (spirit butterfly)
- **Personality:** playful, old and wise underneath, speaks rarely.
- **Speech:** short, gentle, a little riddle-like. Mostly **barks** (hints), not long conversations.
- *Samples:* "Something sleeps beneath those stones." · "Your light is stronger than you think." · "Night opens doors the day keeps shut."

### Sylvaris (elder dragon)
- **Personality:** ancient, patient, kind but distant; carries old guilt about the fallen kingdom.
- **Speech:** slow, formal, short sentences, calls Aurelia "little light". No contractions.
- *Sample:* "The World Tree does not choose the strong, little light. It chooses those who keep walking."

### Ignis Varos, Herald of the Final Ember
- **Personality:** proud, cold, intelligent; sees magic rank as the only truth. Not a screaming villain; he is *certain*.
  Hidden layer: he fears his master more than any hero.
- **Speech:** calm, precise, polite in a cruel way, fire and ash imagery. Calls Aurelia "Spark" as an insult.
  His calm cracks as the Ember Cores fall.
- *Samples:* "Power is a ledger, Spark. Yours is empty." · (late) "You don't understand. If I fail... it comes. And it will not be merciful."

### The Unknown One
- **Never seen in v1.** Only whispers, distorted text, or silence near the Sky Rift. Few words, no name.
- *Sample:* "...*so the herald falters*..."

### Pet dragon
- **No words.** Chirps (sound), **emote bubbles** (♥, !, ?, ♪, zzz) and animations. Aurelia talks *to* it, and its reactions answer.

### Other characters (draft)
| Character | Voice |
|---|---|
| **Village Elder** | Kind, worried, old-fashioned; believes in Aurelia a little more than he shows |
| **Maren** (herbalist, draft) | Warm and practical; calls everyone "dear"; teases gently |
| **Tamsin** (village child, draft) | An explorer at heart; dramatic, honest, easily distracted by dragonflies |
| **Rank Examiner** 💡 | Bored, bureaucratic, dismissive ("Next."); later surprised by Aurelia's growth |
| **Rival apprentice** 💡 | A high-ranked young mage who mocks Aurelia at the start; grows from rival to friend. Shows "lower than everyone" without a narrator saying it |
| **Brinecoil** | Pained and confused while corrupted; grateful and deep-voiced when freed |
| **The Hollow King** | Old royal speech, echoes, sad more than evil |
| **Vharka the Stormbound** | Loud, battle-hungry, loyal to Ignis, respects strength |
| **Emberbound soldiers** (barks) | Short, mocking, rank-obsessed: "A Spark? Don't waste the fire." |

---

## 8. Barks (short remarks)

- Stored in `dialogue/barks/` as titles with several variant lines; one is picked at random.
- Each bark has a **trigger**, a **cooldown** (so it doesn't repeat too often) and a **priority** (story barks beat ambient ones).

| Speaker | Triggers (examples) |
|---|---|
| Lumen | Secret nearby, player stuck on a puzzle for N seconds, low HP first time, new region, night falls |
| Aurelia | Learns a spell, rank up, Exhausted for the first time, dragon levels up, finds lore |
| Enemies | Spot the player, low HP, death, the player has a higher rank than them (late game 💡: "That's no Spark...") |
| Villagers | Passing by; lines change with story flags and Aurelia's rank |
| Dragon | Emote bubbles: happy after a treat, scared in the dark, excited before a boss |

💡 **Rank-aware barks** make growth visible: early on enemies mock Aurelia; later they hesitate or flee.

---

## 9. Story memory (flags)

- Flags are named `{area}_{event}`: `prologue_done`, `met_sylvaris`, `warden_defeated`, `egg_received`, `dragon_hatched`, `cs_ignis_intro_seen`.
- NPCs check flags to change lines. Every important NPC has at least: **before**, **during** and **after** versions for the main quest beat in their area.
- **Repeat talk:** after a full conversation, talking again gives a short reminder line, not the whole conversation.
- A **debug menu** can set and clear flags to test conversations quickly.

---

## 10. Vertical slice script list (Prologue + Elderroot Meadow)

| ID | Scene | Type | Characters |
|---|---|---|---|
| `prologue_morning` | Aurelia wakes and reads her spellbook (`pose_1` art) | Story | Aurelia, Lumen (hidden). *Draft written (Phase 8b): `main/prologue.dialogue`; she reads on the bench by her cottage, the Elder calls from off-screen* |
| `prologue_rank_trial` | Rank trial: she scores **Spark**; the rival mocks her | Story | Aurelia, Examiner, Rival, Elder. *Draft written (Phase 8b): the Elder holds the test at the Rank Stone (owner decision 2026-11-07: no Examiner or Rival yet); ends with the Emberbound horn* |
| `prologue_ignis_arrives` | Emberbound attack, Ignis appears | Cutscene | Aurelia, Ignis, Elder. *Draft written (Phase 8b): after the two Scouts fall* |
| `prologue_unwinnable` | Scripted fight → Sylvaris drives Ignis away | Cutscene | Ignis, Sylvaris. *Draft written (Phase 8b)* |
| `sylvaris_first_meeting` | Sylvaris speaks to Aurelia; Lumen awakens | Story | Aurelia, Sylvaris, Lumen. *Draft written (Phase 8b): follows `prologue_unwinnable` in one scene* |
| `elder_quest_start` | The Elder asks Aurelia to find the Trial shrine | NPC | Elder. *Draft written (Phase 8b): a short scene; also sends her to Maren and Tamsin and starts both quests* |
| `trial_gust_intro` / `_complete` | Trial shrine voice and reward | System | Shrine. *Draft written (Phase 8b): `system/trial_shrines.dialogue` (+ `trial_gust_test`, `trial_gust_repeat`); Lumen's hint `lumen_hint_runes`* |
| `quest_lost_satchel` | Side task: find a child's lost satchel | NPC | Villager child (Tamsin). *Draft written (Phase 6a): `npcs/elderroot_villagers.dialogue`, cues `tamsin`, `tamsin_return`* |
| `quest_herbalist` | Side task: gather herbs → first recipe | NPC | Herbalist (Maren). *Draft written (Phase 6a): cues `maren`, `maren_hand_over`* |
| `warden_intro` / `warden_defeat` | Boss intro and defeat | Cutscene | Cinder Warden, Aurelia |
| `egg_gift` | Sylvaris gives the egg | Story | Sylvaris, Aurelia. *Stand-in written (Phase 7): the Elder gives it, cue `elder_egg` in `npcs/elderroot_villagers.dialogue` (owner decision 2026-11-04)* |
| `dragon_hatch` | Egg hatches, naming the dragon | Cutscene | Aurelia, dragon, Lumen. *Draft written (Phase 7): `story/dragon_hatch.dialogue` (colour = element choice, name box)* |
| `barks_*` | Lumen hints, Emberbound shouts, villager remarks | Barks | Various. *Draft written (Phase 6a): `barks/lumen.dialogue`, villager `*_bark` cues* |

---

## 11. Writing workflow

1. **Owner** decides story beats (GAME_DESIGN.md §3.6).
2. **Claude** drafts the `.dialogue` file following the voice guide, marked `# status: draft` at the top.
3. **Owner** reviews and edits, or asks for changes → `# status: approved`.
4. Lines are tested in game (box length, portrait timing, flags).

**Style rules**
- Max ~100 characters per box; most lines shorter.
- One idea per line. Show feelings with expressions and actions instead of explaining them.
- No modern slang; light fantasy tone, but not old-fashioned for everyone (only Sylvaris and the Hollow King speak formally).
- Names and terms come from `dialogue/glossary.md` (Arcane Ranks: Spark, Glimmer, Lantern, Beacon, Star, Radiant, Sovereign; Emberbound; Ember Cores; Lantern Shrines…).
- No real-world references, and nothing copied from existing games or anime.

---

## 12. Voice acting & translation

- **v1: text only**, with per-character text blips. Optional short **voice grunts/exclamations** for key characters ❓.
- **Aurelia's voice is defined** by the vocals in the owner's song *Sunlight on Ancient Stone* (AUDIO_DESIGN.md §10). Any future Aurelia voice work
  (exclamations, voiced scenes, humming) should match that voice. Her text blip is tuned to the song's key (F#) 💡.
- **Stretch:** voiced key scenes. The `[#voice=id]` tag is reserved for this, so scripts don't need rewriting later.
- **Translation-ready from day one:**
  - All player-facing text lives in `.dialogue` files or Godot translation files, never hard-coded in scripts (UI uses `tr()`).
  - Dialogue Manager can give each line a static ID and export lines for translation; use that once the script stabilises.
  - Choose a font with wide character support; leave ~30% extra space in UI boxes for longer languages.
  - ❓ Which languages, if any, besides English (the owner decides).

---

## 13. Testing

| Check | How |
|---|---|
| Syntax | Dialogue Manager's built-in checker (errors shown in the editor) |
| Every `do`/`if` target exists | GUT test that parses all `.dialogue` files (`FR-DLG-10`) |
| Flags | Debug menu to set/clear flags; playthrough checklist per act |
| Box overflow | Test at the longest text and largest text-size setting |
| Skipped cutscenes still apply effects | GUT/integration test per cutscene with `# required` lines |

---

## 14. Dialogue in the milestones

| Milestone | Dialogue work |
|---|---|
| M0 Setup | Install Dialogue Manager, `dialogue/` folders, glossary file |
| M5 World systems | Dialogue box + portraits + choices, barks, NPC interaction, flags, `Cutscene` API basics. ✅ Built in Phase 6a; also a first Elder conversation (`elder`, a stand-in until `elder_quest_start`) |
| M6 Persistence | Flags saved/loaded; repeat-talk handling |
| M7 Dragon | Hatching cutscene, dragon naming, emote bubbles. ✅ Built in Phase 7 (emotes ♥ ! ? ♪ zzz above the dragon; the Elder mentions it by name) |
| M8 Boss | Boss intro/defeat cutscenes, prologue Ignis scenes, skip system. 🟨 8b: the prologue scenes, the Cutscene camera/actor API and skipping (fast-forward) are built; Trial shrine lines; villagers' Rank Day lines. Boss intro/defeat scenes for the Warden come with 8c |
| 🎯 Vertical slice | All scripts in §10 written, approved and playable |
| M9–M10 | Scripts for Acts 1–4 and the ending |
| M11 Polish | Real portraits, text pass, history log, translation export (if wanted) |

---

## 15. Open questions

1. ❓ Approve the 💡 **Rank Examiner** and **Rival apprentice** characters? (Names to be chosen.)
2. ✅ Default dragon name: ask the player; empty keeps **Pip** (owner decision 2026-11-04).
3. ❓ Short voice exclamations in v1, or text blips only?
4. ❓ Languages other than English?
5. ❓ History log in v1 or later?
