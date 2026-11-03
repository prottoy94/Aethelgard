extends GutTest
## Phase 5 in a physics world: gear changing Aurelia's stats, potions, gathering, enemy loot, recipe scrolls,
## crafting at a station, and the Tab menu pages (FR-ITM-01…05, 07, FR-PLY-08, FR-UI-03).

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const THORNLING_SCENE := preload("res://src/actors/enemies/thornling/thornling.tscn")
const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")
const AMULET := preload("res://data/items/lantern_heart_amulet.tres")
const RING := preload("res://data/items/ember_ward_ring.tres")
const CHARM := preload("res://data/items/swift_quill_charm.tres")
const POTION := preload("res://data/items/healing_potion.tres")
const SUNPETAL := preload("res://data/items/sunpetal.tres")
const LUMEN_CRYSTAL := preload("res://data/items/lumen_crystal.tres")
const IRON_ORE := preload("res://data/items/iron_ore.tres")
const SUNPETAL_PATCH := preload("res://data/items/gather/sunpetal_patch.tres")
const RING_RECIPE := preload("res://data/recipes/ember_ward_ring.tres")

var world: Node3D
var player: Player


func before_all() -> void:
	CombatFx.hit_stop_enabled = false


func after_all() -> void:
	CombatFx.hit_stop_enabled = true
	Engine.time_scale = 1.0
	get_tree().paused = false


func before_each() -> void:
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])
	Inventory.reset()
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	world.add_child(player)
	await wait_physics_frames(3)


func after_each() -> void:
	get_tree().paused = false


func _wear(item: EquipmentData) -> void:
	Inventory.add(item)
	assert_true(Inventory.equip(item), "equipped %s" % item.id)


func test_amulet_raises_max_stamina_at_once() -> void:
	var before := player.stamina.max_stamina
	_wear(AMULET)
	assert_eq(player.stamina.max_stamina, before + AMULET.max_stamina)
	assert_eq(player.stamina.current, player.stamina.max_stamina, "the extra stamina is there straight away")
	Inventory.unequip(2)
	assert_eq(player.stamina.max_stamina, before)
	assert_lte(player.stamina.current, before, "never above the maximum")


func test_ember_ward_ring_reduces_ember_damage() -> void:
	player.health.apply_damage(DamageInfo.create(20.0, Elements.Type.EMBER, Vector3.ZERO, null))
	var plain := player.health.max_health - player.health.current
	player.health.reset()
	_wear(RING)
	player.health.apply_damage(DamageInfo.create(20.0, Elements.Type.EMBER, Vector3.ZERO, null))
	assert_almost_eq(player.health.max_health - player.health.current, plain * (1.0 - RING.resist), 0.01)
	player.health.reset()
	player.health.apply_damage(DamageInfo.create(20.0, Elements.Type.NONE, Vector3.ZERO, null))
	assert_almost_eq(player.health.max_health - player.health.current, 20.0, 0.01, "other damage unchanged")


func test_swift_quill_shortens_real_cooldowns() -> void:
	_wear(CHARM)
	assert_true(player.try_cast(0))
	assert_almost_eq(player.spell_caster.cooldowns[0].remaining, LIGHT_MOTE.cooldown * (1.0 - CHARM.spell_cooldown), 0.02)


func test_potion_heals_and_is_used_up() -> void:
	assert_false(player.use_item(POTION), "refused at full health")
	assert_eq(Inventory.count(&"healing_potion"), 1, "not wasted")
	player.health.apply_damage(DamageInfo.create(50.0, Elements.Type.NONE, Vector3.ZERO, null))
	assert_true(player.use_item(POTION))
	assert_eq(player.health.current, 50.0 + POTION.heal)
	assert_eq(Inventory.count(&"healing_potion"), 0)
	assert_false(player.use_item(POTION), "none left")


func test_gathering_and_regrowth() -> void:
	var data: GatherNodeData = SUNPETAL_PATCH.duplicate()
	data.regrow_time = 0.3
	var node := GatherNode.new()
	node.data = data
	node.position = Vector3(0, 0, -1)
	world.add_child(node)
	watch_signals(EventBus)
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "patch in reach")
	assert_between(Inventory.count(&"sunpetal"), data.min_amount, data.max_amount)
	assert_signal_emitted(EventBus, "item_collected")
	assert_false(node.can_gather(), "picked")
	assert_eq(node.gather(player), 0, "nothing more until it grows back")
	await wait_seconds(0.5)
	assert_true(node.can_gather(), "grown back")


func test_thornling_drops_fibre_and_walking_over_collects_it() -> void:
	var thornling: Enemy = THORNLING_SCENE.instantiate()
	thornling.position = Vector3(0, 0, -6)
	world.add_child(thornling)
	await wait_physics_frames(2)
	thornling.health.apply_damage(DamageInfo.create(999.0, Elements.Type.NONE, Vector3.ZERO, null))
	await wait_seconds(0.6)  # deferred drop + pop arc
	var pickups := world.get_children().filter(func(n: Node) -> bool: return n is ItemPickup)
	assert_gt(pickups.size(), 0, "loot dropped")
	var fibre: ItemPickup = pickups.filter(func(p: ItemPickup) -> bool: return p.item.id == &"thorn_fibre")[0]
	player.global_position = fibre.global_position + Vector3(0, 0.05, 0)
	await wait_physics_frames(6)
	assert_gt(Inventory.count(&"thorn_fibre"), 0, "collected by walking over it")


func test_recipe_scroll_teaches_recipe() -> void:
	var scroll := RecipeScroll.new()
	scroll.recipe = RING_RECIPE
	scroll.persist_id = &"test_recipe_ring"
	scroll.position = Vector3(0, 0, -1)
	world.add_child(scroll)
	await wait_physics_frames(5)
	assert_true(player.try_interact())
	assert_true(Inventory.knows_recipe(&"ember_ward_ring"))
	assert_true(GameState.get_object_state(&"test_recipe_ring").get("taken", false))


func test_workbench_opens_crafting_and_crafts() -> void:
	var menu := CraftingMenu.new()
	add_child_autofree(menu)
	var bench := CraftingStation.new()
	bench.position = Vector3(0, 0, -1.6)
	world.add_child(bench)
	bench.used.connect(func(_by: Player, at: RecipeData.Station) -> void: menu.open_station(at))
	Inventory.add(LUMEN_CRYSTAL, 2)
	Inventory.add(IRON_ORE)
	Inventory.add(SUNPETAL)
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "workbench in reach")
	assert_true(menu.is_open())
	assert_true(get_tree().paused, "crafting pauses the game")
	menu.select(Inventory.LIBRARY.find_recipe(&"lantern_heart_amulet"))
	assert_true(menu.craft())
	assert_eq(Inventory.count(&"lantern_heart_amulet"), 1)
	assert_false(menu.craft(), "materials used up")
	menu.close()


func test_crafting_kit_sits_by_the_shrine() -> void:
	var shrine := RestPoint.new()
	world.add_child(shrine)
	await wait_physics_frames(1)
	assert_eq(shrine.kit.station, RecipeData.Station.KIT)


func test_respawn_keeps_items() -> void:
	Inventory.add(SUNPETAL, 3)
	_wear(RING)
	var before := JSON.stringify(Inventory.to_dict())
	player.health.apply_damage(DamageInfo.create(999.0, Elements.Type.NONE, Vector3.ZERO, null))
	player.respawn()
	assert_eq(JSON.stringify(Inventory.to_dict()), before, "nothing lost on defeat (FR-PLY-08)")


func test_game_menu_pages() -> void:
	var game_menu := GameMenu.new()
	add_child_autofree(game_menu)
	var inventory_menu := InventoryMenu.new()
	game_menu.add_page(inventory_menu)
	inventory_menu.bind(player)
	var grimoire := Grimoire.new()
	game_menu.add_page(grimoire)
	game_menu.open(0)
	assert_true(inventory_menu.is_open())
	assert_true(get_tree().paused)
	game_menu.open(1)
	assert_false(inventory_menu.is_open(), "turning the page closes the other one")
	assert_true(grimoire.is_open())
	assert_true(get_tree().paused, "still paused")
	grimoire.close()
	assert_false(get_tree().paused)


func test_inventory_menu_use_and_equip() -> void:
	var inventory_menu := InventoryMenu.new()
	add_child_autofree(inventory_menu)
	inventory_menu.bind(player)
	Inventory.add(AMULET)
	player.health.apply_damage(DamageInfo.create(30.0, Elements.Type.NONE, Vector3.ZERO, null))
	inventory_menu.open()
	inventory_menu.select(POTION)
	inventory_menu.act()
	assert_eq(player.health.current, minf(70.0 + POTION.heal, player.health.max_health), "potion used from the menu")
	inventory_menu.select(AMULET)
	inventory_menu.pick_slot(3)
	assert_eq(Inventory.equipped(3), AMULET, "chosen gear goes in the clicked slot")
	inventory_menu.pick_slot(3)
	inventory_menu.act()
	assert_null(Inventory.equipped(3), "unequipped")
	inventory_menu.close()
