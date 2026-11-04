# Aethelgard — Audio Design

> Status: **v0.1 draft (planning phase)**, written 2026-11-03.
> Part of the design set: [GAME_DESIGN.md](GAME_DESIGN.md) · [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) · [REQUIREMENTS.md](REQUIREMENTS.md) (audio = `FR-AUD-*`, `NFR-AUD-*`).
> 💡 = suggestion that needs the owner's approval · ❓ = open question.

---

## 1. Audio pillars

1. **Readable.** You can *hear* danger. Every enemy attack has a wind-up sound, and each element sounds different. Combat should be playable by ear as well as by eye.
2. **Wonder.** Exploration is calm and beautiful: soft music, rich nature ambience, sparkles near secrets.
3. **Growth you can hear** 💡. Aurelia's spells sound thin and small at the start and fuller as she masters them (see §6.3).
4. **Ember sounds wrong.** Ignis's corrupted fire is harsh, distorted and low, the opposite of Aurelia's clear, bright magic.

---

## 2. Technical specs

| Item | Rule |
|---|---|
| Short sound effects | `.wav`, 44.1 kHz, 16-bit. **Mono** for sounds placed in the world, **stereo** for UI and big stingers. |
| Music & ambience | `.ogg` (Vorbis, quality ~6), stereo, **loop points** set in the Godot import settings. |
| Loudness (starting targets) | Music mastered around **−16 LUFS**; ambience quieter (about −24 LUFS); sound effects peak ≤ **−1 dBTP**. All volumes are then balanced in the mixer, not baked into files. |
| Length | SFX normally < 2 s; telegraph sounds 0.3–1.5 s (matching the enemy's wind-up time). |
| Variations | 3–5 variants for frequent sounds (footsteps, hits, staff strike), plus random pitch and volume in the engine. |

### 2.1 Naming convention
```
sfx_{category}_{subject}_{action}_{variant}.wav   → sfx_spell_frost_shard_impact_02.wav
mus_{region|context}_{state}.ogg                  → mus_elderroot_explore.ogg, mus_boss_ignis_phase2.ogg
amb_{region}_{time|weather}.ogg                   → amb_azure_coast_day.ogg, amb_weather_rain.ogg
stg_{event}.ogg                                   → stg_rank_up.ogg, stg_spell_learned.ogg
```
Categories: `player`, `spell`, `combat`, `enemy`, `boss`, `dragon`, `world`, `puzzle`, `ui`.

### 2.2 Folders
```
res://assets/audio/
├─ sfx/{player,spells,combat,enemies,bosses,dragon,world,puzzles,ui}/
├─ music/{regions,combat,bosses,themes,stingers}/
├─ ambience/{regions,weather}/
├─ placeholders/              # generated sounds; same file names as the final ones
└─ sound_events/              # SoundEvent .tres files (see §4.2)
res://tools/audio/            # placeholder generator script (folder has a .gdignore so Godot skips it)
```

---

## 3. Mixer (audio bus layout)

```
Master  (limiter)
├─ Music        (ducks under Dialogue; low-pass when paused)
├─ Ambience     (low-pass when paused)
├─ SFX          (reverb effect; settings change per region: open field / cave / great hall / storm)
│  ├─ Player
│  ├─ Enemies
│  ├─ Dragon
│  └─ World
├─ UI           (never ducked or paused)
└─ Dialogue     (reserved for voice/text blips; ducks Music)
```
> Built in Phase 1 as `res://default_bus_layout.tres` by `tools/setup/configure_project.gd`. A Godot bus has only one send target,
> so the reverb is an effect on the SFX bus rather than a separate send bus. The pause low-pass filters exist but start disabled.

- **Settings menu sliders:** Master, Music, SFX, Ambience, UI (and Dialogue later).
- **Ducking:** music dips a few dB during dialogue, boss roars and big stingers.
- **Pause:** Music and Ambience get a low-pass filter (muffled); UI stays clear.
- **Region reverb:** each region sets its reverb when loaded (Ruined Valley halls = long reverb, open meadow = short).

---

## 4. How it works in Godot

### 4.1 `AudioManager` (autoload)
```gdscript
AudioManager.play_sfx(&"spell_frost_shard_cast")                # non-positional sound
AudioManager.play_sfx_at(&"enemy_brine_crab_hurt", global_pos)  # sound placed in the world
AudioManager.play_music(&"mus_elderroot", fade := 1.5)
AudioManager.set_music_state(&"combat")                         # explore ↔ combat ↔ boss phases
AudioManager.play_ambience(&"amb_elderroot", TimeOfDay.period)
AudioManager.play_stinger(&"stg_rank_up")
```
- Game code **never references audio files directly**. It plays **sound event IDs**, so files can be swapped at any time.
- A **voice pool** reuses `AudioStreamPlayer3D` nodes and caps how many copies of one sound can play at once (e.g. max 4 hit sounds), so big fights don't turn into noise.
- Positional sounds use `AudioStreamPlayer3D` (3D game) with a max distance of about 25–30 m and the listener on the camera rig.

> **Built in Phase 6c** (`src/autoload/audio_manager.gd`, `src/audio/`): `play(id, position?)` with pooled 2D/3D
> players (12/24), polyphony and interval limits, random pitch/volume; `play_music` / `set_combat_layer` /
> `set_combat(engaged)` / `play_ambience` / `play_weather` on `MusicChannel`s that loop at a track's loop points with a
> crossfade (no file trimming needed); `play_stinger` and `duck(reason, db)`; low-pass on Music/Ambience while paused.
> Ids follow names where possible: `spell_<id>_cast`, `enemy_<id>_<alert|telegraph|attack|hurt|death>`,
> `combat_hit_<element>`, `combat_status_<id>`, `player_footstep_<surface>` (floor meta `surface`).
> Each region's music and ambience are set in `data/world/regions.tres`. Tuning: `data/audio/audio_tuning.tres`.
> `SoundEvent` stores file **paths** (a missing file silences one sound instead of breaking loading).

### 4.2 `SoundEvent` resource
```gdscript
class_name SoundEvent
extends Resource

@export var id: StringName
@export var streams: Array[AudioStream]       # variants; one is picked at random
@export var bus: StringName = &"SFX"
@export var volume_db: float = 0.0
@export var pitch_range: Vector2 = Vector2(0.95, 1.05)
@export var max_polyphony: int = 4
@export var min_interval: float = 0.03        # ignore re-triggers faster than this
@export var positional: bool = true
```
Engine features we use: `AudioStreamRandomizer` (variants, pitch and volume randomisation) and, for music,
**`AudioStreamInteractive`** (switching between explore, combat and boss clips with timed transitions) and
**`AudioStreamSynchronized`** (layered stems that fade in and out), both available since Godot 4.3.

### 4.3 What triggers sound
- **Animations** trigger footsteps, staff swings and wind-ups through method tracks in the AnimationPlayer, so timing always matches the art.
- **Components** trigger hits and deaths: `HealthComponent.damaged` → hit sound for the element; `died` → death sound.
- **Spells** trigger cast, travel-loop and impact sounds, with the IDs stored in `SpellData`.
- **The `EventBus`** triggers stingers: `spell_learned`, `rank_changed`, `quest_completed`, `dragon_hatched`, `secret_found`.
- **Footsteps change with the surface**: a downward ray reads `surface` metadata from the ground material/collider (grass, stone, wood, water, sand, ice).

---

## 5. Music

### 5.1 Themes (leitmotifs)
Short melodies that come back throughout the game in different arrangements:

| Theme | Feel | Instruments (suggested) |
|---|---|---|
| **Aurelia's theme** | Hopeful, small, curious; grows bigger as the story goes on. **Melody = the chorus of the owner's song *Sunlight on Ancient Stone*** ("Sunlight falls so bright…", see §10) | Solo flute + harp at first; full strings and choir in the finale |
| **World Tree theme** | Ancient, warm, sacred | Strings, soft choir, celesta |
| **Ignis Varos's theme** | Heavy, threatening, burning | Low brass, taiko drums, distorted low choir, crackling textures |
| **Dragon theme** | Playful as a hatchling → noble as an adult | Piccolo/ocarina → French horns |
| **Sky Rift / Unknown One** | Wrong, alien, unsettling | Reversed sounds, detuned pads, silence |

### 5.2 Music list

| Track | Where | States / stems | Priority |
|---|---|---|---|
| `mus_title` | Title screen | ✅ **Have it:** *Sunlight on Ancient Stone* (full vocal song, §10) | MVP |
| `mus_prologue_attack` | Prologue village attack | Single tense loop | MVP |
| `mus_elderroot` | Elderroot Meadow | Explore (day), Explore (night: fewer instruments), Combat layer | MVP |
| `mus_azure_coast` | Azure Coast | Explore (✅ **have it:** *Tides of the Morning Shore*, §10), Combat (needed) | V1 |
| `mus_ruined_valley` | Ruined Valley | Explore (mysterious, night-focused), Combat | V1 |
| `mus_stormspire` | Stormspire Highlands | Explore (tense, storm), Combat | V1 |
| `mus_floating_isle` | Floating Isle | Explore (ethereal), Combat | V1 |
| `mus_rest_point` | Lantern Shrines | Short calm loop | MVP |
| `mus_workshop` | World Tree workbench / hub | Cozy loop | V1 |
| `mus_boss_generic` | Region bosses | Intro, Phase 1, Phase 2 (more intense), Victory | MVP |
| `mus_boss_ignis` | Ignis encounters + final | Intro, Phase 1, 2, 3 (choir), Defeat | MVP (prologue) / V1 |
| `mus_ending` | Ending + credits | ✅ **Have it:** *Sunlight on Ancient Stone* for the credits (its outro "Now I say goodnight" fits), after a Rift theme sting | V1 |

### 5.3 Adaptive music rules
- **Explore → Combat:** when an enemy notices the player, the combat layer fades in over ~1 s (or switches on the next beat).
  Combat → Explore happens ~4 s after the last enemy is defeated or lost.
- **Day → Night:** the region track crossfades to its night version at dusk.
- **Boss phases:** each new phase changes to a more intense section at the next musical bar.
- **Stingers** (short musical moments, 1–4 s): `stg_spell_learned`, `stg_rank_up`, `stg_quest_complete`, `stg_secret_found`,
  `stg_item_crafted`, `stg_dragon_hatched`, `stg_boss_defeated`, `stg_defeat`. Music ducks underneath them.

---

## 6. Sound effects

### 6.1 Element sound families
Every spell, impact and puzzle reaction of an element uses that element's sound palette:

| Element | Sound palette | Example layers |
|---|---|---|
| ✨ Light | Bright, clean, shimmering | Glass bells, chimes, soft choir "ah", sparkle tail |
| 🌪 Wind | Airy, fast | Whooshes, filtered noise sweeps, flapping cloth |
| ❄ Frost | Crisp, crystalline | Ice cracks, tinkling shards, cold hiss |
| 🪨 Earth | Heavy, low | Rock grinding, deep thuds, gravel debris |
| 🔥 Fire (pure) | Warm, powerful | Clean roar, crackle, whoomp |
| 🟥 Ember (enemy) | Harsh, corrupted | Distorted crackle, low drone, metallic screech |

### 6.2 Telegraph sounds (most important for combat)
- Every enemy attack gets a **wind-up sound** that starts with the visual telegraph and lasts as long as it. Rising pitch = attack incoming.
- Each attack type has its own recognisable sound: slash wind-up ≠ projectile charge ≠ ground slam.
- Boss telegraphs are louder and longer. **Off-screen attacks** always have a telegraph sound so the player can react.

### 6.3 💡 Spells grow with mastery
- **Mastery I:** a thin, short sound.
- **Mastery III:** adds body (lower layer).
- **Mastery V:** adds a sparkle tail and sub-bass.

Implementation: each spell's `SoundEvent` holds layered streams, and mastery level controls how many layers play.

### 6.4 Full sound list

**Player (Aurelia)**: MVP unless marked
| ID | Notes |
|---|---|
| `player_footstep_{grass,stone,wood,water,sand,ice}` | 4 variants each; sand/ice V1 |
| `player_dash` | Cloth whoosh + light shimmer |
| `player_staff_swing` / `player_staff_hit` | 3 variants each |
| `player_hurt` | Short grunt-free impact + cloth (no voice in v1 ❓) |
| `player_defeated` | Soft collapse + fading chime |
| `player_cast_fail` | Dull "fizzle" when stamina is too low |
| `player_exhausted` | Breathy low pulse while Exhausted |
| `player_stamina_ready` | Quiet chime when stamina passes the Exhausted threshold |
| `player_heal` | Warm rising chime |
| `player_lantern_on/off` | Small glass clink + glow hum |

**Spells**: each spell has `_cast`, optional `_loop` (travel/channel), `_impact`
| Spell | Priority |
|---|---|
| Light Mote, Lantern Glow, Gust, Mending Bloom | MVP |
| Frost Shard, Tide Ward, Glacial Path, Stone Spire, Root Bind, Radiant Burst, Gale Step, Storm Lance, Earthen Guard, Prism Ray, Dawnflame, Starfall | V1 |

**Combat (general)**
| ID | Notes | Priority |
|---|---|---|
| `combat_hit_{element}` | Impact per element | MVP (Light, Wind, Ember) |
| `combat_crit` | Extra punchy layer | MVP |
| `combat_weak_hit` / `combat_resisted` | Bright "ding" for weakness, dull "thunk" for resisted | MVP |
| `combat_shield_hit` / `combat_shield_break` | Elemental shields | V1 |
| `combat_status_{burn,chill,freeze,stagger,root,daze,ember_mark}` | When applied | MVP (burn, chill, stagger) |
| `combat_loot_drop` / `combat_loot_pickup` | Small sparkle | MVP |

**Enemies**: each type: `_idle` (optional), `_alert`, `_telegraph_{attack}`, `_attack_{attack}`, `_hurt`, `_death`
| Enemies | Priority |
|---|---|
| Ember Wisp, Thornling, Emberbound Scout | MVP |
| Brine Crab, Tide Caster, Corrupted Gull, Stone Sentinel, Lantern Ghost, Ivy Stalker, Storm Hound, Emberbound Mage, Spark Golem, Elite Knight, Rift Shade | V1 |

**Bosses**: each: `_intro_roar`, `_telegraph_*` per move, `_attack_*`, `_phase_change`, `_hurt`, `_defeat`
| Boss | Priority |
|---|---|
| Cinder Warden, Ignis (prologue scene) | MVP |
| Brinecoil, Hollow King, Vharka, Ignis (final) | V1 |

**Dragon**
| ID | Notes | Priority |
|---|---|---|
| `dragon_egg_pulse` / `dragon_egg_crack` / `dragon_hatch` | The hatching moment, a big emotional beat | MVP |
| `dragon_chirp_{hatchling,juvenile,adult}` | Voice gets deeper with each stage | MVP (hatchling) / V1 |
| `dragon_wings` | Flaps; louder for adults | V1 |
| `dragon_breath_{frost,wind,earth,light}` | Per element choice | V1 |
| `dragon_command_ack` | Short call when given a command | V1 |
| `dragon_happy` / `dragon_eat` / `dragon_ko` | Bond and feeding | V1 |
| `dragon_bite` / `dragon_hurt` / `dragon_return` | Its bite, being hit, reappearing beside Aurelia (added in Phase 7) | V1 |

Phase 7 placeholders (generated): every row above except `dragon_wings` and the juvenile/adult chirps, plus
`combat_hit_frost` (the dragon is the first Frost attacker) and the stinger `stg_dragon_hatched`, on the **Dragon** bus.
Stingers now play one at a time: one that comes while another plays is skipped (hatching also finishes a quest).

**World & puzzles**
| ID | Priority |
|---|---|
| `world_chest_open`, `world_door_open`, `world_gather_{herb,ore,wood,crystal}`, `world_rest_point_activate`, `world_region_transition` | MVP |
| `puzzle_brazier_ignite`, `puzzle_block_push`, `puzzle_plate_press`, `puzzle_hidden_reveal`, `puzzle_solved` | MVP |
| `puzzle_water_freeze`, `puzzle_ice_melt`, `puzzle_fan_spin`, `puzzle_pillar_rise`, `puzzle_rune_activate`, `puzzle_rune_wrong`, `puzzle_mirror_turn`, `world_arcane_seal_open`, `world_fast_travel` | V1 |
| `world_secret_shimmer` (positional hum near secrets; Lumen) | V1 |

**UI**
| ID | Priority |
|---|---|
| `ui_hover`, `ui_confirm`, `ui_cancel`, `ui_error`, `ui_menu_open`, `ui_menu_close`, `ui_tab`, `ui_dialogue_blip`, `ui_quest_update` | MVP |
| `ui_equip`, `ui_craft_success`, `ui_page_turn` (journal/Grimoire), `ui_save` | MVP |
| `ui_upgrade`, `ui_map_open` | V1 |

### 6.5 Ambience

| Region | Day | Night | Weather |
|---|---|---|---|
| Elderroot Meadow | Birds, breeze in grass, leaves, distant stream | Crickets, firefly shimmer, owl | Light rain |
| Azure Coast | Waves, gulls, waterfall (positional) | Gentle waves, wind | Sea breeze |
| Ruined Valley | Wind through arches, distant bells | Fireflies, ghostly whispers, crickets | Fog (muffled) |
| Stormspire Highlands | Heavy rain, wind howl, thunder | Same, darker | Storm (always) |
| Floating Isle | High-altitude wind, wind chimes, soft hum | Starry hum, chimes | Golden mist |

Positional ambience sources: waterfalls, streams, braziers, the World Tree (warm low hum), the Sky Rift (unsettling drone).

### Sound count estimate
| | MVP (vertical slice) | V1 |
|---|---|---|
| Sound events | ~90 | ~300 |
| Music tracks (incl. states) | ~8 | ~30 |
| Ambience loops | ~4 | ~14 |

---

## 7. Making the sounds

### 7.1 Phase 1: placeholders (from M0 to the vertical slice)
> **Built in Phase 6c:** `tools/audio/generate_placeholders.py` (numpy only, fixed seed) makes 70 sound events
> (95 WAV files: player, spells, combat hits and statuses, both enemies, world, puzzles, UI, 6 stingers in F# major),
> ambience loops (Elderroot day, night, rain) and a drum combat layer at 76 BPM, writes their SoundEvent/MusicTrack
> `.tres` files and both libraries. Audio is git-ignored: run it after a clone, plus `tools/audio/import_owner_music.py`
> to copy the owner's music into `assets/audio/music/owner/`.
- **Code-generated SFX:** a Python script in `tools/audio/` (numpy + the standard `wave` module) builds sounds from simple recipes:
  - *whoosh* = noise through a moving filter with a fade in/out
  - *chime* = sine partials with a fast decay (Light)
  - *impact* = short noise burst + a falling low tone
  - *crack* = clicks + a high noise burst (Frost)
  - *rumble* = low filtered noise (Earth)
  - *crackle* = random pops (Fire/Ember)
  - *UI click* = short filtered blip
  It outputs files with the **final names** into `assets/audio/placeholders/`, so swapping later means changing only the `SoundEvent` streams.
- **jsfxr / Bfxr / ChipTone** for quick extra effects (retro sounding, fine for placeholders).
- **Placeholder music:** CC0 tracks from OpenGameArt, or simple loops, just to test the adaptive music system.

### 7.2 Phase 2: final audio (M11 polish, or earlier for key moments)
| Source | Good for | Licence note |
|---|---|---|
| **Kenney.nl** audio packs | UI, simple effects | CC0 (no credit needed, credit anyway) |
| **Freesound.org** | Nature ambience, foley, magic layers | Per file: CC0 or CC-BY OK; **avoid CC-BY-NC** if the game might be sold |
| **Sonniss GDC Game Audio Bundle** | Large pro effects library | Royalty-free for commercial use; check the bundle's licence file |
| **OpenGameArt.org** | Music and effects | Mixed licences; check every file |
| **AI tools** (e.g. Suno, Udio, Stable Audio, ElevenLabs SFX) | Region themes, special effects | **Read current terms for commercial use and ownership** before using anything in a release |
| **Commission a composer / sound designer** | Unique soundtrack and signature sounds | Best quality; costs money |

- Final sounds are usually **layered and edited** (e.g. a library ice crack + a chime + a whoosh = Frost Shard). A free editor like **Audacity** is enough. Godot can also stack layers inside one `SoundEvent`.
- Music: Aurelia's theme, the Ignis theme and the boss music matter most, so spend budget/effort there first. ❓ The owner chooses the music.

### 7.3 Licence rules
- Every shipped sound or music file gets a line in **`CREDITS.md`**: file, source URL, author, licence.
- **Never** take audio from other games, anime or films, even as a placeholder in shared builds.
- Prefer CC0; CC-BY is fine with credit; no NC (non-commercial) or ND (no-edits) files unless we're sure the game stays free and unedited.

---

## 8. Accessibility

- Separate volume sliders per bus (§3).
- **Visual sound cues option** 💡: an on-screen arrow for important off-screen sounds (telegraphs, enemies behind the player).
- Subtitles/captions for story moments; text blips can be turned off.
- Nothing depends on sound alone: every telegraph is also visual, and every element also has an icon.
- **Mono audio** option for players with one-sided hearing.

---

## 9. Audio in the milestones

| Milestone | Audio work |
|---|---|
| M0 Setup | Bus layout, `AudioManager` + `SoundEvent` stubs, placeholder generator script |
| M1 Walk the world | Surface footsteps, Elderroot ambience (placeholder) |
| M2 Combat core | Staff, hit, hurt, death, cast-fail, Exhausted sounds; 2 spells; enemy telegraphs |
| M3 Magic | Element sound families, status sounds, rank-up and spell-learned stingers |
| M4 Items | UI sounds, gather, craft, equip, loot |
| M5 World systems | Dialogue blips, puzzle sounds, quest stingers |
| M6 Atmosphere | Day/night ambience swap, weather, region reverb, adaptive explore/combat music |
| M7 Dragon | Egg, hatch, hatchling chirps. ✅ Placeholders in Phase 7 (16 dragon sounds + hatching stinger) |
| M8 Boss | Boss music with phases, Cinder Warden and Ignis-prologue sounds. 🟨 8a: Cinder Warden and Emberbound Scout placeholders (a wind-up sound per move, as long as its warning; hit, alert, hurt, death), `world_fire_wall`, `stg_boss_defeated`; boss music = *The Last Ascent* (`mus_boss_ascent`) |
| 🎯 Vertical slice | Complete placeholder audio + first pass of real Aurelia's theme 💡 |
| M11 Polish | Final sounds and music swapped in, full mix pass, `CREDITS.md` complete |

**Audio test checklist (each milestone):** no missing-sound errors in the log · telegraphs audible over music · big fights don't clip (check the Master bus) · loops don't click at the loop point · volume sliders work.

---

## 10. Owner-provided tracks (`Audio_music/`)

Analysed 2026-11-03 with librosa (tempo, key, loudness, structure) and automatic speech recognition (faster-whisper) for the lyrics.
Times are approximate (±1 s). Lyrics come from automatic transcription, so some words may be wrong and verse 1 was unclear.

### 10.1 What the files are

| | *Sunlight on Ancient Stone* | *Tides of the Morning Shore* |
|---|---|---|
| Type | **Song with vocals**: the protagonist's (Aurelia's) singing voice | **Instrumental** (no vocals found) |
| Length | 3:02 | 2:41 |
| Tempo / key (estimated) | ~80 BPM, **F# major** | ~76 BPM, **B major** |
| Feel | Bright, gentle, hopeful | Warmer and softer (less bright), calm |
| Format | MP3 192 kbps, 44.1 kHz, stereo | MP3 192 kbps, 44.1 kHz, stereo |
| Loudness | Peak ~0 dBFS, average RMS −15 dBFS | Peak ~0 dBFS, average RMS −15.5 dBFS |
| Ending | Song ending + fade ("Now I say goodnight") | Fades out (2:20–2:41) |
| Origin | Embedded content credentials: **"Created by Google Generative AI"**, with an imperceptible **SynthID** watermark | Same |

### 10.2 *Sunlight on Ancient Stone*: structure & lyrics

| Time | Section | Lyrics (auto-transcribed) |
|---|---|---|
| 0:00–0:12 | Intro | *(instrumental)* |
| 0:12–0:35 | Verse 1 | *(unclear; ends with something like "…in this green world I will trust")* |
| 0:35–0:58 | **Chorus** | "Sunlight falls so bright / Holding all the light / Wonders never really end / With nature as my friend" |
| 1:01–1:23 | Verse 2 | "Moss grows on forgotten stone / I read what the ages say / Never feeling truly alone / Learning from yesterday" |
| 1:24–1:46 | Chorus | (as above) |
| 1:47–2:12 | **Instrumental break** (~25 s, no vocals) | — |
| 2:12–2:23 | Bridge | "Whispers in the quiet air / I will find the answers there" |
| 2:23–2:46 | Final chorus | (as above, last line "All I need is nature as my friend") |
| 2:48–3:00 | Outro | "Fading in the evening light / Now I say goodnight" (then fade) |

**The lyrics describe Aurelia:**
- "I read what the ages say" → the bookish elf reading her spellbook (`pose_1` art)
- "Moss grows on forgotten stone" → the overgrown ruins of Aethelgard
- "Holding all the light" → her **Light** affinity and lantern
- "Never feeling truly alone" → Lumen and, later, her dragon
- "Learning from yesterday" → learning spells and lore from the old kingdom

### 10.3 *Tides of the Morning Shore*: structure

| Time | Section | Notes |
|---|---|---|
| 0:00–0:09 | Intro | Can play once when entering the region |
| 0:09–0:38 | Section A | Full arrangement |
| 0:38–1:03 | Section B | |
| 1:03–1:28 | Quiet breakdown | Sparser and quieter: a candidate for a night/calm version |
| 1:28–2:20 | Section A' | Builds back up |
| 2:20–2:41 | Outro | Fade-out: cut this for the in-game loop |

**Best loop found:** loop **from ~2:20.9 back to ~0:08.8** (132 s loop body, 0.98 similarity score on beat-aligned features). It still needs checking by ear in Godot.

### 10.4 How we use them

| Use | Track & part | Why | Priority |
|---|---|---|---|
| **Title screen** (`mus_title`) | *Sunlight*: full song | The lyrics introduce Aurelia before the game starts; the first thing players hear is her voice | MVP |
| **Prologue opening** | *Sunlight*: intro + verse 1, under the `prologue_morning` scene (Aurelia wakes and reads) | Sets the peaceful mood before the Emberbound attack shatters it | MVP |
| **Ending credits** (`mus_ending`) | *Sunlight*: full song | "Fading in the evening light / Now I say goodnight" closes the story | V1 |
| **Aurelia's leitmotif** | *Sunlight*: chorus melody | Quote it in other tracks and stingers: spell learned, rank up, rest point music box, finale | MVP (stingers) / V1 |
| **Rest point / menu background** 💡 | *Sunlight*: instrumental break 1:47–2:12 | Vocal-free, calm, already in her theme. Needs a loop check | V1 |
| **Azure Coast exploration (day)** (`mus_azure_coast`) | *Tides*: loop 0:08.8 → 2:20.9 | The title and calm feel match the turquoise bay region | V1 |
| **Azure Coast night/calm** 💡 | *Tides*: breakdown 1:03–1:28 | Quieter section → night layer or a resting spot by the sea | V1 |
| **Aurelia's voice reference** | *Sunlight* vocal | Defines how Aurelia sounds. Use it as the reference if we add voice lines or short exclamations later (DIALOGUE_DESIGN.md §12) | V1/Stretch |
| **Aurelia sings in the story** 💡 | *Sunlight*: short hummed or sung phrases | e.g. she hums the chorus at a rest point or campfire scene and Lumen reacts; the song returns at an emotional moment in Act 4. Needs a separated vocal (§10.5) | V1 (optional) |

**Don't use the vocal song as looping exploration music.** Vocals get repetitive over many minutes and compete with dialogue text.
For **Elderroot Meadow** exploration (the title "ancient stone" fits it perfectly) we want an **instrumental version of *Sunlight***. See §10.5.

### 10.5 What's still needed to use them in-game

1. **Instrumental version of *Sunlight*** for Elderroot Meadow exploration: ❓ still needed. *Until then the owner's
   instrumental Where the Forest Remembers (same key) plays in Elderroot (Phase 6c, owner to confirm).*
   A stem-separated version was made and then **removed by the owner** (§10.6). Best option: a newly generated instrumental from the same Google tool,
   with an instrument (e.g. flute) playing the vocal melody, in F# major at ~80 BPM.
2. **Matching combat tracks:** combat layers for Elderroot (F# major, ~80 BPM) and Azure Coast (B major, ~76 BPM) in the same key and tempo, so the explore ↔ combat switch (§5.3) is smooth.
3. **Game-ready files:**
   - Use **WAV downloads** from the tool as masters if available (better than re-encoding MP3s). Keep them in `audio_source/` (with a `.gdignore`).
   - Export **OGG** per §2. MP3 has a few milliseconds of encoder padding that can cause a gap at the loop point.
   - Godot loops OGG/MP3 at the **end of the file** and restarts at `loop_offset`, so the loop file is **trimmed at the loop end** (Tides: cut at ~2:20.9, `loop_offset` ≈ 8.8 s).
   - Set the `bpm`, `beat_count` and `bar_beats` import properties so interactive music can switch on the beat.
   - File names: `mus_title.ogg`, `mus_ending_credits.ogg`, `mus_azure_coast_explore.ogg`, `mus_rest_point.ogg`.
   - Normalise both tracks to the same loudness (§2); they're currently close (−15 dBFS RMS).
4. **Licence check (owner):** both files were made with a Google generative AI tool. Confirm which tool it was and that its current terms allow use in a game you might release or sell.
   Record the tool, date and prompt in `CREDITS.md`. Keep the content credentials and watermark intact; they mark the audio as AI-generated, which is honest and expected.

### 10.6 Stem-separation attempt (removed)

On 2026-11-03 an instrumental and a vocal stem of *Sunlight* were made with Demucs (open-source source separation).
The owner **removed those files**, so they are not part of the project. Useful findings that still apply:
- The song separates cleanly (no lyrics detected in the instrumental), so separation is a fallback if ever needed again.
- A good loop for an instrumental of *Sunlight* runs **from ~2:27.5 back to ~0:39.5** (108 s = 36 bars at 80 BPM), skipping intro and outro.
  A newly generated instrumental with the same structure may loop at similar points.

### 10.7 New owner tracks (added 2026-11-03, analysed 2026-11-04)

Analysed with `tools/audio/analyze_track.py` (librosa for tempo, key, loudness, sections and loops; faster-whisper for
words). Tempos marked "~76" were measured as 152 (double time); by feel they sit with *Tides* (76 BPM).

| Track | Length | Tempo / key | Vocals | Feel & sections | Best loop | Suggested use |
|---|---|---|---|---|---|---|
| *Where the Forest Remembers* | 3:03 | ~76, **F# major** | none | The darkest, warmest of all; builds from 0:28, quiet middle 1:41.6–2:18.5, fade from 2:49 | 0:35.9 → 2:48.2 | **Elderroot Meadow by day**; its quiet middle looped **by night**. Same key as *Sunlight*, so Aurelia's theme fits over it |
| *Edge of the Blue* | 2:59 | ~76, **F# major** | none | Bright and open; dips at 1:03–1:28, fade from 2:44 | 0:20.7 → 2:49.2 | **Elderroot Village by day** for now; later the Floating Isle or the Azure Coast cliffs |
| *The Last Ascent* | 3:04 | fast (~86), **C# minor** | none | Builds slowly (full from 0:44), a sudden quiet at 1:36–1:52, then the climax | 1:08.5 → 2:26.8 | **First boss (Cinder Warden)** or the Stormspire climb. C# is the fifth of F#, so it sits well next to Aurelia's music |
| *The World Holds Its Breath* | 1:53 | 80, **F# major** | **spoken lines** (0:03–0:23) | Quiet intro with speech: "the runes are faint, but look at the way they catch the light… a breeze that could clear the fog… you are there", then music | (not looped) | A **story moment**, e.g. finding the Gust trial (a breeze that clears the fog) |

All four are at the same loudness (RMS −14.3 dBFS, peaks ~0 dBFS) and carry the Google content credentials.
In game (Phase 6c) the first two play where suggested; the owner confirms or changes this in the MusicTrack files
(`data/audio/music/*.tres`) and `data/world/regions.tres`.

| File | Likely use (guess from the title only) |
|---|---|
| `Where_the_Forest_Remembers.mp3` | Forest/ruins exploration, maybe Elderroot or the Ruined Valley |
| `Edge_Of_The_Blue.mp3` | Azure Coast or Floating Isle |
| `The_Last_Ascent.mp3` | Stormspire Highlands or the climb to the final battle |
| `The_World_Holds_Its_Breath.mp3` | A tense or emotional story moment (e.g. Ignis's arrival, the Sky Rift) |

These get the same analysis as §10.1–10.3 (tempo, key, vocals, structure, loop points) when audio work starts (BUILD_PLAN.md, Phase 6), or earlier if the owner asks.
