extends State
## Follow and Attack commands with nothing to bite: walks after Aurelia, and turns to fight when the command finds a
## target (Follow: an enemy after her, close by; Attack: her target or the nearest threat).


func physics_update(delta: float) -> void:
	var dragon := actor as Dragon
	if dragon.check_leash():
		return
	var enemy := dragon.pick_target()
	if enemy:
		machine.transition_to(&"Attack", {"target": enemy})
		return
	dragon.follow_player(delta)
