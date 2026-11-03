class_name DialogueBox
extends CanvasLayer
## Story and NPC conversations (FR-DLG-02, FR-DLG-03, FR-DLG-11, FR-UI-06): a parchment box with the speaker's name
## plate, typewriter text, placeholder portraits on two sides with expressions ([#happy] tags) and choices.
## Aurelia speaks from the left, everyone else from the right ([#left] / [#right] tags override). Lines and logic
## come from Dialogue Manager .dialogue files. Pauses the game while open.
## Advance with E, Enter, a click or A; pressing while the text is typing shows the whole line.

signal started
signal finished

const TUNING: DialogueTuning = preload("res://data/dialogue/dialogue_tuning.tres")
const PORTRAITS: PortraitLibrary = preload("res://data/dialogue/portraits.tres")
const PLAYER_NAME := "Aurelia"
const PARCHMENT := Color("f3e9d2")
const INK := Color("3b2a1e")
const GOLD := Color("b8862e")
const BOX_HEIGHT := 200.0
const POSITION_TAGS: PackedStringArray = ["left", "right"]

var line: DialogueLine
var _resource: DialogueResource
var _extra_states: Array = []
var _waiting := false
var _auto_left := -1.0
var _root: Control
var _name_label: Label
var _text: DialogueLabel
var _choices: VBoxContainer
var _left: PortraitView
var _right: PortraitView
var _more: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


## Starts a conversation at `cue`. `extra_states` are extra objects the dialogue may read (e.g. the NPC).
func start(resource: DialogueResource, cue: String, extra_states: Array = []) -> void:
	_resource = resource
	_extra_states = extra_states
	_left.clear()
	_right.clear()
	_root.visible = true
	get_tree().paused = true
	started.emit()
	_show(await _resource.get_next_dialogue_line(cue, _extra_states))


## Finishes the typing, or moves to the next line. (Also used by tests.)
func advance() -> void:
	if not is_open() or line == null:
		return
	if _text.is_typing:
		_text.skip_typing()
	elif _waiting:
		_waiting = false
		_show(await _resource.get_next_dialogue_line(line.next_id, _extra_states))


## Picks choice `index` of the current line.
func choose(index: int) -> void:
	if not is_open() or line == null or index < 0 or index >= line.responses.size():
		return
	var response: DialogueResponse = line.responses[index]
	_clear_choices()
	_show(await _resource.get_next_dialogue_line(response.next_id, _extra_states))


func _process(delta: float) -> void:
	_more.visible = _waiting and line != null and line.responses.is_empty()
	if _auto_left > 0.0:
		_auto_left -= delta
		if _auto_left <= 0.0 and _waiting:
			advance()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if line and line.responses.is_empty():
			advance()
	get_viewport().set_input_as_handled()  # nothing else reacts while talking


func _show(next_line: DialogueLine) -> void:
	_auto_left = -1.0
	if next_line == null:
		_finish()
		return
	line = next_line
	_waiting = false
	_name_label.text = line.character
	_name_label.get_parent().visible = line.character != ""
	_set_portraits()
	_text.dialogue_line = line
	_text.seconds_per_step = TUNING.seconds_per_char[clampi(Settings.text_speed, 0, TUNING.seconds_per_char.size() - 1)]
	if line.has_tag("sfx") and AudioManager.has_method(&"play"):
		AudioManager.play(StringName(line.get_tag_value("sfx")))
	_clear_choices()
	_text.type_out()
	if _text.seconds_per_step <= 0.0:
		_text.skip_typing()
	if _text.is_typing:
		await _text.finished_typing
	if line != next_line:
		return  # a newer line was shown meanwhile
	if not line.responses.is_empty():
		_show_choices()
	else:
		_waiting = true
		if Settings.auto_advance:
			_auto_left = TUNING.auto_advance_delay + line.text.length() * TUNING.auto_advance_per_char


func _finish() -> void:
	line = null
	_waiting = false
	_clear_choices()
	_root.visible = false
	get_tree().paused = false
	finished.emit()


func _set_portraits() -> void:
	var style := PORTRAITS.find(line.character)
	if style == null:
		return
	var on_left := line.character == PLAYER_NAME
	if line.has_tag("left"):
		on_left = true
	elif line.has_tag("right"):
		on_left = false
	var mood := "neutral"
	for tag in line.tags:
		if not tag in POSITION_TAGS and not "=" in tag:
			mood = tag
			break
	var speaking := _left if on_left else _right
	var listening := _right if on_left else _left
	speaking.show_portrait(style, mood, true)
	if listening.style:
		listening.show_portrait(listening.style, listening.mood, false)
	_name_label.add_theme_color_override("font_color", style.name_color)


func _show_choices() -> void:
	for i in line.responses.size():
		var response: DialogueResponse = line.responses[i]
		var button := Button.new()
		button.text = "%d.  %s" % [i + 1, response.text]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not response.is_allowed
		MenuScreen.style_button(button, 20)
		button.pressed.connect(choose.bind(i))
		_choices.add_child(button)
	_choices.visible = true
	var first := _choices.get_child(0) as Button
	first.grab_focus.call_deferred()


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()
	_choices.visible = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_left = _portrait(true)
	_right = _portrait(false)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 100.0
	panel.offset_right = -100.0
	panel.offset_top = -BOX_HEIGHT - 20.0
	panel.offset_bottom = -20.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN  # choices make it taller upwards
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var plate := PanelContainer.new()
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = PARCHMENT.darkened(0.1)
	plate_style.set_corner_radius_all(6)
	plate_style.content_margin_left = 12
	plate_style.content_margin_right = 12
	plate.add_theme_stylebox_override("panel", plate_style)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(plate)
	_name_label = MenuScreen.make_label("", 24, INK)
	plate.add_child(_name_label)
	_text = DialogueLabel.new()
	_text.skip_action = &""  # this box handles skipping
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_color_override("default_color", INK)
	column.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	_choices.visible = false
	column.add_child(_choices)
	_more = MenuScreen.make_label("▼", 18, GOLD)
	_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_more)


## A portrait standing on the box's top edge, near the left or right end.
func _portrait(on_left: bool) -> PortraitView:
	var view := PortraitView.new()
	view.anchor_left = 0.0 if on_left else 1.0
	view.anchor_right = view.anchor_left
	view.anchor_top = 1.0
	view.anchor_bottom = 1.0
	var x := 140.0 if on_left else -140.0 - PortraitView.SIZE.x
	view.offset_left = x
	view.offset_right = x + PortraitView.SIZE.x
	view.offset_top = -BOX_HEIGHT - 26.0 - PortraitView.SIZE.y  # standing just above the box
	view.offset_bottom = view.offset_top + PortraitView.SIZE.y
	_root.add_child(view)
	return view
