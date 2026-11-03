extends SceneTree
## Applies Aethelgard's project settings, input map, physics layer names, autoloads
## and audio bus layout, then saves project.godot and default_bus_layout.tres.
##
## Run (from the project folder):
##   godot --headless --path . --script res://tools/setup/configure_project.gd
##
## Safe to run again: every setting is overwritten with the values below.
## Sources: TECHNICAL_DESIGN.md §2, §4.1, §4.13, §4.14 · AUDIO_DESIGN.md §3 · BUILD_PLAN.md §2.

const AUTOLOADS: Array[Array] = [
	["EventBus", "res://src/autoload/event_bus.gd"],
	["Settings", "res://src/autoload/settings.gd"],
	["GameState", "res://src/autoload/game_state.gd"],
	["PlayerData", "res://src/autoload/player_data.gd"],
	["Inventory", "res://src/autoload/inventory.gd"],
	["QuestManager", "res://src/autoload/quest_manager.gd"],
	["DragonManager", "res://src/autoload/dragon_manager.gd"],
	["TimeOfDay", "res://src/autoload/time_of_day.gd"],
	["AudioManager", "res://src/autoload/audio_manager.gd"],
	["SaveManager", "res://src/autoload/save_manager.gd"],
	["SceneLoader", "res://src/autoload/scene_loader.gd"],
	["Cutscene", "res://src/autoload/cutscene.gd"],
	["DialogueManager", "res://addons/dialogue_manager/dialogue_manager.gd"],
]

const PHYSICS_LAYERS: Array[String] = [
	"world", "player", "enemy", "ally", "player_hurtbox",
	"enemy_hurtbox", "interactable", "elemental", "water", "high_ground",
]

const EDITOR_PLUGINS: Array[String] = [
	"res://addons/gut/plugin.cfg",
	"res://addons/dialogue_manager/plugin.cfg",
]


func _init() -> void:
	_apply_settings()
	_apply_layer_names()
	_apply_autoloads()
	_apply_input_map()
	var err := ProjectSettings.save()
	print("project.godot saved: ", error_string(err))
	_build_bus_layout()
	quit()


func _apply_settings() -> void:
	var s := {
		"application/config/name": "Aethelgard",
		"application/config/description": "2D top-down anime action-RPG.",
		"application/run/main_scene": "res://src/game/main.tscn",
		# Rendering: Compatibility renderer for the 8 GB development laptop (BUILD_PLAN.md §2).
		"rendering/renderer/rendering_method": "gl_compatibility",
		"rendering/renderer/rendering_method.mobile": "gl_compatibility",
		# Display: 1920x1080 base; windowed at 1600x900 so it fits the laptop screen with the taskbar.
		"display/window/size/viewport_width": 1920,
		"display/window/size/viewport_height": 1080,
		"display/window/size/window_width_override": 1600,
		"display/window/size/window_height_override": 900,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"display/window/vsync/vsync_mode": 1,
		# Physics at 60 Hz with interpolation, so movement stays smooth on the 144 Hz screen.
		"physics/common/physics_ticks_per_second": 60,
		"physics/common/physics_interpolation": true,
		"physics/2d/default_gravity": 0.0,
		"editor_plugins/enabled": PackedStringArray(EDITOR_PLUGINS),
	}
	for key: String in s:
		ProjectSettings.set_setting(key, s[key])


func _apply_layer_names() -> void:
	for i in PHYSICS_LAYERS.size():
		ProjectSettings.set_setting("layer_names/2d_physics/layer_%d" % (i + 1), PHYSICS_LAYERS[i])


func _apply_autoloads() -> void:
	for entry: Array in AUTOLOADS:
		ProjectSettings.set_setting("autoload/" + entry[0], "*" + entry[1])


func _apply_input_map() -> void:
	var actions := {
		"move_up": [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_down": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)],
		"aim_up": [_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"aim_down": [_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"aim_left": [_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"aim_right": [_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"attack": [_mouse(MOUSE_BUTTON_LEFT), _joy(JOY_BUTTON_X)],
		"cast_1": [_key(KEY_1), _mouse(MOUSE_BUTTON_RIGHT), _joy(JOY_BUTTON_LEFT_SHOULDER)],
		"cast_2": [_key(KEY_2), _joy(JOY_BUTTON_RIGHT_SHOULDER)],
		"cast_3": [_key(KEY_3), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"cast_4": [_key(KEY_4), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"dash": [_key(KEY_SPACE), _joy(JOY_BUTTON_A)],
		"interact": [_key(KEY_E), _joy(JOY_BUTTON_Y)],
		"dragon_command": [_key(KEY_G), _joy(JOY_BUTTON_DPAD_UP)],
		"dragon_skill": [_key(KEY_H), _joy(JOY_BUTTON_DPAD_DOWN)],
		"menu": [_key(KEY_TAB), _joy(JOY_BUTTON_START)],
		"map": [_key(KEY_M), _joy(JOY_BUTTON_BACK)],
		"journal": [_key(KEY_J)],
		"pause": [_key(KEY_ESCAPE)],
	}
	for action: String in actions:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": actions[action]})


func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.device = -1
	e.physical_keycode = keycode
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.device = -1
	e.button_index = button
	return e


func _joy(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = -1
	e.button_index = button
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = -1
	e.axis = axis
	e.axis_value = value
	return e


## Bus layout from AUDIO_DESIGN.md §3. Godot buses have a single send target,
## so reverb sits on the SFX bus itself instead of on a separate send bus.
func _build_bus_layout() -> void:
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	while AudioServer.get_bus_effect_count(0) > 0:
		AudioServer.remove_bus_effect(0, 0)
	var limiter := AudioEffectHardLimiter.new()
	AudioServer.add_bus_effect(0, limiter)

	var music := _add_bus("Music", "Master")
	var duck := AudioEffectCompressor.new()
	duck.sidechain = &"Dialogue"
	duck.threshold = -24.0
	duck.ratio = 4.0
	AudioServer.add_bus_effect(music, duck)
	_add_pause_lowpass(music)

	var ambience := _add_bus("Ambience", "Master")
	_add_pause_lowpass(ambience)

	var sfx := _add_bus("SFX", "Master")
	var reverb := AudioEffectReverb.new()
	reverb.wet = 0.12
	AudioServer.add_bus_effect(sfx, reverb)
	for child: String in ["Player", "Enemies", "Dragon", "World"]:
		_add_bus(child, "SFX")

	_add_bus("UI", "Master")
	_add_bus("Dialogue", "Master")

	var err := ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres")
	print("default_bus_layout.tres saved: ", error_string(err))


func _add_bus(bus_name: String, send: String) -> int:
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send)
	return idx


## Low-pass that AudioManager enables while the game is paused (muffled music).
func _add_pause_lowpass(bus: int) -> void:
	var lowpass := AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = 900.0
	AudioServer.add_bus_effect(bus, lowpass)
	AudioServer.set_bus_effect_enabled(bus, AudioServer.get_bus_effect_count(bus) - 1, false)
