class_name HealthComponent
extends Node
## Hit points for anything that can be hurt. Applies element multipliers and defense (TECHNICAL_DESIGN.md §4.5).

signal damaged(amount: float, info: DamageInfo)
signal healed(amount: float)
signal changed(current: float, maximum: float)
signal died

@export var max_health := 100.0
@export var defense := 0.0                          ## flat reduction per hit
@export var element := Elements.Type.NONE           ## the owner's own element (for weaknesses)
## −fraction of damage taken per attacking element (from gear, e.g. the Ember-Ward Ring).
var resistances: Dictionary[Elements.Type, float] = {}

var current := 0.0


func _ready() -> void:
	current = max_health


## Applies a hit and returns the damage actually taken (0 if already dead).
func apply_damage(info: DamageInfo) -> float:
	if is_dead():
		return 0.0
	var amount := compute_damage(info.amount * (1.0 - resistances.get(info.element, 0.0)), info.element, element, defense)
	current = maxf(current - amount, 0.0)
	damaged.emit(amount, info)
	changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()
	return amount


func heal(amount: float) -> void:
	if is_dead():
		return
	var before := current
	current = minf(current + amount, max_health)
	healed.emit(current - before)
	changed.emit(current, max_health)


## Changes the maximum. With `keep_gain` a higher maximum also adds the difference now; current health never
## ends above the new maximum.
func set_max_health(value: float, keep_gain: bool) -> void:
	var gain := value - max_health
	max_health = value
	if not is_dead():
		if keep_gain and gain > 0.0:
			current += gain
		current = minf(current, max_health)
	changed.emit(current, max_health)


## Back to full health (respawn).
func reset() -> void:
	current = max_health
	changed.emit(current, max_health)


func is_dead() -> bool:
	return current <= 0.0


func ratio() -> float:
	return current / max_health if max_health > 0.0 else 0.0


## Damage after element multiplier and defense; every hit does at least 1.
static func compute_damage(base: float, attack: Elements.Type, defender: Elements.Type, flat_defense: float) -> float:
	return maxf(1.0, base * Elements.multiplier(attack, defender) - flat_defense)
