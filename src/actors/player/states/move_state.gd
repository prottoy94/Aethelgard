extends State
## Walking: accelerates towards the input direction and turns to face it.


func physics_update(delta: float) -> void:
	var player := actor as Player
	if player.consume_dash_request():
		machine.transition_to(&"Dash")
		return
	var direction := player.move_input()
	if direction == Vector3.ZERO:
		machine.transition_to(&"Idle")
		return
	player.apply_movement(direction * player.stats.walk_speed, player.stats.acceleration, delta)
	player.face_towards(direction, delta)
