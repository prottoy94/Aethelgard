extends CanvasLayer
## Cutscene helpers called from .dialogue files (DIALOGUE_DESIGN.md §5.2, FR-DLG-06): letterbox bars, fading to and
## from black, waiting, playing a scripted scene and asking the player to type a name. Each timed action can be
## awaited (`do Cutscene.wait(1)`). Camera moves, actor movement and skipping arrive with the story cutscenes (Phase 8).
##
## Scripted scenes (Phase 7): `Cutscene.play(&"dragon_hatch")` adds that scene's CutsceneScene next to Aurelia; it runs
## its dialogue, and the dialogue's `do Cutscene.cue("name")` lines run the scene's effects.

signal cutscene_started(id: StringName)
signal cutscene_finished(id: StringName)
signal _text_entered(text: String)

const LAYER := 25             ## the bars and fade: above the HUD and menus, below the dialogue box (30)
const PROMPT_LAYER := 45      ## the name box: above everything
const BAR_HEIGHT := 0.11      ## of the screen height
const BAR_TIME := 0.4         ## s to slide the bars in or out
## Scripted scenes by id (loaded when played).
const SCENES := {
	&"dragon_hatch": "res://src/cutscenes/dragon_hatch/dragon_hatch_cutscene.gd",
}
const PARCHMENT := Color("f3e9d2")
const INK := Color("3b2a1e")
const GOLD := Color("b8862e")

var active: CutsceneScene
var _active_id: StringName = &""
var _top: ColorRect
var _bottom: ColorRect
var _fade: ColorRect
var _prompt: PanelContainer
var _prompt_label: Label
var _prompt_edit: LineEdit
var _prompt_default := ""


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_top = _bar(Control.PRESET_TOP_WIDE)
	_bottom = _bar(Control.PRESET_BOTTOM_WIDE)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	_build_prompt()


func is_letterboxed() -> bool:
	return _top.scale.y > 0.5


## Slides the black bars in (true) or out (false).
func letterbox(on: bool) -> void:
	var target := 1.0 if on else 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_top, "scale:y", target, BAR_TIME)
	tween.tween_property(_bottom, "scale:y", target, BAR_TIME)
	await tween.finished


func fade_out(seconds := 0.6) -> void:
	await _fade_to(1.0, seconds)


func fade_in(seconds := 0.6) -> void:
	await _fade_to(0.0, seconds)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


## Back to normal at once (scene changes, skipping).
func clear() -> void:
	_top.scale.y = 0.0
	_bottom.scale.y = 0.0
	_fade.color.a = 0.0
	if _prompt.visible:
		_submit(_prompt_edit.text)


# --- Scripted scenes -----------------------------------------------------------------------------

func is_playing() -> bool:
	return active != null


## Plays scripted scene `id` next to Aurelia and returns when it is over. Does nothing while another one plays.
func play(id: StringName) -> void:
	if active or not SCENES.has(id):
		if not SCENES.has(id):
			push_warning("Cutscene: no scene called %s" % id)
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var parent: Node = player.get_parent() if player else get_tree().current_scene
	if parent == null:
		return
	var script := load(SCENES[id]) as Script
	active = script.new() as CutsceneScene
	_active_id = id
	parent.add_child(active)
	cutscene_started.emit(id)
	await active.run()
	if is_instance_valid(active):
		active.queue_free()
	active = null
	_active_id = &""
	letterbox(false)
	cutscene_finished.emit(id)


## Runs effect `cue_name` of the scene that is playing (`do Cutscene.cue("hatch")`); waits until it is done.
func cue(cue_name: String) -> void:
	if active:
		await active.cue(StringName(cue_name))


# --- Typing a name (FR-DLG-09) -------------------------------------------------------------------

func is_asking() -> bool:
	return _prompt.visible


## Shows a small parchment box with a text field and waits for Enter or OK. An empty answer returns `default_text`.
func ask_text(question: String, default_text: String, max_length := 14) -> String:
	_prompt_label.text = question
	_prompt_default = default_text
	_prompt_edit.text = ""
	_prompt_edit.placeholder_text = default_text
	_prompt_edit.max_length = max_length
	_prompt.visible = true
	_prompt_edit.grab_focus.call_deferred()
	var text: String = await _text_entered
	return text


## Answers the open name box (the OK button, Enter, and tests).
func submit_text(text: String) -> void:
	if _prompt.visible:
		_submit(text)


func _submit(text: String) -> void:
	_prompt.visible = false
	var answer := text.strip_edges()
	_text_entered.emit(answer if answer != "" else _prompt_default)


func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	_prompt.add_theme_stylebox_override("panel", style)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BOTH
	_prompt.custom_minimum_size = Vector2(460, 0)
	_prompt.visible = false
	var prompt_layer := CanvasLayer.new()
	prompt_layer.layer = PROMPT_LAYER
	add_child(prompt_layer)
	prompt_layer.add_child(_prompt)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_prompt.add_child(column)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 26)
	_prompt_label.add_theme_color_override("font_color", INK)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_prompt_label)
	_prompt_edit = LineEdit.new()
	_prompt_edit.add_theme_font_size_override("font_size", 26)
	_prompt_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_edit.custom_minimum_size = Vector2(0, 48)
	_prompt_edit.text_submitted.connect(_submit)
	column.add_child(_prompt_edit)
	var hint := Label.new()
	hint.text = "Type a name, then Enter.  Leave it empty to keep the suggestion."
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", INK.lightened(0.3))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(140, 44)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuScreen.style_button(ok, 20)
	ok.pressed.connect(func() -> void: _submit(_prompt_edit.text))
	column.add_child(ok)
	_prompt_edit.focus_neighbor_bottom = _prompt_edit.get_path_to(ok)
	ok.focus_neighbor_top = ok.get_path_to(_prompt_edit)


# --- Inside --------------------------------------------------------------------------------------

func _fade_to(alpha: float, seconds: float) -> void:
	if seconds <= 0.0:
		_fade.color.a = alpha
		return
	await create_tween().tween_property(_fade, "color:a", alpha, seconds).finished


func _bar(preset: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(preset)
	bar.anchor_top = 0.0 if preset == Control.PRESET_TOP_WIDE else 1.0 - BAR_HEIGHT
	bar.anchor_bottom = BAR_HEIGHT if preset == Control.PRESET_TOP_WIDE else 1.0
	bar.offset_top = 0.0
	bar.offset_bottom = 0.0
	bar.scale.y = 0.0
	add_child(bar)
	bar.resized.connect(func() -> void:  # scale from the screen edge
		bar.pivot_offset = Vector2(0, 0.0 if preset == Control.PRESET_TOP_WIDE else bar.size.y))
	return bar
