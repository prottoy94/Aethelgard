class_name TitleScreen
extends Control
## The title screen (FR-UI-05): Continue (the latest save), New Game, Load, Options and Quit over a painted Elderroot
## dusk, with the owner's song *Sunlight on Ancient Stone* (FR-AUD-12).
## Started with any test option (`-- --spawn=…`, `--region=…`, `--open=…`, `--benchmark=…` …) it goes straight into
## a new game, with saving off unless `--saves` is given, so quick test runs never touch real saves. `--title` keeps
## the title screen (e.g. `-- --title --benchmark=<dir>`).

const PARCHMENT := Color("f3e9d2")
const GOLD := Color("e8c06a")
const INK := Color("3b2a1e")

var _continue: Button
var _new_game: Button
var _continue_info: Label
var _confirm_new := false
var _load_menu: SaveMenu
var _options: OptionsMenu


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not "--title" in args:
		_quick_start.call_deferred(args)
		return
	_build()
	_refresh()
	AudioManager.set_combat_layer(&"")
	AudioManager.play_ambience(&"")
	AudioManager.play_weather(&"")
	AudioManager.play_music(&"mus_title")  # the owner's song, sung by Aurelia (FR-AUD-12)
	if "--benchmark" in "".join(args):
		add_child(PerfOverlay.new())


func continue_game() -> void:
	var slot := SaveManager.latest_slot()
	if slot != &"" and not SaveManager.load_slot(slot):
		_continue_info.text = SaveManager.last_error


## Starts over. If there is an autosave, asks once first (the new game's first autosave replaces it).
func new_game() -> void:
	if SaveManager.has_slot(SaveManager.AUTO) and not _confirm_new:
		_confirm_new = true
		_new_game.text = "Start over?  (replaces the autosave)"
		return
	SaveManager.start_new_game()


func _quick_start(args: PackedStringArray) -> void:
	SaveManager.writes_enabled = "--saves" in args
	SceneLoader.autosave_on_arrival = SaveManager.writes_enabled
	var region := SaveManager.NEW_GAME_REGION
	for arg in args:
		if arg.begins_with("--region="):
			region = StringName(arg.trim_prefix("--region="))
	SaveManager.start_new_game(region, &"")


func _refresh() -> void:
	var slot := SaveManager.latest_slot()
	_continue.disabled = slot == &""
	var info := SaveManager.slot_info(slot) if slot != &"" else {}
	_continue_info.text = "%s · %s · %s" % [SaveManager.slot_name(slot), info["region"], info["clock"]] \
			if not info.is_empty() else "No saved game yet."
	(_continue if not _continue.disabled else _new_game).grab_focus.call_deferred()


func _build() -> void:
	var background := TitleBackground.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	column.offset_left = 160.0
	column.offset_top = -300.0
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var title := Label.new()
	title.text = "Aethelgard"
	title.add_theme_font_size_override("font_size", 112)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.16))
	title.add_theme_constant_override("outline_size", 18)
	column.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	column.add_child(gap)
	_continue = _menu_button("Continue", continue_game)
	column.add_child(_continue)
	_continue_info = MenuScreen.make_label("", 17, PARCHMENT)
	_continue_info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_continue_info.add_theme_constant_override("outline_size", 6)
	column.add_child(_continue_info)
	_new_game = _menu_button("New Game", new_game)
	column.add_child(_new_game)
	column.add_child(_menu_button("Load Game", func() -> void: _load_menu.open()))
	column.add_child(_menu_button("Options", func() -> void: _options.open()))
	column.add_child(_menu_button("Quit", func() -> void: get_tree().quit()))
	var build := MenuScreen.make_label("Elderroot test build · Phase 6", 15, Color(1, 1, 1, 0.55))
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	build.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	build.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build.offset_right = -24.0
	build.offset_bottom = -16.0
	add_child(build)
	_load_menu = SaveMenu.new()
	_load_menu.title_mode = true
	add_child(_load_menu)
	_options = OptionsMenu.new()
	add_child(_options)


func _menu_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 56)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	MenuScreen.style_button(button, 24)
	button.pressed.connect(func() -> void: action.call())
	return button
