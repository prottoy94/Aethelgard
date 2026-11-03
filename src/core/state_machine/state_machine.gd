class_name StateMachine
extends Node
## Runs one child State at a time and forwards process, physics and input callbacks to it.
## Child State nodes are addressed by their node name, e.g. `transition_to(&"Dash")`.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var state: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		var child_state := child as State
		if child_state:
			child_state.actor = get_parent()
			child_state.machine = self
			_states[StringName(child_state.name)] = child_state
	if not get_parent().is_node_ready():
		await get_parent().ready
	state = initial_state if initial_state else _states.values()[0]
	state.enter(&"", {})


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: no state named %s" % state_name)
		return
	var previous := StringName(state.name)
	state.exit()
	state = _states[state_name]
	state.enter(previous, data)
	state_changed.emit(previous, state_name)


func is_in(state_name: StringName) -> bool:
	return state != null and StringName(state.name) == state_name


func _process(delta: float) -> void:
	if state:
		state.update(delta)


func _physics_process(delta: float) -> void:
	if state:
		state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if state:
		state.handle_input(event)
