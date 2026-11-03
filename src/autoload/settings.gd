extends Node
## Player options, stored in user://settings.cfg (ConfigFile): graphics preset (Phase 1b), dialogue text speed and
## auto-advance (FR-DLG-11, Phase 6). Volumes, key bindings and accessibility join them with the audio work.

signal graphics_changed(preset: GraphicsPreset)
signal changed

const GRAPHICS_PRESET_PATHS: Array[String] = [
	"res://data/graphics/low.tres",
	"res://data/graphics/medium.tres",
	"res://data/graphics/high.tres",
]
const DEFAULT_GRAPHICS: StringName = &"high"
const PATH := "user://settings.cfg"
const TEXT_SPEEDS := 4  ## slow, normal, fast, instant (DialogueTuning.SPEED_NAMES)

var graphics: GraphicsPreset
var text_speed := 1
var auto_advance := false
## False while running tests or tools, so they never overwrite the player's file.
var persist := true


func _ready() -> void:
	var preset := DEFAULT_GRAPHICS
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		preset = StringName(config.get_value("graphics", "preset", String(DEFAULT_GRAPHICS)))
		text_speed = clampi(int(config.get_value("dialogue", "text_speed", text_speed)), 0, TEXT_SPEEDS - 1)
		auto_advance = bool(config.get_value("dialogue", "auto_advance", auto_advance))
	for arg in OS.get_cmdline_user_args():  # e.g. `-- --graphics=low` for testing
		if arg.begins_with("--graphics="):
			preset = StringName(arg.trim_prefix("--graphics="))
	_apply_graphics(preset)


func get_graphics_presets() -> Array[GraphicsPreset]:
	var presets: Array[GraphicsPreset] = []
	for path in GRAPHICS_PRESET_PATHS:
		presets.append(load(path) as GraphicsPreset)
	return presets


func set_graphics_preset(id: StringName) -> void:
	if _apply_graphics(id):
		save()


func set_text_speed(speed: int) -> void:
	text_speed = clampi(speed, 0, TEXT_SPEEDS - 1)
	save()


func set_auto_advance(on: bool) -> void:
	auto_advance = on
	save()


func save() -> void:
	changed.emit()
	if not persist:
		return
	var config := ConfigFile.new()
	config.set_value("graphics", "preset", String(graphics.id) if graphics else String(DEFAULT_GRAPHICS))
	config.set_value("dialogue", "text_speed", text_speed)
	config.set_value("dialogue", "auto_advance", auto_advance)
	config.save(PATH)


func _apply_graphics(id: StringName) -> bool:
	for preset in get_graphics_presets():
		if preset.id == id:
			graphics = preset
			graphics.apply_to_viewport(get_viewport())
			graphics_changed.emit(graphics)
			return true
	push_error("Unknown graphics preset: %s" % id)
	return false
