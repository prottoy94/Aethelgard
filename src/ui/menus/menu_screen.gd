class_name MenuScreen
extends CanvasLayer
## Base for the book-style menus (FR-UI-03; GAME_DESIGN.md §13: parchment with gold trim). Pauses the game while
## open; Esc, B or the menu key close it. Subclasses fill `body` in _build_body() and redraw it in refresh().
## GameMenu can give a screen a row of page tabs: Q/R (D-pad left/right) turn the page.

signal opened
signal closed

const PANEL_SIZE := Vector2(1180, 720)
const BACKDROP := Color(0.03, 0.02, 0.06, 0.72)
const PARCHMENT := Color("f3e9d2")
const INK := Color("3b2a1e")
const GOLD := Color("b8862e")
const WARN := Color("a8322a")
const GOOD := Color("3f7a32")

var body: VBoxContainer
var _root: Control
var _title: Label
var _tabs: HBoxContainer
var _footer: Label
var _tab_pick: Callable
var _tab_index := 0
var _tab_count := 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	_build_body()
	_root.visible = false


## The heading shown at the top. Override.
func title() -> String:
	return "Menu"


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_title.text = title()
	_root.visible = true
	refresh()
	get_tree().paused = true
	AudioManager.play(&"ui_menu_open")
	opened.emit()


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	AudioManager.play(&"ui_menu_close")
	closed.emit()


## Shows page tabs (used by GameMenu). Picking page i calls `on_pick(i)`.
func set_tabs(titles: PackedStringArray, current: int, on_pick: Callable) -> void:
	_tab_pick = on_pick
	_tab_index = current
	_tab_count = titles.size()
	for child in _tabs.get_children():
		child.queue_free()
	for i in titles.size():
		var tab := Button.new()
		tab.text = titles[i]
		tab.toggle_mode = true
		tab.button_pressed = i == current
		style_button(tab, 20)
		tab.pressed.connect(on_pick.bind(i))
		_tabs.add_child(tab)
	_footer.text = "Q / R: turn the page     Esc: close"


## Rebuilds the contents from the current game state. Override.
func refresh() -> void:
	pass


## Keeps keyboard/gamepad focus inside the menu when lists are rebuilt (the old buttons are being freed):
## moves it to `preferred`, or the first button. Leaves it alone while a live, visible control has it.
func keep_focus(preferred: Control) -> void:
	if not is_open():
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused and not focused.is_queued_for_deletion() and focused.is_visible_in_tree():
		return
	var target := preferred if preferred else _first_button(body)
	if target:
		target.grab_focus.call_deferred()


static func _first_button(node: Node) -> Button:
	for child in node.get_children():
		var button := child as Button
		if button and not button.is_queued_for_deletion() and button.visible and not button.disabled:
			return child
		var found := _first_button(child)
		if found:
			return found
	return null


## Fills `body`. Override.
func _build_body() -> void:
	pass


## Extra keys while open. Return true if the event was used. Override.
func _menu_input(_event: InputEvent) -> bool:
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or Cutscene.is_asking():
		return  # (typing a name: keys belong to the text box)
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		close()
		get_viewport().set_input_as_handled()
	elif _tab_count > 1 and (event.is_action_pressed("camera_rotate_left") or event.is_action_pressed("camera_rotate_right")):
		var step := -1 if event.is_action_pressed("camera_rotate_left") else 1
		AudioManager.play(&"ui_tab")
		_tab_pick.call(wrapi(_tab_index + step, 0, _tab_count))
		get_viewport().set_input_as_handled()
	elif _menu_input(event):
		get_viewport().set_input_as_handled()


func _build_frame() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = PANEL_SIZE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	_title = make_label(title(), 40, INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	_tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_tabs)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_footer = make_label("Esc: close", 15, INK.lightened(0.3))
	column.add_child(_footer)


# --- Shared look ---------------------------------------------------------------------------

## Parchment buttons with ink text; a pressed (chosen) button turns ink-dark with parchment text.
static func style_button(button: Button, font_size := 18) -> void:
	var looks := {
		"normal": PARCHMENT.darkened(0.08), "hover": PARCHMENT.darkened(0.16),
		"pressed": INK, "hover_pressed": INK.lightened(0.12), "focus": Color.TRANSPARENT,
		"disabled": PARCHMENT.darkened(0.04),
	}
	for state: String in looks:
		var box := StyleBoxFlat.new()
		box.bg_color = looks[state]
		box.set_corner_radius_all(6)
		box.set_content_margin_all(8)
		if state == "focus":
			box.border_color = GOLD
			box.set_border_width_all(2)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, PARCHMENT)
	button.add_theme_color_override("font_disabled_color", INK.lightened(0.5))
	button.pressed.connect(func() -> void: AudioManager.play(&"ui_confirm"))
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			AudioManager.play(&"ui_hover"))
	button.focus_entered.connect(func() -> void: AudioManager.play(&"ui_hover"))


static func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
