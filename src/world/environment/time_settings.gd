class_name TimeSettings
extends Resource
## The game clock and weather rules (GAME_DESIGN.md §12, FR-WLD-06/07). File: data/world/time_settings.tres.

@export var real_seconds_per_day := 1200.0   ## ~20 real minutes per game day
@export var start_hour := 15.0               ## a new game starts in the golden afternoon
@export var night_start_hour := 20.5
@export var night_end_hour := 5.5
@export var weather_change_hours := 3.0      ## a new weather roll this often (game hours)
## Weather ids and their chances on each roll (should add up to 1).
@export var weather_ids: Array[StringName] = [&"clear", &"rain", &"fog"]
@export var weather_chances: PackedFloat32Array = [0.65, 0.2, 0.15]


## Game minutes that pass per real second.
func minutes_per_second() -> float:
	return 1440.0 / real_seconds_per_day
