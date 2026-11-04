class_name HurtboxComponent
extends Area3D
## The part of a character that can be hit. Forwards accepted hits to its HealthComponent.
## Give it a CollisionShape3D child. Team picks the physics layer (player_hurtbox / enemy_hurtbox).

signal hurt(info: DamageInfo, amount: float)

enum Team { PLAYER, ENEMY }

const PLAYER_HURTBOX_LAYER := 1 << 4  # layer 5
const ENEMY_HURTBOX_LAYER := 1 << 5   # layer 6

@export var team := Team.ENEMY
@export var health: HealthComponent
@export var status_effects: StatusEffectComponent  ## optional: receives the hit's status effect

## Optional: returns true while hits should be ignored (dash i-frames, after being hurt).
var invulnerable_check: Callable


func _ready() -> void:
	collision_layer = PLAYER_HURTBOX_LAYER if team == Team.PLAYER else ENEMY_HURTBOX_LAYER
	collision_mask = 0
	monitoring = false


## Called by hitboxes. Returns true if the hit landed.
func receive_hit(info: DamageInfo) -> bool:
	if health == null or health.is_dead():
		return false
	if invulnerable_check.is_valid() and invulnerable_check.call():
		return false
	if status_effects:
		info.amount *= status_effects.damage_taken_multiplier()
	var amount := health.apply_damage(info)
	_play_hit_sound(info)
	if status_effects and info.status != &"" and not health.is_dead():
		status_effects.apply(info.status, info.status_duration, info.status_power, info.element)
	hurt.emit(info, amount)
	return true


## The element's impact (AUDIO_DESIGN.md §6.1), plus a bright "ding" on a weakness or a dull "thunk" when resisted.
func _play_hit_sound(info: DamageInfo) -> void:
	var element := String(Elements.Type.find_key(info.element)).to_lower()
	if not AudioManager.play(StringName("combat_hit_%s" % element), global_position):
		AudioManager.play(&"combat_hit_none", global_position)
	var multiplier := Elements.multiplier(info.element, health.element)
	if multiplier > 1.0:
		AudioManager.play(&"combat_weak_hit", global_position)
	elif multiplier < 1.0:
		AudioManager.play(&"combat_resisted", global_position)
