class_name State
extends Node
## One state of a StateMachine (TECHNICAL_DESIGN.md §4.3). Override only the hooks you need.
## `actor` is the node that owns the state machine (for example the Player).

var actor: Node
var machine: StateMachine


func enter(_previous: StringName, _data: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
