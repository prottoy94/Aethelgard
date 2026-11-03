extends GutTest
## SaveManager (FR-SAV-01…04): JSON files only, every system round-trips, slots, versions and damaged files.
## Writes to user://test_saves/, never the player's user://saves/.

const TEST_DIR := "user://test_saves/"
const SUNPETAL := preload("res://data/items/sunpetal.tres")
const RING := preload("res://data/items/ember_ward_ring.tres")
const GUST := preload("res://data/spells/gust.tres")


func before_all() -> void:
	SaveManager.save_dir = TEST_DIR


func after_all() -> void:
	_clear_dir()
	SaveManager.save_dir = "user://saves/"
	SaveManager.writes_enabled = true


func before_each() -> void:
	_clear_dir()
	SaveManager.writes_enabled = true
	SaveManager.reset_world()


func _clear_dir() -> void:
	for slot in SaveManager.SLOTS:
		SaveManager.delete_slot(slot)


## A game in progress across every system.
func _play_a_little() -> void:
	GameState.set_flag(&"met_elder")
	GameState.set_object_state(&"ruins_gate", {"solved": true})
	Inventory.add(SUNPETAL, 4)
	Inventory.add(RING)
	Inventory.equip(RING)
	PlayerData.learn(GUST)
	PlayerData.add_mastery_xp(&"light_mote", 30)
	QuestManager.start(&"herbs_for_maren")
	TimeOfDay.advance(500.0)
	TimeOfDay.set_weather(&"fog")
	SaveManager.play_time = 1234.0


func _snapshot() -> String:
	return JSON.stringify([GameState.to_dict(), Inventory.to_dict(), PlayerData.to_dict(), QuestManager.to_dict(),
			TimeOfDay.to_dict(), SaveManager.play_time])


func test_everything_round_trips() -> void:
	_play_a_little()
	var before := _snapshot()
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.build_save()))  # as on disk
	SaveManager.reset_world()
	assert_ne(_snapshot(), before, "reset really changed things")
	SaveManager.apply_save(data)
	assert_eq(_snapshot(), before, "every system is back exactly (FR-SAV-04)")
	assert_eq(PlayerData.magic_power, PlayerData.magic_power, "")
	assert_true(PlayerData.equipment_power > 0, "gear Magic Power counted after loading")


func test_slots_on_disk() -> void:
	assert_false(SaveManager.has_any_save())
	assert_eq(SaveManager.latest_slot(), &"")
	_play_a_little()
	assert_true(SaveManager.save_slot(&"slot_2"))
	assert_true(FileAccess.file_exists(TEST_DIR + "slot_2.json"), "a JSON file (FR-SAV-01)")
	assert_true(SaveManager.has_slot(&"slot_2"))
	assert_eq(SaveManager.latest_slot(), &"slot_2")
	var info := SaveManager.slot_info(&"slot_2")
	assert_string_contains(info["clock"], "Day 1")
	assert_eq(info["play_time"], "0 h 20 min")
	var data := SaveManager.read_slot(&"slot_2")
	assert_eq(int(data["version"]), SaveManager.VERSION)
	assert_false(SaveManager.save_slot(&"slot_9"), "unknown slot")


func test_saving_can_be_switched_off() -> void:
	SaveManager.writes_enabled = false
	assert_false(SaveManager.autosave())
	assert_false(SaveManager.has_slot(SaveManager.AUTO))


func test_old_saves_are_upgraded() -> void:
	var old := {"region": "elderroot_meadow", "game_state": {"flags": ["met_elder"]}}  # version 0: no clock
	var data := SaveManager.parse_save(JSON.stringify(old))
	assert_eq(int(data["version"]), SaveManager.VERSION, "migrated (FR-SAV-03)")
	assert_true(data.has("time"))
	assert_true(data.has("play_time"))


func test_newer_or_damaged_saves_are_refused() -> void:
	assert_true(SaveManager.parse_save(JSON.stringify({"version": SaveManager.VERSION + 1})).is_empty())
	assert_string_contains(SaveManager.last_error, "newer")
	assert_true(SaveManager.parse_save("{ this is not json").is_empty())
	assert_string_contains(SaveManager.last_error, "damaged")
	assert_true(SaveManager.read_slot(&"slot_3").is_empty(), "nothing there")


func test_player_state_capture() -> void:
	var player: Player = load("res://src/actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	player.global_position = Vector3(3, 0, -4)
	player.health.apply_damage(DamageInfo.create(30.0, Elements.Type.NONE, Vector3.ZERO, null))
	var state: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.capture_player(player)))
	player.global_position = Vector3.ZERO
	player.health.reset()
	SaveManager.apply_player(player, state, true)
	assert_almost_eq(player.global_position, Vector3(3, 0, -4), Vector3.ONE * 0.001)
	assert_eq(player.health.current, 70.0)
