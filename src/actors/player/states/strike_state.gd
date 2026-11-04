extends State
## Staff strike (FR-PLY-05): a quick, free melee swing towards the aim. Wind-up, short active window, recovery.
## Uses no stamina, so Aurelia can always fight back, even when Exhausted.

var _time := 0.0
var _hit_started := false
var _hit_ended := false


func enter(_previous: StringName, _data: Dictionary) -> void:
	var player := actor as Player
	_time = 0.0
	_hit_started = false
	_hit_ended = false
	player.strike_cooldown.start(player.combat.strike_cooldown)
	player.face_instantly(player.aim_direction())
	player.strike_hitbox.rotation.y = player.facing_yaw
	player.play_role(&"strike")


func exit() -> void:
	(actor as Player).strike_hitbox.deactivate()


func physics_update(delta: float) -> void:
	var player := actor as Player
	var combat := player.combat
	_time += delta
	if not _hit_started and _time >= combat.strike_windup:
		_hit_started = true
		player.strike_hitbox.activate()
		AudioManager.play(&"player_staff_swing", player.global_position)
	if _hit_started and not _hit_ended and _time >= combat.strike_windup + combat.strike_active:
		_hit_ended = true
		player.strike_hitbox.deactivate()
	var slow := player.move_input() * player.stats.walk_speed * combat.strike_move_factor
	player.apply_movement(slow, player.stats.acceleration, delta)
	if player.consume_dash_request():
		machine.transition_to(&"Dash")  # dash-cancel the recovery
		return
	if _time >= combat.strike_windup + combat.strike_active + combat.strike_recovery:
		machine.transition_to(&"Move" if player.move_input() != Vector3.ZERO else &"Idle")
