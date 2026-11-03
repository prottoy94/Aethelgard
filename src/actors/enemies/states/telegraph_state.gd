extends State
## The warning before every attack (FR-CMB-05): the enemy stops, faces the player and shows a growing
## ring on the ground. Dash out of the ring, or dash through the hit, before it ends.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	if enemy.has_live_target():
		enemy.face(enemy.direction_to(enemy.target.global_position))


func exit() -> void:
	(actor as Enemy).visual.set_telegraph(-1.0)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	enemy.visual.set_telegraph(_time / enemy.data.telegraph_time)
	if _time >= enemy.data.telegraph_time:
		machine.transition_to(&"Attack")
