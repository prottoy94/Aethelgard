extends GutTest
## "Show the way" and the map (owner request 2026-11-04): waypoints, the objective for the tracked quest (here or
## through the exit to another area), the trail and HUD line, the opening's main quest, and the Map page.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")

var world: Node3D
var player: Player


func before_each() -> void:
	Settings.persist = false
	Inventory.reset()
	GameState.reset()
	QuestManager.reset()
	DragonManager.from_dict({})
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])
	SceneLoader.current_region = &"elderroot_meadow"
	world = Node3D.new()
	add_child_autofree(world)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	world.add_child(player)
	await wait_physics_frames(2)


func after_each() -> void:
	SceneLoader.current_region = &""
	Settings.persist = true
	get_tree().paused = false


func _spot(id: StringName, at: Vector3) -> Node3D:
	var node := Node3D.new()
	world.add_child(node)
	node.global_position = at
	Waypoint.mark(node, id)
	return node


func test_waypoints_find_the_nearest() -> void:
	_spot(&"sunpetal", Vector3(20, 0, 0))
	var near := _spot(&"sunpetal", Vector3(5, 0, 0))
	_spot(&"moonbloom", Vector3(1, 0, 0))
	assert_eq(Waypoint.find(get_tree(), &"sunpetal", Vector3.ZERO), near)
	assert_null(Waypoint.find(get_tree(), &"iron_ore", Vector3.ZERO))


func test_objective_here_points_at_the_waypoint() -> void:
	var flowers := _spot(&"sunpetal", Vector3(6, 0, -8))
	QuestManager.start(&"herbs_for_maren")
	var goal := Navigator.objective(get_tree(), player.global_position)
	assert_eq(goal["position"], flowers.global_position, "points at the Sunpetal")
	assert_almost_eq(float(goal["distance"]), 10.0, 0.1)
	assert_string_contains(goal["text"], "Sunpetal")
	assert_string_contains(Navigator.describe(goal), "10 m")


func test_objective_in_another_area_leads_to_the_exit() -> void:
	var exit := RegionExit.new()
	exit.target_region = &"elderroot_village"
	world.add_child(exit)
	exit.global_position = Vector3(0, 0, 22)
	QuestManager.start(&"morning_in_elderroot")
	var goal := Navigator.objective(get_tree(), player.global_position)
	assert_eq(goal["position"], exit.global_position, "the Elder is in the village: the way leads to its gate")
	assert_eq(goal["via"], "Elderroot Village")
	assert_string_contains(Navigator.describe(goal), "go to Elderroot Village")


func test_no_quest_says_so() -> void:
	var goal := Navigator.objective(get_tree(), Vector3.ZERO)
	assert_null(goal["position"])
	assert_string_contains(goal["text"], "No quest")


func test_show_way_draws_a_trail_and_a_line() -> void:
	var hud := Hud.new()
	world.add_child(hud)
	hud.bind(player)
	var navigator := Navigator.new()
	navigator.hud = hud
	world.add_child(navigator)
	_spot(&"tamsin", Vector3(-8, 0, 3))
	QuestManager.start(&"lost_satchel")
	QuestManager.advance(&"lost_satchel")  # step 2: bring it back to Tamsin
	var goal := navigator.show_way()
	assert_true(goal.get("position") is Vector3)
	assert_string_contains(hud._guide.text, "Tamsin", "the line says what to do")
	var trails := world.get_children().filter(func(n: Node) -> bool: return n is GuideTrail)
	assert_eq(trails.size(), 1, "a trail of lights runs towards her")


func test_main_quest_follows_the_village_tasks() -> void:
	QuestManager.start(&"morning_in_elderroot")
	assert_true(QuestManager.is_on_step(&"morning_in_elderroot", 0), "first: talk to the Elder")
	GameState.set_flag(&"met_elder")
	assert_true(QuestManager.is_on_step(&"morning_in_elderroot", 1))
	GameState.set_flag(QuestManager.done_flag(&"lost_satchel"))  # Tamsin first is fine too
	GameState.set_flag(QuestManager.done_flag(&"herbs_for_maren"))
	assert_true(QuestManager.is_on_step(&"morning_in_elderroot", 3), "then back to the Elder")
	DragonManager.receive_egg()
	assert_true(QuestManager.is_done(&"morning_in_elderroot"), "the egg finishes it")


func test_finishing_a_quest_sets_its_flag() -> void:
	QuestManager.start(&"lost_satchel")
	QuestManager.advance(&"lost_satchel")
	QuestManager.advance(&"lost_satchel")
	assert_true(GameState.has_flag(&"quest_done_lost_satchel"))


func test_every_quest_step_with_a_waypoint_names_a_real_area() -> void:
	for quest in QuestManager.LIBRARY.quests:
		for step in quest.steps:
			if step.waypoint_region != &"":
				assert_not_null(SceneLoader.REGIONS.find(step.waypoint_region), "%s: %s" % [quest.id, step.waypoint_region])
	for region in SceneLoader.REGIONS.regions:
		assert_gt(region.map_size, 0.0, "%s has a map frame" % region.id)


func test_map_page_shows_the_area_and_the_objective() -> void:
	var exit := RegionExit.new()
	exit.target_region = &"elderroot_village"
	world.add_child(exit)
	QuestManager.start(&"morning_in_elderroot")
	var page := MapMenu.new()
	world.add_child(page)
	page.open()
	assert_eq(page._region_label.text, "Elderroot Meadow")
	assert_string_contains(page._goal_label.text, "Talk to the Elder")
	var center := page.to_map(Vector3(page.region.map_center.x, 0, page.region.map_center.y))
	assert_almost_eq(center.x, MapMenu.MAP_SIZE * 0.5, 0.01, "the area's middle is the map's middle")
	page.close()
