class_name TrialData
extends Resource
## A Trial (spell shrine, GAME_DESIGN.md §11, FR-QST-03): a self-contained challenge that gives a spell tome. The Gust
## Trial (owner decision 2026-11-07): Lantern Glow reveals runes hidden in the mist, Light lights them in order, then
## a ring of wind seals the courtyard for short waves of enemies; passing puts the tome on the altar.
## Files: data/trials/*.tres.

@export var id: StringName
@export var display_name := ""          ## the shrine's place name (map, "Discovered: …")
@export var place_id: StringName        ## its Landmark id; found_<place_id> is set when Aurelia first walks in
@export var spell: SpellData            ## the tome it gives
@export var radius := 9.0               ## m: the courtyard (and the ring of wind)

@export_group("Runes")
@export var rune_count := 3
@export var rune_distance := 6.0        ## m from the altar
@export var rune_angles: PackedFloat32Array = []  ## degrees round the courtyard, in rune order (empty = even)

@export_group("Fight")
@export var waves: Array[TrialWave] = []
@export var wave_delay := 2.0           ## s between one wave falling and the next arriving
@export var spawn_distance := 5.5       ## m from the altar where enemies appear

@export_group("Story")
@export var passed_flag: StringName     ## GameState flag once passed
@export var found_music: StringName     ## MusicTrack played when the shrine is first found
@export var dialogue: DialogueResource
@export var intro_cue := ""             ## the shrine's voice on first finding it
@export var test_cue := ""              ## when the runes wake and the wind rises
@export var complete_cue := ""          ## when the Trial is passed
@export var repeat_cue := ""            ## talking to the altar later
@export var hint_cue := ""              ## Lumen's hint (dialogue/barks/lumen.dialogue)


func puzzle_id() -> StringName:
	return StringName("%s_runes" % id)


func tome_id() -> StringName:
	return StringName("%s_tome" % id)
