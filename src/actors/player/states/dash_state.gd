extends State
## Dash: a short, fast burst in the input direction (or facing direction) with brief invulnerability.
## Uses no stamina (GAME_DESIGN.md §6.1); has its own cooldown.

var _direction := Vector3.FORWARD
var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	var player := actor as Player
	var input := player.move_input()
	_direction = input.normalized() if input != Vector3.ZERO else player.facing_direction()
	_time = 0.0
	player.grant_invulnerability(player.stats.dash_invulnerable_time)
	player.dash_cooldown.start(player.stats.dash_cooldown)
	player.facing_yaw = Player.yaw_of(_direction)
	player.visual.rotation.y = player.facing_yaw
	player.dashed.emit()


func exit() -> void:
	var player := actor as Player
	var carry := _direction * player.stats.walk_speed  # leave the dash at walking speed
	player.velocity.x = carry.x
	player.velocity.z = carry.z


func physics_update(delta: float) -> void:
	var player := actor as Player
	_time += delta
	var dash_velocity := _direction * player.stats.dash_speed
	player.apply_movement(dash_velocity, INF, delta)
	if _time >= player.stats.dash_duration:
		machine.transition_to(&"Move" if player.move_input() != Vector3.ZERO else &"Idle")
