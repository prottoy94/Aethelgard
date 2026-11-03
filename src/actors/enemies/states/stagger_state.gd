extends State
## Staggered (by Gust or heavy hits) or frozen: interrupted and stunned while knocked back.
## Optional enter data: {"time": seconds} (Freeze); otherwise the enemy's stagger time.

var _time := 0.0
var _length := 0.0


func enter(_previous: StringName, data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	_length = float(data.get("time", enemy.data.stagger_time))
	enemy.attack_hitbox.deactivate()
	enemy.visual.set_telegraph(-1.0)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= _length:
		machine.transition_to(&"Chase" if enemy.has_live_target() else &"Idle")
