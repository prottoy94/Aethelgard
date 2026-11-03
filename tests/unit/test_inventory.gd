extends GutTest
## Inventory, equipment, gear bonuses, recipes, crafting, loot tables and item data (FR-ITM-01…05, 07).

const SUNPETAL := preload("res://data/items/sunpetal.tres")
const IRON_ORE := preload("res://data/items/iron_ore.tres")
const LUMEN_CRYSTAL := preload("res://data/items/lumen_crystal.tres")
const EMBER_CINDER := preload("res://data/items/ember_cinder.tres")
const HEALING_POTION := preload("res://data/items/healing_potion.tres")
const AMULET := preload("res://data/items/lantern_heart_amulet.tres")
const RING := preload("res://data/items/ember_ward_ring.tres")
const CHARM := preload("res://data/items/swift_quill_charm.tres")
const STAFF := preload("res://data/items/apprentice_staff.tres")
const AMULET_RECIPE := preload("res://data/recipes/lantern_heart_amulet.tres")
const RING_RECIPE := preload("res://data/recipes/ember_ward_ring.tres")
const POTION_RECIPE := preload("res://data/recipes/healing_potion.tres")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")

const WORKBENCH := RecipeData.Station.WORKBENCH
const KIT := RecipeData.Station.KIT


func before_each() -> void:
	Inventory.reset()
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])


func test_new_game_kit() -> void:
	assert_eq(Inventory.equipped(0), STAFF, "Apprentice Staff in the staff slot")
	assert_eq(Inventory.equipped(1).id, &"plum_capelet")
	assert_null(Inventory.equipped(2), "no accessories yet")
	assert_eq(Inventory.count(&"healing_potion"), 1)
	assert_true(Inventory.knows_recipe(&"healing_potion"))
	assert_true(Inventory.knows_recipe(&"lantern_heart_amulet"))
	assert_false(Inventory.knows_recipe(&"ember_ward_ring"), "found in the world")
	assert_eq(PlayerData.magic_power, 14, "starting gear adds no Magic Power")


func test_stacks_and_limits() -> void:
	assert_eq(Inventory.add(SUNPETAL, 3), 3)
	assert_eq(Inventory.add(SUNPETAL, 2), 2)
	assert_eq(Inventory.count(&"sunpetal"), 5, "stacks")
	assert_eq(Inventory.add(SUNPETAL, 500), SUNPETAL.max_stack - 5, "stops at the stack limit")
	assert_false(Inventory.remove(&"iron_ore"), "can't remove what you don't have")
	assert_true(Inventory.remove(&"sunpetal", SUNPETAL.max_stack))
	assert_false(Inventory.counts.has(&"sunpetal"), "empty stacks disappear")


func test_bag_sorted_by_category_then_name() -> void:
	Inventory.add(SUNPETAL)
	Inventory.add(AMULET)
	Inventory.add(IRON_ORE)
	var ids: Array = Inventory.bag_items().map(func(item: ItemData) -> StringName: return item.id)
	assert_eq(ids, [&"iron_ore", &"sunpetal", &"healing_potion", &"lantern_heart_amulet"])


func test_equip_takes_from_bag_and_returns_old() -> void:
	Inventory.add(AMULET)
	watch_signals(Inventory)
	assert_true(Inventory.equip(AMULET))
	assert_eq(Inventory.equipped(2), AMULET, "first free accessory slot")
	assert_eq(Inventory.count(&"lantern_heart_amulet"), 0, "worn, not in the bag")
	assert_signal_emitted(Inventory, "equipment_changed")
	Inventory.add(RING)
	assert_true(Inventory.equip(RING, 2), "replace slot 1")
	assert_eq(Inventory.count(&"lantern_heart_amulet"), 1, "the amulet went back to the bag")
	assert_false(Inventory.equip(RING, 0), "a ring doesn't go in the staff slot")
	assert_false(Inventory.equip(CHARM), "not owned")


func test_same_accessory_moves_instead_of_doubling() -> void:
	Inventory.add(RING)
	Inventory.equip(RING, 2)
	assert_true(Inventory.equip(RING, 4))
	assert_null(Inventory.equipped(2))
	assert_eq(Inventory.equipped(4), RING)
	assert_eq(Inventory.gear_bonus().resistances[Elements.Type.EMBER], 0.3, "counted once")


func test_unequip() -> void:
	assert_true(Inventory.unequip(0))
	assert_null(Inventory.equipped(0))
	assert_eq(Inventory.count(&"apprentice_staff"), 1)
	assert_false(Inventory.unequip(0), "already empty")


func test_gear_bonus_and_magic_power() -> void:
	for item: EquipmentData in [AMULET, RING, CHARM]:
		Inventory.add(item)
		Inventory.equip(item)
	var gear := Inventory.gear_bonus()
	assert_eq(gear.magic_power, 15)
	assert_eq(gear.max_stamina, 20.0)
	assert_almost_eq(gear.spell_cooldown, 0.1, 0.001)
	assert_eq(PlayerData.magic_power, 14 + 15, "equipment power counts towards Magic Power")
	assert_almost_eq(PlayerData.modifiers_for(LIGHT_MOTE).cooldown, 0.9, 0.001, "Swift Quill: −10% cooldowns")


func test_crafting_rules() -> void:
	assert_false(Inventory.can_craft(AMULET_RECIPE, WORKBENCH), "no materials yet")
	Inventory.add(LUMEN_CRYSTAL, 2)
	Inventory.add(IRON_ORE, 1)
	Inventory.add(SUNPETAL, 1)
	assert_false(Inventory.can_craft(AMULET_RECIPE, KIT), "accessories need the workbench")
	assert_true(Inventory.can_craft(AMULET_RECIPE, WORKBENCH))
	watch_signals(Inventory)
	assert_true(Inventory.craft(AMULET_RECIPE, WORKBENCH))
	assert_eq(Inventory.count(&"lantern_heart_amulet"), 1)
	assert_eq(Inventory.count(&"lumen_crystal"), 0, "inputs used up")
	assert_eq(Inventory.count(&"iron_ore"), 0)
	assert_signal_emitted(Inventory, "item_crafted")
	Inventory.add(EMBER_CINDER, 3)
	Inventory.add(IRON_ORE, 1)
	assert_false(Inventory.craft(RING_RECIPE, WORKBENCH), "recipe not found yet")
	assert_eq(Inventory.count(&"ember_cinder"), 3, "nothing used when crafting fails")


func test_potions_at_kit_and_workbench() -> void:
	Inventory.add(SUNPETAL, 4)
	assert_true(Inventory.craft(POTION_RECIPE, KIT))
	assert_true(Inventory.craft(POTION_RECIPE, WORKBENCH), "the workbench makes everything")
	assert_eq(Inventory.count(&"healing_potion"), 3)


func test_recipes_for_station_include_unknown() -> void:
	assert_eq(Inventory.recipes_for(KIT).size(), 2, "potion + tonic")
	assert_eq(Inventory.recipes_for(WORKBENCH).size(), 5, "all five slice recipes (unknown ones show as ???)")
	assert_true(Inventory.learn_recipe(RING_RECIPE))
	assert_false(Inventory.learn_recipe(RING_RECIPE), "already known")


func test_loot_table_roll() -> void:
	var table := LootTable.new()
	table.items = [EMBER_CINDER, LUMEN_CRYSTAL] as Array[ItemData]
	table.chances = PackedFloat32Array([1.0, 0.0])
	table.min_counts = PackedInt32Array([2, 1])
	table.max_counts = PackedInt32Array([2, 1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var drops := table.roll(rng)
	assert_eq(drops.size(), 1, "the 0% entry never drops")
	assert_eq(drops[EMBER_CINDER], 2)


func test_save_round_trip() -> void:
	Inventory.add(SUNPETAL, 4)
	Inventory.add(RING)
	Inventory.equip(RING, 3)
	Inventory.learn_recipe(RING_RECIPE)
	var json := JSON.stringify(Inventory.to_dict())
	Inventory.reset()
	Inventory.from_dict(JSON.parse_string(json))
	assert_eq(Inventory.count(&"sunpetal"), 4)
	assert_eq(Inventory.equipped(3), RING)
	assert_true(Inventory.knows_recipe(&"ember_ward_ring"))
	assert_eq(JSON.stringify(Inventory.to_dict()), json, "same data after loading")


func test_load_skips_unknown_ids() -> void:
	Inventory.from_dict({"items": {"sunpetal": 2, "removed_item": 5}, "equipment": ["sunpetal", "", "", "", ""],
			"recipes": ["no_such_recipe"]})
	assert_eq(Inventory.count(&"sunpetal"), 2)
	assert_false(Inventory.counts.has(&"removed_item"))
	assert_null(Inventory.equipped(0), "a material can't be worn as a staff")
	assert_true(Inventory.recipes.is_empty())


func test_item_data_is_consistent() -> void:
	var ids: Array[StringName] = []
	for item in Inventory.LIBRARY.items:
		assert_false(item.id in ids, "unique id %s" % item.id)
		ids.append(item.id)
		assert_ne(item.display_name, "", "%s has a name" % item.id)
	for recipe in Inventory.LIBRARY.recipes:
		assert_eq(recipe.inputs.size(), recipe.input_counts.size(), "%s inputs and counts line up" % recipe.id)
		assert_has(Inventory.LIBRARY.items, recipe.output, "%s output is in the library" % recipe.id)
	for file in DirAccess.get_files_at("res://data/loot_tables"):
		var table := load("res://data/loot_tables/" + file) as LootTable if file.ends_with(".tres") else null
		if table:
			assert_eq(table.chances.size(), table.items.size(), file)
			assert_eq(table.min_counts.size(), table.items.size(), file)
			assert_eq(table.max_counts.size(), table.items.size(), file)
