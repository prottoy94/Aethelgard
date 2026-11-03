extends State
## Runs at the player. Winds up an attack when close; gives up beyond the leash range.


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	var distance := enemy.distance_to_target()
	if distance > enemy.data.leash_range:
		machine.transition_to(&"Idle")
		return
	if distance <= enemy.data.attack_range:
		machine.transition_to(&"Telegraph")
		return
	enemy.move(enemy.direction_to(enemy.target.global_position) * enemy.data.move_speed, delta)
