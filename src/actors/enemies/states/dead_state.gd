extends State
## Defeated: stops colliding, plays the death effect, then removes itself. (Loot drops come in Phase 5.)

const REMOVE_AFTER := 1.2  ## s

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	enemy.attack_hitbox.deactivate()
	enemy.visual.set_telegraph(-1.0)
	enemy.visual.play_death()
	enemy.hurtbox.set_deferred(&"monitorable", false)
	enemy.set_deferred(&"collision_layer", 0)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= REMOVE_AFTER:
		enemy.queue_free()
