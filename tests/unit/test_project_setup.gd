extends GutTest
## Project setup checks: settings the rest of the project relies on (BUILD_PLAN.md §2, 3D_PROPOSAL.md).

const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"aim_up", &"aim_down", &"aim_left", &"aim_right",
	&"attack", &"cast_1", &"cast_2", &"cast_3", &"cast_4",
	&"dash", &"interact", &"dragon_command", &"dragon_skill",
	&"menu", &"map", &"journal", &"pause",
	&"camera_rotate_left", &"camera_rotate_right", &"camera_zoom_in", &"camera_zoom_out",
	&"camera_drag", &"camera_reset",
]
const AUTOLOADS: Array[String] = [
	"EventBus", "Settings", "GameState", "PlayerData", "Inventory", "QuestManager",
	"DragonManager", "TimeOfDay", "AudioManager", "SaveManager", "SceneLoader",
	"Cutscene", "DialogueManager",
]
const BUSES: Array[String] = [
	"Master", "Music", "Ambience", "SFX", "Player", "Enemies", "Dragon", "World", "UI", "Dialogue",
]


func test_renderer_is_forward_plus() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "forward_plus")


func test_physics_engine_is_jolt() -> void:
	assert_eq(ProjectSettings.get_setting("physics/3d/physics_engine"), "Jolt Physics")


func test_base_resolution_and_stretch() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")


func test_input_actions_exist_with_events() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "action exists: %s" % action)
		if InputMap.has_action(action):
			assert_gt(InputMap.action_get_events(action).size(), 0, "action has a binding: %s" % action)


func test_3d_physics_layer_names() -> void:
	assert_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_1"), "world")
	assert_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_9"), "water")
	assert_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_10"), "high_ground")
	assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_1"), "", "old 2D layer names removed")


func test_autoloads_are_registered() -> void:
	for autoload_name in AUTOLOADS:
		assert_true(ProjectSettings.has_setting("autoload/" + autoload_name), "autoload: %s" % autoload_name)


func test_audio_buses_exist() -> void:
	for bus in BUSES:
		assert_ne(AudioServer.get_bus_index(bus), -1, "bus exists: %s" % bus)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index("Player")), &"SFX")


func test_main_scene_is_the_3d_test_level() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(path, "res://src/world/test/test_level_3d.tscn")
	assert_true(ResourceLoader.exists(path), "main scene exists")


func test_vrm_importer_enabled() -> void:
	var plugins: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled")
	assert_has(plugins, "res://addons/vrm/plugin.cfg")
