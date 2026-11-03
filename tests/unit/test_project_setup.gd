extends GutTest
## Phase 1 setup checks: settings that the rest of the project relies on (BUILD_PLAN.md §2, Phase 1).

const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"aim_up", &"aim_down", &"aim_left", &"aim_right",
	&"attack", &"cast_1", &"cast_2", &"cast_3", &"cast_4",
	&"dash", &"interact", &"dragon_command", &"dragon_skill",
	&"menu", &"map", &"journal", &"pause",
]
const AUTOLOADS: Array[String] = [
	"EventBus", "Settings", "GameState", "PlayerData", "Inventory", "QuestManager",
	"DragonManager", "TimeOfDay", "AudioManager", "SaveManager", "SceneLoader",
	"Cutscene", "DialogueManager",
]
const BUSES: Array[String] = [
	"Master", "Music", "Ambience", "SFX", "Player", "Enemies", "Dragon", "World", "UI", "Dialogue",
]


func test_renderer_is_compatibility() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")


func test_base_resolution_and_stretch() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")


func test_input_actions_exist_with_events() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "action exists: %s" % action)
		if InputMap.has_action(action):
			assert_gt(InputMap.action_get_events(action).size(), 0, "action has a binding: %s" % action)


func test_physics_layer_names() -> void:
	assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_1"), "world")
	assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_9"), "water")
	assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_10"), "high_ground")


func test_autoloads_are_registered() -> void:
	for autoload_name in AUTOLOADS:
		assert_true(ProjectSettings.has_setting("autoload/" + autoload_name), "autoload: %s" % autoload_name)


func test_audio_buses_exist() -> void:
	for bus in BUSES:
		assert_ne(AudioServer.get_bus_index(bus), -1, "bus exists: %s" % bus)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index("Player")), &"SFX")


func test_main_scene_loads() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(ResourceLoader.exists(path), "main scene exists")
