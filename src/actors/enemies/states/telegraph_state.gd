extends State
## The warning before every attack (FR-CMB-05): the enemy stops, faces the player and shows a growing
## ring on the ground. Dash out of the ring, or dash through the hit, before it ends.
## Melee enemies join the "danger_zone" group while winding up, so the pet dragon steps out of the ring.

const DANGER_GROUP: StringName = &"danger_zone"

var _time := 0.0


func enter(_previous: StringName, _data: Dictionary) -> void:
	_time = 0.0
	var enemy := actor as Enemy
	enemy.begin_telegraph()  # its sound starts with the visual wind-up and lasts as long (FR-AUD-03)
	if enemy.threatens_area():
		enemy.add_to_group(DANGER_GROUP)


func exit() -> void:
	var enemy := actor as Enemy
	enemy.end_telegraph()
	if enemy.is_in_group(DANGER_GROUP):
		enemy.remove_from_group(DANGER_GROUP)


func physics_update(delta: float) -> void:
	var enemy := actor as Enemy
	_time += delta
	enemy.move(Vector3.ZERO, delta)
	enemy.update_telegraph(_time / enemy.telegraph_time())
	if _time >= enemy.telegraph_time():
		machine.transition_to(&"Attack")
