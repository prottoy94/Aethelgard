extends Node
## Moves between regions (TECHNICAL_DESIGN.md §4.7): fades to black, swaps the region scene, lets the new region place
## Aurelia (at a spawn point, or where a save says), fades back in and autosaves (FR-SAV-02). Also returns to the
## title screen. Regions are listed in data/world/regions.tres.

signal region_changed(region_id: StringName)

const REGIONS: RegionLibrary = preload("res://data/world/regions.tres")
const TITLE_SCENE := "res://src/ui/title/title_screen.tscn"
const FADE_TIME := 0.35

var current_region: StringName = &""
var is_changing := false
var autosave_on_arrival := true
## Tests set this: regions are then loaded as children of it instead of replacing the whole scene.
var scene_parent: Node
var _arrival := {}
var _child_scene: Node


## Goes to `region_id`. Aurelia appears at the RegionSpawn `spawn_id`, or (with an empty spawn) where `player_state`
## says (a loaded save). `player_state` also carries her health and stamina through exits. Await it to know when done.
func change_region(region_id: StringName, spawn_id: StringName = &"", player_state: Dictionary = {}) -> bool:
	var region := REGIONS.find(region_id)
	if region == null:
		push_error("Unknown region: %s" % region_id)
		return false
	if is_changing:
		return false
	is_changing = true
	_arrival = {"spawn": spawn_id, "player": player_state}
	AudioManager.play(&"world_region_transition")
	await Cutscene.fade_out(FADE_TIME)
	get_tree().paused = false
	TimeOfDay.running = false
	current_region = region_id
	await _swap_scene(load(region.scene_path))
	region_changed.emit(region_id)
	EventBus.region_changed.emit(region_id)
	await Cutscene.fade_in(FADE_TIME)
	is_changing = false
	if autosave_on_arrival:
		SaveManager.autosave()
	return true


func go_to_title() -> void:
	if is_changing:
		return
	is_changing = true
	await Cutscene.fade_out(FADE_TIME)
	get_tree().paused = false
	TimeOfDay.running = false
	current_region = &""
	await _swap_scene(load(TITLE_SCENE))
	await Cutscene.fade_in(FADE_TIME)
	is_changing = false


## Where and how Aurelia should appear: {"spawn": StringName, "player": Dictionary}. Read once by the new region.
func take_arrival() -> Dictionary:
	var arrival := _arrival
	_arrival = {}
	return arrival


func _swap_scene(packed: PackedScene) -> void:
	if scene_parent:
		if _child_scene and is_instance_valid(_child_scene):
			_child_scene.queue_free()
			await get_tree().process_frame
		_child_scene = packed.instantiate()
		scene_parent.add_child(_child_scene)
	else:
		get_tree().change_scene_to_packed(packed)
		await get_tree().process_frame  # the old scene leaves, the new one enters at the end of this frame
	await get_tree().process_frame
