class_name Hud
extends CanvasLayer
## In-game HUD (FR-UI-01): health and stamina bars (with the Exhausted warning), Arcane Rank badge with progress,
## status effect icons with timers, the 4 spell slots, a banner when Aurelia ranks up, and a feed of picked-up items.
## Call bind(player) once the player exists.

const BAR_SIZE := Vector2(320, 20)
const BAR_TEXT_SIZE := 14
const RANK_BAR_HEIGHT := 16.0
const HP_COLOR := Color("e2557a")
const STAMINA_COLOR := Color("6fd3e8")
const FAIL_COLOR := Color("ff4a4a")
const BAR_BACK := Color(0.08, 0.06, 0.1, 0.8)
const FAIL_FLASH_TIME := 0.3
const SLOT_GAP := 10
const RANK_COLOR := Color("ffd98a")
const BANNER_TIME := 3.5
const FEED_TIME := 3.0   ## s a "+2 Sunpetal" line stays
const FEED_LINES := 5

var player: Player
var _hp_bar: Control
var _stamina_bar: Control
var _exhausted_label: Label
var _slots: Array[SpellSlot] = []
var _fail_flash := 0.0
var _rank_label: Label
var _rank_bar: Control
var _status_row: HBoxContainer
var _banner: Label
var _banner_time := 0.0
var _feed: VBoxContainer
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
	_rank_label = _text("", 18, RANK_COLOR)
	top_left.add_child(_rank_label)
	_rank_bar = _make_bar(func() -> Array:
		var rank_floor: int = PlayerData.PROGRESSION.rank_thresholds[PlayerData.rank]
		var next: int = PlayerData.PROGRESSION.next_threshold(PlayerData.rank)
		if next < 0:
			return [1.0, 1.0, RANK_COLOR, "Magic Power"]
		return [PlayerData.magic_power - rank_floor, next - rank_floor, RANK_COLOR, "Next rank"])
	_rank_bar.custom_minimum_size = Vector2(BAR_SIZE.x, RANK_BAR_HEIGHT)
	top_left.add_child(_rank_bar)
	_status_row = HBoxContainer.new()
	_status_row.add_theme_constant_override("separation", 6)
	top_left.add_child(_status_row)
	_banner = _text("", 52, RANK_COLOR)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 140.0
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)

	_feed = VBoxContainer.new()
	_feed.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_feed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_feed.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_feed.offset_right = -32.0
	_feed.offset_bottom = -150.0
	_feed.alignment = BoxContainer.ALIGNMENT_END
	add_child(_feed)
	EventBus.item_collected.connect(_on_item_collected)

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
	_refresh_slots()
	_refresh_rank()
	PlayerData.loadout_changed.connect(_refresh_slots.call_deferred)
	PlayerData.magic_power_changed.connect(func(_magic_power: int) -> void: _refresh_rank())
	PlayerData.rank_changed.connect(func(rank: int, _previous: int) -> void:
		show_banner("RANK UP!   %s" % PlayerData.PROGRESSION.rank_label(rank)))


## A big message at the top of the screen (rank-ups, new spells).
func show_banner(text: String) -> void:
	_banner.text = text
	_banner_time = BANNER_TIME


func _refresh_slots() -> void:
	for i in _slots.size():
		_slots[i].setup(player.spell_caster.loadout[i], player.spell_caster.cooldowns[i], str(i + 1))
		_slots[i].cost_provider = player.spell_caster.effective_cost.bind(i)


func _refresh_rank() -> void:
	_rank_label.text = "%s     Magic Power %d" % [PlayerData.rank_label(), PlayerData.magic_power]
	_rank_bar.queue_redraw()


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
	_update_status_row()
	_update_feed(delta)
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time, 0.0, 1.0)


func _on_item_collected(item_id: StringName, amount: int) -> void:
	var item := Inventory.LIBRARY.find_item(item_id)
	if item == null:
		return
	var line := _text("+%d  %s" % [amount, item.display_name], 20, item.color.lightened(0.25))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.set_meta(&"time", FEED_TIME)
	_feed.add_child(line)
	if _feed.get_child_count() > FEED_LINES:
		_feed.get_child(0).free()


func _update_feed(delta: float) -> void:
	for line in _feed.get_children():
		var left: float = line.get_meta(&"time") - delta
		line.set_meta(&"time", left)
		(line as Label).modulate.a = clampf(left, 0.0, 1.0)
		if left <= 0.0:
			line.queue_free()


func _update_status_row() -> void:
	var effects := player.status_effects.effects
	while _status_row.get_child_count() < effects.size():
		_status_row.add_child(_text("", 15, Color.WHITE))
	var i := 0
	for id in effects:
		var chip := _status_row.get_child(i) as Label
		chip.visible = true
		chip.text = " %s %.1f " % [String(id).replace("_", " ").to_upper(), player.status_effects.time_left(id)]
		chip.add_theme_color_override("font_color", StatusEffectComponent.COLORS.get(id, Color.WHITE))
		i += 1
	for j in range(i, _status_row.get_child_count()):
		_status_row.get_child(j).visible = false


func _text(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label


## A bar that asks `values` for [current, maximum, colour, label] every redraw.
func _make_bar(values: Callable) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.draw.connect(func() -> void:
		if player == null:
			return
		var v: Array = values.call()
		var ratio := clampf(float(v[0]) / maxf(float(v[1]), 0.001), 0.0, 1.0)
		var size := bar.size
		bar.draw_rect(Rect2(Vector2.ZERO, size), BAR_BACK)
		bar.draw_rect(Rect2(Vector2(2, 2), Vector2((size.x - 4) * ratio, size.y - 4)), v[2])
		var font := bar.get_theme_default_font()
		var font_size := mini(BAR_TEXT_SIZE, roundi(size.y) - 4)
		var text := "%s  %d / %d" % [v[3], roundi(float(v[0])), roundi(float(v[1]))]
		var baseline := Vector2(8, (size.y + font_size) * 0.5 - 2.0)
		bar.draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color.BLACK)
		bar.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE))
	return bar
