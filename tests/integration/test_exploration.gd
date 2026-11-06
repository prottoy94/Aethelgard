extends GutTest
## More to explore (owner request 2026-11-05): named places that are discovered once, things to read, the bigger
## meadow and village with their borders, Aurelia's animated look, and sounds heard from Aurelia's position.

const TEST_DIR := "user://test_saves/"

var holder: Node


func before_all() -> void:
	CombatFx.hit_stop_enabled = false
	Settings.persist = false
	SaveManager.save_dir = TEST_DIR


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Settings.persist = true
	SaveManager.save_dir = "user://saves/"
	SaveManager.writes_enabled = true
	SceneLoader.scene_parent = null
	SceneLoader.current_region = &""
	TimeOfDay.running = false
	get_tree().paused = false


func before_each() -> void:
	SaveManager.writes_enabled = false
	SaveManager.reset_world()
	holder = Node.new()
	add_child(holder)
	SceneLoader.scene_parent = holder


func after_each() -> void:
	get_tree().paused = false
	TimeOfDay.running = false
	holder.queue_free()
	await wait_process_frames(2)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func test_the_meadow_has_places_to_find() -> void:
	assert_true(await SceneLoader.change_region(&"elderroot_meadow", &"start"))
	var places := get_tree().get_nodes_in_group(&"landmark")
	assert_gte(places.size(), 11, "seven new places plus the old ones, named")
	assert_gte(get_tree().get_nodes_in_group(&"lore").size(), 6, "things to read")
	var grove: Landmark
	for node in places:
		if (node as Landmark).place_id == &"whispering_grove":
			grove = node
	assert_not_null(grove)
	watch_signals(EventBus)
	assert_true(grove.discover(), "found the first time")
	assert_false(grove.discover(), "only once")
	assert_true(grove.is_discovered())
	assert_signal_emitted(EventBus, "place_reached")


func test_reading_a_stone_opens_its_text() -> void:
	await SceneLoader.change_region(&"elderroot_meadow", &"start")
	var stone := get_tree().get_first_node_in_group(&"lore") as LoreStone
	var box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	stone.read_requested.emit(LoreStone.LORE, stone.cue)
	await wait_process_frames(2)
	assert_true(box.is_open(), "the text shows in the dialogue box")


func test_the_meadow_is_bigger_and_closed_off() -> void:
	await SceneLoader.change_region(&"elderroot_meadow", &"start")
	var player := _player()
	player.global_position = Vector3(0, 0.1, -60)
	await wait_physics_frames(2)
	for i in 90:  # walk north into the border
		player.velocity = Vector3(0, 0, -6)
		player.move_and_slide()
		await wait_physics_frames(1)
	assert_gt(player.global_position.z, MeadowLandmarks.MEADOW_MIN.y - 1.0, "the edge stops her")
	var region := SceneLoader.REGIONS.find(&"elderroot_meadow")
	assert_gte(region.map_size, 140.0, "the map shows the whole meadow")


func test_the_village_has_more_people_and_a_workbench() -> void:
	await SceneLoader.change_region(&"elderroot_village", &"from_meadow")
	var benches := get_tree().get_nodes_in_group(&"crafting_station").filter(func(n: Node) -> bool:
		return (n as CraftingStation).station == RecipeData.Station.WORKBENCH)
	assert_eq(benches.size(), 1, "Bram's forge has a workbench")
	var ids: Array = get_tree().get_nodes_in_group(&"npc").map(func(n: Node) -> StringName: return (n as Npc).npc_id)
	for id: StringName in [&"bram", &"wenna", &"pell"]:
		assert_has(ids, id)


func test_aurelia_is_animated_and_sounds_are_heard_from_her() -> void:
	await SceneLoader.change_region(&"elderroot_meadow", &"start")
	var player := _player()
	assert_true(player.visual is HumanoidVisual, "the animated model with real walk animations is the default")
	var rig := get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
	await wait_process_frames(3)
	assert_not_null(rig.listener)
	assert_lt(rig.listener.global_position.distance_to(player.global_position), 2.5,
			"the ears are at Aurelia, not at the camera 13 m away")
