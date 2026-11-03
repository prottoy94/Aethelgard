extends Node
## Story flags and persistent world state (opened chests, solved puzzles, defeated bosses),
## keyed by IDs. Saved and loaded by SaveManager through to_dict() / from_dict().

signal flag_changed(flag: StringName, value: bool)

var _flags: Dictionary[StringName, bool] = {}
## persist_id -> small state dictionary owned by that object (e.g. {"opened": true}).
var _objects: Dictionary[StringName, Dictionary] = {}


func set_flag(flag: StringName, value: bool = true) -> void:
	if value:
		_flags[flag] = true
	else:
		_flags.erase(flag)
	flag_changed.emit(flag, value)


func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


func clear_flag(flag: StringName) -> void:
	set_flag(flag, false)


func set_object_state(persist_id: StringName, state: Dictionary) -> void:
	_objects[persist_id] = state.duplicate(true)


func get_object_state(persist_id: StringName) -> Dictionary:
	return _objects.get(persist_id, {}).duplicate(true)


func reset() -> void:
	_flags.clear()
	_objects.clear()


func to_dict() -> Dictionary:
	var flags: Array[String] = []
	for flag: StringName in _flags:
		flags.append(String(flag))
	flags.sort()
	var objects := {}
	for id: StringName in _objects:
		objects[String(id)] = _objects[id].duplicate(true)
	return {"flags": flags, "objects": objects}


func from_dict(data: Dictionary) -> void:
	reset()
	for flag: Variant in data.get("flags", []):
		_flags[StringName(str(flag))] = true
	var objects: Dictionary = data.get("objects", {})
	for id: Variant in objects:
		_objects[StringName(str(id))] = (objects[id] as Dictionary).duplicate(true)
