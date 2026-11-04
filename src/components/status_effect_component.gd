class_name StatusEffectComponent
extends Node
## Timed status effects on a character (FR-MAG-13): Burn (damage over time), Chill (slow; enough stacks Freeze),
## Freeze (can't move), Daze (slow), Ember Mark (takes more damage). Stagger is handled by the owner's states.

signal changed
signal frozen(seconds: float)

const BURN := &"burn"
const CHILL := &"chill"
const FREEZE := &"freeze"
const DAZE := &"daze"
const EMBER_MARK := &"ember_mark"
const RULES: StatusRules = preload("res://data/combat/status_rules.tres")
const COLORS := {
	BURN: Color("ff7a3c"), CHILL: Color("9fd4ff"), FREEZE: Color("dff3ff"),
	DAZE: Color("ffe066"), EMBER_MARK: Color("b3202a"),
}

@export var health: HealthComponent

## id → {"time": seconds left, "power": strength, "stacks": int, "element": Elements.Type, "tick": float}
var effects: Dictionary[StringName, Dictionary] = {}


func _process(delta: float) -> void:
	tick(delta)


## Adds or refreshes an effect. `power` is effect-specific (Burn: damage per second).
func apply(id: StringName, duration: float, power := 0.0, element := Elements.Type.NONE) -> void:
	if health and health.is_dead():
		return
	if id == CHILL:
		var stacks := int(effects.get(CHILL, {}).get("stacks", 0)) + 1
		if stacks >= RULES.freeze_stacks:
			effects.erase(CHILL)
			effects[FREEZE] = {"time": RULES.freeze_time, "power": 0.0, "stacks": 1, "element": element, "tick": 0.0}
			_play_sound(FREEZE)
			frozen.emit(RULES.freeze_time)
			changed.emit()
			return
		effects[CHILL] = {"time": duration, "power": power, "stacks": stacks, "element": element, "tick": 0.0}
	else:
		var old: Dictionary = effects.get(id, {})
		effects[id] = {"time": maxf(duration, float(old.get("time", 0.0))), "power": maxf(power, float(old.get("power", 0.0))),
				"stacks": 1, "element": element, "tick": float(old.get("tick", 0.0))}
	_play_sound(id)
	changed.emit()


func _play_sound(id: StringName) -> void:
	var owner_node := get_parent() as Node3D
	if owner_node:
		AudioManager.play(StringName("combat_status_%s" % id), owner_node.global_position)


func tick(delta: float) -> void:
	if effects.is_empty():
		return
	var expired := false
	for id: StringName in effects.keys():
		var effect := effects[id]
		effect["time"] = float(effect["time"]) - delta
		if id == BURN:
			_tick_burn(effect, delta)
		if float(effect["time"]) <= 0.0:
			effects.erase(id)
			expired = true
	if expired:
		changed.emit()


func has(id: StringName) -> bool:
	return effects.has(id)


func time_left(id: StringName) -> float:
	return float(effects[id]["time"]) if effects.has(id) else 0.0


func clear() -> void:
	effects.clear()
	changed.emit()


## Movement speed factor: 0 when frozen, lower when chilled or dazed.
func speed_multiplier() -> float:
	if has(FREEZE):
		return 0.0
	var factor := 1.0
	if has(CHILL):
		factor -= RULES.chill_slow_per_stack * int(effects[CHILL]["stacks"])
	if has(DAZE):
		factor -= RULES.daze_slow
	return clampf(factor, 0.1, 1.0)


func damage_taken_multiplier() -> float:
	return RULES.ember_mark_damage if has(EMBER_MARK) else 1.0


func _tick_burn(effect: Dictionary, delta: float) -> void:
	if health == null:
		return
	effect["tick"] = float(effect["tick"]) + delta
	while float(effect["tick"]) >= RULES.burn_tick:
		effect["tick"] = float(effect["tick"]) - RULES.burn_tick
		var info := DamageInfo.create(float(effect["power"]) * RULES.burn_tick, effect["element"], Vector3.ZERO, null)
		health.apply_damage(info)
