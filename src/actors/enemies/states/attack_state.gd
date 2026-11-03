extends State
## The hit itself: the attack hitbox is active for a moment, then the enemy recovers.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	enemy.attack_hitbox.activate()
	enemy.visual.play_attack()


func exit() -> void:
	(actor as Enemy).attack_hitbox.deactivate()


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= enemy.data.attack_active:
		machine.transition_to(&"Recover")
