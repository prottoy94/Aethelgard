extends Control
## Phase 1 check screen: shows that the project, renderer, GPU, autoloads and placeholder
## art are set up. Replaced by the title screen in a later phase. Press Esc to quit.

const AUTOLOAD_NAMES: Array[String] = [
	"EventBus", "Settings", "GameState", "PlayerData", "Inventory", "QuestManager",
	"DragonManager", "TimeOfDay", "AudioManager", "SaveManager", "SceneLoader",
	"Cutscene", "DialogueManager",
]
const PLACEHOLDERS: Array[String] = [
	"res://assets/art/placeholders/characters/aurelia_sheet.png",
	"res://assets/art/placeholders/enemies/thornling_sheet.png",
	"res://assets/art/placeholders/tiles/terrain_atlas.png",
	"res://assets/art/placeholders/props/tree.png",
	"res://assets/art/placeholders/props/ruin_pillar.png",
	"res://assets/art/placeholders/props/lantern_shrine.png",
	"res://assets/art/placeholders/ui/element_icons.png",
]
const BACKGROUND := Color("1d1a2b")
const ACCENT := Color("e8c66a")


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	column.add_child(_label("Aethelgard: Phase 1 project check", 44, ACCENT))
	column.add_child(_label(_system_info(), 22, Color.WHITE))
	column.add_child(_label(_autoload_info(), 20, Color("b9b4d0")))
	column.add_child(_label("Placeholder art (generated, final sizes):", 22, ACCENT))
	column.add_child(_gallery())
	column.add_child(_label("Press Esc to quit.", 18, Color("8a85a3")))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _system_info() -> String:
	var viewport := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return "Godot %s   |   Renderer: %s   |   GPU: %s   |   Base resolution: %dx%d" % [
		Engine.get_version_info().string,
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(),
		viewport.x, viewport.y,
	]


func _autoload_info() -> String:
	var loaded := 0
	var missing: Array[String] = []
	for autoload_name: String in AUTOLOAD_NAMES:
		if get_tree().root.has_node(autoload_name):
			loaded += 1
		else:
			missing.append(autoload_name)
	var text := "Global managers loaded: %d / %d" % [loaded, AUTOLOAD_NAMES.size()]
	if not missing.is_empty():
		text += "   (missing: %s)" % ", ".join(missing)
	return text


func _gallery() -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 24)
	row.add_theme_constant_override("v_separation", 24)
	for path: String in PLACEHOLDERS:
		if not ResourceLoader.exists(path):
			row.add_child(_label("missing: " + path.get_file(), 18, Color.TOMATO))
			continue
		var rect := TextureRect.new()
		rect.texture = load(path)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var tex_size := rect.texture.get_size()
		var height := minf(tex_size.y, 300.0)
		rect.custom_minimum_size = Vector2(tex_size.x * height / tex_size.y, height)
		row.add_child(rect)
	return row


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
