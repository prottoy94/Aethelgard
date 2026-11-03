class_name SaveMenu
extends MenuScreen
## The Save page (FR-SAV-02, FR-WLD-05): the autosave and 3 manual slots with where and when each was saved.
## Saving needs a Lantern Shrine nearby (GAME_DESIGN.md §12: shrines are where you save); loading and quitting to the
## title work anywhere. Esc opens this page during play. On the title screen (`title_mode`) it only loads.

const SAVE_RANGE := 4.0  ## m from a Lantern Shrine

var title_mode := false

var _rows: VBoxContainer
var _note: Label
var _message: Label
var _quit: Button


func title() -> String:
	return "Load Game" if title_mode else "Save"


func open() -> void:
	_message.text = ""
	super()


## True when Aurelia stands near a Lantern Shrine.
func can_save_here() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return false
	for node in get_tree().get_nodes_in_group(&"rest_point"):
		if (node as Node3D).global_position.distance_to(player.global_position) <= SAVE_RANGE:
			return true
	return false


func save_to(slot: StringName) -> bool:
	if not can_save_here():
		return false
	var ok := SaveManager.save_slot(slot)
	_message.text = "Saved to %s." % SaveManager.slot_name(slot) if ok else SaveManager.last_error
	refresh()
	return ok


func load_from(slot: StringName) -> void:
	close()
	if not SaveManager.load_slot(slot):
		open()
		_message.text = SaveManager.last_error


func quit_to_title() -> void:
	close()
	SceneLoader.go_to_title()


func refresh() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()
	var near_shrine := can_save_here()
	_note.text = "Rest by a Lantern Shrine to save. You can load or quit anywhere." if not near_shrine \
			else "You're by a Lantern Shrine: choose a slot to save."
	if title_mode:
		_note.text = "Choose a save to load."
	_quit.visible = not title_mode
	for slot in SaveManager.SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := SaveManager.slot_info(slot)
		var label := make_label("%s   —   %s" % [SaveManager.slot_name(slot), _describe(info)], 19, INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if slot != SaveManager.AUTO and not title_mode:
			var save_button := _button("Save", save_to.bind(slot))
			save_button.disabled = not near_shrine
			row.add_child(save_button)
		var load_button := _button("Load", load_from.bind(slot))
		load_button.disabled = info.is_empty()
		row.add_child(load_button)
		_rows.add_child(row)
	keep_focus(null)


static func _describe(info: Dictionary) -> String:
	if info.is_empty():
		return "empty"
	return "%s, %s  (played %s)  saved %s" % [info["region"], info["clock"], info["play_time"], info["saved_at"]]


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 40)
	style_button(button)
	button.pressed.connect(func() -> void: action.call())
	return button


func _build_body() -> void:
	_note = make_label("", 18, GOLD.darkened(0.25))
	body.add_child(_note)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	body.add_child(_rows)
	_message = make_label("", 17, GOOD)
	body.add_child(_message)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	_quit = _button("Quit to title", quit_to_title)
	_quit.custom_minimum_size = Vector2(200, 44)
	_quit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(_quit)
