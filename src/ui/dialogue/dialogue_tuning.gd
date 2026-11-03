class_name DialogueTuning
extends Resource
## Timing for conversations and barks (DIALOGUE_DESIGN.md §3.1, FR-DLG-11). File: data/dialogue/dialogue_tuning.tres.

const SPEED_NAMES: Array[String] = ["Slow", "Normal", "Fast", "Instant"]

## Seconds per typed character for each text speed (Settings.text_speed); 0 = the whole line at once.
@export var seconds_per_char: PackedFloat32Array = [0.05, 0.028, 0.012, 0.0]
@export var auto_advance_delay := 1.2       ## s after a line finishes typing (auto-advance on)
@export var auto_advance_per_char := 0.03   ## extra s per character, so long lines stay readable
@export var bark_time := 2.4                ## s a speech bubble stays, plus...
@export var bark_time_per_char := 0.04      ## ...this much per character
