extends GutTest
## Combat rules without physics: element multipliers, health, stamina and the spell caster's checks.

const LIGHT_MOTE := preload("res://data/spells/light_mote.tres")
const GUST := preload("res://data/spells/gust.tres")


# --- Elements (FR-MAG-06) --------------------------------------------------------------------

func test_strong_pairs_both_ways() -> void:
	var E := Elements.Type
	for pair: Array in [[E.FIRE, E.FROST], [E.WIND, E.EARTH], [E.LIGHT, E.EMBER]]:
		assert_eq(Elements.multiplier(pair[0], pair[1]), Elements.STRONG, "%s vs %s" % pair)
		assert_eq(Elements.multiplier(pair[1], pair[0]), Elements.STRONG, "%s vs %s" % [pair[1], pair[0]])


func test_frost_beats_ember_and_ember_resists_fire() -> void:
	assert_eq(Elements.multiplier(Elements.Type.FROST, Elements.Type.EMBER), Elements.STRONG)
	assert_eq(Elements.multiplier(Elements.Type.FIRE, Elements.Type.EMBER), Elements.RESISTED)


func test_same_element_resisted_and_neutral_normal() -> void:
	assert_eq(Elements.multiplier(Elements.Type.EARTH, Elements.Type.EARTH), Elements.RESISTED)
	assert_eq(Elements.multiplier(Elements.Type.LIGHT, Elements.Type.WIND), Elements.NORMAL)
	assert_eq(Elements.multiplier(Elements.Type.NONE, Elements.Type.EMBER), Elements.NORMAL)


# --- Health ------------------------------------------------------------------------------------

func _health(max_health := 30.0, defense := 0.0, element := Elements.Type.NONE) -> HealthComponent:
	var h := HealthComponent.new()
	h.max_health = max_health
	h.defense = defense
	h.element = element
	add_child_autofree(h)
	return h


func test_damage_applies_multiplier_and_defense() -> void:
	var h := _health(30.0, 2.0, Elements.Type.EARTH)
	var taken := h.apply_damage(DamageInfo.create(10.0, Elements.Type.WIND, Vector3.ZERO, null))
	assert_eq(taken, 13.0, "10 × 1.5 (Wind vs Earth) − 2 defense")
	assert_eq(h.current, 17.0)


func test_minimum_one_damage() -> void:
	var h := _health(30.0, 50.0)
	assert_eq(h.apply_damage(DamageInfo.create(5.0, Elements.Type.NONE, Vector3.ZERO, null)), 1.0)


func test_dies_once_and_ignores_hits_after() -> void:
	var h := _health(10.0)
	watch_signals(h)
	h.apply_damage(DamageInfo.create(50.0, Elements.Type.NONE, Vector3.ZERO, null))
	h.apply_damage(DamageInfo.create(50.0, Elements.Type.NONE, Vector3.ZERO, null))
	assert_true(h.is_dead())
	assert_signal_emit_count(h, "died", 1)
	h.heal(5.0)
	assert_true(h.is_dead(), "no healing while dead")
	h.reset()
	assert_eq(h.current, 10.0)


# --- Stamina (FR-MAG-01, 02, 04) ----------------------------------------------------------------

func _stamina() -> StaminaComponent:
	var s := StaminaComponent.new()
	s.max_stamina = 40.0
	s.regen_rate = 10.0
	s.regen_delay = 0.8
	s.recover_ratio = 0.3
	add_child_autofree(s)
	s.set_process(false)  # tick manually
	return s


func test_spend_and_refuse_when_too_little() -> void:
	var s := _stamina()
	watch_signals(s)
	assert_true(s.try_spend(30.0))
	assert_false(s.try_spend(15.0), "only 10 left")
	assert_signal_emitted(s, "spend_failed")
	assert_eq(s.current, 10.0)


func test_regen_waits_for_the_delay() -> void:
	var s := _stamina()
	s.try_spend(20.0)
	s.tick(0.5)
	assert_eq(s.current, 20.0, "no regen during the delay")
	s.tick(0.4)
	assert_almost_eq(s.current, 21.0, 0.01, "refilled only for the 0.1 s after the 0.8 s delay")


func test_exhausted_until_thirty_percent() -> void:
	var s := _stamina()
	assert_true(s.try_spend(40.0))
	assert_true(s.exhausted)
	assert_false(s.try_spend(1.0), "can't cast while Exhausted")
	s.tick(0.8)  # delay just over: nothing refilled yet
	s.tick(1.0)  # 10 stamina: 25% < 30%
	assert_true(s.exhausted)
	s.tick(0.3)  # 13 stamina: past 12 (30%)
	assert_false(s.exhausted)


# --- Spell caster (FR-MAG-03) --------------------------------------------------------------------

func _caster() -> SpellCaster:
	var s := _stamina()
	var caster := SpellCaster.new()
	caster.stamina = s
	caster.global_cooldown = 0.25
	add_child_autofree(caster)
	caster.set_process(false)
	caster.set_slot(0, LIGHT_MOTE)
	caster.set_slot(1, GUST)
	return caster


func test_cast_checks_in_order() -> void:
	var caster := _caster()
	assert_eq(caster.check(2), &"empty")
	assert_eq(caster.check(0), &"")
	var origin: Node3D = autofree(Node3D.new())
	var data_without_scene := LIGHT_MOTE.duplicate() as SpellData
	data_without_scene.scene = null
	caster.set_slot(3, data_without_scene)
	assert_true(caster.try_cast(3, origin, Vector3.FORWARD))
	assert_eq(caster.check(3), &"cooldown", "own cooldown running")
	assert_eq(caster.check(1), &"global", "short global cooldown after any cast")
	caster.tick(0.3)
	assert_eq(caster.check(1), &"", "global cooldown over")
	assert_eq(caster.stamina.current, 40.0 - LIGHT_MOTE.stamina_cost)


func test_cast_refused_without_stamina() -> void:
	var caster := _caster()
	caster.stamina.try_spend(30.0)  # 10 left; Gust costs 15
	watch_signals(caster)
	var origin: Node3D = autofree(Node3D.new())
	assert_false(caster.try_cast(1, origin, Vector3.FORWARD))
	assert_signal_emitted_with_parameters(caster, "cast_failed", [1, &"stamina"])
