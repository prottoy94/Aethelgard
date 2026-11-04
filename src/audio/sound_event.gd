class_name SoundEvent
extends Resource
## One sound the game can play by id (AUDIO_DESIGN.md §4.2, FR-AUD-01): its variant files, mixer bus, loudness,
## random pitch/volume and how many copies may play at once (FR-AUD-05). Files are listed by path, so a missing file
## only silences this sound instead of breaking loading; swapping a path swaps the sound with no code change.
## Files: assets/audio/sound_events/*.tres (written by tools/audio/generate_placeholders.py for placeholders).

@export var id: StringName
@export_file("*.wav", "*.ogg", "*.mp3") var files: PackedStringArray = []  ## variants; one is picked at random
@export var bus: StringName = &"SFX"
@export var volume_db := 0.0
@export var volume_jitter_db := 1.5     ## ± random volume per play
@export var pitch_range := Vector2(0.95, 1.05)
@export var max_polyphony := 4          ## copies playing at once; the oldest stops for a new one
@export var min_interval := 0.03        ## s; faster re-triggers are ignored
@export var positional := true          ## placed in the world when played with a position
@export var max_distance := 28.0        ## m, positional sounds
