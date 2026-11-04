extends State
## The breath skill (H): runs a little way towards the target if it is out of reach (for a short time at most),
## breathes in visibly, then breathes along the target's direction (or where Aurelia aims when there is no target).
## Data: {"target": Enemy or null, "direction": Vector3}.

enum Phase { APPROACH, WIND_UP }

var _target: Enemy
var _direction := Vector3.FORWARD
var _phase := Phase.APPROACH
var _time := 0.0


func enter(_previous: StringName, data: Dictionary) -> void:
	var dragon := actor as Dragon
	_target = data.get("target") as Enemy
	_direction = data.get("direction", dragon.forward())
	_time = 0.0
	_phase = Phase.APPROACH
	if not _needs_to_close_in(dragon):
		_start_wind_up(dragon)


func physics_update(delta: float) -> void:
	var dragon := actor as Dragon
	_time += delta
	if _phase == Phase.APPROACH:
		if not Dragon.is_live_enemy(_target) or not _needs_to_close_in(dragon) \
				or _time >= Dragon.TUNING.skill_approach_time:
			_start_wind_up(dragon)
			return
		dragon.move_to(_target.global_position, dragon.run_speed() * Dragon.TUNING.catch_up_multiplier, delta)
		return
	dragon.move_with(Vector3.ZERO, delta)
	if Dragon.is_live_enemy(_target):
		_direction = _target.global_position - dragon.global_position
	dragon.face(_direction)
	if _time >= dragon.skill.wind_up:
		dragon.breathe(_direction)
		machine.transition_to(dragon.command_state())


func _needs_to_close_in(dragon: Dragon) -> bool:
	if not Dragon.is_live_enemy(_target):
		return false
	var offset := _target.global_position - dragon.global_position
	offset.y = 0.0
	return offset.length() > dragon.skill.radius * 0.75


func _start_wind_up(dragon: Dragon) -> void:
	_phase = Phase.WIND_UP
	_time = 0.0
	dragon.visual.play_inhale(dragon.skill.wind_up)
	dragon.chirp()
