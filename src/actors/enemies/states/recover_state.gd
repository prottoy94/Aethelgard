extends State
## After attacking the enemy is open for a moment: the player's chance to strike back.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= enemy.recover_time():
		machine.transition_to(&"Chase" if enemy.has_live_target() else &"Idle")
