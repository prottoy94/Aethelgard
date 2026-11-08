extends Node
## Saves and loads the game as JSON files in user://saves/ (FR-SAV-01…04, TECHNICAL_DESIGN.md §4.9): one autosave
## (made when resting at a Lantern Shrine and on arriving in a region) and 3 manual slots. Every file carries a format
## version and is upgraded when the format changes. Only JSON is ever read from user:// (never .tres/.res, which can
## run code), and everything is referenced by id. A save holds the region, Aurelia's position and state, and the
## to_dict() of every saveable autoload.

signal saved(slot: StringName)
signal loaded(slot: StringName)

const VERSION := 1
const AUTO: StringName = &"auto"
const SLOTS: Array[StringName] = [&"auto", &"slot_1", &"slot_2", &"slot_3"]
const SLOT_NAMES: Array[String] = ["Autosave", "Slot 1", "Slot 2", "Slot 3"]
const COMBAT: PlayerCombatStats = preload("res://data/player/aurelia_combat.tres")
const NEW_GAME_REGION: StringName = &"elderroot_meadow"
const NEW_GAME_SPAWN: StringName = &"start"
## A new story starts with the prologue (Phase 8b): Rank Day in Elderroot Village, on the bench by Aurelia's cottage.
const PROLOGUE_REGION: StringName = &"elderroot_village"
const PROLOGUE_SPAWN: StringName = &"home"
const PROLOGUE_FLAG: StringName = &"prologue_active"

var save_dir := "user://saves/"   ## tests point this somewhere else
## False for quick test runs started with options, so they never overwrite the player's saves.
var writes_enabled := true
var play_time := 0.0              ## seconds actually played
var last_error := ""


func _process(delta: float) -> void:
	if TimeOfDay.running:
		play_time += delta


# --- New game, saving and loading --------------------------------------------------------------

## Everything back to the start, then `region`. Without the prologue (test starts) the game begins just after it.
func start_new_game(region := NEW_GAME_REGION, spawn := NEW_GAME_SPAWN, with_prologue := false) -> void:
	reset_world()
	if with_prologue:
		GameState.set_flag(PROLOGUE_FLAG)
	SceneLoader.change_region(region, spawn)


## A new story: the prologue in the village (the title screen's New Game).
func start_prologue() -> void:
	start_new_game(PROLOGUE_REGION, PROLOGUE_SPAWN, true)


func reset_world() -> void:
	GameState.reset()
	Inventory.reset()
	PlayerData.reset(COMBAT.starting_spells)
	QuestManager.reset()
	TimeOfDay.reset()
	DragonManager.from_dict({})
	play_time = 0.0


func autosave() -> bool:
	return save_slot(AUTO)


## Writes the current game to `slot`. Returns false (with last_error) if it couldn't.
func save_slot(slot: StringName) -> bool:
	last_error = ""
	if not slot in SLOTS:
		last_error = "Unknown save slot %s." % slot
		return false
	if not writes_enabled:
		last_error = "Saving is off for this test run."
		return false
	DirAccess.make_dir_recursive_absolute(save_dir)
	var path := _path(slot)
	var temp := path + ".tmp"  # write fully first, so a crash never leaves half a save
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Couldn't write the save (%s)." % error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(build_save(), "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(temp, path)
	saved.emit(slot)
	return true


## Loads `slot`: restores every system, then the saved region with Aurelia where she was. Returns false if the
## file is missing, damaged or from a newer version of the game (see last_error).
func load_slot(slot: StringName) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		return false
	apply_save(data)
	SceneLoader.change_region(StringName(str(data.get("region", NEW_GAME_REGION))), &"", data.get("player", {}))
	loaded.emit(slot)
	return true


## The save in `slot`, upgraded to the current format, or {} (with last_error) if there is none or it can't be used.
func read_slot(slot: StringName) -> Dictionary:
	last_error = ""
	var path := _path(slot)
	if not FileAccess.file_exists(path):
		last_error = "There is no save in %s." % slot_name(slot)
		return {}
	return parse_save(FileAccess.get_file_as_string(path))


## Checks and upgrades a save's JSON text. Returns {} (with last_error) if it can't be used.
func parse_save(text: String) -> Dictionary:
	last_error = ""
	var json := JSON.new()  # reports damage through its return value instead of the error log
	if json.parse(text) != OK or not json.data is Dictionary:
		last_error = "This save file is damaged."
		return {}
	var data: Dictionary = json.data
	var version := int(data.get("version", 0))
	if version > VERSION:
		last_error = "This save was made by a newer version of Aethelgard."
		return {}
	return migrate(data)


func has_slot(slot: StringName) -> bool:
	return FileAccess.file_exists(_path(slot))


func has_any_save() -> bool:
	return SLOTS.any(has_slot)


## The most recently written slot, or &"" if there are none.
func latest_slot() -> StringName:
	var best: StringName = &""
	var best_time := ""
	for slot in SLOTS:
		var info := slot_info(slot)
		if not info.is_empty() and String(info["saved_at"]) > best_time:
			best_time = info["saved_at"]
			best = slot
	return best


## A summary for menus: {"saved_at", "region", "clock", "play_time"}, or {} if the slot is empty or unusable.
func slot_info(slot: StringName) -> Dictionary:
	if not has_slot(slot):
		return {}
	var data := read_slot(slot)
	if data.is_empty():
		return {}
	var region := SceneLoader.REGIONS.find(StringName(str(data.get("region", ""))))
	var time: Dictionary = data.get("time", {})
	var minutes := int(float(time.get("minutes", 0.0)))
	return {
		"saved_at": str(data.get("saved_at", "")),
		"region": region.display_name if region else "?",
		"clock": "Day %d, %02d:%02d" % [int(time.get("day", 1)), minutes / 60, minutes % 60],
		"play_time": play_time_text(float(data.get("play_time", 0.0))),
	}


func delete_slot(slot: StringName) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(_path(slot))


func slot_name(slot: StringName) -> String:
	var index := SLOTS.find(slot)
	return SLOT_NAMES[index] if index != -1 else String(slot)


static func play_time_text(seconds: float) -> String:
	var total := int(seconds) / 60
	return "%d h %02d min" % [total / 60, total % 60]


# --- What a save contains ----------------------------------------------------------------------

func build_save() -> Dictionary:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	return {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"play_time": play_time,
		"region": String(SceneLoader.current_region),
		"player": capture_player(player) if player else {},
		"game_state": GameState.to_dict(),
		"inventory": Inventory.to_dict(),
		"player_data": PlayerData.to_dict(),
		"quests": QuestManager.to_dict(),
		"time": TimeOfDay.to_dict(),
		"dragon": DragonManager.to_dict(),
	}


## Puts a save into every system (Inventory before PlayerData: Magic Power counts the equipped gear).
func apply_save(data: Dictionary) -> void:
	play_time = float(data.get("play_time", 0.0))
	GameState.from_dict(data.get("game_state", {}))
	Inventory.from_dict(data.get("inventory", {}))
	PlayerData.from_dict(data.get("player_data", {}))
	QuestManager.from_dict(data.get("quests", {}))
	TimeOfDay.from_dict(data.get("time", {}))
	DragonManager.from_dict(data.get("dragon", {}))


## Upgrades an older save one version at a time (FR-SAV-03).
func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	while version < VERSION:
		match version:
			0:
				data = _from_version_0(data)
		version += 1
		data["version"] = version
	return data


## Version 0 (development saves before the clock existed): no clock, dragon or play time yet.
func _from_version_0(data: Dictionary) -> Dictionary:
	data.get_or_add("time", {})
	data.get_or_add("dragon", {})
	data.get_or_add("play_time", 0.0)
	return data


## Aurelia's own state: where she stands and how she's doing.
static func capture_player(player: Player) -> Dictionary:
	var pos := player.global_position
	var respawn := player.respawn_point
	return {
		"position": [pos.x, pos.y, pos.z],
		"facing": player.facing_yaw,
		"health": player.health.current,
		"stamina": player.stamina.current,
		"respawn": [respawn.x, respawn.y, respawn.z],
	}


## Restores what capture_player() saved. `with_position` is false when she arrives through a region exit.
static func apply_player(player: Player, state: Dictionary, with_position: bool) -> void:
	if state.is_empty():
		return
	if with_position and state.get("position") is Array and (state["position"] as Array).size() == 3:
		var p: Array = state["position"]
		player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		var r: Array = state.get("respawn", p)
		player.respawn_point = Vector3(float(r[0]), float(r[1]), float(r[2]))
		player.face_instantly(Vector3.FORWARD.rotated(Vector3.UP, float(state.get("facing", 0.0))))
	if state.has("health"):
		player.health.current = clampf(float(state["health"]), 1.0, player.health.max_health)
		player.health.changed.emit(player.health.current, player.health.max_health)
	if state.has("stamina"):
		player.stamina.current = clampf(float(state["stamina"]), 0.0, player.stamina.max_stamina)


func _path(slot: StringName) -> String:
	return save_dir.path_join("%s.json" % slot)
