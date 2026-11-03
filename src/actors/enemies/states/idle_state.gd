extends State
## Wanders slowly around its home spot until the player comes within aggro range.

const WANDER_RADIUS := 3.0
const WANDER_PAUSE := Vector2(1.5, 3.5)  ## s between wander moves

var _goal := Vector3.ZERO
var _pause := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	var enemy := actor as Enemy
	enemy.visual.set_telegraph(-1.0)
	_goal = enemy.global_position
	_pause = randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	if enemy.distance_to_target() <= enemy.data.aggro_range:
		machine.transition_to(&"Chase")
		return
	_pause -= delta
	if _pause <= 0.0:
		_goal = enemy.home + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf() * WANDER_RADIUS
		_pause = randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
	var to_goal := _goal - enemy.global_position
	to_goal.y = 0.0
	var velocity := to_goal.normalized() * enemy.data.wander_speed if to_goal.length() > 0.3 else Vector3.ZERO
	enemy.move(velocity, delta)
