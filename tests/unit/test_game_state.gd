extends GutTest
## GameState: story flags, persistent object states and the JSON save round-trip.

const GameStateScript := preload("res://src/autoload/game_state.gd")

var state: Node


func before_each() -> void:
	state = GameStateScript.new()
	add_child_autofree(state)


func test_flag_set_and_clear() -> void:
	assert_false(state.has_flag(&"met_sylvaris"))
	state.set_flag(&"met_sylvaris")
	assert_true(state.has_flag(&"met_sylvaris"))
	state.clear_flag(&"met_sylvaris")
	assert_false(state.has_flag(&"met_sylvaris"))


func test_flag_changed_signal() -> void:
	watch_signals(state)
	state.set_flag(&"prologue_done")
	assert_signal_emitted_with_parameters(state, "flag_changed", [&"prologue_done", true])


func test_object_state_is_copied() -> void:
	var chest := {"opened": true}
	state.set_object_state(&"elderroot_chest_01", chest)
	chest["opened"] = false
	assert_eq(state.get_object_state(&"elderroot_chest_01"), {"opened": true})
	assert_eq(state.get_object_state(&"unknown_id"), {})


func test_json_round_trip_restores_everything() -> void:
	state.set_flag(&"warden_defeated")
	state.set_flag(&"egg_received")
	state.set_object_state(&"puzzle_brazier_02", {"lit": true, "order": [2, 1, 3]})

	var json := JSON.stringify(state.to_dict())
	var restored: Node = autofree(GameStateScript.new())
	restored.from_dict(JSON.parse_string(json))

	assert_true(restored.has_flag(&"warden_defeated"))
	assert_true(restored.has_flag(&"egg_received"))
	assert_false(restored.has_flag(&"met_sylvaris"))
	assert_eq(restored.get_object_state(&"puzzle_brazier_02")["lit"], true)
	assert_eq(restored.to_dict(), JSON.parse_string(json), "to_dict after load matches the saved data")


func test_from_dict_replaces_old_state() -> void:
	state.set_flag(&"old_flag")
	state.from_dict({"flags": ["new_flag"], "objects": {}})
	assert_false(state.has_flag(&"old_flag"))
	assert_true(state.has_flag(&"new_flag"))
