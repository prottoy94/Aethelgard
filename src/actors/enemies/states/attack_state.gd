extends State
## The hit itself: the attack hitbox is active for a moment, then the enemy recovers.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	(actor as Enemy).perform_attack()


func exit() -> void:
	(actor as Enemy).end_attack()


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= enemy.data.attack_active:
		machine.transition_to(&"Recover")
