extends State
## The warning before every attack (FR-CMB-05): the enemy stops, faces the player and shows a growing
## ring on the ground. Dash out of the ring, or dash through the hit, before it ends.
## Melee enemies join the "danger_zone" group while winding up, so the pet dragon steps out of the ring.

const DANGER_GROUP: StringName = &"danger_zone"

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	enemy.play_sound("telegraph")  # starts with the visual wind-up and lasts as long (FR-AUD-03)
	if enemy.has_live_target():
		enemy.face(enemy.direction_to(enemy.target.global_position))
	if enemy.data.min_range <= 0.0:
		enemy.add_to_group(DANGER_GROUP)


func exit() -> void:
	var enemy := actor as Enemy
	enemy.visual.set_telegraph(-1.0)
	if enemy.is_in_group(DANGER_GROUP):
		enemy.remove_from_group(DANGER_GROUP)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	enemy.visual.set_telegraph(_time / enemy.data.telegraph_time)
	if _time >= enemy.data.telegraph_time:
		machine.transition_to(&"Attack")
