class_name InventoryMenu
extends MenuScreen
## The Inventory page of the Tab menu (FR-ITM-01, FR-ITM-02, FR-PLY-07): the bag sorted by category (with unread
## spell tomes), the 5 equipment slots, and Aurelia's current stats. Choose an item to read it, then Use or Equip.
## With equipment chosen, clicking a matching slot puts it there. Call bind(player) once the player exists.

var player: Player
var selected: ItemData
var selected_slot := -1  ## an equipment slot chosen instead of a bag item
var _list: VBoxContainer
var _details: Label
var _action: Button
var _message: Label
var _slot_buttons: Array[Button] = []
var _stats: Label


func _ready() -> void:
	super()
	Inventory.item_added.connect(func(_item: ItemData, _amount: int) -> void: _refresh_if_open())
	Inventory.item_removed.connect(func(_item: ItemData, _amount: int) -> void: _refresh_if_open())
	Inventory.equipment_changed.connect(_refresh_if_open)


func title() -> String:
	return "Inventory"


func bind(player_: Player) -> void:
	player = player_


func open() -> void:
	_message.text = ""
	super()


## Chooses a bag item.
func select(item: ItemData) -> void:
	selected = item
	selected_slot = -1
	_message.text = ""
	refresh()


## Clicking a slot: equips the chosen gear there if it fits, otherwise shows what is worn in it.
func pick_slot(slot: int) -> void:
	var gear := selected as EquipmentData
	if selected_slot == -1 and gear and gear.slot == Inventory.SLOT_TYPES[slot] and Inventory.has(gear.id):
		_equip(gear, slot)
		return
	selected_slot = slot
	selected = Inventory.equipped(slot)
	_message.text = ""
	refresh()


## Use / Equip / Unequip, depending on what is chosen.
func act() -> void:
	if selected == null:
		return
	if selected_slot != -1:
		if Inventory.unequip(selected_slot):
			_message.text = "Took off the %s." % selected.display_name
			selected_slot = -1
		refresh()
	elif DragonManager.is_food(selected):
		var treat := selected as ConsumableData
		var reason := DragonManager.feed(treat)
		if reason == &"":
			_message.text = "%s gobbled the %s!" % [DragonManager.display_name(), treat.display_name]
		else:
			AudioManager.play(&"ui_error")
			_message.text = {&"no_dragon": "Only a dragon would eat this.",
					&"knocked_out": "%s is knocked out. Let it rest first." % DragonManager.display_name(),
					&"full": "%s is full." % DragonManager.display_name()}.get(reason, "That wouldn't help right now.")
		refresh()
	elif selected is ConsumableData:
		var item := selected as ConsumableData
		if player and player.use_item(item):
			_message.text = "Used a %s." % item.display_name
		else:
			AudioManager.play(&"ui_error")
			_message.text = "That wouldn't help right now."
		refresh()
	elif selected is EquipmentData:
		_equip(selected as EquipmentData, -1)


func refresh() -> void:
	if _list == null:
		return
	if selected and selected_slot == -1 and not Inventory.has(selected.id):
		selected = null  # used up or equipped
	_rebuild_list()
	_refresh_details()
	for slot in _slot_buttons.size():
		var worn := Inventory.equipped(slot)
		_slot_buttons[slot].text = "%s:  %s" % [Inventory.SLOT_NAMES[slot], worn.display_name if worn else "(empty)"]
		_slot_buttons[slot].button_pressed = slot == selected_slot
	_stats.text = _stats_text()


func _refresh_if_open() -> void:
	if is_open():
		refresh()


func _equip(gear: EquipmentData, slot: int) -> void:
	if Inventory.equip(gear, slot):
		AudioManager.play(&"ui_equip")
		_message.text = "Equipped the %s." % gear.display_name
		selected = null
	else:
		_message.text = "That doesn't fit there."
	refresh()


func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var chosen: Button
	var category := -1
	for item in Inventory.bag_items():
		if item.category != category:
			category = item.category
			_list.add_child(make_label(ItemData.CATEGORY_NAMES[category], 17, GOLD.darkened(0.25)))
		var button := Button.new()
		button.text = "%s   ×%d" % [item.display_name, Inventory.count(item.id)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = item == selected and selected_slot == -1
		style_button(button, 17)
		button.pressed.connect(select.bind(item))
		_list.add_child(button)
		if item == selected and selected_slot == -1:
			chosen = button
	if not PlayerData.tomes.is_empty():
		_list.add_child(make_label("Spell tomes (read at a Lantern Shrine)", 17, GOLD.darkened(0.25)))
		for id in PlayerData.tomes:
			var spell := PlayerData.LIBRARY.find(id)
			if spell:
				_list.add_child(make_label("   %s tome" % spell.display_name, 17, INK))
	if _list.get_child_count() == 0:
		_list.add_child(make_label("Your bag is empty.", 17, INK))
	keep_focus(chosen)


func _refresh_details() -> void:
	if selected == null:
		_details.text = "Choose an item." if selected_slot == -1 else "Nothing is worn here."
		_action.visible = false
		return
	var lines := PackedStringArray([selected.display_name, ItemData.CATEGORY_NAMES[selected.category], "",
			selected.description])
	var effects := selected.effect_lines()
	if not effects.is_empty():
		lines.append("")
		lines.append_array(effects)
	if selected is EquipmentData:
		lines.append("")
		lines.append("Slot: %s" % ("Accessory (3 slots)" if (selected as EquipmentData).slot == EquipmentData.Slot.ACCESSORY \
				else Inventory.SLOT_NAMES[(selected as EquipmentData).slot]))
	_details.text = "\n".join(lines)
	_action.visible = true
	if selected_slot != -1:
		_action.text = "Unequip"
	elif DragonManager.is_food(selected):
		_action.text = "Feed %s" % DragonManager.display_name() if DragonManager.is_hatched() else "Feed"
	elif selected is ConsumableData:
		_action.text = "Use"
	elif selected is EquipmentData:
		_action.text = "Equip"
	else:
		_action.visible = false  # materials are for crafting


func _stats_text() -> String:
	var lines := PackedStringArray()
	if player:
		lines.append("HP  %d / %d" % [roundi(player.health.current), roundi(player.health.max_health)])
		lines.append("Stamina  %d / %d" % [roundi(player.stamina.current), roundi(player.stamina.max_stamina)])
	lines.append("Magic Power  %d   (%s)" % [PlayerData.magic_power, PlayerData.rank_label()])
	var gear := Inventory.gear_bonus()
	if player:
		lines.append("Defense  %d" % roundi(player.health.defense))
	lines.append("Move speed  %d%%" % roundi(100.0 * (1.0 + gear.move_speed)))
	if gear.spell_cooldown > 0.0:
		lines.append("Spell cooldowns  −%d%%" % roundi(gear.spell_cooldown * 100.0))
	for element: Elements.Type in gear.resistances:
		lines.append("%s damage taken  −%d%%" % [String(Elements.Type.find_key(element)).capitalize(),
				roundi(gear.resistances[element] * 100.0)])
	return "\n".join(lines)


func _build_body() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	columns.add_child(middle)
	_details = make_label("", 18, INK)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_details)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(160, 44)
	_action.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_button(_action)
	_action.pressed.connect(act)
	middle.add_child(_action)
	_message = make_label("", 17, GOOD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_message)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(330, 0)
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	right.add_child(make_label("Equipped", 20, GOLD.darkened(0.25)))
	for slot in Inventory.SLOT_TYPES.size():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		style_button(button, 16)
		button.pressed.connect(pick_slot.bind(slot))
		right.add_child(button)
		_slot_buttons.append(button)
	right.add_child(make_label("", 8, INK))
	right.add_child(make_label("Aurelia", 20, GOLD.darkened(0.25)))
	_stats = make_label("", 17, INK)
	right.add_child(_stats)
