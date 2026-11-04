class_name RegionData
extends Resource
## One playable region (or area of a region): its id, name and scene (TECHNICAL_DESIGN.md §4.7).

@export var id: StringName
@export var display_name: String
@export_file("*.tscn") var scene_path: String

@export_group("Sound (MusicTrack ids)")
@export var music_day: StringName
@export var music_night: StringName       ## empty = the day music all the time
@export var combat_layer: StringName      ## fades in while enemies are engaged (FR-AUD-07)
@export var ambience_day: StringName
@export var ambience_night: StringName
