class_name OptionsMenu
extends MenuScreen
## The Options page (FR-UI-03 Settings, FR-DLG-11, NFR-AUD-04): volume per sound group, dialogue text speed,
## auto-advance and the graphics preset. Changes apply at once and are saved by Settings.

const VOLUME_LABELS := {&"Master": "Volume", &"Music": "Music", &"Ambience": "Ambience", &"SFX": "Sound effects",
		&"UI": "Menu sounds"}

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
	for bus: StringName in VOLUME_LABELS:
		_add_slider(VOLUME_LABELS[bus], bus)
	keep_focus(null)


func _add_slider(label: String, bus: StringName) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := make_label(label, 20, INK)
	name_label.custom_minimum_size = Vector2(300, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.volumes.get(bus, 1.0)
	slider.custom_minimum_size = Vector2(400, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var percent := make_label("%d%%" % roundi(slider.value * 100.0), 18, INK)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_volume(bus, value)
		percent.text = "%d%%" % roundi(value * 100.0)
		AudioManager.play(&"ui_hover"))
	row.add_child(slider)
	row.add_child(percent)
	_rows.add_child(row)


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
