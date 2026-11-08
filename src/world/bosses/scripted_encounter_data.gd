class_name ScriptedEncounterData
extends Resource
## A fight that ends by the story, not by winning (TECHNICAL_DESIGN.md §4.12, FR-BOS-04): the prologue Ignis. The boss
## can't be hurt; the fight ends after `duration` seconds or as soon as Aurelia's health falls to `end_health_ratio`,
## and she can't fall while it runs. Files: data/encounters/*.tres.

@export var id: StringName
@export var boss_scene: PackedScene
@export var actor_id: StringName              ## the boss's id in cutscenes ("ignis")
@export var duration := 35.0                  ## s: the fight ends after this long…
@export_range(0.0, 1.0) var end_health_ratio := 0.35  ## …or when Aurelia's health is this low
@export var player_minimum_health := 1.0      ## her health never drops below this during the fight
@export var safe_time := 3.0                  ## s she can't be hit once it ends (bolts still in the air)
@export var music: StringName                 ## MusicTrack while fighting (empty: the boss's own)
@export var done_flag: StringName             ## GameState flag set when it ends
