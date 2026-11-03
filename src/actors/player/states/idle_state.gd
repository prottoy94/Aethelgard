extends State
## Standing still: slows to a stop. Moves on input; dashes or strikes when asked.


func physics_update(delta: float) -> void:
	var player := actor as Player
	if player.consume_dash_request():
		machine.transition_to(&"Dash")
		return
	if player.consume_strike_request():
		machine.transition_to(&"Strike")
		return
	if player.move_input() != Vector3.ZERO:
		machine.transition_to(&"Move")
		return
	player.apply_movement(Vector3.ZERO, player.stats.deceleration, delta)
