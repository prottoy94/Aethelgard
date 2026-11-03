class_name CraftingMenu
extends MenuScreen
## Crafting at a workbench or crafting kit (FR-ITM-04, FR-ITM-05): every recipe the station can make, with recipes
## not found yet shown as "???", the ingredients you have against what is needed, and a Craft button.
## Opened by CraftingStation.used (the level connects it to open_station).

var station := RecipeData.Station.WORKBENCH
var selected: RecipeData
var _list: VBoxContainer
var _details: Label
var _ingredients: VBoxContainer
var _craft_button: Button
var _message: Label


func title() -> String:
	return RecipeData.STATION_NAMES[station]


func open_station(at: RecipeData.Station) -> void:
	station = at
	var recipes := Inventory.recipes_for(station)
	if selected == null or not selected in recipes:
		selected = recipes[0] if not recipes.is_empty() else null
	_message.text = ""
	open()


func select(recipe: RecipeData) -> void:
	selected = recipe
	_message.text = ""
	refresh()


## Crafts the chosen recipe once. Returns true if something was made.
func craft() -> bool:
	if selected == null or not Inventory.craft(selected, station):
		return false
	var output := selected.output
	if output is EquipmentData:
		_message.text = "Made the %s! Equip it from the Inventory (Tab)." % output.display_name
	else:
		_message.text = "Made a %s. You have %d." % [output.display_name, Inventory.count(output.id)]
	refresh()
	return true


func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var chosen: Button
	for recipe in Inventory.recipes_for(station):
		var known := Inventory.knows_recipe(recipe.id)
		var button := Button.new()
		button.text = recipe.display_name() if known else "???"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = recipe == selected
		style_button(button)
		button.pressed.connect(select.bind(recipe))
		_list.add_child(button)
		if recipe == selected:
			chosen = button
	keep_focus(chosen)
	for child in _ingredients.get_children():
		child.queue_free()
	_craft_button.visible = false
	if selected == null:
		_details.text = "No recipes for this station yet."
		return
	if not Inventory.knows_recipe(selected.id):
		_details.text = "???\n\nYou haven't found this recipe yet. Recipes are found around the world, given by " + \
				"people you help, or earned from bosses."
		return
	var output := selected.output
	var lines := PackedStringArray([output.display_name, output.description])
	var effects := output.effect_lines()
	if not effects.is_empty():
		lines.append("")
		lines.append_array(effects)
	_details.text = "\n".join(lines)
	_ingredients.add_child(make_label("Ingredients", 19, GOLD.darkened(0.25)))
	for i in selected.inputs.size():
		var item := selected.inputs[i]
		var have := Inventory.count(item.id)
		var need := selected.needed(i)
		_ingredients.add_child(make_label("%d × %s   (you have %d)" % [need, item.display_name, have], 18,
				INK if have >= need else WARN))
	_craft_button.visible = true
	_craft_button.disabled = not Inventory.can_craft(selected, station)
	_craft_button.text = "Craft" if not _craft_button.disabled else "Not enough materials"


func _build_body() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(420, 0)
	_list.add_theme_constant_override("separation", 4)
	columns.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	_details = make_label("", 18, INK)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_details)
	_ingredients = VBoxContainer.new()
	right.add_child(_ingredients)
	_craft_button = Button.new()
	_craft_button.custom_minimum_size = Vector2(240, 46)
	_craft_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_button(_craft_button, 19)
	_craft_button.pressed.connect(craft)
	right.add_child(_craft_button)
	_message = make_label("", 17, GOOD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_message)
