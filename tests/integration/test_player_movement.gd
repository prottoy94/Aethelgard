extends GutTest
## Drives the real player scene in a small physics world: walk, dash, stairs ramp, ledge, interaction.
## Uses simulated input (Input.action_press) and real physics frames.

const PLAYER_SCENE := preload("res://src/actors/player/player.tscn")
const LEDGE_HEIGHT := 1.2

var world: Node3D
var player: Player


func before_each() -> void:
	world = Node3D.new()
	add_child_autofree(world)
	_box(Vector3(60, 1, 60), Vector3(0, -0.5, 0))                            # floor
	_box(Vector3(6, LEDGE_HEIGHT, 6), Vector3(20, LEDGE_HEIGHT / 2.0, -10))  # platform (ledge)
	var ramp := StaticBody3D.new()                                            # stairs ramp in front of it
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 0.1, Vector2(2.4, LEDGE_HEIGHT).length())
	shape.shape = box
	shape.rotation.x = atan2(LEDGE_HEIGHT, 2.4)
	shape.position = Vector3(0, LEDGE_HEIGHT / 2.0 - 0.05, 0)
	ramp.add_child(shape)
	ramp.position = Vector3(20, 0, -7 + 1.2)
	world.add_child(ramp)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	world.add_child(player)
	await wait_physics_frames(5)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	world.add_child(body)


func test_walks_right_and_turns() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(60)
	Input.action_release(&"move_right")
	assert_gt(player.global_position.x, 3.0, "walked about 5 m/s for 1 s")
	assert_lt(player.global_position.x, 6.0, "not faster than walk speed")
	assert_almost_eq(player.facing_direction().x, 1.0, 0.05, "faces the way it walks")
	assert_true(player.state_machine.is_in(&"Move"))


func test_stops_when_input_released() -> void:
	Input.action_press(&"move_up")
	await wait_physics_frames(30)
	Input.action_release(&"move_up")
	await wait_physics_frames(20)
	assert_true(player.state_machine.is_in(&"Idle"))
	assert_almost_eq(Vector2(player.velocity.x, player.velocity.z).length(), 0.0, 0.01)


func test_dash_is_fast_has_iframes_and_cooldown() -> void:
	var start := player.global_position
	player.request_dash()
	await wait_physics_frames(2)
	assert_true(player.state_machine.is_in(&"Dash"))
	assert_true(player.is_invulnerable, "invulnerable during the dash")
	await wait_physics_frames(14)
	assert_false(player.state_machine.is_in(&"Dash"), "dash ends after about 0.18 s")
	var dashed := player.global_position.distance_to(start)
	assert_gt(dashed, 2.0, "dash covers about 2.7 m, much more than walking")
	assert_false(player.dash_cooldown.is_ready(), "cooldown running")
	player.request_dash()
	await wait_physics_frames(2)
	assert_false(player.state_machine.is_in(&"Dash"), "no second dash during the cooldown")
	await wait_physics_frames(40)
	assert_false(player.is_invulnerable)


func test_climbs_stairs_ramp_without_jumping() -> void:
	player.global_position = Vector3(20, 0.05, -4.0)
	await wait_physics_frames(3)
	Input.action_press(&"move_up")
	await wait_physics_frames(60)  # reaches the top after ~40 frames; much longer walks off the far edge
	Input.action_release(&"move_up")
	assert_gt(player.global_position.y, LEDGE_HEIGHT - 0.1, "reached the platform top")
	assert_lt(player.global_position.z, -7.0, "standing on the platform, past the stairs")


func test_ledge_blocks_without_stairs() -> void:
	player.global_position = Vector3(14.0, 0.05, -10)  # west of the platform, walking east into its side
	await wait_physics_frames(3)
	Input.action_press(&"move_right")
	await wait_physics_frames(90)
	Input.action_release(&"move_right")
	assert_lt(player.global_position.y, 0.3, "a 1.2 m ledge cannot be climbed")
	assert_lt(player.global_position.x, 17.0, "stopped at the wall")


func test_interact_with_nearby_interactable() -> void:
	var interactable := InteractableComponent.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	shape.shape = sphere
	interactable.add_child(shape)
	interactable.position = Vector3(0, 0.8, -1.0)
	world.add_child(interactable)
	watch_signals(interactable)
	await wait_physics_frames(5)
	assert_true(player.try_interact(), "something to interact with")
	assert_signal_emitted(interactable, "interacted")
	interactable.global_position = Vector3(30, 0.8, 30)
	await wait_physics_frames(5)
	assert_false(player.try_interact(), "nothing in range after it moved away")
