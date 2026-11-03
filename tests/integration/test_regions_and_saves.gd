extends GutTest
## Phase 6b end to end: travelling between regions through exits (health kept, autosave on arrival), saving at a
## shrine, "quitting" and loading back with the world as it was (FR-SAV-02/04, FR-WLD-05/09, FR-PUZ-06),
## day/night and rain in a region, and the title screen. Regions load under this test instead of replacing the scene.

const TEST_DIR := "user://test_saves/"
const VILLAGE := &"elderroot_village"

var holder: Node


func before_all() -> void:
	CombatFx.hit_stop_enabled = false
	Settings.persist = false
	SaveManager.save_dir = TEST_DIR


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Settings.persist = true
	for slot in SaveManager.SLOTS:
		SaveManager.delete_slot(slot)
	SaveManager.save_dir = "user://saves/"
	SaveManager.writes_enabled = true
	SceneLoader.scene_parent = null
	SceneLoader.current_region = &""
	TimeOfDay.running = false
	get_tree().paused = false


func before_each() -> void:
	for slot in SaveManager.SLOTS:
		SaveManager.delete_slot(slot)
	SaveManager.writes_enabled = true
	SceneLoader.autosave_on_arrival = true
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


func test_go_to_the_village_and_autosave() -> void:
	assert_true(await SceneLoader.change_region(VILLAGE, &"from_meadow"))
	assert_eq(SceneLoader.current_region, VILLAGE)
	var player := _player()
	assert_not_null(player)
	var spawn := RegionSpawn.find(get_tree(), &"from_meadow")
	assert_almost_eq(player.global_position.distance_to(spawn.global_position), 0.0, 0.1, "at the arrival spawn")
	assert_true(TimeOfDay.running, "the clock runs while playing")
	assert_true(SaveManager.has_slot(SaveManager.AUTO), "autosave on arriving (FR-SAV-02)")
	assert_eq(get_tree().get_nodes_in_group(&"npc").size(), 2, "the Elder and Maren live here")


func test_exit_keeps_health_and_leads_back() -> void:
	await SceneLoader.change_region(VILLAGE, &"from_meadow", {"health": 61.0})
	var player := _player()
	assert_eq(player.health.current, 61.0, "health carried through the exit")
	await wait_seconds(RegionExit.ARM_DELAY + 0.1)
	var exit: RegionExit
	for node in holder.get_child(0).get_children():
		if node is RegionExit:
			exit = node
	assert_not_null(exit)
	player.global_position = exit.global_position + Vector3(0, 0.1, 0)
	await wait_seconds(2.5)  # fade, load the meadow, fade in
	assert_eq(SceneLoader.current_region, &"elderroot_meadow")
	var arrived := _player()
	assert_almost_eq(arrived.health.current, 61.0, 0.01)
	var spawn := RegionSpawn.find(get_tree(), &"from_village")
	assert_almost_eq(arrived.global_position.distance_to(spawn.global_position), 0.0, 0.2, "at the village gate")


func test_save_quit_and_load_back() -> void:
	await SceneLoader.change_region(VILLAGE, &"from_meadow")
	var player := _player()
	var shrine := get_tree().get_first_node_in_group(&"rest_point") as RestPoint
	player.global_position = shrine.respawn_position()
	await wait_physics_frames(3)
	var garden: GatherNode
	for node in holder.get_child(0).get_children():
		if node is GatherNode:
			garden = node
			break
	assert_gt(garden.gather(player), 0, "picked from the garden")
	var garden_id := garden.persist_id
	player.health.apply_damage(DamageInfo.create(25.0, Elements.Type.NONE, Vector3.ZERO, null))
	QuestManager.start(&"lost_satchel")
	var save_menu := SaveMenu.new()
	add_child_autofree(save_menu)
	assert_true(save_menu.can_save_here(), "next to a Lantern Shrine")
	assert_true(save_menu.save_to(&"slot_1"))
	var where := player.global_position
	var sunpetal := Inventory.count(&"sunpetal")
	# "Quit": everything back to a fresh start, then load the slot.
	SaveManager.reset_world()
	assert_true(SaveManager.load_slot(&"slot_1"))
	await wait_seconds(1.5)
	var loaded := _player()
	assert_ne(loaded, player, "a new region scene")
	assert_almost_eq(loaded.global_position.distance_to(where), 0.0, 0.2, "standing where she saved")
	assert_eq(loaded.health.current, loaded.health.max_health - 25.0, "same health")
	assert_eq(Inventory.count(&"sunpetal"), sunpetal)
	assert_true(QuestManager.is_active(&"lost_satchel"))
	var reloaded_garden: GatherNode
	for node in holder.get_child(0).get_children():
		if node is GatherNode and node.persist_id == garden_id:
			reloaded_garden = node
	assert_false(reloaded_garden.can_gather(), "the picked patch is still growing back (FR-WLD-09)")


func test_saving_needs_a_shrine() -> void:
	await SceneLoader.change_region(VILLAGE, &"from_meadow")
	var save_menu := SaveMenu.new()
	add_child_autofree(save_menu)
	_player().global_position = Vector3(30, 0, 30)
	assert_false(save_menu.can_save_here())
	assert_false(save_menu.save_to(&"slot_1"))


func test_day_night_and_rain_in_a_region() -> void:
	await SceneLoader.change_region(VILLAGE, &"from_meadow")
	var region := holder.get_child(0)
	var runtime: RegionRuntime = region.runtime
	TimeOfDay.set_hour(12.0)
	runtime.cycle.apply(12.0)
	var noon := runtime.sun.light_energy
	TimeOfDay.set_hour(0.0)
	runtime.cycle.apply(0.0)
	assert_gt(noon, runtime.sun.light_energy * 3.0, "much darker at night (FR-WLD-06)")
	TimeOfDay.set_weather(&"rain")
	await wait_seconds(1.0)
	assert_gt(runtime.cycle.rain_amount, 0.1, "rain fades in (FR-WLD-07)")
	assert_true(runtime.cycle._rain.emitting)


func test_title_screen_offers_continue_after_a_save() -> void:
	var title: TitleScreen = load("res://src/ui/title/title_screen.tscn").instantiate()
	add_child_autofree(title)
	await wait_process_frames(2)
	assert_true(title._continue.disabled, "nothing to continue yet")
	SaveManager.save_slot(&"slot_3")
	title._refresh()
	assert_false(title._continue.disabled, "Continue loads the latest save (FR-UI-05)")
