extends State
## Staggered (by Gust or heavy hits): interrupted and briefly stunned while knocked back.

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	enemy.attack_hitbox.deactivate()
	enemy.visual.set_telegraph(-1.0)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	if _time >= enemy.data.stagger_time:
		machine.transition_to(&"Chase" if enemy.has_live_target() else &"Idle")
