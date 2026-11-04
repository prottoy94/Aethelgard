extends State
## Guard command: stays close to Aurelia, on the side of the nearest enemy that is after her (so bolts hit the dragon
## first), facing it; bites anything that comes within reach of her. With no threat it waits at her side.


func physics_update(delta: float) -> void:
	var dragon := actor as Dragon
	var player := dragon.player
	if player == null or dragon.check_leash():
		dragon.move_with(Vector3.ZERO, delta)
		return
	var close := dragon.pick_target()
	if close:
		machine.transition_to(&"Attack", {"target": close})
		return
	var tuning := Dragon.TUNING
	var threat := dragon.find_threat(player.global_position, tuning.attack_search_radius, true)
	var side: Vector3
	if threat:
		side = threat.global_position - player.global_position
		side.y = 0.0
		side = side.normalized()
	else:
		side = player.facing_direction().rotated(Vector3.UP, -PI * 0.5)  # her right-hand side
	var spot := player.global_position + side * tuning.guard_distance
	var left := dragon.move_to(spot, dragon.run_speed() * tuning.catch_up_multiplier, delta)
	if left <= Dragon.ARRIVE_DISTANCE:
		dragon.face(threat.global_position - dragon.global_position if threat else player.facing_direction())
