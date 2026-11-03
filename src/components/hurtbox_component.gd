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
	var amount := health.apply_damage(info)
	hurt.emit(info, amount)
	return true
