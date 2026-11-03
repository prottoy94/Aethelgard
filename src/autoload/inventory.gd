extends Node
## Aurelia's items (FR-ITM-01): stacks by item id, the 5 equipment slots (FR-ITM-02: staff, cloak, 3 accessories),
## known recipes (FR-ITM-05) and crafting (FR-ITM-04). Equipped items leave the bag while worn.
## Saved by SaveManager through to_dict() / from_dict(), by id.

signal item_added(item: ItemData, amount: int)
signal item_removed(item: ItemData, amount: int)
signal equipment_changed
signal recipe_learned(recipe: RecipeData)
signal item_crafted(recipe: RecipeData)

const LIBRARY: ItemLibrary = preload("res://data/items/item_library.tres")
const NEW_GAME: NewGameItems = preload("res://data/items/new_game_items.tres")
const SLOT_TYPES: Array[EquipmentData.Slot] = [
	EquipmentData.Slot.STAFF, EquipmentData.Slot.CLOAK,
	EquipmentData.Slot.ACCESSORY, EquipmentData.Slot.ACCESSORY, EquipmentData.Slot.ACCESSORY,
]
const SLOT_NAMES: Array[String] = ["Staff", "Cloak", "Accessory 1", "Accessory 2", "Accessory 3"]

## item id → amount in the bag
var counts: Dictionary[StringName, int] = {}
## item id per equipment slot (&"" = empty), in SLOT_TYPES order
var equipment: Array[StringName] = [&"", &"", &"", &"", &""]
var recipes: Array[StringName] = []
## False until a new game or a save has filled the inventory.
var started := false


## New game: the starting items, gear and recipes.
func reset(kit: NewGameItems = NEW_GAME) -> void:
	counts.clear()
	equipment = [&"", &"", &"", &"", &""]
	recipes.clear()
	for item in kit.items:
		counts[item.id] = counts.get(item.id, 0) + 1
	for item in kit.equipment:
		equipment[_best_slot(item)] = item.id
	for recipe in kit.recipes:
		recipes.append(recipe.id)
	started = true
	equipment_changed.emit()


func count(id: StringName) -> int:
	return counts.get(id, 0)


func has(id: StringName, amount := 1) -> bool:
	return count(id) >= amount


## Adds up to `amount` (stacks stop at the item's max_stack). Returns how many were added.
func add(item: ItemData, amount := 1) -> int:
	var added := clampi(item.max_stack - count(item.id), 0, amount)
	if added > 0:
		counts[item.id] = count(item.id) + added
		item_added.emit(item, added)
	return added


## Takes `amount` out of the bag. Returns false (and takes nothing) if there aren't enough.
func remove(id: StringName, amount := 1) -> bool:
	if amount <= 0 or not has(id, amount):
		return false
	counts[id] -= amount
	if counts[id] == 0:
		counts.erase(id)
	item_removed.emit(LIBRARY.find_item(id), amount)
	return true


## Items in the bag, sorted by category, then name (FR-ITM-01).
func bag_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for id in counts:
		var item := LIBRARY.find_item(id)
		if item:
			result.append(item)
	result.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return a.display_name < b.display_name if a.category == b.category else a.category < b.category)
	return result


# --- Equipment ---------------------------------------------------------------------------------

func equipped(slot: int) -> EquipmentData:
	return LIBRARY.find_item(equipment[slot]) as EquipmentData if equipment[slot] != &"" else null


func equipped_items() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	for slot in equipment.size():
		var item := equipped(slot)
		if item:
			result.append(item)
	return result


func is_equipped(id: StringName) -> bool:
	return id in equipment


## Wears `item` in `slot` (-1 = the natural slot: the staff/cloak slot, or the first free accessory slot).
## It comes out of the bag and whatever was in the slot goes back. An accessory already worn moves (swaps)
## instead, so the same accessory can't count twice. Returns false if the slot doesn't fit or none is owned.
func equip(item: EquipmentData, slot := -1) -> bool:
	if slot == -1:
		slot = _best_slot(item)
	if slot < 0 or slot >= equipment.size() or SLOT_TYPES[slot] != item.slot:
		return false
	var worn_in := equipment.find(item.id)
	if worn_in == slot:
		return true
	if worn_in != -1:
		equipment[worn_in] = equipment[slot]
	else:
		if not remove(item.id):
			return false
		_return_to_bag(equipment[slot])
	equipment[slot] = item.id
	equipment_changed.emit()
	return true


func unequip(slot: int) -> bool:
	if equipment[slot] == &"":
		return false
	_return_to_bag(equipment[slot])
	equipment[slot] = &""
	equipment_changed.emit()
	return true


func gear_bonus() -> GearBonus:
	return GearBonus.total(equipped_items())


# --- Recipes & crafting ------------------------------------------------------------------------

func knows_recipe(id: StringName) -> bool:
	return id in recipes


func learn_recipe(recipe: RecipeData) -> bool:
	if knows_recipe(recipe.id):
		return false
	recipes.append(recipe.id)
	recipe_learned.emit(recipe)
	return true


## Known recipes plus "not found yet" ones for a station, in library order.
func recipes_for(station: RecipeData.Station) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in LIBRARY.recipes:
		if recipe.can_make_at(station):
			result.append(recipe)
	return result


func can_craft(recipe: RecipeData, at: RecipeData.Station) -> bool:
	if not knows_recipe(recipe.id) or not recipe.can_make_at(at):
		return false
	if count(recipe.output.id) + recipe.output_count > recipe.output.max_stack:
		return false
	for i in recipe.inputs.size():
		if not has(recipe.inputs[i].id, recipe.needed(i)):
			return false
	return true


## Uses up the inputs and adds the output (FR-ITM-04). Returns false (changing nothing) if it can't be made.
func craft(recipe: RecipeData, at: RecipeData.Station) -> bool:
	if not can_craft(recipe, at):
		return false
	for i in recipe.inputs.size():
		remove(recipe.inputs[i].id, recipe.needed(i))
	add(recipe.output, recipe.output_count)
	item_crafted.emit(recipe)
	EventBus.item_crafted.emit(recipe.output.id)
	return true


# --- Saving ------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	var items := {}
	var ids: Array[StringName] = []
	ids.assign(counts.keys())
	ids.sort()
	for id in ids:
		items[String(id)] = counts[id]
	var known: Array[String] = []
	for id in recipes:
		known.append(String(id))
	known.sort()
	return {
		"items": items,
		"equipment": equipment.map(func(id: StringName) -> String: return String(id)),
		"recipes": known,
	}


## Restores a saved inventory. Ids no longer in the game are skipped.
func from_dict(data: Dictionary) -> void:
	counts.clear()
	var items: Dictionary = data.get("items", {})
	for id: Variant in items:
		if LIBRARY.find_item(StringName(str(id))) and int(items[id]) > 0:
			counts[StringName(str(id))] = int(items[id])
	var slots: Array = data.get("equipment", [])
	for i in equipment.size():
		var id := StringName(str(slots[i])) if i < slots.size() else &""
		var item := LIBRARY.find_item(id) as EquipmentData
		equipment[i] = id if item and item.slot == SLOT_TYPES[i] else &""
	recipes.clear()
	for id: Variant in data.get("recipes", []):
		if LIBRARY.find_recipe(StringName(str(id))):
			recipes.append(StringName(str(id)))
	started = true
	equipment_changed.emit()


func _best_slot(item: EquipmentData) -> int:
	var first := SLOT_TYPES.find(item.slot)
	if item.slot != EquipmentData.Slot.ACCESSORY:
		return first
	for slot in range(first, equipment.size()):
		if equipment[slot] == &"":
			return slot
	return first


func _return_to_bag(id: StringName) -> void:
	var item := LIBRARY.find_item(id)
	if item:
		add(item)
