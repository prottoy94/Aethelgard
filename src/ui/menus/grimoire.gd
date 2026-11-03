class_name Grimoire
extends MenuScreen
## Aurelia's spellbook (FR-MAG-05, FR-UI-03): rank and Magic Power, learned spells with mastery, unread tomes,
## and the 4-slot loadout. Choose a spell, then a slot (click or press 1–4). A page of the Tab menu (GameMenu).

const ROMAN: PackedStringArray = ["", "I", "II", "III", "IV", "V"]

var selected: StringName = &""
var _rank_label: Label
var _spell_list: VBoxContainer
var _details: Label
var _slot_buttons: Array[Button] = []
var _tomes_label: Label


func _ready() -> void:
	super()
	PlayerData.loadout_changed.connect(refresh)
	PlayerData.spell_learned.connect(func(_spell: SpellData) -> void: refresh())
	PlayerData.mastery_changed.connect(func(_id: StringName, _level: int) -> void: refresh())


func title() -> String:
	return "Grimoire"


func open() -> void:
	if selected == &"":
		selected = PlayerData.loadout[0]
	super()


func _menu_input(event: InputEvent) -> bool:
	for slot in PlayerData.SLOTS:
		if event.is_action_pressed(Player.SPELL_ACTIONS[slot]):
			assign(slot)
			return true
	return false


## Puts the selected spell in `slot`.
func assign(slot: int) -> void:
	if selected != &"":
		PlayerData.set_loadout_slot(slot, selected)


func select(id: StringName) -> void:
	selected = id
	refresh()


func refresh() -> void:
	if _rank_label == null:
		return
	var progression := PlayerData.PROGRESSION
	var next := progression.next_threshold(PlayerData.rank)
	_rank_label.text = "Arcane Rank  %s     Magic Power %d%s" % [PlayerData.rank_label(), PlayerData.magic_power,
			("   (next rank at %d)" % next) if next > 0 else "   (highest rank)"]
	for child in _spell_list.get_children():
		child.queue_free()
	var chosen: Button
	for spell in PlayerData.learned_spells():
		var button := Button.new()
		var level := PlayerData.mastery_level(spell.id)
		button.text = "%s   ·   %s   ·   Mastery %s" % [spell.display_name, _element_name(spell.element), ROMAN[level]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = spell.id == selected
		style_button(button)
		button.pressed.connect(select.bind(spell.id))
		_spell_list.add_child(button)
		if spell.id == selected:
			chosen = button
	keep_focus(chosen)
	var spell := PlayerData.LIBRARY.find(selected)
	if spell:
		var mods := PlayerData.modifiers_for(spell)
		var level := PlayerData.mastery_level(spell.id)
		var mastery_line := "Mastery %s  (%d%% to %s)" % [ROMAN[level], roundi(PlayerData.mastery_progress(spell.id) * 100.0),
				ROMAN[level + 1]] if level < progression.max_mastery else "Mastery V (complete)"
		_details.text = "%s\n%s element\n\n%s\n\nStamina %d   ·   Cooldown %.1f s%s\n%s\nAdds %d Magic Power" % [
			spell.display_name, _element_name(spell.element), spell.description,
			roundi(spell.stamina_cost * mods.cost), spell.cooldown * mods.cooldown,
			("   ·   Power %d" % roundi(spell.base_damage * mods.damage)) if spell.base_damage > 0.0 else "",
			mastery_line, roundi(progression.spell_power(spell, level))]
	else:
		_details.text = "Choose a spell."
	var loadout := PlayerData.loadout_spells()
	for i in _slot_buttons.size():
		_slot_buttons[i].text = "%d   %s" % [i + 1, loadout[i].display_name if loadout[i] else "(empty)"]
	var tome_names: Array[String] = []
	for id in PlayerData.tomes:
		var tome := PlayerData.LIBRARY.find(id)
		if tome:
			tome_names.append("%s (needs Magic Power %d)" % [tome.display_name, tome.required_magic_power] \
					if PlayerData.magic_power < tome.required_magic_power else tome.display_name)
	_tomes_label.text = "Unread tomes: %s.  Rest at a Lantern Shrine to read them." % ", ".join(tome_names) \
			if not tome_names.is_empty() else "No unread tomes."


func _build_body() -> void:
	_rank_label = make_label("", 22, GOLD.darkened(0.2))
	body.add_child(_rank_label)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	_spell_list = VBoxContainer.new()
	_spell_list.custom_minimum_size = Vector2(520, 0)
	columns.add_child(_spell_list)
	_details = make_label("", 19, INK)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(_details)
	body.add_child(make_label("Loadout: choose a spell, then a slot (or press 1–4)", 18, INK))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	body.add_child(slots)
	for i in PlayerData.SLOTS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 44)
		style_button(button)
		button.pressed.connect(assign.bind(i))
		slots.add_child(button)
		_slot_buttons.append(button)
	_tomes_label = make_label("", 17, INK)
	body.add_child(_tomes_label)


static func _element_name(element: Elements.Type) -> String:
	return String(Elements.Type.find_key(element)).capitalize()
