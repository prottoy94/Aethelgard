extends State
## Defeated: no control. After a short pause Aurelia respawns at her respawn point with full health,
## keeping everything she carries (FR-PLY-08).

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	(actor as Player).play_role(&"death")


func physics_update(delta: float) -> void:
	var player := actor as Player
	_time += delta
	player.apply_movement(Vector3.ZERO, player.stats.deceleration, delta)
	if _time >= player.combat.respawn_delay:
		player.respawn()
