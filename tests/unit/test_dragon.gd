extends GutTest
## The pet dragon's rules in DragonManager (FR-DRG-01/03/04/05/06/07, FR-DLG-09, FR-SAV-04): the egg and its warmth,
## choosing the element, hatching, naming, bond levels and the skills they unlock, Magic Power from the bond,
## petting, treats, commands, knock-outs and saving. Also checks the dragon data files.

const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const TREAT := preload("res://data/items/dragon_treat.tres")
const TUNING: DragonTuning = preload("res://data/dragons/dragon_tuning.tres")


func before_each() -> void:
	GameState.reset()
	Inventory.reset()
	QuestManager.reset()
	TimeOfDay.reset()
	DragonManager.from_dict({})
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])


func after_each() -> void:
	TimeOfDay.running = false
	DragonManager.from_dict({})


func _hatched(element := "frost") -> void:
	DragonManager.receive_egg()
	DragonManager.choose_element(element)
	DragonManager.hatch()


func test_a_new_game_has_no_dragon() -> void:
	assert_eq(DragonManager.stage, DragonTypes.Stage.NONE)
	assert_eq(DragonManager.to_dict(), {}, "nothing to save yet")
	assert_eq(DragonManager.magic_power_bonus(), 0)
	assert_false(DragonManager.is_active())


func test_the_egg_warms_from_fighting_and_exploring() -> void:
	watch_signals(DragonManager)
	DragonManager.receive_egg()
	assert_true(DragonManager.has_egg())
	assert_true(GameState.has_flag(DragonManager.EGG_FLAG))
	EventBus.enemy_defeated.emit(&"thornling")
	assert_almost_eq(DragonManager.warmth, TUNING.warmth_per_enemy, 0.001, "fighting warms it")
	EventBus.puzzle_solved.emit(&"test_puzzle")
	EventBus.region_changed.emit(&"elderroot_village")
	assert_almost_eq(DragonManager.warmth, TUNING.warmth_per_enemy + TUNING.warmth_per_puzzle + TUNING.warmth_per_region,
			0.001, "puzzles and new areas too")
	assert_false(DragonManager.is_egg_ready())
	DragonManager.add_warmth(TUNING.warmth_needed)
	assert_true(DragonManager.is_egg_ready())
	assert_eq(DragonManager.warmth, TUNING.warmth_needed, "never more than needed")
	assert_true(GameState.has_flag(DragonManager.WARM_FLAG))
	assert_signal_emit_count(DragonManager, "egg_ready", 1)


func test_no_warmth_without_an_egg() -> void:
	EventBus.enemy_defeated.emit(&"thornling")
	DragonManager.add_warmth(10.0)
	assert_eq(DragonManager.warmth, 0.0)


func test_choose_the_element_then_hatch() -> void:
	DragonManager.receive_egg()
	assert_false(DragonManager.choose_element("fire"), "only frost, wind, earth or light (FR-DRG-06)")
	assert_true(DragonManager.choose_element("wind"))
	assert_eq(DragonManager.element, Elements.Type.WIND)
	watch_signals(EventBus)
	DragonManager.hatch()
	assert_eq(DragonManager.stage, DragonTypes.Stage.HATCHLING)
	assert_eq(DragonManager.dragon_name, "Pip", "the default name (owner decision)")
	assert_true(GameState.has_flag(DragonManager.HATCHED_FLAG))
	assert_signal_emitted(EventBus, "dragon_hatched")
	assert_false(DragonManager.choose_element("earth"), "the element is fixed once hatched")
	assert_eq(DragonManager.species().display_name, "Wind dragon")


func test_hatching_without_a_choice_uses_the_first_species() -> void:
	DragonManager.receive_egg()
	DragonManager.hatch()
	assert_eq(DragonManager.element, TUNING.species[0].element)


func test_names_are_cleaned() -> void:
	assert_eq(DragonManager.clean_name("  Ember  ", 14, "Pip"), "Ember")
	assert_eq(DragonManager.clean_name("", 14, "Pip"), "Pip", "empty keeps the default (FR-DLG-09)")
	assert_eq(DragonManager.clean_name("   ", 14, "Pip"), "Pip")
	assert_false("[" in DragonManager.clean_name("[b]Bo[/b]", 14, "Pip"), "no text markup")
	assert_eq(DragonManager.clean_name("{{Sunny}}", 14, "Pip"), "Sunny")
	assert_eq(DragonManager.clean_name("Bartholomew the Brave", 14, "Pip").length(), 14, "cut to the limit")
	assert_eq(DragonManager.clean_name("Big   Toe", 14, "Pip"), "Big Toe")
	_hatched()
	DragonManager.set_dragon_name("  Ember ")
	assert_eq(DragonManager.dragon_name, "Ember")


func test_bond_levels_unlock_skills_and_add_magic_power() -> void:
	var base := PlayerData.magic_power
	_hatched("frost")
	assert_eq(DragonManager.bond_level, 1)
	assert_eq(PlayerData.magic_power, base + TUNING.power_per_bond, "bond 1 already counts")
	assert_eq(DragonManager.active_skill().id, &"frost_puff", "the breath from the start")
	assert_eq(DragonManager.passives().size(), 0)
	watch_signals(DragonManager)
	DragonManager.add_bond_xp(TUNING.bond_xp_needed(1))
	assert_eq(DragonManager.bond_level, 2)
	DragonManager.add_bond_xp(TUNING.bond_xp_needed(2) + 5)
	assert_eq(DragonManager.bond_level, 3)
	assert_eq(DragonManager.bond_xp, 5, "the rest carries over")
	assert_signal_emitted(DragonManager, "skill_unlocked")
	assert_eq(DragonManager.passives()[0].id, &"cold_nip", "bond 3 unlocks the trait (FR-DRG-05)")
	assert_eq(PlayerData.magic_power, base + TUNING.power_per_bond * 3)
	assert_gt(DragonManager.max_health(), DragonManager.stats().max_health, "stats grow with the bond")


func test_bond_stops_at_the_top_level() -> void:
	_hatched()
	DragonManager.add_bond_xp(100000)
	assert_eq(DragonManager.bond_level, TUNING.max_bond())
	assert_eq(DragonManager.bond_xp, 0)
	assert_eq(DragonManager.bond_progress(), 1.0)


func test_fighting_together_raises_the_bond() -> void:
	_hatched()
	EventBus.enemy_defeated.emit(&"thornling")
	assert_eq(DragonManager.bond_xp, TUNING.bond_per_fight)
	DragonManager.knock_out()
	EventBus.enemy_defeated.emit(&"thornling")
	assert_eq(DragonManager.bond_xp, TUNING.bond_per_fight, "not while it is knocked out")


func test_petting_raises_the_bond_every_few_hours() -> void:
	_hatched()
	assert_true(DragonManager.pet())
	assert_eq(DragonManager.bond_xp, TUNING.bond_per_pet)
	assert_false(DragonManager.pet(), "happy, but no more bond for a while")
	TimeOfDay.advance(TUNING.pet_cooldown_minutes + 1.0)
	assert_true(DragonManager.pet())


func test_feeding_treats() -> void:
	assert_eq(DragonManager.feed(TREAT), &"no_dragon")
	_hatched()
	assert_eq(DragonManager.feed(TREAT), &"none_left")
	Inventory.add(TREAT, 2)
	DragonManager.health_ratio = 0.5
	assert_eq(DragonManager.feed(TREAT), &"", "eaten")
	assert_eq(Inventory.count(TREAT.id), 1)
	assert_eq(DragonManager.bond_xp, TREAT.dragon_bond, "treats raise the bond (FR-DRG-05)")
	assert_gt(DragonManager.health_ratio, 0.5, "and heal it")
	DragonManager.knock_out()
	assert_eq(DragonManager.feed(TREAT), &"knocked_out")
	assert_true(DragonManager.is_food(TREAT))
	assert_false(DragonManager.is_food(preload("res://data/items/healing_potion.tres")))


func test_commands_cycle() -> void:
	_hatched()
	assert_eq(DragonManager.command, DragonTypes.Command.FOLLOW)
	assert_eq(DragonManager.cycle_command(), DragonTypes.Command.ATTACK)
	assert_eq(DragonManager.cycle_command(), DragonTypes.Command.GUARD)
	assert_eq(DragonManager.cycle_command(), DragonTypes.Command.FOLLOW)


func test_knocked_out_comes_back_after_a_while() -> void:
	_hatched()
	watch_signals(DragonManager)
	DragonManager.knock_out()
	assert_false(DragonManager.is_active())
	assert_eq(DragonManager.knocked_out_left, TUNING.ko_time, "about 20 s (FR-DRG-07)")
	TimeOfDay.running = true
	DragonManager._physics_process(TUNING.ko_time * 0.5)
	assert_false(DragonManager.is_active(), "still resting")
	DragonManager._physics_process(TUNING.ko_time * 0.5 + 0.1)
	assert_true(DragonManager.is_active(), "back")
	assert_signal_emitted(DragonManager, "recovered")
	assert_almost_eq(DragonManager.health_ratio, TUNING.ko_return_health, 0.001)


func test_resting_wakes_and_heals_it() -> void:
	_hatched()
	DragonManager.knock_out()
	DragonManager.rest()
	assert_true(DragonManager.is_active())
	assert_eq(DragonManager.health_ratio, 1.0)


func test_save_round_trip() -> void:
	_hatched("light")
	DragonManager.set_dragon_name("Sunny")
	DragonManager.add_bond_xp(TUNING.bond_xp_needed(1) + TUNING.bond_xp_needed(2) + 7)
	DragonManager.set_command(DragonTypes.Command.GUARD)
	DragonManager.health_ratio = 0.4
	DragonManager.pet()
	var saved := DragonManager.to_dict()
	var through_json: Dictionary = JSON.parse_string(JSON.stringify(saved))
	DragonManager.from_dict({})
	assert_eq(DragonManager.stage, DragonTypes.Stage.NONE)
	DragonManager.from_dict(through_json)
	assert_eq(DragonManager.to_dict(), saved, "the same dragon after saving and loading (FR-SAV-04)")
	assert_eq(DragonManager.element, Elements.Type.LIGHT)
	assert_eq(DragonManager.dragon_name, "Sunny")
	assert_eq(DragonManager.bond_level, 3)
	assert_eq(saved["element"], "light", "saved by id")


func test_damaged_saves_are_clamped() -> void:
	DragonManager.from_dict({"stage": 99, "element": "lava", "bond_level": 50, "health": 7.0, "name": "[x]"})
	assert_eq(DragonManager.stage, DragonTypes.Stage.ADULT)
	assert_eq(DragonManager.bond_level, TUNING.max_bond())
	assert_eq(DragonManager.health_ratio, 1.0)
	assert_ne(DragonManager.species(), null, "an unknown element falls back to a real species")
	assert_eq(DragonManager.dragon_name, "x")


func test_every_species_has_its_own_skills() -> void:
	var elements: Array[Elements.Type] = []
	var skill_ids: Array[StringName] = []
	for kind in TUNING.species:
		assert_false(kind.element in elements, "%s only once" % kind.display_name)
		elements.append(kind.element)
		var stats := kind.stats_for(DragonTypes.Stage.HATCHLING)
		assert_gt(stats.max_health, 0.0, kind.display_name)
		var breath := kind.active_skill(DragonTypes.Stage.HATCHLING, 1)
		assert_not_null(breath, "%s has a breath from bond 1" % kind.display_name)
		assert_eq(breath.element, kind.element, "%s breathes its own element" % kind.display_name)
		assert_gt(breath.cooldown, 0.0)
		assert_eq(kind.passives(DragonTypes.Stage.HATCHLING, 1).size(), 0)
		assert_eq(kind.locked_skills(DragonTypes.Stage.HATCHLING, 1).size(), 1, "a trait to unlock with the bond")
		for skill in kind.skills:
			assert_false(skill.id in skill_ids, "%s is unique" % skill.id)
			skill_ids.append(skill.id)
	for element: Elements.Type in [Elements.Type.FROST, Elements.Type.WIND, Elements.Type.EARTH, Elements.Type.LIGHT]:
		assert_has(elements, element, "the four hatching choices (FR-DRG-06)")


func test_treat_recipe_and_egg_quest_exist() -> void:
	var recipe := Inventory.LIBRARY.find_recipe(&"dragon_treat")
	assert_not_null(recipe, "rebuild data/items/item_library.tres after adding items")
	assert_true(recipe.can_make_at(RecipeData.Station.KIT), "made at a shrine's kit")
	var quest := QuestManager.LIBRARY.find(&"dragon_egg")
	assert_not_null(quest)
	assert_eq(quest.steps[0].target, DragonManager.WARM_FLAG)
	assert_eq(quest.steps[1].target, DragonManager.HATCHED_FLAG)
	DragonManager.receive_egg()
	QuestManager.start(&"dragon_egg")
	DragonManager.add_warmth(TUNING.warmth_needed)
	assert_true(QuestManager.is_on_step(&"dragon_egg", 1), "a warm egg moves the quest on")
	DragonManager.hatch()
	assert_true(QuestManager.is_done(&"dragon_egg"), "hatching finishes the quest")
	assert_true(Inventory.knows_recipe(&"dragon_treat"), "and teaches the treat recipe")
	assert_eq(Inventory.count(TREAT.id), 2)
