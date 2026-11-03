class_name Hud
extends CanvasLayer
## In-game HUD (FR-UI-01): health and stamina bars (with the Exhausted warning) and the 4 spell slots.
## Call bind(player) once the player exists.

const BAR_SIZE := Vector2(320, 20)
const HP_COLOR := Color("e2557a")
const STAMINA_COLOR := Color("6fd3e8")
const FAIL_COLOR := Color("ff4a4a")
const BAR_BACK := Color(0.08, 0.06, 0.1, 0.8)
const FAIL_FLASH_TIME := 0.3
const SLOT_GAP := 10

var player: Player
var _hp_bar: Control
var _stamina_bar: Control
var _exhausted_label: Label
var _slots: Array[SpellSlot] = []
var _fail_flash := 0.0
var _time := 0.0


func _ready() -> void:
	layer = 10
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(24, 24)
	top_left.add_theme_constant_override("separation", 6)
	add_child(top_left)
	_hp_bar = _make_bar(func() -> Array: return [player.health.current, player.health.max_health, HP_COLOR, "HP"])
	top_left.add_child(_hp_bar)
	_stamina_bar = _make_bar(func() -> Array:
		var color := FAIL_COLOR.lerp(STAMINA_COLOR, 1.0 - _fail_flash / FAIL_FLASH_TIME)
		return [player.stamina.current, player.stamina.max_stamina, color, "Stamina"])
	top_left.add_child(_stamina_bar)
	_exhausted_label = Label.new()
	_exhausted_label.text = "EXHAUSTED"
	_exhausted_label.add_theme_color_override("font_color", FAIL_COLOR)
	_exhausted_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_exhausted_label.add_theme_constant_override("outline_size", 6)
	_exhausted_label.visible = false
	top_left.add_child(_exhausted_label)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", SLOT_GAP)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.offset_top = -SpellSlot.SIZE.y - 24
	bottom.offset_bottom = -24
	add_child(bottom)
	for i in SpellCaster.SLOT_COUNT:
		var slot := SpellSlot.new()
		bottom.add_child(slot)
		_slots.append(slot)


func bind(player_: Player) -> void:
	player = player_
	player.stamina.spend_failed.connect(func() -> void: _fail_flash = FAIL_FLASH_TIME)
	for i in _slots.size():
		_slots[i].setup(player.spell_caster.loadout[i], player.spell_caster.cooldowns[i], str(i + 1))


func _process(delta: float) -> void:
	if player == null:
		return
	_time += delta
	_fail_flash = maxf(_fail_flash - delta, 0.0)
	_exhausted_label.visible = player.stamina.exhausted
	_exhausted_label.modulate.a = 0.55 + 0.45 * absf(sin(_time * 6.0))
	for i in _slots.size():
		var reason := player.spell_caster.check(i)
		_slots[i].usable = reason == &"" or reason == &"cooldown" or reason == &"global"
	_hp_bar.queue_redraw()
	_stamina_bar.queue_redraw()


## A bar that asks `values` for [current, maximum, colour, label] every redraw.
func _make_bar(values: Callable) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.draw.connect(func() -> void:
		if player == null:
			return
		var v: Array = values.call()
		var ratio := clampf(float(v[0]) / maxf(float(v[1]), 0.001), 0.0, 1.0)
		bar.draw_rect(Rect2(Vector2.ZERO, BAR_SIZE), BAR_BACK)
		bar.draw_rect(Rect2(Vector2(2, 2), Vector2((BAR_SIZE.x - 4) * ratio, BAR_SIZE.y - 4)), v[2])
		var font := bar.get_theme_default_font()
		bar.draw_string(font, Vector2(8, 15), "%s  %d / %d" % [v[3], roundi(float(v[0])), roundi(float(v[1]))],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE))
	return bar
