extends State
## The hit itself: the attack hitbox is active for a moment, then the enemy recovers. A melee enemy's ring stays a
## "danger_zone" until the hit is over, so the pet dragon doesn't walk back in too early.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	if enemy.data.min_range <= 0.0:
		enemy.add_to_group(&"danger_zone")
	enemy.perform_attack()


func exit() -> void:
	var enemy := actor as Enemy
	enemy.end_attack()
	if enemy.is_in_group(&"danger_zone"):
		enemy.remove_from_group(&"danger_zone")


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= enemy.data.attack_active:
		machine.transition_to(&"Recover")
