class_name OptionsMenu
extends MenuScreen
## The Options page (FR-UI-03 Settings, FR-DLG-11): dialogue text speed, auto-advance and the graphics preset.
## Changes apply at once and are saved by Settings. Volumes and key bindings join with the audio work.

var _rows: VBoxContainer


func title() -> String:
	return "Options"


func refresh() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()
	_add_row("Text speed", DialogueTuning.SPEED_NAMES, Settings.text_speed, Settings.set_text_speed)
	_add_row("Auto-advance dialogue", ["Off", "On"], 1 if Settings.auto_advance else 0,
			func(i: int) -> void: Settings.set_auto_advance(i == 1))
	var presets := Settings.get_graphics_presets()
	var names: Array[String] = []
	var current := 0
	for i in presets.size():
		names.append(presets[i].display_name)
		if Settings.graphics and presets[i].id == Settings.graphics.id:
			current = i
	_add_row("Graphics", names, current, func(i: int) -> void: Settings.set_graphics_preset(presets[i].id))
	keep_focus(null)


func _add_row(label: String, choices: Array, current: int, on_pick: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := make_label(label, 20, INK)
	name_label.custom_minimum_size = Vector2(300, 0)
	row.add_child(name_label)
	for i in choices.size():
		var button := Button.new()
		button.text = choices[i]
		button.toggle_mode = true
		button.button_pressed = i == current
		button.custom_minimum_size = Vector2(130, 42)
		style_button(button)
		button.pressed.connect(func() -> void:
			on_pick.call(i)
			refresh())
		row.add_child(button)
	_rows.add_child(row)


func _build_body() -> void:
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 16)
	body.add_child(_rows)
