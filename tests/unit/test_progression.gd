extends GutTest
## Magic Power, Arcane Rank, learning, tomes, mastery and the loadout (PlayerData + MagicProgression).

const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const LANTERN_GLOW := preload("res://data/spells/lantern_glow.tres")
const GUST := preload("res://data/spells/gust.tres")
const MENDING_BLOOM := preload("res://data/spells/mending_bloom.tres")

var progression: MagicProgression


func before_each() -> void:
	progression = PlayerData.PROGRESSION
	Inventory.reset()
	PlayerData.reset([LIGHT_MOTE, LANTERN_GLOW] as Array[SpellData])


func test_rank_thresholds() -> void:
	assert_eq(progression.rank_for(0), 0)
	assert_eq(progression.rank_for(49), 0)
	assert_eq(progression.rank_for(50), 1)
	assert_eq(progression.rank_for(5000), 6)
	assert_eq(progression.rank_label(1), "E · Glimmer")
	assert_eq(progression.next_threshold(0), 50)
	assert_eq(progression.next_threshold(6), -1, "no rank above Sovereign")


func test_new_game_is_spark_rank() -> void:
	assert_eq(PlayerData.magic_power, LIGHT_MOTE.power_value + LANTERN_GLOW.power_value)
	assert_eq(PlayerData.rank, 0, "Aurelia starts at F · Spark, the lowest rank")
	assert_eq(PlayerData.loadout, [&"light_mote", &"lantern_glow", &"", &""] as Array[StringName])


func test_learning_adds_power_and_fills_a_slot() -> void:
	watch_signals(PlayerData)
	assert_true(PlayerData.learn(GUST))
	assert_false(PlayerData.learn(GUST), "can't learn twice")
	assert_eq(PlayerData.magic_power, 8 + 6 + 12)
	assert_eq(PlayerData.loadout[2], &"gust")
	assert_signal_emitted(PlayerData, "spell_learned")


func test_tomes_need_magic_power_and_unlock_in_a_chain() -> void:
	assert_true(PlayerData.add_tome(MENDING_BLOOM))
	assert_false(PlayerData.add_tome(MENDING_BLOOM), "already carried")
	var result := PlayerData.read_tomes()
	assert_eq(result["learned"].size(), 0, "Mending Bloom needs 20 Magic Power; she has 14")
	assert_eq(result["blocked"].size(), 1)
	# Carrying Gust too: reading Gust (26 MP) unlocks Mending Bloom in the same rest.
	PlayerData.add_tome(GUST)
	result = PlayerData.read_tomes()
	assert_eq(result["learned"].size(), 2)
	assert_true(PlayerData.knows(&"mending_bloom"))
	assert_true(PlayerData.tomes.is_empty())


func test_mastery_levels_up_and_caps() -> void:
	watch_signals(PlayerData)
	PlayerData.add_mastery_xp(&"light_mote", 19)
	assert_eq(PlayerData.mastery_level(&"light_mote"), 1)
	PlayerData.add_mastery_xp(&"light_mote", 1)
	assert_eq(PlayerData.mastery_level(&"light_mote"), 2)
	assert_signal_emitted_with_parameters(PlayerData, "mastery_changed", [&"light_mote", 2])
	assert_eq(PlayerData.magic_power, roundi(8 * 1.25 + 6), "mastery adds Magic Power")
	PlayerData.add_mastery_xp(&"light_mote", 10000)
	assert_eq(PlayerData.mastery_level(&"light_mote"), progression.max_mastery, "capped at V")


func test_modifiers_from_mastery() -> void:
	PlayerData.add_mastery_xp(&"light_mote", 20 + 50)  # → III
	var mods := PlayerData.modifiers_for(LIGHT_MOTE)
	assert_almost_eq(mods.cost, 0.9, 0.001, "−5% cost per level above I")
	assert_almost_eq(mods.cooldown, 0.9, 0.001)
	assert_gt(mods.damage, 1.2, "+10% per level, plus Magic Power scaling")


func test_rank_up_signal_when_crossing_threshold() -> void:
	watch_signals(PlayerData)
	PlayerData.set_equipment_power(40)  # 14 + 40 = 54 ≥ 50
	assert_eq(PlayerData.rank, 1)
	assert_signal_emitted_with_parameters(PlayerData, "rank_changed", [1, 0])


func test_loadout_assign_and_swap() -> void:
	PlayerData.set_loadout_slot(3, &"light_mote")
	assert_eq(PlayerData.loadout[3], &"light_mote")
	assert_eq(PlayerData.loadout[0], &"", "moved out of slot 1, which takes slot 4's old (empty) content")
	PlayerData.set_loadout_slot(0, &"gust")
	assert_eq(PlayerData.loadout[0], &"", "unknown spells can't be equipped")


func test_save_round_trip() -> void:
	PlayerData.learn(GUST)
	PlayerData.add_tome(MENDING_BLOOM)
	PlayerData.add_mastery_xp(&"gust", 25)
	var json := JSON.stringify(PlayerData.to_dict())
	PlayerData.reset([LIGHT_MOTE] as Array[SpellData])
	PlayerData.from_dict(JSON.parse_string(json))
	assert_true(PlayerData.knows(&"gust"))
	assert_eq(PlayerData.mastery_level(&"gust"), 2)
	assert_eq(PlayerData.tomes, [&"mending_bloom"] as Array[StringName])
	assert_eq(PlayerData.loadout[2], &"gust")
	assert_eq(JSON.stringify(PlayerData.to_dict()), json, "same data after loading")
