extends GutTest
## Status effects (FR-MAG-13): Burn damage over time, Chill stacking into Freeze, Daze, Ember Mark, expiry.

var health: HealthComponent
var status: StatusEffectComponent
var rules: StatusRules


func before_each() -> void:
	rules = StatusEffectComponent.RULES
	health = HealthComponent.new()
	health.max_health = 100.0
	add_child_autofree(health)
	status = StatusEffectComponent.new()
	status.health = health
	add_child_autofree(status)
	status.set_process(false)  # tick manually


func test_burn_deals_damage_over_time_then_ends() -> void:
	status.apply(StatusEffectComponent.BURN, 2.0, 3.0, Elements.Type.EMBER)  # 3 damage per second
	for i in 20:
		status.tick(0.1)
	assert_almost_eq(health.current, 100.0 - 6.0, 0.01, "3/s for 2 s")
	assert_false(status.has(StatusEffectComponent.BURN), "expired")


func test_chill_slows_and_three_stacks_freeze() -> void:
	watch_signals(status)
	status.apply(StatusEffectComponent.CHILL, 3.0)
	assert_almost_eq(status.speed_multiplier(), 1.0 - rules.chill_slow_per_stack, 0.001)
	status.apply(StatusEffectComponent.CHILL, 3.0)
	status.apply(StatusEffectComponent.CHILL, 3.0)
	assert_true(status.has(StatusEffectComponent.FREEZE))
	assert_false(status.has(StatusEffectComponent.CHILL))
	assert_eq(status.speed_multiplier(), 0.0, "frozen solid")
	assert_signal_emitted_with_parameters(status, "frozen", [rules.freeze_time])
	status.tick(rules.freeze_time + 0.01)
	assert_eq(status.speed_multiplier(), 1.0, "thawed")


func test_daze_and_ember_mark() -> void:
	status.apply(StatusEffectComponent.DAZE, 1.0)
	assert_almost_eq(status.speed_multiplier(), 1.0 - rules.daze_slow, 0.001)
	status.apply(StatusEffectComponent.EMBER_MARK, 5.0)
	assert_eq(status.damage_taken_multiplier(), rules.ember_mark_damage)


func test_refresh_keeps_the_longer_time() -> void:
	status.apply(StatusEffectComponent.DAZE, 3.0)
	status.apply(StatusEffectComponent.DAZE, 1.0)
	assert_almost_eq(status.time_left(StatusEffectComponent.DAZE), 3.0, 0.001)


func test_no_effects_on_the_dead_and_clear() -> void:
	health.apply_damage(DamageInfo.create(500.0, Elements.Type.NONE, Vector3.ZERO, null))
	status.apply(StatusEffectComponent.BURN, 2.0, 3.0)
	assert_false(status.has(StatusEffectComponent.BURN))
	health.reset()
	status.apply(StatusEffectComponent.DAZE, 2.0)
	status.clear()
	assert_true(status.effects.is_empty())


func test_hurtbox_applies_status_and_mark_multiplier() -> void:
	var hurtbox := HurtboxComponent.new()
	hurtbox.health = health
	hurtbox.status_effects = status
	add_child_autofree(hurtbox)
	status.apply(StatusEffectComponent.EMBER_MARK, 5.0)
	var info := DamageInfo.create(10.0, Elements.Type.NONE, Vector3.ZERO, null).with_status(StatusEffectComponent.BURN, 2.0, 1.0)
	assert_true(hurtbox.receive_hit(info))
	assert_almost_eq(health.current, 100.0 - 10.0 * rules.ember_mark_damage, 0.01)
	assert_true(status.has(StatusEffectComponent.BURN))
