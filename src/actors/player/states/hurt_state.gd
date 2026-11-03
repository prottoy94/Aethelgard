extends State
## Hit reaction: a short stun while the knockback carries Aurelia back. She is invulnerable for a moment
## afterwards (Player.grant_invulnerability), so hits can't chain.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	(actor as Player).play_role(&"hurt")


func physics_update(delta: float) -> void:
	var player := actor as Player
	_time += delta
	player.apply_movement(Vector3.ZERO, player.stats.deceleration, delta)
	if _time >= player.combat.hurt_stun:
		machine.transition_to(&"Move" if player.move_input() != Vector3.ZERO else &"Idle")
