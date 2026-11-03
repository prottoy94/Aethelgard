class_name Puzzle
extends Node3D
## A puzzle's logic (FR-PUZ-01, FR-PUZ-06): solved once every part is on (braziers lit, plates pressed). Then it
## activates its targets (gates open, chests unlock), announces EventBus.puzzle_solved and stays solved (GameState).
## Lumen offers `hint_cue` if Aurelia lingers near it unsolved (FR-PUZ-07). Parts need is_on() and `state_changed`;
## targets need activate(instant: bool). The level calls setup() once parts and targets exist.

signal solved

@export var puzzle_id: StringName
@export var hint_cue := ""          ## a cue in dialogue/barks/lumen.dialogue
@export var hint_radius := 9.0      ## m: Aurelia counts as "at the puzzle" within this distance

var parts: Array[Node] = []
var targets: Array[Node] = []
var is_solved := false
## Goes up whenever a part changes (Lumen waits for a lack of progress before hinting).
var progress_count := 0


func _ready() -> void:
	add_to_group(&"puzzle")


func setup(parts_: Array[Node], targets_: Array[Node]) -> void:
	parts = parts_
	targets = targets_
	if GameState.get_object_state(puzzle_id).get("solved", false):
		is_solved = true
		for target in targets:
			target.activate(true)
		return
	for part in parts:
		part.state_changed.connect(_on_part_changed)
	_check()


func _on_part_changed() -> void:
	progress_count += 1
	_check()


func _check() -> void:
	if is_solved or parts.is_empty():
		return
	for part in parts:
		if not part.is_on():
			return
	is_solved = true
	GameState.set_object_state(puzzle_id, {"solved": true})
	for target in targets:
		target.activate(false)
	solved.emit()
	EventBus.puzzle_solved.emit(puzzle_id)
