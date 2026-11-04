extends State
## Runs at its target and bites it when close (stepping out of telegraph rings on the way). Picks the next target when
## this one falls or strays too far from Aurelia, otherwise goes back to its command. Data: {"target": Enemy}.


func enter(_previous: StringName, data: Dictionary) -> void:
	(actor as Dragon).target = data.get("target") as Enemy


func exit() -> void:
	(actor as Dragon).target = null


func physics_update(delta: float) -> void:
	var dragon := actor as Dragon
	if dragon.check_leash():
		machine.transition_to(dragon.command_state())
		return
	if not dragon.should_keep_fighting(dragon.target):
		var next := dragon.pick_target()
		if next == null:
			machine.transition_to(dragon.command_state())
			return
		dragon.target = next
	var offset := dragon.target.global_position - dragon.global_position
	offset.y = 0.0
	if offset.length() <= dragon.stats.bite_range:
		dragon.move_with(Vector3.ZERO, delta)
		dragon.face(offset)
		dragon.try_bite(dragon.target)
	else:
		dragon.move_with(offset.normalized() * dragon.run_speed(), delta)
