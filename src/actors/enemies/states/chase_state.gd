extends State
## Runs at the player (or, for ranged enemies, keeps a distance). Winds up an attack when in range;
## gives up beyond the leash range.


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	var distance := enemy.distance_to_target()
	if distance > enemy.data.leash_range:
		machine.transition_to(&"Idle")
		return
	var towards := enemy.direction_to(enemy.target.global_position)
	if distance < enemy.data.min_range:
		enemy.move(-towards * enemy.data.move_speed, delta)  # too close: back away
		return
	if enemy.ready_to_attack(distance):
		machine.transition_to(&"Telegraph")
		return
	enemy.move(towards * enemy.data.move_speed, delta)
