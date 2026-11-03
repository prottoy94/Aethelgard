extends Node
## Player options. Graphics presets work now (Phase 1b); volumes, key bindings, accessibility and
## text speed are added with the settings menu, stored in user://settings.cfg (ConfigFile).

signal graphics_changed(preset: GraphicsPreset)

const GRAPHICS_PRESET_PATHS: Array[String] = [
	"res://data/graphics/low.tres",
	"res://data/graphics/medium.tres",
	"res://data/graphics/high.tres",
]
const DEFAULT_GRAPHICS: StringName = &"high"

var graphics: GraphicsPreset


func _ready() -> void:
	var preset := DEFAULT_GRAPHICS
	for arg in OS.get_cmdline_user_args():  # e.g. `-- --graphics=low` for testing
		if arg.begins_with("--graphics="):
			preset = StringName(arg.trim_prefix("--graphics="))
	set_graphics_preset(preset)


func get_graphics_presets() -> Array[GraphicsPreset]:
	var presets: Array[GraphicsPreset] = []
	for path in GRAPHICS_PRESET_PATHS:
		presets.append(load(path) as GraphicsPreset)
	return presets


func set_graphics_preset(id: StringName) -> void:
	for preset in get_graphics_presets():
		if preset.id == id:
			graphics = preset
			graphics.apply_to_viewport(get_viewport())
			graphics_changed.emit(graphics)
			return
	push_error("Unknown graphics preset: %s" % id)
